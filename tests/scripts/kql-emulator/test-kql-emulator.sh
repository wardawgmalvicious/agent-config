#!/usr/bin/env bash
# Exercise skills/meta/learn/scripts/kql-emulator.sh.
#
# The cases need no Docker and no network. A stub docker ahead of the real
# one on PATH records every call and fails it, so the licence refusal is
# checked to make no call at all, and a query aimed at a port nothing
# listens on must fail rather than print a table. With KQL_EMULATOR_LIVE=1
# and an emulator already up from `start`, five more cases run against the
# real engine: a result table, two files joined, a syntax error, a runtime
# error and the version line.
#
#     bash tests/scripts/kql-emulator/test-kql-emulator.sh
#     KQL_EMULATOR_LIVE=1 bash tests/scripts/kql-emulator/test-kql-emulator.sh
#
set -u

here=$(cd "$(dirname "$0")" && pwd)
repo=$(cd "$here/../../.." && pwd)
script="$repo/skills/meta/learn/scripts/kql-emulator.sh"
tmproot=$(mktemp -d)
trap 'rm -rf "$tmproot"' EXIT
: > "$tmproot/out.txt"
: > "$tmproot/err.txt"

pass=0
fail=0

# A docker that records each call and fails it, ahead of the real one.
mkdir -p "$tmproot/bin"
cat > "$tmproot/bin/docker" << 'STUB'
#!/usr/bin/env bash
printf '%s\n' "$*" >> "$DOCKER_CALLS"
exit 1
STUB
chmod +x "$tmproot/bin/docker"
export DOCKER_CALLS="$tmproot/docker-calls.txt"
stub_path="$tmproot/bin:$PATH"

# run <args>...: the script with the stub docker; stdout in out.txt,
# stderr in err.txt, exit in $rc
run() {
    : > "$DOCKER_CALLS"
    PATH="$stub_path" bash "$script" "$@" > "$tmproot/out.txt" 2> "$tmproot/err.txt"
    rc=$?
}

# live <args>...: the script with the real docker, for the live cases
live() {
    bash "$script" "$@" > "$tmproot/out.txt" 2> "$tmproot/err.txt"
    rc=$?
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
        sed 's/^/        out | /' "$tmproot/out.txt"
        sed 's/^/        err | /' "$tmproot/err.txt"
        fail=$((fail + 1))
    fi
}

calls() {
    wc -l < "$DOCKER_CALLS" | tr -d ' '
}

printf '%s\n' 'print x = 1' > "$tmproot/one.kql"

echo "1. A usage error exits 2"
run
check "no subcommand" is "$rc:$(grep -c '^usage:' "$tmproot/err.txt")" "2:1"
run explode
check "an unknown subcommand" is "$rc" 2
run query
check "query with no file" is "$rc" 2
run query "$tmproot/absent.kql"
check "query with a missing file" is "$rc:$(grep -c '^error: no readable file' "$tmproot/err.txt")" "2:1"
run mgmt "$tmproot/one.kql" "$tmproot/one.kql"
check "mgmt with two files" is "$rc" 2
run block "$tmproot/one.kql" 0
check "block 0" is "$rc" 2
run block "$tmproot/one.kql" x
check "block x" is "$rc" 2
run start --yes
check "start with another flag" is "$rc:$(calls)" "2:0"

echo "2. start refuses without the licence, before any docker call"
check "the stub shadows docker" is "$(PATH="$stub_path" command -v docker)" "$tmproot/bin/docker"
unset KQL_EMULATOR_ACCEPT_EULA
run start
check "no flag, no variable: exit 2, no docker call" is "$rc:$(calls)" "2:0"
check "it names the licence terms" matches "$(cat "$tmproot/err.txt")" 'https://aka\.ms/adx\.emulator\.license'
KQL_EMULATOR_ACCEPT_EULA=N run start
check "KQL_EMULATOR_ACCEPT_EULA=N: exit 2, no docker call" is "$rc:$(calls)" "2:0"
run start --accept-eula
check "--accept-eula reaches docker, and a daemon that fails stops it" \
    is "$rc:$(cat "$DOCKER_CALLS")" "1:info"
