#!/usr/bin/env bash
# Exercises claude/hooks/offer-handoff.sh with the JSON Claude Code sends on
# SessionStart, against throwaway repos. No session needed:
#
#   bash tests/hooks/offer-handoff/test-offer-handoff.sh                           # repo copy
#   HOOK=~/.claude/hooks/offer-handoff.sh bash tests/hooks/offer-handoff/test-offer-handoff.sh
#
# Run the second form after scripts/link-claude.ps1: hooks are copies, so
# the repo passing says nothing about what is live.
#
# The hook reads its stdin, so run by hand with none it waits: pipe it JSON,
# or give it </dev/null. Paths reach it in the long Windows form Claude Code
# records as a cwd.
#
# Which files are briefs is scripts/handoff-status.py's rule, restated in the
# hook because a hook spawns no Python. The last section runs that script
# over a fixture holding every case of the rule and compares its list with
# the hook's, so the copy cannot drift from its source unseen. It needs uv,
# and fails rather than passing without it.

set -uo pipefail
HERE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
HOOK="${HOOK:-$HERE/../../../claude/hooks/offer-handoff.sh}"
STATUS=$HERE/../../../scripts/handoff-status.py
[ -f "$HOOK" ] || {
    echo "no hook at $HOOK" >&2
    exit 1
}

WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT
PASS=0
FAIL=0
BAD_RC=0
OUT=

win() { cygpath -w -l "$1" 2>/dev/null || printf '%s\n' "$1"; }
ok() {
    PASS=$((PASS + 1))
    echo "  ok   $1"
}
bad() {
    FAIL=$((FAIL + 1))
    echo "  FAIL $1"
}

