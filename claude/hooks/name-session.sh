#!/usr/bin/env bash
# name-session.sh — UserPromptSubmit hook: name a session from its first
# prompt, so ListAgents, `claude agents` and the /resume picker show what it
# is for instead of a default such as `agent-config-67`.
#
# A name is an address: SendMessage reaches a live session by it, and a
# rename strands a peer mid-conversation. So this hook decides once per
# session, on the first prompt that reaches it (built-in commands such as
# /model or /color never do), and names the session only when that prompt
# matches a rule. First match wins:
#
#   1. starts with a skill or command  /test-skill prune-branches  -> test-skill: prune-branches
#   2. names a handoff brief           docs/handoffs/execute/x.md  -> brief: x
#   3. names an inbox note             handoff-inbox/<repo>/<date>-y.md -> inbox: y
#   4. runs in a worktree              .claude/worktrees/w  -> brief: w if that brief exists, else worktree: w
#   5. is on a branch other than main or master             -> the branch name
#
# Anything else keeps Claude Code's default name; `/rename` with no argument
# names a session from its conversation instead. Against the first prompts
# of 195 past sessions (2026-10-06) the rules would have named about half.
#
# Leaves alone a session that already has a name (`session_title` in the
# input: --name, /rename, a probe's `-n "probe: ..."`), and one whose
# transcript already holds a prompt: a session that was running when this
# hook was deployed, or a resumed one. "Seen" is a marker in the session's
# own temp folder, the parent of `scratchpad_dir`, so every prompt after the
# first costs one bash start and two file tests, and the marker goes when
# that folder does. Without `scratchpad_dir` in the input it names nothing:
# a CLI that drops the field turns this hook off, which
# tests/hooks/name-session/ exists to catch.
#
# Spawns nothing for a new session (git's HEAD is read, not run; one grep
# runs, once, only where a transcript already exists), never blocks, and
# prints nothing but the title JSON: plain stdout from this event is added
# to Claude's context. Always exits 0.

IFS= read -r -d '' INPUT || true
CR=$'\r'
CONFIG_DIR=${CLAUDE_CONFIG_DIR:-$HOME/.claude}

# Already named: by --name, /rename, a probe's -n, or this hook.
[[ $INPUT == *'"session_title":"'* ]] && exit 0
[[ $INPUT == *'"prompt":"'* ]] || exit 0

