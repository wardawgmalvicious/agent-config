#!/usr/bin/env bash
# Exercise skills/workflow/land/scripts/placed-elsewhere.sh against throwaway
# trees and config directories.
#
# One temp directory holds the trees: a main checkout with a subdirectory and
# a linked worktree inside it, under .claude/worktrees/ where EnterWorktree
# puts one, a second repository, and a directory in none. Each case builds a
# fresh CLAUDE_CONFIG_DIR beside them, holding registry entries shaped like
# the ones Claude Code 2.1.300 wrote (2026-10-16), each `cwd` in Windows form
# wherever cygpath exists, as the registry spells one. It runs the script
# from one of the trees and checks its exit and its line for each name. Cases
# 1 and 2 place a session each way, case 3 spells one directory every way
# measured, and the rest are the doubts it must keep in this tree, which
# skills/workflow/land/references/never-prompted-sessions.md names. No
# network, and nothing read from the real ~/.claude.
#
#     bash tests/scripts/placed-elsewhere/test-placed-elsewhere.sh
#
set -u

here=$(cd "$(dirname "$0")" && pwd)
repo=$(cd "$here/../../.." && pwd)
script="$repo/skills/workflow/land/scripts/placed-elsewhere.sh"
tmproot=$(mktemp -d)
trap 'rm -rf "$tmproot"' EXIT
: > "$tmproot/out.txt"

pass=0
fail=0

# native <path>: the path as the registry spells one
native() {
    if command -v cygpath > /dev/null; then cygpath -w "$1"; else printf '%s\n' "$1"; fi
}

main="$tmproot/trees/main"
wt="$main/.claude/worktrees/wt"
plain="$tmproot/trees/plain"
git init -q -b main "$main"
git -C "$main" config user.name test
git -C "$main" config user.email test@example.invalid
git -C "$main" commit -q --allow-empty -m base
git -C "$main" worktree add -q -b wt "$wt"
git init -q -b main "$tmproot/trees/other"
mkdir -p "$main/sub" "$plain"
MAIN=$(native "$main")
SUB=$(native "$main/sub")
WT=$(native "$wt")
OTHER=$(native "$tmproot/trees/other")
PLAIN=$(native "$plain")

# A temp directory inside a repository, as a home under git would put it,
# leaves no directory in none.
in_repo=0
git -C "$plain" rev-parse --show-toplevel > /dev/null 2>&1 && in_repo=1

# config <name>: a fresh config directory in $c, exported, with an empty
# registry
config() {
    c="$tmproot/$1"
    mkdir -p "$c/sessions"
    export CLAUDE_CONFIG_DIR="$c"
}

# entry <pid> <name> <cwd>: one registry entry, in the shape 2.1.300 writes
entry() {
    jq -n --argjson pid "$1" --arg name "$2" --arg cwd "$3" '{
        pid: $pid, sessionId: "0f3c2a1e-5b6d-4e7f-8a9b-0c1d2e3f4a5b",
        cwd: $cwd, startedAt: 1792154522781, version: "2.1.300",
        kind: "interactive", entrypoint: "claude-vscode", name: $name,
        nameSource: "hook", status: "busy", updatedAt: 1792154850849
    }' > "$c/sessions/$1.json"
}

# raw <pid> <json>: a registry entry written as given
raw() {
    printf '%s\n' "$2" > "$c/sessions/$1.json"
}

# run <dir> <name>...: the script, run from <dir>; output in out.txt, exit in $rc
run() {
    local dir=$1
    shift
    (cd "$dir" && bash "$script" "$@") > "$tmproot/out.txt" 2>&1
    rc=$?
}

# line <name> <text>: how many lines of the last run's output open "<name>: <text>"
line() {
    grep -c "^$1: $2" "$tmproot/out.txt"
}

is() {
    [[ "$1" == "$2" ]] && return
    printf '        expected %q\n        got      %q\n' "$2" "$1"
    return 1
}

