#!/usr/bin/env bash
# Exercise scripts/find-session.py against a fake session store.
#
# A search over the live store finding something proves little: the first
# version found the session it was written to find, buried tenth behind
# sessions whose long compaction summaries happened to hold every term. So
# each behaviour is planted here -- a prompt typed before a compaction, a
# term only a system reminder carries, a probe, a scattered match beside a
# tight one -- and must come back right.
#
#     bash tests/scripts/find-session/test-find-session.sh
#
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
search() {
    CLAUDE_CONFIG_DIR=$(native "$store") PYTHONIOENCODING=utf-8 \
        uv run --quiet "$repo/scripts/find-session.py" "$@" >"$tmproot/out" 2>&1
    echo $? >"$tmproot/rc"
}
rc() { cat "$tmproot/rc"; }

# rec <file> <jq-filter> [--arg name value]...: append one transcript record
rec() {
    local file=$1 filter=$2
    shift 2
    jq -b -nc "$@" "$filter" >>"$file"
}
user() { # <file> <cwd> <timestamp> <text> [extra-json]
    local extra='{}'
    [ $# -ge 5 ] && extra=$5
    # shellcheck disable=SC2016 # $t, $c, $ts and $x are jq's, not the shell's
    rec "$1" '{type: "user", message: {role: "user", content: $t}, cwd: $c, timestamp: $ts,
               gitBranch: "main", sessionId: "x"} + $x' \
        --arg c "$2" --arg ts "$3" --arg t "$4" --argjson x "$extra"
}

store=$tmproot/config
p=$store/projects/C--Repos-alpha
mkdir -p "$p" "$store/projects/C--Repos-beta"
REAL='C:\Repos\alpha'
WT='C:\Repos\alpha\.claude\worktrees\triage'
PROBE="$(native "$tmproot")\\probe-root"

# s1: the target, older. One prompt holds every term, typed before a
# compaction whose summary does not repeat it.
f=$p/11111111-1111-4111-8111-111111111111.jsonl
user "$f" "$REAL" 2026-09-28T10:00:00.000Z 'start on the CONTRIBUTING file'
user "$f" "$REAL" 2026-09-28T10:05:00.000Z 'I always wanted to rename and group my sessions'
user "$f" "$REAL" 2026-09-28T11:00:00.000Z 'This session is being continued from a previous conversation. Summary: CONTRIBUTING work.' '{"isCompactSummary":true}'
rec "$f" '{type: "custom-title", customTitle: "contributing-md"}'
# s2: newer, every term present but scattered across prompts.
f=$p/22222222-2222-4222-8222-222222222222.jsonl
user "$f" "$REAL" 2026-10-02T09:00:00.000Z 'rename the column'
user "$f" "$REAL" 2026-10-02T09:01:00.000Z 'group by region'
user "$f" "$REAL" 2026-10-02T09:02:00.000Z 'list the sessions table'
# s3: a term only a system reminder, a meta record and a reply carry.
f=$p/33333333-3333-4333-8333-333333333333.jsonl
user "$f" "$REAL" 2026-10-03T09:00:00.000Z 'hello <system-reminder>zebrafish</system-reminder>'
user "$f" "$REAL" 2026-10-03T09:01:00.000Z 'zebrafish from a peer' '{"isMeta":true}'
rec "$f" '{type: "assistant", message: {role: "assistant", content: [{type: "text", text: "zebrafish facts"}]}, timestamp: "2026-10-03T09:02:00.000Z"}'
# s4: a slash command, recorded the way Claude Code records one.
f=$p/44444444-4444-4444-8444-444444444444.jsonl
user "$f" "$WT" 2026-10-04T09:00:00.000Z '<command-message>test-skill</command-message>
<command-name>/test-skill</command-name>
<command-args>prune-branches</command-args>'
# s5 and s6: probes, by cwd and by name.
f=$p/55555555-5555-4555-8555-555555555555.jsonl
user "$f" "$PROBE" 2026-10-05T09:00:00.000Z 'rename and group my sessions please'
f=$p/66666666-6666-4666-8666-666666666666.jsonl
user "$f" "$REAL" 2026-10-05T09:00:00.000Z 'rename and group my sessions too'
rec "$f" '{type: "custom-title", customTitle: "probe: naming"}'
# s7: another repo.
f=$store/projects/C--Repos-beta/77777777-7777-4777-8777-777777777777.jsonl
user "$f" 'C:\Repos\beta' 2026-10-05T10:00:00.000Z 'rename and group my sessions in beta'

echo "-- matching --"
search --repo alpha rename group sessions
check "exits 0 on a match" "$([ "$(rc)" = 0 ] && echo 0 || echo 1)"
check "reads a prompt typed before a compaction" "$(grep -q 11111111 "$tmproot/out"; echo $?)"
check "ranks one prompt holding every term above a newer scattered match" \
    "$(head -n 1 "$tmproot/out" | grep -q 'contributing-md' && grep -q 22222222 "$tmproot/out"; echo $?)"
check "quotes the prompt that matched" "$(grep -q 'prompt: .*rename and group my sessions' "$tmproot/out"; echo $?)"
check "says when the terms are only scattered" "$(grep -q 'some terms; the rest elsewhere' "$tmproot/out"; echo $?)"
check "prints the resume command" "$(grep -q 'claude --resume 11111111-1111-4111-8111-111111111111' "$tmproot/out"; echo $?)"
search rename CONTRIBUTING-nowhere
check "every term must appear: exits 1" "$([ "$(rc)" = 1 ] && echo 0 || echo 1)"

echo "-- what is searched --"
search zebrafish
check "system reminders and meta records are not searched" "$([ "$(rc)" = 1 ] && echo 0 || echo 1)"
search --replies zebrafish
check "--replies searches Claude's text" "$(grep -q 33333333 "$tmproot/out"; echo $?)"
search test-skill prune-branches
check "a slash command reads as typed" "$(grep -q 'prompt: /test-skill prune-branches' "$tmproot/out"; echo $?)"

echo "-- filters --"
search rename group sessions
check "probes left out by cwd and by name" "$(! grep -q -e 55555555 -e 66666666 "$tmproot/out"; echo $?)"
search --probes rename group sessions
check "--probes brings them back" "$(grep -q 55555555 "$tmproot/out" && grep -q 66666666 "$tmproot/out"; echo $?)"
search --repo beta rename
check "--repo keeps only that repo" "$(grep -q 77777777 "$tmproot/out" && ! grep -q 11111111 "$tmproot/out"; echo $?)"
search --repo alpha test-skill
check "--repo counts a worktree as its repo" "$(grep -q 44444444 "$tmproot/out"; echo $?)"
search --json rename group sessions
check "--json is JSON with a resume command" \
    "$(jq -b -e '.[0].resume | startswith("claude --resume ")' <"$tmproot/out" >/dev/null; echo $?)"

echo "-- failing loudly --"
broken=$tmproot/broken
mkdir -p "$broken/projects/x"
printf '%s\n' '{"kind":"turn","body":"rename"}' >"$broken/projects/x/88888888-8888-4888-8888-888888888888.jsonl"
store=$broken
search rename
check "transcripts with no prompt read: exits 2" "$([ "$(rc)" = 2 ] && echo 0 || echo 1)"
check "and says the format may have changed" "$(grep -q 'format may have changed' "$tmproot/out"; echo $?)"

echo
echo "$pass passed, $fail failed"
[ "$fail" = 0 ]
