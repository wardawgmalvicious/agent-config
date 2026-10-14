#!/usr/bin/env bash
# Run KQL on a local Kusto emulator, to check a claim against the engine
# before it is written into guidance.
#
# The Kusto emulator is Azure Data Explorer's query engine in a Linux
# container (https://learn.microsoft.com/azure/data-explorer/kusto-emulator-overview),
# the Kusto engine a Fabric Eventhouse runs too, with no cluster, sign-in
# or cost. A pass here proves the language: what a function, a lambda or an
# operator returns. It proves nothing Fabric adds, such as OneLake or the
# item APIs, and nothing about speed, which the licence forbids measuring.
# So a claim it settles reads "Kusto emulator, <date>; not yet run in
# Fabric".
#
# Four choices, each against a failure that would be silent:
#   - The image is pinned by digest, so a result can be re-run on the
#     engine that gave it, and `start` prints that engine's build. A new
#     pin is a dated edit here; KQL_EMULATOR_IMAGE overrides it for a run.
#   - The port binds 127.0.0.1 alone. The emulator has no authentication,
#     and Docker's bare `-p 18080:8080` publishes on every interface,
#     `0.0.0.0` and `[::]` (2026-10-13).
#   - `start` needs --accept-eula, or KQL_EMULATOR_ACCEPT_EULA=Y, which
#     hands the container ACCEPT_EULA=Y and so accepts Microsoft's licence
#     terms, https://aka.ms/adx.emulator.license. The consent stays visible
#     in every command that gives it.
#   - The query reaches curl on stdin, never argv: on Windows argv is one
#     command line, capped at 32,767 characters and decoded through the
#     ANSI code page (~/.claude/rules/coding-bash.md).
#
# One emulator per machine, shared: `start` reuses a running one, and
# `stop` removes it for every session. The first `start` pulls several GB
# for a few minutes, so run it in the background or with a long timeout.
#
# Usage:
#   bash ~/.claude/skills/learn/scripts/kql-emulator.sh start --accept-eula
#   bash ~/.claude/skills/learn/scripts/kql-emulator.sh query <file.kql>...
#   bash ~/.claude/skills/learn/scripts/kql-emulator.sh mgmt <file.kql>
#   bash ~/.claude/skills/learn/scripts/kql-emulator.sh block <file.md> <n>
#   bash ~/.claude/skills/learn/scripts/kql-emulator.sh version
#   bash ~/.claude/skills/learn/scripts/kql-emulator.sh stop
#
# query joins its files in order into one query, so a lambda's file and a
# test's run as one; mgmt sends one management command. block prints the
# <n>th ```kusto or ```kql fence of a markdown file, its indentation
# removed, so a block runs as the file ships it.
#
# KQL_EMULATOR_PORT (18080), KQL_EMULATOR_NAME (kql-emulator) and
# KQL_EMULATOR_DB (NetDefaultDB) override the defaults.
#
# stdout: the first result table, a header line then a line per row, cells
# joined by " | "; from start and version, the image and engine lines.
# Exit 0 on success, 1 when the engine reports an error or nothing
# answers, 2 on a usage error. tests/scripts/kql-emulator/ holds the cases.
set -euo pipefail

# Pinned 2026-10-13: engine 1.0.9782.18301, build 2026.10.13.1002-2641-a3e7c31-master.
IMAGE=${KQL_EMULATOR_IMAGE:-mcr.microsoft.com/azuredataexplorer/kustainer-linux@sha256:6102cb2f6dad61cb1259534c8fb9e801dc1935be3df61cc35a00f9b0b135c223}
NAME=${KQL_EMULATOR_NAME:-kql-emulator}
PORT=${KQL_EMULATOR_PORT:-18080}
DB=${KQL_EMULATOR_DB:-NetDefaultDB}
URL=http://127.0.0.1:$PORT
LICENCE=https://aka.ms/adx.emulator.license
# Set out here: an ANSI-C quote inside $(...) reads empty in Git Bash.
NL=$'\n'

