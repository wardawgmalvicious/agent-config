#!/usr/bin/env bash
# Exit 0 only when every named session reads as never prompted. Any doubt
# reads as live.
#
# `ListAgents` lists a Claude Code process nobody has typed into exactly as
# it lists a working peer: the VS Code extension can leave one running
# that the user does not know is there (2026-09-30). `land` must not move
# HEAD under a live session, and `commit` must not message one that was
# never prompted, since the message would prompt it. Both ask this script.
#
# It reads two things Claude Code writes and does not document: the
# session registry, <config>/sessions/<pid>.json, and the transcripts,
# <config>/projects/**/<sessionId>.jsonl. A name passes when exactly one
# registry entry carries it, that entry is still `idle` with `updatedAt`
# under 1000 ms after `startedAt`, and a transcript lookup that ran found
# nothing. Every other outcome reads as live and exits 1: no entry, two, a
# field missing or of another type, an unreadable file or directory, a
# transcript, no jq. A release that changes the format then costs a round
# with the user, never a switch under a real peer. No -e: each failure is
# caught where it happens, so every name still gets its line.
#
# No entry, two, and one not still idle from its start each have a line of
# their own, and the first names each entry whose name ends in ": <name>":
# a name passed short finds no entry, and placed-elsewhere.sh has why.
#
# skills/workflow/land/references/never-prompted-sessions.md has the
# measurements behind each read, and tests/scripts/never-prompted/ holds
# each case.
#
# <config> is $CLAUDE_CONFIG_DIR when set, as for Claude Code, else
# ~/.claude.
#
# Usage, each <name> as a `ListAgents` row prints it:
#   bash ~/.claude/skills/land/scripts/never-prompted.sh <name>...
#
# stdout: one line per name. Exit 0 when every name passes, 1 when any
# reads as live, 2 on a usage error.
set -uo pipefail

if [[ $# -eq 0 ]]; then
    echo "usage: never-prompted.sh <name>..." >&2
    exit 2
fi

if ! command -v jq > /dev/null 2>&1; then
    echo "error: jq not found on PATH, so every session reads as live" >&2
    exit 1
fi

# A native jq.exe writes CRLF without -b, and Git Bash reports OSTYPE=cygwin.
JQ_BIN=()
case "$OSTYPE" in msys* | cygwin*) JQ_BIN=(-b) ;; esac

CONFIG_DIR=$HOME/.claude
if [[ -n ${CLAUDE_CONFIG_DIR:-} ]]; then
    CONFIG_DIR=$(cygpath -u "$CLAUDE_CONFIG_DIR" 2> /dev/null || printf '%s' "$CLAUDE_CONFIG_DIR")
fi

# What the registry holds under $n, as "<entries carrying it><tab><detail>":
# for one still idle and touched under a second after its start,
# "<sessionId> <pid> <minutes since its start> <ms from start to updatedAt>
# <entrypoint>", where a field missing or of another type selects nothing;
# for none, a clause naming each entry whose name ends in ": $n",
# shell-quoted, when any does; else nothing.
# shellcheck disable=SC2016 # $n, $e and $d are jq variables
FILTER='
    [.[] | select(.name == $n)] as $e
    | "\($e | length)\t" + (
        if ($e | length) == 1 then
            ($e[0]
            | select(.status == "idle"
                and (.sessionId | type) == "string"
                and (.startedAt | type) == "number"
                and (.updatedAt | type) == "number")
            | (.updatedAt - .startedAt) as $d
            | select($d >= 0 and $d < 1000)
            | "\(.sessionId) \(.pid) \((now - .startedAt / 1000) / 60 | floor) \($d) \(.entrypoint)"
            ) // ""
        elif ($e | length) == 0 then
            [.[].name | select(type == "string" and endswith(": " + $n)) | @sh]
            | if length == 0 then ""
              elif length == 1 then "one is named \(.[0])"
              else "\(length) are named \(join(", "))" end
        else "" end)
'
TAB=$'\t'
UUID='^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'
RC=0

# live <name> <why>: report the name as live, and fail the run
live() {
    printf '%s: live, %s\n' "$1" "$2"
    RC=1
}

for name in "$@"; do
    if ! got=$(jq "${JQ_BIN[@]}" -r -s --arg n "$name" "$FILTER" "$CONFIG_DIR"/sessions/*.json); then
        live "$name" "the session registry did not read"
        continue
    fi
    count=${got%%"$TAB"*}
    detail=${got#*"$TAB"}
    if [[ $count == 0 ]]; then
        live "$name" "no registry entry under this name${detail:+; $detail}"
        continue
    fi
    if [[ $count != 1 ]]; then
        live "$name" "$count registry entries under this name"
        continue
    fi
    if [[ -z $detail ]]; then
        live "$name" "its registry entry is not still idle from its start"
        continue
    fi
    read -r sid pid minutes delta entrypoint <<< "$detail"
    # A UUID, so the lookup below can match no other session's transcript.
    if [[ ! $sid =~ $UUID ]]; then
        live "$name" "its sessionId is not a UUID"
        continue
    fi
    if ! transcript=$(find "$CONFIG_DIR/projects" -name "$sid.jsonl" -print -quit); then
        live "$name" "the transcript lookup failed"
        continue
    fi
    if [[ -n $transcript ]]; then
        live "$name" "it has a transcript"
        continue
    fi
    printf '%s: never prompted, pid %s, %s, started %s min ago, updatedAt %s ms after start, no transcript\n' \
        "$name" "$pid" "$entrypoint" "$minutes" "$delta"
done
exit "$RC"
