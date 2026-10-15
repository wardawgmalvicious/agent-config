#!/usr/bin/env bash
# Exercise skills/meta/scope-instructions/scripts/folder-sessions.py against a
# fake repo and a fake session store.
#
# The script reads a transcript format the docs call internal, so each record
# here is planted in the shape 2.1.293 writes, chained by parentUuid as Claude
# Code chains them, and each behaviour must come back right: a README a prompt
# @-mentions, a worktree's paths, a probe, and the loads that follow parallel
# calls. Its first version pinned a load to the last result in its batch, so
# on 2026-10-15 it left 295 of this repo's loads "after Bash", where pinning a
# rule by its globs leaves 29; and it never pinned a nested AGENTS.md, whose
# hook context is a list of strings and whose toolUseID ends "-context".
#
#     bash tests/scripts/folder-sessions/test-folder-sessions.sh
#
# shellcheck disable=SC2016 # every $name in a single-quoted filter is jq's
set -u

here=$(cd "$(dirname "$0")" && pwd)
repo=$(cd "$here/../../.." && pwd)
tmproot=$(mktemp -d)
trap 'rm -rf "$tmproot"' EXIT

pass=0
fail=0

# A native Windows python resolves a /tmp path to C:\tmp, not %TEMP%, so
# hand it a Windows path wherever cygpath exists to make one.
native() {
    if command -v cygpath >/dev/null; then cygpath -w -l "$1"; else echo "$1"; fi
}
check() { # <label> <condition-exit-code>
    if [ "$2" = 0 ]; then
        pass=$((pass + 1))
        echo "  ok   $1"
    else
        fail=$((fail + 1))
        echo "  FAIL $1"
        sed 's/^/       | /' "$tmproot/out"
    fi
}
# The script leaves out the session CLAUDE_CODE_SESSION_ID names, and a run
# inside Claude Code inherits its own, so each run clears it unless a case
# sets $asking.
run() {
    env -u CLAUDE_CODE_SESSION_ID ${asking:+"CLAUDE_CODE_SESSION_ID=$asking"} \
        CLAUDE_CONFIG_DIR="$(native "$store")" PYTHONIOENCODING=utf-8 \
        uv run --quiet --no-project "$repo/skills/meta/scope-instructions/scripts/folder-sessions.py" \
        --repo "$ROOT" "$@" >"$tmproot/out" 2>&1
    echo $? >"$tmproot/rc"
}
rc() { cat "$tmproot/rc"; }
asking=
# jqt <filter>: 0 when the filter holds on the last run's JSON
jqt() { jq -b -e "$1" <"$tmproot/out" >/dev/null; echo $?; }
# folder <name>: a filter selecting one folder of that JSON
folder() { printf '.folders[] | select(.folder == "%s")' "$1"; }

# The fake repo. Folder names keep their case, which the report must too.
mkdir -p "$tmproot/repo/Contracts" "$tmproot/repo/sql" "$tmproot/repo/docs"
for f in Contracts/README.md Contracts/CLAUDE.md Contracts/orders.md \
    sql/AGENTS.md sql/orders.sql docs/guide.md; do
    : >"$tmproot/repo/$f"
done
ROOT=$(native "$tmproot/repo")
HOMEW=$(native "$HOME")

