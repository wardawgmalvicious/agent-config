#!/bin/bash
# Exercises claude/hooks/identity-guard.sh against throwaway repos and a
# throwaway denylist. Machine-checkable, no session needed:
#
#   bash tests/hooks/identity-guard/test-identity-guard.sh            # repo copy
#   HOOK=~/.claude/hooks/identity-guard.sh bash tests/hooks/...       # deployed copy
#
# The denylist is generated here with made-up terms (contoso, fabrikam-tools)
# and handed to the hook through IDENTITY_DENYLIST, so a run never reads the
# machine's real ~/.config/identity-denylist.txt and never depends on it.
# Every temp path is removed on exit.

set -uo pipefail
HERE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
HOOK="${HOOK:-$HERE/../../../claude/hooks/identity-guard.sh}"
[ -f "$HOOK" ] || {
    echo "no hook at $HOOK" >&2
    exit 1
}

WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT
PASS=0
FAIL=0

# call <event> <tool> <cwd> <command>  → prints exit code
# Files, not pipes: an earlier version fed the hook through `jq | bash`
# inside "$(...)" and hung intermittently on Windows with no child process
# left to blame — MSYS pipe handles. Every pass now goes through disk.
call() {
    jq -nc --arg e "$1" --arg t "$2" --arg c "$3" --arg cmd "$4" \
        '{hook_event_name:$e, tool_name:$t, cwd:$c, tool_input:{command:$cmd}}' >"$WORK/in.json"
    IDENTITY_DENYLIST="${LIST:-}" ${HOOK_SHELL:-bash} "$HOOK" <"$WORK/in.json" >/dev/null 2>"$WORK/stderr"
    echo $? >"$WORK/rc"
    cat "$WORK/rc"
}
expect() { # <label> <want> <got>
    if [ "$2" = "$3" ]; then
        PASS=$((PASS + 1))
        echo "  ok   $1"
    else
        FAIL=$((FAIL + 1))
        echo "  FAIL $1: wanted exit $2, got $3"
        sed 's/^/       | /' "$WORK/stderr"
    fi
}
mkrepo() { # <dir>
    git init -q "$1" && git -C "$1" config user.email t@example.com && git -C "$1" config user.name t &&
        echo clean >"$1/a.txt" && git -C "$1" add a.txt && git -C "$1" commit -qm "init"
}

LIST="$WORK/denylist.txt"
EXEMPT="$WORK/client-root"
mkdir -p "$EXEMPT"
printf '# test list\r\nexempt: %s\r\n\r\ncontoso\r\nfabrikam-tools\r\n' "$(cygpath -m "$EXEMPT" 2>/dev/null || echo "$EXEMPT")" >"$LIST"

R="$WORK/repo"
mkrepo "$R"
W=$(cygpath -w "$R" 2>/dev/null || echo "$R") # hooks receive a Windows cwd on this machine

echo "guard: $HOOK"
echo "-- gating --"
expect "non-git command is ignored" 0 "$(call PreToolUse Bash "$W" 'ls -la')"
expect "git log mentioning push is ignored" 0 "$(call PreToolUse Bash "$W" 'git log --grep push')"
expect "unknown tool is ignored" 0 "$(call PreToolUse Edit "$W" 'git commit -m x')"
LIST_SAVE=$LIST
LIST="$WORK/absent.txt"
expect "missing denylist allows" 0 "$(call PreToolUse Bash "$W" 'git commit -m x')"
LIST=$LIST_SAVE

