#!/usr/bin/env bash
# offer-handoff.sh — SessionStart hook (matcher "compact"): after a
# compaction, tell Claude that a handoff brief could be written while the
# summary still holds the thread, and list the briefs the repo already keeps,
# so the offer can name the one a thread belongs to.
#
# The user decides when to hand off, so this offers and never blocks. A
# PreCompact hook that stopped a bare /compact with a hand-off message was
# tried in a client sandbox repo on 2026-10-01 and dropped the same day: the
# user sometimes runs a session long on purpose and judges when it has run
# long enough. PreCompact could not have offered anything anyway: Claude Code
# discards its systemMessage, and its exit-2 stderr reaches only the user, on
# a manual /compact. PostCompact receives the summary and discards its output
# too. SessionStart with matcher "compact" fires after every compaction, auto
# or manual, and its plain stdout joins Claude's context: after a /compact on
# 2.1.291 (2026-10-06), Claude quoted the text back, which it sees prefixed
# "SessionStart:compact hook success:", from a transcript record of type
# attachment, hook_success, written just after the compact_boundary. No hook
# input carries the context's size as it fills, so no hook can warn before an
# auto compaction (code.claude.com/docs/en/hooks, read 2026-10-06). The text
# is statements, not commands: that page warns that text framed as system
# commands can trip Claude's prompt-injection defences, so Claude would show
# it to the user rather than use it.
#
# The queue is the one in the checkout holding the input's `cwd`, the nearest
# folder with a .git, which in a worktree is its own .git file:
# CLAUDE_PROJECT_DIR stays at the main checkout when Claude enters a
# worktree. A brief is what scripts/handoff-status.py counts: any .md under
# docs/handoffs/, dot folders included, but a README.md, CLAUDE.md or
# AGENTS.md, anything under a templates/ or examples/ folder, and
# declined.md at the tree's root. The rule is restated here because a hook
# spawns no Python, and tests/hooks/offer-handoff/ holds the two together.
# With no docs/handoffs/ folder it prints nothing: an offer there would have
# nowhere to put a brief.
#
# Bash builtins only, so it starts nothing but bash. The list stops at 8,000
# characters, keeping the whole under the 10,000 Claude Code allows a hook's
# stdout, past which Claude would see a file path and a preview instead. It
# never blocks, prints nothing on input it cannot read, and always exits 0.

IFS= read -r -d '' INPUT || true
CR=$'\r'
LIMIT=8000

# json_value <field>: the field's string value in REPLY, separators as "/".
# Only for fields holding a path or a plain word, which never hold a quote.
json_value() {
    local re="\"$1\"[[:space:]]*:[[:space:]]*\"([^\"]*)\""
    [[ $INPUT =~ $re ]] || return 1
    REPLY=${BASH_REMATCH[1]//\\\\//}
}

# checkout_root <dir>: the checkout holding <dir>, in REPLY.
checkout_root() {
    local d=${1%/}
    while [[ -n $d ]]; do
        if [[ -e $d/.git ]]; then
            REPLY=$d
            return 0
        fi
        [[ $d == */* ]] || return 1
        d=${d%/*}
    done
    return 1
}

# brief_line <file> <path>: the brief's line for the list, in REPLY, from the
# frontmatter between its opening --- and the next. A needs or blocked-by of
# [] says nothing, so it is left out.
brief_line() {
    local line key value n=0 closed=0 status='' priority='' needs='' blocked='' reopen=''
    REPLY="- $2: no frontmatter"
    [[ -f $1 && -r $1 ]] || return 0
    while IFS= read -r line || [[ -n $line ]]; do
        line=${line%"$CR"}
        if ((n++ == 0)); then
            [[ $line == --- ]] || return 0
            continue
        fi
        if [[ $line == --- ]]; then
            closed=1
            break
        fi
        ((n > 20)) && break
        key=${line%%:*}
        value=${line#*:}
        value=${value#"${value%%[![:space:]]*}"}
        value=${value%"${value##*[![:space:]]}"}
        case $key in
        status) status=$value ;;
        priority) priority=$value ;;
        needs) needs=$value ;;
        blocked-by) blocked=$value ;;
        reopen-when) reopen=$value ;;
        esac
    done <"$1"
    ((closed)) || return 0
    REPLY="- $2: ${status:-no status}"
    [[ -n $priority ]] && REPLY+=", P$priority"
    [[ -n $needs && $needs != '[]' ]] && REPLY+=", needs $needs"
    [[ -n $blocked && $blocked != '[]' ]] && REPLY+=", blocked by $blocked"
    [[ -n $reopen ]] && REPLY+=", reopens when $reopen"
    return 0
}

json_value source && [[ $REPLY == compact ]] || exit 0
json_value cwd || exit 0
checkout_root "$REPLY" || exit 0
TREE=$REPLY/docs/handoffs
[[ -d $TREE ]] || exit 0

LIST=
MORE=0
shopt -s globstar nullglob dotglob
for f in "$TREE"/**/*.md; do
    rel=${f#"$TREE"/}
    name=${rel##*/}
    case ${name,,} in readme.md | claude.md | agents.md) continue ;; esac
    [[ /$rel == */templates/* || /$rel == */examples/* ]] && continue
    [[ $rel != */* && ${name,,} == declined.md ]] && continue
    [[ -f $f ]] || continue
    if ((MORE)); then
        ((MORE++))
        continue
    fi
    brief_line "$f" "$rel"
    if ((${#LIST} + ${#REPLY} >= LIMIT)); then
        MORE=1
        continue
    fi
    LIST+=$REPLY$'\n'
done

MSG='This session was just compacted. A compaction summary keeps conclusions and
drops detail, most often what was not checked and which claims were observed
rather than inferred.

This repo keeps work that outlasts a session in handoff briefs under
docs/handoffs/, and the user decides when to hand off. After a compaction,
the convention is to mention once that a brief could be written now, while
the summary still holds the thread, and to write one only if the user says
so. A thread that belongs to a brief below is handed off by updating that
brief.'

if [[ -z $LIST ]]; then
    printf '%s\n\nBriefs under docs/handoffs/: none.\n' "$MSG"
else
    printf '%s\n\nBriefs under docs/handoffs/:\n%s' "$MSG" "$LIST"
    ((MORE)) && printf -- '- and %d more, past what fits here\n' "$MORE"
fi
exit 0
