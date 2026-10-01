#!/usr/bin/env bash
# Exercise skills/workflow/land/scripts/never-prompted.sh against throwaway
# config directories.
#
# Each case builds a fresh CLAUDE_CONFIG_DIR in a temp directory, holding
# registry entries shaped like the ones Claude Code 2.1.283 to 2.1.285 wrote
# (2026-09-30), and a transcript where a case needs one, then checks the
# script's exit and its line for each name. Case 1 passes a session that was
# never prompted; the rest are the doubts it must read as live, which
# skills/workflow/land/references/never-prompted-sessions.md names. No
# network, and nothing read from the real ~/.claude.
#
#     bash tests/scripts/never-prompted/test-never-prompted.sh
#
set -u

here=$(cd "$(dirname "$0")" && pwd)
repo=$(cd "$here/../../.." && pwd)
script="$repo/skills/workflow/land/scripts/never-prompted.sh"
tmproot=$(mktemp -d)
trap 'rm -rf "$tmproot"' EXIT
: > "$tmproot/out.txt"

pass=0
fail=0

sid1=0f3c2a1e-5b6d-4e7f-8a9b-0c1d2e3f4a5b
sid2=1a2b3c4d-5e6f-4a7b-8c9d-0e1f2a3b4c5d
# a minute ago, in ms, as the registry stores a start
printf -v start '%(%s)T' -1
start=$((start * 1000 - 60000))

# config <name>: a fresh config directory in $c, exported, with an empty
# registry and one project directory
config() {
    c="$tmproot/$1"
    mkdir -p "$c/sessions" "$c/projects/c--Repos-x"
    export CLAUDE_CONFIG_DIR="$c"
}

# entry <pid> <name> <sessionId> <status> <ms from start to updatedAt>:
# one registry entry, in the shape 2.1.285 writes
entry() {
    printf '{"pid":%s,"sessionId":"%s","startedAt":%s,"version":"2.1.285","kind":"interactive","entrypoint":"claude-vscode","name":"%s","nameSource":"derived","status":"%s","updatedAt":%s,"statusUpdatedAt":%s}\n' \
        "$1" "$3" "$start" "$2" "$4" "$((start + $5))" "$((start + $5))" > "$c/sessions/$1.json"
}

# raw <pid> <json>: a registry entry written as given
raw() {
    printf '%s\n' "$2" > "$c/sessions/$1.json"
}

# transcript <sessionId> [<subdirectory>]: a transcript for the session
transcript() {
    local d="$c/projects/c--Repos-x${2:+/$2}"
    mkdir -p "$d"
    printf '{"type":"user"}\n' > "$d/$1.jsonl"
}

