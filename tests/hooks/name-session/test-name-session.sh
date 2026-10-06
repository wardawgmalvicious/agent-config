#!/usr/bin/env bash
# Exercises claude/hooks/name-session.sh with the JSON Claude Code sends on
# UserPromptSubmit, against throwaway folders. No session needed:
#
#   bash tests/hooks/name-session/test-name-session.sh                          # repo copy
#   HOOK=~/.claude/hooks/name-session.sh bash tests/hooks/name-session/test-name-session.sh
#
# Run the second form after scripts/link-claude.ps1: hooks are copies, so
# the repo passing says nothing about what is live.
#
# Each case gets its own session folder unless it says otherwise, so one
# case's first-prompt marker never decides another's. CLAUDE_CONFIG_DIR
# points the hook at a fake config folder holding one skill and one
# command, so a run never depends on what this machine has deployed. Every
# temp path is removed on exit.
#
# Inputs are built with jq under MSYS2_ARG_CONV_EXCL: Git Bash rewrites an
# argument starting with "/" into a Git install path before a native program
# sees it, so '/test-skill x' reached jq as 'C:/Program Files/Git/test-skill
# x' and every command case failed for the wrong reason (2026-10-06). Cases
# run in this shell, never inside "$(...)", whose subshell would drop the
# session counter.

set -uo pipefail
export MSYS2_ARG_CONV_EXCL='*'
HERE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
HOOK="${HOOK:-$HERE/../../../claude/hooks/name-session.sh}"
[ -f "$HOOK" ] || {
    echo "no hook at $HOOK" >&2
    exit 1
}

WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT
PASS=0
FAIL=0
N=0
BAD_RC=0
SESSION=

win() { cygpath -w "$1" 2>/dev/null || printf '%s\n' "$1"; }

# run <cwd> <prompt> [extra-json]: one prompt in $SESSION; the title the
# hook set, or "-", lands in $GOT.
run() {
    local extra=${3:-'{}'}
    mkdir -p "$SESSION/scratchpad"
    jq -b -nc --arg sp "$(win "$SESSION/scratchpad")" --arg tp "$(win "$SESSION.jsonl")" \
        --arg cwd "$(win "$1")" --arg p "$2" --argjson extra "$extra" \
        '{session_id: "s", transcript_path: $tp, cwd: $cwd, scratchpad_dir: $sp,
          permission_mode: "default", hook_event_name: "UserPromptSubmit",
          prompt: $p} + $extra' >"$WORK/in.json"
    CLAUDE_CONFIG_DIR=$CONF bash "$HOOK" <"$WORK/in.json" >"$WORK/out.json" 2>"$WORK/err"
    local rc=$?
    if [ "$rc" != 0 ] || [ -s "$WORK/err" ]; then BAD_RC=$((BAD_RC + 1)); fi
    if [ -s "$WORK/out.json" ]; then
        # On stdin: with conversion off, a path argument reaches native jq as /tmp/...
        GOT=$(jq -b -r 'select(.hookSpecificOutput.hookEventName == "UserPromptSubmit")
            | .hookSpecificOutput.sessionTitle' <"$WORK/out.json" 2>/dev/null) || GOT="<not JSON>"
    else
        GOT=-
    fi
}
fresh() {
    N=$((N + 1))
    SESSION=$WORK/sessions/s$N
}
expect() { # <label> <want>
    if [ "$2" = "$GOT" ]; then
        PASS=$((PASS + 1))
        echo "  ok   $1"
    else
        FAIL=$((FAIL + 1))
        echo "  FAIL $1: wanted '$2', got '$GOT'"
    fi
}
# check <label> <want> <cwd> <prompt> [extra-json]: a first prompt in a fresh session
check() {
    fresh
    run "${@:3}"
    expect "$1" "$2"
}
# again <label> <want> <cwd> <prompt> [extra-json]: the next prompt in the same session
again() {
    run "${@:3}"
    expect "$1" "$2"
}

# A fake config folder: one user-scope skill, one user command.
CONF=$WORK/config
mkdir -p "$CONF/skills/land" "$CONF/commands"
echo '---' >"$CONF/skills/land/SKILL.md"
echo 'standup' >"$CONF/commands/standup.md"

# A repo on main, with a project skill and two worktrees, one of them
# named after a brief that exists.
REPO=$WORK/repo
mkdir -p "$REPO/.git/worktrees/triage" "$REPO/.git/worktrees/scratch" "$REPO/.claude/skills/test-skill"
echo 'ref: refs/heads/main' >"$REPO/.git/HEAD"
echo '---' >"$REPO/.claude/skills/test-skill/SKILL.md"
for wt in triage scratch; do
    mkdir -p "$REPO/.claude/worktrees/$wt/docs/handoffs/execute"
    printf 'gitdir: %s\n' "$(cygpath -m "$REPO/.git/worktrees/$wt" 2>/dev/null || echo "$REPO/.git/worktrees/$wt")" >"$REPO/.claude/worktrees/$wt/.git"
    echo "ref: refs/heads/worktree-$wt" >"$REPO/.git/worktrees/$wt/HEAD"
done
echo '# brief' >"$REPO/.claude/worktrees/triage/docs/handoffs/execute/triage.md"