matches() {
    [[ "$1" =~ $2 ]] && return
    printf '        no match for /%s/ in %q\n' "$2" "$1"
    return 1
}

# check <label> <predicate> <args...>: one ok or FAIL line
check() {
    local label=$1
    shift
    if "$@"; then
        echo "ok    $label"
        pass=$((pass + 1))
    else
        echo "FAIL  $label"
        sed 's/^/        | /' "$tmproot/out.txt"
        fail=$((fail + 1))
    fi
}

echo "1. A session in another tree is placed elsewhere"
config elsewhere
entry 101 p-01 "$OTHER"
run "$main" p-01
check "another repository: exit 0" is "$rc" 0
check "its line names the cwd and the top level git gave it" matches "$(cat "$tmproot/out.txt")" \
    '^p-01: elsewhere, cwd .+, top level .+/trees/other$'
if [[ $in_repo == 1 ]]; then
    echo "skip  in no git repository: the temp directory sits inside one"
else
    entry 101 p-01 "$PLAIN"
    run "$main" p-01
    check "in no git repository: exit 0" is "$rc:$(line p-01 'elsewhere, cwd .*, in no git repository$')" "0:1"
fi
entry 101 p-01 "$WT"
run "$main" p-01
check "a linked worktree inside the main checkout, run from the main checkout: exit 0" is "$rc:$(line p-01 'elsewhere')" "0:1"
entry 101 p-01 "$MAIN"
run "$wt" p-01
check "the main checkout, run from a linked worktree inside it: exit 0" is "$rc:$(line p-01 'elsewhere')" "0:1"
entry 101 'brief: p-01' "$OTHER"
run "$main" 'brief: p-01'
check "a name a hook set: exit 0" is "$rc:$(line 'brief: p-01' 'elsewhere')" "0:1"

echo "2. A session in this tree is kept"
config thistree
entry 101 p-01 "$MAIN"
run "$main" p-01
check "at its top level: exit 1" is "$rc:$(line p-01 'this tree, cwd ')" "1:1"
entry 101 p-01 "$SUB"
run "$main" p-01
check "in a subdirectory: exit 1" is "$rc:$(line p-01 'this tree')" "1:1"
entry 101 p-01 "$MAIN"
run "$main/sub" p-01
check "run from a subdirectory: exit 1" is "$rc:$(line p-01 'this tree')" "1:1"
entry 101 p-01 "$WT"
run "$wt" p-01
check "the same linked worktree: exit 1" is "$rc:$(line p-01 'this tree')" "1:1"

echo "3. Every spelling of this tree is this tree"
# spelled <label> <cwd>: a session in this tree's top level, spelled so
spelled() {
    entry 101 p-01 "$2"
    run "$main" p-01
    check "$1: exit 1" is "$rc:$(line p-01 'this tree')" "1:1"
}
if command -v cygpath > /dev/null; then
    config spellings
    long=$(cygpath -lw "$main")
    spelled "the long form" "$long"
    spelled "the 8.3 form" "$(cygpath -sw "$main")"
    spelled "a lowercase drive letter" "${long,}"
    spelled "all upper case" "${long^^}"
    spelled "forward slashes" "$(cygpath -lm "$main")"
    spelled "a trailing backslash" "$long\\"
else
    echo "skip  spellings: no cygpath, so no Windows forms to spell"
fi

echo "4. A registry that does not single out the session is in doubt"
config entries
entry 101 p-01 "$OTHER"
run "$main" p-02
check "no entry under the name: exit 1" is "$rc:$(line p-02 'in doubt, no single')" "1:1"
entry 102 p-01 "$OTHER"
run "$main" p-01
check "two entries under the name, both elsewhere: exit 1" is "$rc:$(line p-01 'in doubt, no single')" "1:1"