# Each record goes to $f, chained to the one before it by parentUuid, with the
# session's $cwd. A path is given relative to the session's checkout, $base,
# unless it opens with a drive, and written as Windows writes it; $msg is the
# API response a tool call belongs to. The helpers expand parameters rather
# than spawn $(...), since a spawn can cost 2 s in a degraded Git Bash
# (2026-10-15).
n=0
last=
begin() { # <project-dir> <session-id> <cwd>: start a transcript
    mkdir -p "$1"
    f=$1/$2.jsonl
    cwd=$3
    base=$3
    last=
}
win() { # <path>: REPLY = the path as a Windows path
    case $1 in
    [A-Za-z]:*) REPLY=$1 ;;
    *) REPLY="$base/$1" ;;
    esac
    REPLY=${REPLY//\//\\}
}
rec() { # <jq-object> [--arg name value]...: append one record
    local body=$1
    shift
    n=$((n + 1))
    jq -b -nc --arg rec_uuid "u$n" --arg rec_parent "$last" --arg rec_cwd "$cwd" "$@" \
        "($body)"' + {uuid: $rec_uuid, cwd: $rec_cwd, version: "2.1.293"}
        + (if $rec_parent == "" then {} else {parentUuid: $rec_parent} end)' >>"$f"
    last=u$n
}
prompt() { # <text>
    rec '{type: "user", message: {role: "user", content: $t}}' --arg t "$1"
}
call() { # <id> <tool> <input>: one tool call in response $msg, then its result
    local key=file_path value=$3
    case $2 in
    Bash) key='command' ;;
    Agent) key='prompt' ;;
    Grep) key='pattern' ;;
    *)
        win "$3"
        value=$REPLY
        ;;
    esac
    rec '{type: "assistant", message: {id: $m, role: "assistant",
          content: [{type: "tool_use", id: $id, name: $n, input: {($k): $v}}]}}' \
        --arg m "$msg" --arg id "$1" --arg n "$2" --arg k "$key" --arg v "$value"
    rec '{type: "user", message: {role: "user",
          content: [{type: "tool_result", tool_use_id: $id, content: "ok"}]}}' --arg id "$1"
}
reply() { # <text>
    rec '{type: "assistant", message: {id: $m, role: "assistant",
          content: [{type: "text", text: $t}]}}' --arg m "$msg" --arg t "$1"
}
mention() { # <path>: a prompt's @-mention, which puts the file in context
    win "$1"
    rec '{type: "attachment", attachment: {type: "file", filename: $p, displayPath: $p,
          content: {}}}' --arg p "$REPLY"
}
nested() { # <path> [globs-json]: a nested CLAUDE.md, or a rule and its paths: globs
    win "$1"
    rec '{type: "attachment", attachment: {type: "nested_memory", path: $p, displayPath: $p,
          content: ({type: "Project", content: "rules"} + (if $g then {globs: $g} else {} end))}}' \
        --arg p "$REPLY" --argjson g "${2:-null}"
}
agents() { # <path> <call-id>: a nested AGENTS.md, as its PostToolUse hook context carries it
    win "$1"
    rec '{type: "attachment", attachment: {type: "hook_additional_context",
          content: ["Contents of \($p):\n\nrules"], hookName: "tool.call",
          hookEvent: "PostToolUse", toolUseID: "\($id)-context"}}' --arg p "$REPLY" --arg id "$2"
}
compacted() { rec '{type: "system", subtype: "compact_boundary", content: "compacted"}'; }
title() { rec '{type: "custom-title", customTitle: $t}' --arg t "$1"; }