# json_path <field>: the field's string value in REPLY, separators as "/".
# Only for fields holding paths, which never contain a quote.
json_path() {
    local re="\"$1\":\"([^\"]*)\""
    [[ $INPUT =~ $re ]] || return 1
    REPLY=${BASH_REMATCH[1]//\\\\//}
}

json_path scratchpad_dir || exit 0
SESSION_DIR=${REPLY%/scratchpad}
[[ -d $SESSION_DIR ]] || exit 0
MARKER=$SESSION_DIR/.name-session
[[ -e $MARKER ]] && exit 0
: >"$MARKER" 2>/dev/null || exit 0

# Already under way: running before this hook was deployed, or resumed.
if json_path transcript_path && [[ -s $REPLY ]] &&
    grep -q -m1 '"type":"user"' "$REPLY" 2>/dev/null; then
    exit 0
fi

CWD=
json_path cwd && CWD=$REPLY
# The prompt's JSON text and whatever fields follow it; the rules below
# match only shapes no other field can hold.
PROMPT=${INPUT#*\"prompt\":\"}
NAME=

# is_command <name>: a skill or custom command this session can see, or a
# plugin's (plugin:name). A prompt that merely starts with a slash, such as
# a path, is not one.
is_command() {
    [[ $1 == *:* ]] ||
        [[ -f $CONFIG_DIR/skills/$1/SKILL.md || -f $CONFIG_DIR/commands/$1.md ]] ||
        [[ -n $CWD && (-f $CWD/.claude/skills/$1/SKILL.md || -f $CWD/.claude/commands/$1.md) ]]
}

# first_slug <regex> <group>: the first match's slug in REPLY, passing over
# README.md, which names a folder's index rather than a piece of work.
first_slug() {
    local rest=$PROMPT
    while [[ $rest =~ $1 ]]; do
        REPLY=${BASH_REMATCH[$2]}
        [[ ${REPLY,,} != readme ]] && return 0
        rest=${rest#*"${BASH_REMATCH[0]}"}
    done
    return 1
}

# git_branch <dir>: the branch checked out in the repo holding <dir>, in
# REPLY, read from HEAD rather than by starting git.
git_branch() {
    local d=$1 gitdir='' head
    while [[ -n $d ]]; do
        if [[ -d $d/.git ]]; then
            gitdir=$d/.git
            break
        elif [[ -f $d/.git ]]; then
            IFS= read -r gitdir <"$d/.git" || return 1
            gitdir=${gitdir%"$CR"}
            gitdir=${gitdir#gitdir: }
            [[ $gitdir == /* || $gitdir == ?:* ]] || gitdir=$d/$gitdir
            break
        fi
        [[ $d == */* ]] || return 1
        d=${d%/*}
    done
    [[ -n $gitdir ]] || return 1
    IFS= read -r head <"$gitdir/HEAD" || return 1
    head=${head%"$CR"}
    [[ $head == 'ref: refs/heads/'* ]] || return 1
    REPLY=${head#ref: refs/heads/}
}

# 1. A skill or command. Its first argument joins the name when it names
#    something, as a path or @-mention, or is the whole first line; prose
#    does not, so "/learn the thing about X" is just "learn". A path keeps
#    its last segment, less a .md extension.
RE_COMMAND='^/([A-Za-z0-9][A-Za-z0-9:_.-]*)(( |\\t)+(([^ "\\]|\\\\)+))?'
if [[ $PROMPT =~ $RE_COMMAND ]] && is_command "${BASH_REMATCH[1]}"; then
    NAME=${BASH_REMATCH[1]}
    arg=${BASH_REMATCH[4]}
    after=${PROMPT:${#BASH_REMATCH[0]}:2}
    if [[ -n $arg && ($arg == *[/@.\\]* || $after == '"'* || $after == '\n'* || $after == '\r'*) ]]; then
        arg=${arg//\\\\//}
        arg=${arg#@}
        arg=${arg%/}
        arg=${arg##*/}
        arg=${arg%.md}
        [[ -n $arg ]] && NAME="$NAME: $arg"
    fi
fi

# 2. A handoff brief.
RE_BRIEF='docs(/|\\\\)+handoffs(/|\\\\)+execute(/|\\\\)+([A-Za-z0-9._-]+)\.md'
[[ -z $NAME ]] && first_slug "$RE_BRIEF" 4 && NAME="brief: $REPLY"

# 3. An inbox note, less its date prefix.
RE_NOTE='handoff-inbox(/|\\\\)+[A-Za-z0-9._-]+(/|\\\\)+([A-Za-z0-9._-]+)\.md'
if [[ -z $NAME ]] && first_slug "$RE_NOTE" 3; then
    NAME="inbox: ${REPLY#[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]-}"
fi

# 4. A worktree, which in a repo that briefs its work is named after one.
RE_WORKTREE='/\.claude/worktrees/([^/]+)'
if [[ -z $NAME && $CWD =~ $RE_WORKTREE ]]; then
    wt=${BASH_REMATCH[1]}
    root=${CWD%%/.claude/worktrees/*}/.claude/worktrees/$wt
    if [[ -f $root/docs/handoffs/execute/$wt.md ]]; then
        NAME="brief: $wt"
    else
        NAME="worktree: $wt"
    fi
fi

# 5. A branch other than the default.
if [[ -z $NAME && -n $CWD ]] && git_branch "$CWD" &&
    [[ $REPLY != main && $REPLY != master ]]; then
    NAME=$REPLY
fi

[[ -n $NAME ]] || exit 0
NAME=${NAME//[^A-Za-z0-9 ._:\/@+-]/-}
NAME=${NAME:0:80}
printf '{"hookSpecificOutput":{"hookEventName":"UserPromptSubmit","sessionTitle":"%s"}}\n' "$NAME"
exit 0