echo "5. A cwd missing, retyped or unreadable is in doubt"
config fields
raw 101 '{"pid":101,"name":"p-01","status":"busy"}'
run "$main" p-01
check "cwd missing: exit 1" is "$rc:$(line p-01 'in doubt, no single')" "1:1"
raw 101 '{"pid":101,"name":"p-01","Cwd":"x"}'
run "$main" p-01
check "cwd renamed: exit 1" is "$rc:$(line p-01 'in doubt, no single')" "1:1"
raw 101 '{"pid":101,"name":"p-01","cwd":""}'
run "$main" p-01
check "cwd empty: exit 1" is "$rc:$(line p-01 'in doubt, no single')" "1:1"
raw 101 '{"pid":101,"name":"p-01","cwd":42}'
run "$main" p-01
check "cwd a number: exit 1" is "$rc:$(line p-01 'in doubt, no single')" "1:1"
entry 101 p-01 "$(native "$tmproot/trees/gone")"
run "$main" p-01
check "cwd a directory that is gone: exit 1" is "$rc:$(line p-01 'in doubt, git could not read its cwd')" "1:1"
entry 101 p-01 "$(native "$main/.git")"
run "$main" p-01
check "cwd inside .git, which has no working tree: exit 1" is "$rc:$(line p-01 'in doubt, git could not read its cwd')" "1:1"

echo "6. A read that fails is in doubt"
config halfwritten
entry 101 p-01 "$OTHER"
printf '{"pid":102,"cwd":' > "$c/sessions/102.json"
run "$main" p-01
check "a half-written entry beside it: exit 1" is "$rc:$(line p-01 'in doubt, the session registry did not read')" "1:1"
config noentries
run "$main" p-01
check "an empty registry: exit 1" is "$rc:$(line p-01 'in doubt, the session registry did not read')" "1:1"
config noregistry
rmdir "$c/sessions"
run "$main" p-01
check "no registry directory: exit 1" is "$rc" 1
config nojq
entry 101 p-01 "$OTHER"
(cd "$main" && PATH=/nonexistent "$BASH" "$script" p-01) > "$tmproot/out.txt" 2>&1
rc=$?
check "no jq on PATH: exit 1" is "$rc:$(grep -c '^error: jq not found' "$tmproot/out.txt")" "1:1"

echo "7. Several names pass only together"
config several
entry 101 p-01 "$OTHER"
entry 102 p-02 "$WT"
run "$main" p-01 p-02
check "both elsewhere: exit 0, a line each" is "$rc:$(line p-01 'elsewhere'):$(line p-02 'elsewhere')" "0:1:1"
entry 102 p-02 "$SUB"
run "$main" p-01 p-02
check "one in this tree: exit 1, and both still reported" is "$rc:$(line p-01 'elsewhere'):$(line p-02 'this tree')" "1:1:1"

echo "8. Usage and the config directory"
run "$main"
check "no name: exit 2 with the usage" is "$rc:$(grep -c '^usage:' "$tmproot/out.txt")" "2:1"
if [[ $in_repo == 1 ]]; then
    echo "skip  run outside a working tree: the temp directory sits inside one"
else
    run "$plain" p-01
    check "run outside a working tree: exit 2" is "$rc:$(grep -c '^error: no git working tree' "$tmproot/out.txt")" "2:1"
fi
config homecfg
entry 101 p-01 "$OTHER"
mkdir -p "$tmproot/home"
mv "$c" "$tmproot/home/.claude"
unset CLAUDE_CONFIG_DIR
(cd "$main" && HOME="$tmproot/home" "$BASH" "$script" p-01) > "$tmproot/out.txt" 2>&1
rc=$?
check "unset, it reads ~/.claude: exit 0" is "$rc" 0
if command -v cygpath > /dev/null; then
    config winpath
    entry 101 p-01 "$OTHER"
    CLAUDE_CONFIG_DIR=$(cygpath -w "$c")
    run "$main" p-01
    check "set in Windows form, it reads the same: exit 0" is "$rc" 0
fi

echo
echo "$pass passed, $fail failed"
[ "$fail" = 0 ]