# Claude Code names a project directory after the launch directory, every
# character but a letter or digit made "-" (sessions page, 2026-10-15).
store=$tmproot/config
P=$store/projects/${ROOT//[^A-Za-z0-9]/-}

# s1: types the README's path, Reads it first, then edits beside it.
begin "$P" 11111111-1111-4111-8111-111111111111 "$ROOT"
msg='m1'
prompt 'read Contracts/README.md, then tidy the contracts'
call t1 Read Contracts/README.md
call t2 Read Contracts/orders.md
call t3 Edit Contracts/orders.md
# s2: opens the README only after another file, loading a user-scope rule.
begin "$P" 22222222-2222-4222-8222-222222222222 "$ROOT"
msg='m2'
prompt 'fix the orders contract'
call t4 Read Contracts/orders.md
nested "$HOMEW/.claude/rules/coding-markdown.md" '["**/*.md"]'
call t5 Read Contracts/README.md
# s3: never opens it, and compacts.
begin "$P" 33333333-3333-4333-8333-333333333333 "$ROOT"
msg='m3'
prompt 'read the orders contract'
call t6 Read Contracts/orders.md
compacted
prompt 'carry on'
# s4: @-mentions the README before any call; the folder's CLAUDE.md arrives
# with it, following no tool call.
begin "$P" 44444444-4444-4444-8444-444444444444 "$ROOT"
msg='m4'
prompt '@Contracts/README.md follow it'
mention Contracts/README.md
nested Contracts/CLAUDE.md
call t7 Read Contracts/orders.md
# s5: @-mentions a file and works nowhere.
begin "$P" 55555555-5555-4555-8555-555555555555 "$ROOT"
msg='m5'
prompt '@docs/guide.md what does this say'
mention docs/guide.md
reply 'it says hello'
# s6: works in docs/.
begin "$P" 66666666-6666-4666-8666-666666666666 "$ROOT"
msg='m6'
prompt 'proofread the guide'
call t8 Read docs/guide.md
# s7: a worktree session, whose project directory spells the drive c--.
WT="$ROOT\\.claude\\worktrees\\wt"
WTDIR=${WT//[^A-Za-z0-9]/-}
begin "$store/projects/c${WTDIR:1}" 77777777-7777-4777-8777-777777777777 "$WT"
msg='m7'
prompt 'check the sql'
call t9 Read sql/orders.sql
# s8: three calls in one response; every load after them chains to the last.
begin "$P" 88888888-8888-4888-8888-888888888888 "$ROOT"
msg='m8'
prompt 'compare the contract and the table'
call t10 Read Contracts/orders.md
call t11 Read sql/orders.sql
agents sql/AGENTS.md t11
call t12 Bash 'git status'
nested .claude/rules/sql.md '["**/*.sql"]'
nested .claude/rules/contracts.md '["Contracts"]' # the record's form of Contracts/**
nested .claude/rules/agents.md '["sql/orders.sql"]' # a rule, though named as AGENTS.md is
# s9: a rule after a Bash view that no Read matches, then one after a later
# prompt's @-mention, whose chain runs on into the turn before, to a Grep.
begin "$P" 99999999-9999-4999-8999-999999999999 "$ROOT"
msg='m9'
prompt 'look at the queries'
call t13 Read sql/orders.sql
call t14 Bash 'cat queries/a.kql'
nested .claude/rules/kql.md '["**/*.kql"]'
call t19 Grep 'TODO'
reply 'read them'
prompt '@notes.txt and this'
mention notes.txt
nested .claude/rules/dax.md '["**/*.dax"]'
# s10: a probe, by name.
begin "$P" aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa "$ROOT"
title 'probe: loader'
msg='m10'
prompt 'read it'
call t15 Read Contracts/orders.md
# s11: works in sql/ only through a subagent.
begin "$P" bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb "$ROOT"
msg='m11'
prompt 'have an agent read the schema'
call t16 Agent 'read sql/schema.sql'
begin "$P/bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb/subagents" agent-a1 "$ROOT"
msg='m12'
call t17 Read sql/schema.sql
# s12: another repo whose path starts with this one's.
TWO="$ROOT-two"
begin "$store/projects/${TWO//[^A-Za-z0-9]/-}" cccccccc-cccc-4ccc-8ccc-cccccccccccc "$TWO"
msg='m13'
prompt 'tidy'
call t18 Read Contracts/orders.md

echo "-- what counts as work --"
run --json --min 1
check "exits 0 on a store with sessions" "$([ "$(rc)" = 0 ] && echo 0 || echo 1)"
check "counts each session once per folder it worked in" "$(jqt "$(folder Contracts) | .worked == 5")"
check "counts the sessions that edited" "$(jqt "$(folder Contracts) | .edited == 1")"
check "README read first, later, never" \
    "$(jqt "$(folder Contracts) | .readme_opened | .first == 2 and .later == 1 and .never == 2")"
check "a README @-mentioned before any call is first, and named, as one typed is" \
    "$(jqt "$(folder Contracts) | .readme_opened.first_named_by_user == 2")"
check "another file @-mentioned is not work" "$(jqt "$(folder docs) | .worked == 1")"
check "counts the sessions that compacted" "$(jqt "$(folder Contracts) | .compacted == 1")"
check "work through a subagent alone is counted apart" \
    "$(jqt "$(folder sql) | .subagent_only == 1")"
check "a worktree session is folded into its repo" \
    "$(jqt "($(folder sql) | .worked == 3) and ([.folders[].folder | select(startswith(\".claude\"))] == [])")"
check "a repo whose path starts with this one's is left out" "$(jqt '.sessions == 10')"

echo "-- what loaded there --"
check "a nested file that follows no file call is pinned to its own folder" \
    "$(jqt "$(folder Contracts) | .loaded[\"Contracts/CLAUDE.md\"] == 1")"
check "a nested AGENTS.md, from its hook's list of strings, is pinned to its folder" \
    "$(jqt "$(folder sql) | .loaded[\"sql/AGENTS.md\"] == 1")"
check "a rule after parallel calls goes to the file its globs match, not the last call" \
    "$(jqt "($(folder sql) | .loaded[\".claude/rules/sql.md\"] == 1)
            and ($(folder Contracts) | .loaded[\".claude/rules/sql.md\"] == null)")"
check "a recorded glob covers what lies under what it names" \
    "$(jqt "$(folder Contracts) | .loaded[\".claude/rules/contracts.md\"] == 1")"
check "a rule whose file is named agents.md still pins by its globs" \
    "$(jqt "$(folder sql) | .loaded[\".claude/rules/agents.md\"] == 1")"
check "a user-scope rule prints from ~" \
    "$(jqt "$(folder Contracts) | .loaded[\"~/.claude/rules/coding-markdown.md\"] == 1")"
check "a rule no touched file matches is counted by the call it follows" \
    "$(jqt '.unpinned_loads.Bash == 1')"
check "a load after a later prompt follows no call, not the turn before's" \
    "$(jqt '.unpinned_loads == {"Bash": 1, "no call": 1}')"
run
check "folder names print as written" "$(grep -q '^Contracts/  holds README.md, CLAUDE.md$' "$tmproot/out"; echo $?)"
check "the summary gives the reach and the loads pinned nowhere" \
    "$(grep -q 'from 10 sessions' "$tmproot/out" && grep -q 'versions 2.1.293 to 2.1.293' "$tmproot/out" &&
        grep -q 'Loads pinned to no folder: 1 after Bash, 1 after no call' "$tmproot/out"; echo $?)"

echo "-- filters --"
run --json --min 1 --probes
check "probes are left out unless --probes" "$(jqt "$(folder Contracts) | .worked == 6")"
asking=66666666-6666-4666-8666-666666666666
run --json --min 1
asking=
check "leaves out the session running the script" "$(jqt "[$(folder docs)] == []")"
run --json --min 1 --folder sql
check "--folder keeps only that folder" "$(jqt '[.folders[].folder] == ["sql"]')"

echo "-- failing loudly --"
store=$tmproot/empty
mkdir -p "$store/projects"
run
check "no session ran in the repo: exits 1" "$([ "$(rc)" = 1 ] && echo 0 || echo 1)"
check "and says so" "$(grep -q 'no session under' "$tmproot/out"; echo $?)"
store=$tmproot/nocwd
mkdir -p "$store/projects/${ROOT//[^A-Za-z0-9]/-}"
printf '%s\n' '{"kind":"turn","body":"x"}' \
    >"$store/projects/${ROOT//[^A-Za-z0-9]/-}/dddddddd-dddd-4ddd-8ddd-dddddddddddd.jsonl"
run
check "transcripts with no session directory read: exits 2" "$([ "$(rc)" = 2 ] && echo 0 || echo 1)"
check "and says the format may have changed" "$(grep -q 'format may have changed' "$tmproot/out"; echo $?)"
store=$tmproot/nomessage
begin "$store/projects/${ROOT//[^A-Za-z0-9]/-}" eeeeeeee-eeee-4eee-8eee-eeeeeeeeeeee "$ROOT"
rec '{type: "turn", body: "x"}'
run
check "transcripts with no message read: exits 2" "$([ "$(rc)" = 2 ] && echo 0 || echo 1)"

echo
echo "$pass passed, $fail failed"
[ "$fail" = 0 ]