# run <name>...: the script; output in out.txt, exit in $rc
run() {
    bash "$script" "$@" > "$tmproot/out.txt" 2>&1
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

echo "1. A session never prompted passes"
config passes
entry 101 p-01 "$sid1" idle 355
run p-01
check "exit 0" is "$rc" 0
check "its line names the pid, the entrypoint and both reads" matches "$(cat "$tmproot/out.txt")" \
    '^p-01: never prompted, pid 101, claude-vscode, started [12] min ago, updatedAt 355 ms after start, no transcript$'
entry 101 p-01 "$sid1" idle 999
run p-01
check "999 ms from start to updatedAt still passes" is "$rc" 0

echo "2. A session that reads prompted is live"
config prompted
entry 101 p-01 "$sid1" idle 355
transcript "$sid1"
run p-01
check "a transcript: exit 1" is "$rc:$(line p-01 'live, it has a transcript')" "1:1"
rm "$c/projects/c--Repos-x/$sid1.jsonl"
transcript "$sid1" deeper/still
run p-01
check "a transcript nested deeper: exit 1" is "$rc:$(line p-01 'live, it has a transcript')" "1:1"
config touched
entry 101 p-01 "$sid1" idle 1000
run p-01
check "updatedAt 1000 ms after start: exit 1" is "$rc:$(line p-01 'live, no single')" "1:1"
entry 101 p-01 "$sid1" busy 355
run p-01
check "busy: exit 1" is "$rc" 1
entry 101 p-01 "$sid1" idle -5
run p-01
check "updatedAt before startedAt: exit 1" is "$rc" 1

echo "3. A registry that does not single out the session is live"
config entries
entry 101 p-01 "$sid1" idle 355
run p-02
check "no entry under the name: exit 1" is "$rc:$(line p-02 'live, no single')" "1:1"
entry 102 p-01 "$sid2" idle 355
run p-01
check "two entries under the name: exit 1" is "$rc:$(line p-01 'live, no single')" "1:1"

echo "4. A field missing, renamed or retyped is live"
config fields
raw 101 '{"pid":101,"sessionId":"'"$sid1"'","name":"p-01","status":"idle","startedAt":'"$start"'}'
run p-01
check "updatedAt missing: exit 1" is "$rc" 1
raw 101 '{"pid":101,"sessionId":"'"$sid1"'","name":"p-01","status":"idle","startedAt":'"$start"',"updatedAt":"'"$((start + 355))"'"}'
run p-01
check "updatedAt a string: exit 1" is "$rc" 1
raw 101 '{"pid":101,"sessionId":"'"$sid1"'","name":"p-01","state":"idle","startedAt":'"$start"',"updatedAt":'"$((start + 355))"'}'
run p-01
check "status renamed: exit 1" is "$rc" 1
raw 101 '{"pid":101,"name":"p-01","status":"idle","startedAt":'"$start"',"updatedAt":'"$((start + 355))"'}'
run p-01
check "sessionId missing: exit 1" is "$rc" 1
raw 101 '{"pid":101,"sessionId":"*","name":"p-01","status":"idle","startedAt":'"$start"',"updatedAt":'"$((start + 355))"'}'
run p-01
check "a sessionId that is not a UUID: exit 1" is "$rc:$(line p-01 'live, its sessionId is not a UUID')" "1:1"

echo "5. A read that fails is live"
config halfwritten
entry 101 p-01 "$sid1" idle 355
printf '{"pid":102,"sessionId":' > "$c/sessions/102.json"
run p-01
check "a half-written entry beside it: exit 1" is "$rc:$(line p-01 'live, the session registry did not read')" "1:1"
config noentries
run p-01
check "an empty registry: exit 1" is "$rc:$(line p-01 'live, the session registry did not read')" "1:1"
config noregistry
rmdir "$c/sessions"
run p-01
check "no registry directory: exit 1" is "$rc" 1
config noprojects
entry 101 p-01 "$sid1" idle 355
rm -rf "$c/projects"
run p-01
check "no projects directory: exit 1" is "$rc:$(line p-01 'live, the transcript lookup failed')" "1:1"
config nojq
entry 101 p-01 "$sid1" idle 355
PATH=/nonexistent "$BASH" "$script" p-01 > "$tmproot/out.txt" 2>&1
rc=$?
check "no jq on PATH: exit 1" is "$rc:$(grep -c '^error: jq not found' "$tmproot/out.txt")" "1:1"

echo "6. Several names pass only together"
config several
entry 101 p-01 "$sid1" idle 355
entry 102 p-02 "$sid2" idle 277
run p-01 p-02
check "both never prompted: exit 0, a line each" is "$rc:$(line p-01 'never prompted'):$(line p-02 'never prompted')" "0:1:1"
transcript "$sid2"
run p-01 p-02
check "one prompted: exit 1, and both still reported" is "$rc:$(line p-01 'never prompted'):$(line p-02 'live')" "1:1:1"

echo "7. Usage and the config directory"
run
check "no name: exit 2 with the usage" is "$rc:$(grep -c '^usage:' "$tmproot/out.txt")" "2:1"
config homecfg
entry 101 p-01 "$sid1" idle 355
mkdir -p "$tmproot/home"
mv "$c" "$tmproot/home/.claude"
unset CLAUDE_CONFIG_DIR
HOME="$tmproot/home" "$BASH" "$script" p-01 > "$tmproot/out.txt" 2>&1
rc=$?
check "unset, it reads ~/.claude: exit 0" is "$rc" 0
if command -v cygpath > /dev/null; then
    config winpath
    entry 101 p-01 "$sid1" idle 355
    CLAUDE_CONFIG_DIR=$(cygpath -w "$c")
    run p-01
    check "set in Windows form, it reads the same: exit 0" is "$rc" 0
fi

echo
echo "$pass passed, $fail failed"
[ "$fail" = 0 ]
