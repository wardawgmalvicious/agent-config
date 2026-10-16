#!/usr/bin/env bash
# Exit 0 only when every named session sits outside this working tree. Any
# doubt keeps it in.
#
# A `ListAgents` row is named `<cwd-basename>-<hash>`, or by `/rename`,
# `--name` or a hook, and no name says where its session sits: a basename
# reads the same for a clone elsewhere and differs for a subdirectory, and
# any other name can look like one. `land` must not move HEAD under a
# session in this tree, and `commit` counts one as a peer. Both ask this
# script.
#
# It reads the session registry never-prompted.sh reads,
# <config>/sessions/<pid>.json, which Claude Code writes and does not
# document: the one entry carrying the name, and its `cwd`, the session's
# working directory, which follows `EnterWorktree`. git gives the top level
# of that `cwd` and of the directory this runs in, and a name sits
# elsewhere when the two differ, or when git finds no repository at the
# `cwd`. A linked worktree has a top level of its own, even inside its main
# checkout. One directory has several spellings, so the two compare as git
# spells them, case-insensitively, or as one directory to bash.
#
# Every other outcome keeps the name in this tree and exits 1: no entry,
# two, a `cwd` missing, empty or of another type, a `cwd` git cannot read,
# an unreadable registry, no jq. A release that changes the format then
# costs a round with the user, never a switch under a real peer. No -e:
# each failure is caught where it happens, so every name still gets its
# line.
#
# skills/workflow/land/references/never-prompted-sessions.md has the
# measurements behind each read, and tests/scripts/placed-elsewhere/ holds
# each case.
#
# <config> is $CLAUDE_CONFIG_DIR when set, as for Claude Code, else
# ~/.claude.
#
# Usage, from inside the working tree, each <name> as a `ListAgents` row
# prints it:
#   bash ~/.claude/skills/land/scripts/placed-elsewhere.sh <name>...
#
# stdout: one line per name. Exit 0 when every name sits elsewhere, 1 when
# any sits in this tree or is in doubt, 2 on a usage error.
set -uo pipefail

if [[ $# -eq 0 ]]; then
    echo "usage: placed-elsewhere.sh <name>..." >&2
    exit 2
fi

if ! command -v jq > /dev/null 2>&1; then
    echo "error: jq not found on PATH, so every session reads as in this tree" >&2
    exit 1
fi

if ! HERE=$(git rev-parse --show-toplevel 2> /dev/null); then
    echo "error: no git working tree here, so none to place a session against" >&2
    exit 2
fi

# A native jq.exe writes CRLF without -b, and Git Bash reports OSTYPE=cygwin.
JQ_BIN=()
case "$OSTYPE" in msys* | cygwin*) JQ_BIN=(-b) ;; esac

CONFIG_DIR=$HOME/.claude
if [[ -n ${CLAUDE_CONFIG_DIR:-} ]]; then
    CONFIG_DIR=$(cygpath -u "$CLAUDE_CONFIG_DIR" 2> /dev/null || printf '%s' "$CLAUDE_CONFIG_DIR")
fi

# The `cwd` of the entry under $n when it is the only one, a string with
# something in it. Nothing otherwise.
# shellcheck disable=SC2016 # $n is a jq variable
FILTER='
    [.[] | select(.name == $n)]
    | select(length == 1) | .[0].cwd
    | select(type == "string" and . != "")
'
RC=0

# kept <name> <text>: report the name as in this tree, and fail the run
kept() {
    printf '%s: %s\n' "$1" "$2"
    RC=1
}

for name in "$@"; do
    if ! cwd=$(jq "${JQ_BIN[@]}" -r -s --arg n "$name" "$FILTER" "$CONFIG_DIR"/sessions/*.json); then
        kept "$name" "in doubt, the session registry did not read"
        continue
    fi
    if [[ -z $cwd ]]; then
        kept "$name" "in doubt, no single registry entry with a cwd"
        continue
    fi
    # stderr stays out of $top: a warning printed beside a top level would
    # fail the compare below, and a failed compare places a session elsewhere.
    if ! top=$(git -C "$cwd" rev-parse --show-toplevel 2> /dev/null); then
        why=$(git -C "$cwd" rev-parse --show-toplevel 2>&1 > /dev/null)
        if [[ $why == *"not a git repository"* ]]; then
            printf '%s: elsewhere, cwd %s, in no git repository\n' "$name" "$cwd"
        else
            kept "$name" "in doubt, git could not read its cwd, $cwd"
        fi
        continue
    fi
    if [[ ${top,,} == "${HERE,,}" || "$top" -ef "$HERE" ]]; then
        kept "$name" "this tree, cwd $cwd"
    else
        printf '%s: elsewhere, cwd %s, top level %s\n' "$name" "$cwd" "$top"
    fi
done
exit "$RC"