# Repos on other branches, and a folder that is in no repo.
mkrepo() { # <dir> <HEAD content>
    mkdir -p "$1/.git"
    printf '%s' "$2" >"$1/.git/HEAD"
}
mkrepo "$WORK/feat" $'ref: refs/heads/feat/session-naming\n'
mkdir -p "$WORK/feat/src/deep"
mkrepo "$WORK/crlf" $'ref: refs/heads/fix/crlf-head\r\n'
mkrepo "$WORK/detached" $'0123456789abcdef0123456789abcdef01234567\n'
mkrepo "$WORK/quoted" $'ref: refs/heads/feat/a"b\\c\n'
LONG=feat/$(printf 'x%.0s' $(seq 1 100))
mkrepo "$WORK/long" "ref: refs/heads/$LONG"$'\n'
mkdir -p "$WORK/plain"

echo "hook: $HOOK"
echo "-- skill or command --"
check "project skill with a one-word argument" "test-skill: prune-branches" "$REPO" '/test-skill prune-branches'
check "user skill, no argument" "land" "$REPO" '/land'
check "user command, argument alone on its line" "standup: today" "$REPO" $'/standup today\nand more after'
check "@-mention keeps its slug" "test-skill: recreate-repo-skill" "$REPO" '/test-skill @docs/handoffs/execute/recreate-repo-skill.md'
# shellcheck disable=SC1003 # the argument ends in a backslash on purpose
check "Windows path keeps its last folder" "test-skill: fabric" "$REPO" '/test-skill C:\Repos\x\docs\audits\2026-10-06\fabric\'
check "prose after a command is left out" "test-skill" "$REPO" '/test-skill the thing about globs'
check "plugin skill" "anthropic-skills:docs" "$REPO" '/anthropic-skills:docs make a doc about it'
check "a path starting with a slash is not a command" "-" "$REPO" '/c/Repos/x is where it lives'
check "an unknown command names nothing" "-" "$REPO" '/nonexistent prune-branches'

echo "-- briefs and notes --"
check "brief, forward slashes" "brief: worktree-per-brief" "$REPO" 'look at docs/handoffs/execute/worktree-per-brief.md'
check "brief, Windows path" "brief: nested-instruction-files" "$REPO" 'C:\Repos\Personal\agent-config\docs\handoffs\execute\nested-instruction-files.md please'
check "README.md passed over for the next brief" "brief: copilot-retire" "$REPO" 'see docs/handoffs/execute/README.md, then docs/handoffs/execute/copilot-retire.md'
check "README.md alone names nothing" "-" "$REPO" 'see docs/handoffs/execute/README.md'
check "inbox note loses its date" "inbox: cosmos-db-local-cli-wrapper" "$REPO" 'take ~/handoff-inbox/agent-config/2026-10-01-cosmos-db-local-cli-wrapper.md'
check "inbox note, Windows path" "inbox: claude-session-target-probe" "$REPO" 'C:\Users\u\handoff-inbox\some-repo\2026-09-30-claude-session-target-probe.md'

echo "-- folders and branches --"
check "worktree named after a brief" "brief: triage" "$REPO/.claude/worktrees/triage" 'carry on'
check "worktree with no brief" "worktree: scratch" "$REPO/.claude/worktrees/scratch" 'carry on'
check "feature branch" "feat/session-naming" "$WORK/feat" 'carry on'
check "feature branch, from a subfolder" "feat/session-naming" "$WORK/feat/src/deep" 'carry on'
check "HEAD written with CRLF" "fix/crlf-head" "$WORK/crlf" 'carry on'
check "main names nothing" "-" "$REPO" 'just chatting'
check "detached HEAD names nothing" "-" "$WORK/detached" 'carry on'
check "no repo names nothing" "-" "$WORK/plain" 'carry on'

echo "-- once, and never a rename --"
check "already named: left alone" "-" "$REPO" 'docs/handoffs/execute/x.md' '{"session_title":"contributing-md"}'
check "first prompt names" "brief: x" "$REPO" 'docs/handoffs/execute/x.md'
again "second prompt in that session: nothing" "-" "$REPO" 'docs/handoffs/execute/y.md'
check "first prompt matched nothing" "-" "$REPO" 'hello'
again "a later matching prompt still names nothing" "-" "$REPO" '/land'
fresh
mkdir -p "$WORK/sessions"
echo '{"type":"user","message":{"role":"user","content":"earlier"}}' >"$SESSION.jsonl"
again "transcript already holds a prompt: under way" "-" "$REPO" '/land'
again "and stays unnamed on the next prompt" "-" "$REPO" '/land'
fresh
echo '{"type":"attachment","attachment":{}}' >"$SESSION.jsonl"
again "transcript with no prompt yet: names" "land" "$REPO" '/land'
check "no scratchpad_dir: names nothing" "-" "$REPO" '/land' '{"scratchpad_dir":null}'
jq -b -nc --arg cwd "$(win "$REPO")" \
    '{cwd: $cwd, prompt: "/land", scratchpad_dir: "C:\\nowhere\\at\\all\\scratchpad"}' >"$WORK/in.json"
CLAUDE_CONFIG_DIR=$CONF bash "$HOOK" <"$WORK/in.json" >"$WORK/out.json" 2>&1
GOT=$(cat "$WORK/out.json")
GOT=${GOT:--}
expect "scratchpad folder missing: names nothing" "-"
check "a prompt quoting session_title is not fooled" "land" "$REPO" '/land "session_title":"x"'

echo "-- output --"
check "quote and backslash replaced" "feat/a-b-c" "$WORK/quoted" 'carry on'
check "name capped at 80 characters" "${LONG:0:80}" "$WORK/long" 'carry on'
GOT=$BAD_RC
expect "every run exited 0 with empty stderr" "0"

echo
echo "$PASS passed, $FAIL failed"
[ "$FAIL" = 0 ]