# A native jq.exe writes CRLF without -b, and Git Bash reports OSTYPE=cygwin.
JQ_BIN=()
case "$OSTYPE" in msys* | cygwin*) JQ_BIN=(-b) ;; esac

usage() {
    echo "usage: kql-emulator.sh start --accept-eula | query <file.kql>... | mgmt <file.kql> | block <file.md> <n> | version | stop" >&2
    exit 2
}

# need <tool> <hint>: fail unless <tool> is on PATH
need() {
    if ! command -v "$1" > /dev/null 2>&1; then
        echo "error: $1 not found on PATH" >&2
        echo "hint: $2" >&2
        exit 1
    fi
}

# unix_path <file>: the file as Git Bash names it, given either form
unix_path() {
    cygpath -u "$1" 2> /dev/null || printf '%s' "$1"
}

# readable <file>: a usage error unless <file> can be read
readable() {
    if [[ ! -f $1 || ! -r $1 ]]; then
        echo "error: no readable file: $1" >&2
        exit 2
    fi
}

# post <endpoint>: send stdin's KQL as one request to /v1/rest/<endpoint>
# and print the response; on an error print the engine's own message,
# which Kusto's v1 REST error carries as "@message", and fail
post() {
    local response status body msg
    if ! response=$(jq "${JQ_BIN[@]}" -Rs --arg db "$DB" '{db: $db, csl: .}' |
        curl -sS -m 120 -w "$NL%{http_code}" \
            -H 'Content-Type: application/json; charset=utf-8' \
            --data-binary @- "$URL/v1/rest/$1"); then
        echo "error: nothing answered at $URL; run: kql-emulator.sh start --accept-eula" >&2
        return 1
    fi
    status=${response##*"$NL"}
    body=${response%"$NL"*}
    if [[ $status != 200 ]]; then
        msg=$(printf '%s' "$body" | jq "${JQ_BIN[@]}" -r '.error["@message"] // .error.message // empty' 2> /dev/null) || msg=""
        printf 'error: HTTP %s: %s\n' "$status" "${msg:-$body}" >&2
        return 1
    fi
    printf '%s' "$body"
}

# table: print a response's first result table as " | "-joined lines,
# header first; fail if any table reports an exception
table() {
    jq "${JQ_BIN[@]}" -r '
        [.Tables[]? | .Exceptions? // empty | .[] | tostring] as $ex
        | if ($ex | length) > 0 then "error: \($ex | join("; "))\n" | halt_error(1)
          else .Tables[0] | (.Columns | map(.ColumnName) | join(" | ")),
              (.Rows[] | map(tostring) | join(" | "))
          end'
}

# wait_ready: poll the engine until it answers, for up to three minutes
wait_ready() {
    local deadline=$((SECONDS + 180))
    until printf '%s' '{"csl":".show version"}' |
        curl -sf -m 5 -H 'Content-Type: application/json' \
            --data-binary @- "$URL/v1/rest/mgmt" > /dev/null 2>&1; do
        if ((SECONDS > deadline)); then
            echo "error: $NAME did not answer within 180 s; see: docker logs $NAME" >&2
            exit 1
        fi
        sleep 2
    done
}

# version: the engine's build, as `.show version` reports it
version() {
    need curl "curl ships with Git for Windows"
    need jq "winget install jqlang.jq"
    printf '%s' '.show version' | post mgmt | jq "${JQ_BIN[@]}" -r '
        .Tables[0] | (.Columns | map(.ColumnName)) as $c | .Rows[0] as $r
        | "engine \($r[$c | index("BuildVersion")]), build \($r[$c | index("ProductVersion")])"'
}

start() {
    local accept=${KQL_EMULATOR_ACCEPT_EULA:-} state
    if [[ ${1:-} == --accept-eula ]]; then
        accept=Y
    fi
    if [[ $accept != Y ]]; then
        echo "error: the emulator runs only under Microsoft's licence terms, $LICENCE" >&2
        echo "hint: pass --accept-eula, or set KQL_EMULATOR_ACCEPT_EULA=Y, to accept them" >&2
        exit 2
    fi
    need docker "install Docker Desktop (winget install Docker.DockerDesktop), then start it"
    need curl "curl ships with Git for Windows"
    need jq "winget install jqlang.jq"
    if ! docker info > /dev/null 2>&1; then
        echo "error: the Docker daemon does not answer; start Docker Desktop" >&2
        exit 1
    fi
    state=$(docker inspect -f '{{.State.Running}} {{.Config.Image}}' "$NAME" 2> /dev/null) || state=""
    if [[ $state == "true $IMAGE" ]]; then
        echo "note: reusing the running $NAME" >&2
    elif [[ $state == true* ]]; then
        echo "error: $NAME runs ${state#true }, not $IMAGE; run: kql-emulator.sh stop" >&2
        exit 1
    else
        # A container stopped in an earlier run holds nothing worth keeping.
        [[ -z $state ]] || docker rm "$NAME" > /dev/null
        if ! docker image inspect "$IMAGE" > /dev/null 2>&1; then
            echo "note: pulling $IMAGE, several GB, for a few minutes" >&2
            docker pull "$IMAGE" >&2
        fi
        docker run -d -t --name "$NAME" -e ACCEPT_EULA=Y -m 4G \
            -p "127.0.0.1:$PORT:8080" "$IMAGE" > /dev/null
    fi
    wait_ready
    printf 'image %s\n' "$IMAGE"
    version
}

stop() {
    need docker "install Docker Desktop (winget install Docker.DockerDesktop), then start it"
    if docker inspect "$NAME" > /dev/null 2>&1; then
        docker rm -f "$NAME" > /dev/null
        echo "note: removed $NAME; its image stays cached, and docker rmi $IMAGE removes that" >&2
    else
        echo "note: no container named $NAME" >&2
    fi
}

# block <file.md> <n>: print the <n>th ```kusto or ```kql fence, each line
# stripped of the opening fence's indentation; exit 3 when there is none
block() {
    awk -v want="$2" '
        !open && /^[ \t]*```(kusto|kql)[ \t]*$/ {
            if (++seen == want) {
                open = 1
                match($0, /^[ \t]*/)
                pad = RLENGTH
            }
            next
        }
        open && /^[ \t]*```[ \t]*$/ { closed = 1; exit }
        open {
            line = $0
            for (i = 0; i < pad && line ~ /^[ \t]/; i++) line = substr(line, 2)
            print line
        }
        END { exit closed ? 0 : 3 }
    ' "$1"
}

[[ $# -gt 0 ]] || usage
cmd=$1
shift
case $cmd in
start)
    [[ $# -eq 0 || ($# -eq 1 && $1 == --accept-eula) ]] || usage
    start "$@"
    ;;
query | mgmt)
    [[ $# -gt 0 && ($cmd == query || $# -eq 1) ]] || usage
    files=()
    for f in "$@"; do
        f=$(unix_path "$f")
        readable "$f"
        files+=("$f")
    done
    need curl "curl ships with Git for Windows"
    need jq "winget install jqlang.jq"
    cat -- "${files[@]}" | post "$cmd" | table
    ;;
block)
    [[ $# -eq 2 && $2 =~ ^[1-9][0-9]*$ ]] || usage
    file=$(unix_path "$1")
    readable "$file"
    if ! block "$file" "$2"; then
        echo "error: no complete \`\`\`kusto or \`\`\`kql block $2 in $1" >&2
        exit 1
    fi
    ;;
version | stop)
    [[ $# -eq 0 ]] || usage
    "$cmd"
    ;;
*) usage ;;
esac