# hook <input-file>: one run of the hook; its stdout lands in $OUT.
hook() {
    bash "$HOOK" <"$1" >"$WORK/out" 2>"$WORK/err"
    local rc=$?
    if [ "$rc" != 0 ] || [ -s "$WORK/err" ]; then BAD_RC=$((BAD_RC + 1)); fi
    OUT=
    IFS= read -r -d '' OUT <"$WORK/out" || true
}
# run <cwd> [source] [extra-json]: the hook on a SessionStart input.
run() {
    local extra=${3:-'{}'}
    jq -b -nc --arg cwd "$(win "$1")" --arg src "${2:-compact}" --argjson extra "$extra" \
        '{session_id: "s", transcript_path: "t.jsonl", cwd: $cwd, permission_mode: "default",
          hook_event_name: "SessionStart", source: $src, model: "claude-opus-5-5"} + $extra' \
        >"$WORK/in.json"
    hook "$WORK/in.json"
}
# listed: the paths the last run listed, one per line, in byte order.
listed() {
    local line
    while IFS= read -r line; do
        [[ $line == '- '*': '* ]] || continue
        line=${line#- }
        printf '%s\n' "${line%%: *}"
    done <<<"$OUT" | LC_ALL=C sort
}
first_line() { printf '%s' "${OUT%%$'\n'*}"; }
speaks() { # <label>: the last run made the offer
    if [ "$(first_line)" = 'This session was just compacted. A compaction summary keeps conclusions and' ]; then
        ok "$1"
    else bad "$1: first line '$(first_line)'"; fi
}
silent() { # <label>: the last run printed nothing
    if [ -z "$OUT" ]; then ok "$1"; else bad "$1: printed '$(first_line)'"; fi
}
has() { # <label> <line>: the last run printed exactly that line
    if grep -Fxq -- "$2" <<<"$OUT"; then ok "$1"; else bad "$1: no line '$2'"; fi
}
same() { # <label> <want> <got>: two newline-separated lists match
    if [ "$2" = "$3" ]; then ok "$1"; else
        bad "$1"
        diff <(printf '%s\n' "$2") <(printf '%s\n' "$3") | sed 's/^/       | /'
    fi
}

# brief <file> <status> <priority> [needs] [blocked-by] [reopen-when]
brief() {
    mkdir -p "${1%/*}"
    {
        printf -- '---\nstatus: %s\npriority: %s\nneeds: %s\nblocked-by: %s\n' \
            "$2" "$3" "${4:-[]}" "${5:-[]}"
        if [ -n "${6:-}" ]; then printf 'reopen-when: %s\n' "$6"; fi
        printf 'written: 2026-10-06\n---\n\n# Brief\n'
    } >"$1"
}

# A repo whose queue holds every kind of line, and every file the rule
# passes over. Those carry frontmatter too, so one listed by mistake shows.
REPO=$WORK/repo
Q=$REPO/docs/handoffs
mkdir -p "$REPO/.git" "$REPO/docs/sub"
brief "$Q/execute/open-user.md" open 2 '[user]'
brief "$Q/execute/ready.md" open 3
brief "$Q/execute/blocked.md" open 2 '[user]' '[open-user.md]'
brief "$Q/execute/deferred.md" deferred 3 '[]' '[]' 'a /drift-audit run compacts mid-Phase-1'
printf -- '---\r\nstatus: open\r\npriority: 1\r\nneeds: []\r\nwritten: 2026-10-06\r\n---\r\n\r\n# CRLF\r\n' \
    >"$Q/execute/crlf.md"
printf '# No frontmatter\n\nstatus: open\n' >"$Q/execute/no-frontmatter.md"
printf -- '---\nstatus: open\npriority: 1\n' >"$Q/execute/unclosed.md"
printf -- '---\nstatus: open\npriority: 1\n---\n\nstatus: bogus\npriority: 9\n' >"$Q/execute/body-keys.md"
printf -- '---\nstatus:   open  \npriority:3\n---\n' >"$Q/execute/spaced.md"
brief "$Q/execute/declined.md" open 3
brief "$Q/.drafts/hidden.md" open 3
brief "$Q/flat.md" open 2
for p in README.md CLAUDE.md declined.md templates/t.md execute/README.md execute/AGENTS.md \
    execute/examples/e.md execute/notes.MD archive/Readme.md; do
    brief "$Q/$p" open 1
done

# A worktree inside it, holding a queue of its own.
WT=$REPO/.claude/worktrees/wt
mkdir -p "$WT"
printf 'gitdir: %s\n' "$(win "$REPO/.git/worktrees/wt")" >"$WT/.git"
brief "$WT/docs/handoffs/execute/wt-only.md" open 2

# A repo with no queue, one whose queue holds no brief, and a queue in no repo.
mkdir -p "$WORK/noqueue/.git" "$WORK/emptyq/.git"
brief "$WORK/emptyq/docs/handoffs/README.md" open 1
brief "$WORK/plain/docs/handoffs/execute/x.md" open 2

echo "hook: $HOOK"
echo "-- when it speaks --"
run "$REPO"
speaks "after a compaction"
has "names the list" "Briefs under docs/handoffs/:"
for src in startup resume clear fork; do
    run "$REPO" "$src"
    silent "source $src: nothing"
done
run "$REPO" compact '{"source":null}'
silent "no source: nothing"
hook /dev/null
silent "empty stdin: nothing"
printf 'not json' >"$WORK/garbage"
hook "$WORK/garbage"
silent "not JSON: nothing"
jq -b -n --arg cwd "$(win "$REPO")" '{cwd: $cwd, hook_event_name: "SessionStart", source: "compact"}' \
    >"$WORK/pretty.json"
hook "$WORK/pretty.json"
speaks "JSON with spaces after its colons"

echo "-- which checkout --"
run "$REPO"
FROM_ROOT=$(listed)
run "$REPO/docs/sub"
same "a subfolder lists its repo's queue" "$FROM_ROOT" "$(listed)"
export CLAUDE_PROJECT_DIR
CLAUDE_PROJECT_DIR=$(win "$REPO")
run "$WT"
same "a worktree lists its own queue, whatever CLAUDE_PROJECT_DIR says" "execute/wt-only.md" "$(listed)"
unset CLAUDE_PROJECT_DIR
run "$WORK/noqueue"
silent "a repo with no docs/handoffs/: nothing"
run "$WORK/plain"
silent "a queue in no checkout: nothing"
run "$WORK/emptyq"
has "a queue with no brief says none" "Briefs under docs/handoffs/: none."
run "$REPO" compact '{"cwd":null}'
silent "no cwd: nothing"

echo "-- which files are briefs --"
WANT=$(printf '%s\n' .drafts/hidden.md execute/blocked.md execute/body-keys.md execute/crlf.md \
    execute/declined.md execute/deferred.md execute/no-frontmatter.md execute/open-user.md \
    execute/ready.md execute/spaced.md execute/unclosed.md flat.md | LC_ALL=C sort)
same "every brief, and nothing the rule passes over" "$WANT" "$FROM_ROOT"

echo "-- each line --"
run "$REPO"
has "needs shown" "- execute/open-user.md: open, P2, needs [user]"
has "needs [] left out" "- execute/ready.md: open, P3"
has "blocked-by shown" "- execute/blocked.md: open, P2, needs [user], blocked by [open-user.md]"
has "a deferred brief's trigger" "- execute/deferred.md: deferred, P3, reopens when a /drift-audit run compacts mid-Phase-1"
has "CRLF frontmatter" "- execute/crlf.md: open, P1"
if [[ $OUT != *$'\r'* ]]; then ok "no CR reaches the output"; else bad "a CR reached the output"; fi
has "no frontmatter" "- execute/no-frontmatter.md: no frontmatter"
has "a fence never closed is no frontmatter" "- execute/unclosed.md: no frontmatter"
has "keys after the fence ignored" "- execute/body-keys.md: open, P1"
has "spacing around values trimmed" "- execute/spaced.md: open, P3"
has "declined.md below the root is a brief" "- execute/declined.md: open, P3"

echo "-- size --"
BIG=$WORK/big
mkdir -p "$BIG/.git"
TRIGGER='the quarterly review turns up a second catalog, or a run needs more than its legend, whichever comes first'
for i in $(seq -w 1 120); do
    brief "$BIG/docs/handoffs/execute/brief-$i.md" deferred 3 '[]' '[]' "$TRIGGER ($i)"
done
run "$BIG"
if ((${#OUT} < 10000)); then ok "120 long briefs stay under 10,000 characters (${#OUT})"; else
    bad "120 long briefs: ${#OUT} characters"
fi
LAST=${OUT%$'\n'}
LAST=${LAST##*$'\n'}
SHOWN=$(listed | grep -c '^execute/brief-')
if [[ $LAST =~ ^-\ and\ ([0-9]+)\ more,\ past\ what\ fits\ here$ ]] &&
    ((SHOWN + BASH_REMATCH[1] == 120)); then
    ok "the rest counted: $SHOWN shown, ${BASH_REMATCH[1]} more"
else bad "the rest counted: $SHOWN shown, last line '$LAST'"; fi

echo "-- against handoff-status.py --"
FIX=$WORK/status
mkdir -p "$FIX/.git"
for p in README.md CLAUDE.md declined.md flat.md .dot.md templates/t.md .drafts/h.md archive/Readme.md \
    execute/a.md execute/AGENTS.md execute/declined.md execute/examples/e.md execute/n.MD \
    execute/templates-not/x.md; do
    brief "$FIX/docs/handoffs/$p" open 2
done
run "$FIX"
FROM_HOOK=$(listed)
if command -v uv >/dev/null 2>&1; then
    PYTHONIOENCODING=utf-8 uv run --quiet "$(win "$STATUS")" "$(win "$FIX")" --no-inbox \
        >"$WORK/status.out" 2>&1
    FROM_SCRIPT=$(
        dir=
        while IFS= read -r line; do
            line=${line%$'\r'}
            if [[ $line =~ ^\ \ queue:\ docs/handoffs/(.*)\ \ \(each ]]; then
                dir=${BASH_REMATCH[1]}
            elif [[ $line =~ ^\ {6}P.\ \ ([^ ]+) ]]; then
                printf '%s%s\n' "$dir" "${BASH_REMATCH[1]}"
            fi
        done <"$WORK/status.out" | LC_ALL=C sort
    )
    if [ -z "$FROM_SCRIPT" ]; then
        bad "handoff-status.py listed nothing"
        sed 's/^/       | /' "$WORK/status.out"
    else
        same "the hook's briefs are handoff-status.py's" "$FROM_SCRIPT" "$FROM_HOOK"
    fi
else
    bad "needs uv to run handoff-status.py"
fi

echo "-- output --"
if [ "$BAD_RC" = 0 ]; then ok "every run exited 0 with empty stderr"; else
    bad "$BAD_RC runs exited non-zero or wrote stderr"
fi

echo
echo "$PASS passed, $FAIL failed"
[ "$FAIL" = 0 ]