echo "-- commit: staged diff --"
echo "Contact CONTOSO support" >>"$R/a.txt"
git -C "$R" add a.txt
expect "staged added line with a term blocks (Bash)" 2 "$(call PreToolUse Bash "$W" 'git commit -m "docs: note"')"
expect "staged added line with a term blocks (PowerShell)" 2 "$(call PreToolUse PowerShell "$W" 'git commit -m "docs: note"')"
expect "global opts between git and commit still gate" 2 "$(call PreToolUse Bash "$W" "git -C \"$W\" --no-pager commit -F -")"
expect "a quoted -C value with a space is skipped whole" 2 "$(call PreToolUse Bash "$W" "git -C \"C:\\Program Files\\x\" commit -m \"a b\"")"
git -C "$R" commit -qm "seed a term" # commit it so the next case can remove it
printf 'clean\n' >"$R/a.txt"
git -C "$R" add a.txt
expect "removing a term does not block" 0 "$(call PreToolUse Bash "$W" 'git commit -m "docs: scrub"')"
git -C "$R" commit -qm "scrub"
echo "fabrikam-tools reference" >>"$R/a.txt" # unstaged only
expect "unstaged term, plain commit: allowed" 0 "$(call PreToolUse Bash "$W" 'git commit -m x')"
expect "unstaged term, commit -a: blocked" 2 "$(call PreToolUse Bash "$W" 'git commit -am x')"
git -C "$R" checkout -q -- a.txt

echo "-- commit: message (PostToolUse) --"
echo more >>"$R/a.txt"
git -C "$R" commit -qam "chore: contoso onboarding"
expect "HEAD message with a term feeds back" 2 "$(call PostToolUse Bash "$W" 'git commit -am "chore: contoso onboarding"')"
if grep -q 'amend' "$WORK/stderr"; then
    PASS=$((PASS + 1))
    echo "  ok   feedback tells the model to reword"
else
    FAIL=$((FAIL + 1))
    echo "  FAIL feedback text"
fi
git -C "$R" commit -q --amend -m "chore: client onboarding"
expect "HEAD message clean passes" 0 "$(call PostToolUse Bash "$W" 'git commit -am x')"
expect "PostToolUse ignores push" 0 "$(call PostToolUse Bash "$W" 'git push')"

echo "-- push: unpushed history --"
BARE="$WORK/origin.git"
git init -q --bare "$BARE"
git -C "$R" remote add origin "$BARE"
git -C "$R" push -q -u origin HEAD 2>/dev/null
expect "nothing unpushed passes" 0 "$(call PreToolUse Bash "$W" 'git push')"
echo x >>"$R/a.txt"
git -C "$R" commit -qam "feat: contoso adapter"
expect "unpushed message with a term blocks" 2 "$(call PreToolUse Bash "$W" 'git push')"
git -C "$R" commit -q --amend -m "feat: adapter"
expect "reworded, and the diff is clean: passes" 0 "$(call PreToolUse Bash "$W" 'git push origin HEAD')"
echo "contoso" >>"$R/a.txt"
git -C "$R" commit -qam "feat: more"
expect "unpushed added line with a term blocks" 2 "$(call PreToolUse Bash "$W" 'git push')"
BR=$(git -C "$R" branch --show-current)
git -C "$R" switch -q -c side && git -C "$R" reset -q --hard origin/"$BR" 2>/dev/null
expect "push names a ref: that ref is scanned, not HEAD" 2 "$(call PreToolUse Bash "$W" "git push origin $BR")"
expect "push of a clean ref passes" 0 "$(call PreToolUse Bash "$W" 'git push origin side')"
git -C "$R" switch -q "$BR"
git -C "$R" push -q origin HEAD 2>/dev/null # bare remote takes it; the guard is the only thing that would not
expect "push after remote has it passes" 0 "$(call PreToolUse Bash "$W" 'git push')"

echo "-- exempt roots --"
E="$EXEMPT/client-repo"
mkrepo "$E"
echo "contoso everywhere" >>"$E/a.txt"
git -C "$E" add a.txt
expect "repo under an exempt root is skipped" 0 "$(call PreToolUse Bash "$(cygpath -w "$E" 2>/dev/null || echo "$E")" 'git commit -m x')"

echo
echo "$PASS passed, $FAIL failed"
[ "$FAIL" = 0 ]