KQL_EMULATOR_ACCEPT_EULA=Y run start
check "KQL_EMULATOR_ACCEPT_EULA=Y does the same" is "$rc:$(cat "$DOCKER_CALLS")" "1:info"

echo "3. A query nothing answers fails, and prints no table"
KQL_EMULATOR_PORT=1 run query "$tmproot/one.kql"
check "exit 1, stdout empty" is "$rc:$(wc -c < "$tmproot/out.txt" | tr -d ' ')" "1:0"
check "it says nothing answered" is "$(grep -c '^error: nothing answered at http://127\.0\.0\.1:1;' "$tmproot/err.txt")" 1
KQL_EMULATOR_PORT=1 run version
check "version: exit 1" is "$rc" 1

echo "4. block prints a fence as the file ships it"
cat > "$tmproot/doc.md" << 'DOC'
# A doc

```python
print("not this one")
```

```kusto
let f = (x: long) { x + 1 };
print f(1)
```

- A list item:

  ```kql
  print y = 2
  | extend z = y * 2
  ```

```kusto
print unterminated = true
DOC
run block "$tmproot/doc.md" 1
check "block 1 is the first kusto fence" is "$rc:$(cat "$tmproot/out.txt")" \
    "0:let f = (x: long) { x + 1 };"$'\n'"print f(1)"
run block "$tmproot/doc.md" 2
check "block 2, the indented kql fence, unindented" is "$rc:$(cat "$tmproot/out.txt")" \
    "0:print y = 2"$'\n'"| extend z = y * 2"
run block "$tmproot/doc.md" 3
check "block 3, unterminated: exit 1" is "$rc:$(grep -c '^error: no complete' "$tmproot/err.txt")" "1:1"
run block "$tmproot/doc.md" 4
check "block 4, absent: exit 1" is "$rc" 1
if command -v cygpath > /dev/null; then
    run block "$(cygpath -w "$tmproot/doc.md")" 1
    check "a Windows-form path reads the same" is "$rc:$(head -n 1 "$tmproot/out.txt")" \
        "0:let f = (x: long) { x + 1 };"
fi

if [[ ${KQL_EMULATOR_LIVE:-} == 1 ]]; then
    echo "5. Against the running emulator"
    live query "$tmproot/one.kql"
    check "a result table: header, then the row" is "$rc:$(cat "$tmproot/out.txt")" "0:x"$'\n'"1"
    printf '%s\n' 'let twice = (n: long) { n * 2 };' > "$tmproot/lambda.kql"
    printf '%s\n' 'print r = twice(21)' > "$tmproot/call.kql"
    live query "$tmproot/lambda.kql" "$tmproot/call.kql"
    check "two files run as one query" is "$rc:$(cat "$tmproot/out.txt")" "0:r"$'\n'"42"
    printf '%s\n' 'print x = ' > "$tmproot/bad.kql"
    live query "$tmproot/bad.kql"
    check "a syntax error: exit 1, the engine's message, no table" \
        is "$rc:$(grep -c '^error: HTTP 400: ' "$tmproot/err.txt"):$(wc -c < "$tmproot/out.txt" | tr -d ' ')" "1:1:0"
    printf '%s\n' 'print assert(false, "boom")' > "$tmproot/assert.kql"
    live query "$tmproot/assert.kql"
    check "a runtime error: exit 1, no table" is "$rc:$(wc -c < "$tmproot/out.txt" | tr -d ' ')" "1:0"
    live version
    check "version: the engine line" matches "$(cat "$tmproot/out.txt")" '^engine [0-9.]+, build [^ ]+$'
fi

echo
echo "$pass passed, $fail failed"
[ "$fail" = 0 ]
