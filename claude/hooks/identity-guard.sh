#!/usr/bin/env bash
# identity-guard.sh
#
# Blocks a `git commit` or `git push` whose content would carry an identity
# string — a client or employer name, an account or tenant name, a hardcoded
# profile path — the kind of thing ~/.claude/CLAUDE.md says never goes into a
# file or a commit message, whatever the repo's visibility.
#
# Why a hook and not gitleaks: gitleaks matches secrets, not identities, and
# it never reads a commit message (measured 2026-09-04 on 8.30.1 — a message
# carrying an AWS-key pattern scanned clean). The pre-commit framework sees
# staged content only. A message cannot be fixed forward, and once pushed
# neither can history: refs/pull/N/head pin every commit a PR ever touched,
# so a rewrite-in-place leaves the leak reachable and the only real remedy
# is delete-and-recreate. Hence a gate on push, not only on commit.
#
# Wired on Bash|PowerShell for two events; the script branches on
# hook_event_name:
#   PreToolUse  `git commit` — ADDED lines of the staged diff (plus the
#               working-tree diff when -a/--all is present). Removing a term
#               never blocks. The message is NOT scanned here: it arrives
#               inside the command text next to cwd paths and heredoc
#               plumbing, so scanning the command would block on a path the
#               commit does not contain.
#   PostToolUse `git commit` — HEAD's message. The commit exists, so this
#               cannot block; exit 2 hands the finding back so the message is
#               reworded while it is still local.
#   PreToolUse  `git push`   — messages and ADDED lines of every commit on
#               the pushed ref that no remote already has. The ref is the
#               second positional after `push` when one is given, else HEAD.
#               This is the hard gate: nothing past it can be fixed cheaply.
#
# The denylist is ~/.config/identity-denylist.txt (IDENTITY_DENYLIST
# overrides — the test harness uses that to keep the real list out of a
# run). It lives outside every repo because the list is itself the thing
# that must not be committed. Format: one literal per line, matched as a
# case-insensitive fixed string; `#` comments and blank lines ignored;
# `exempt: <path-prefix>` names repo roots the guard skips — a client's own
# repo legitimately carries its own name, so mirror the includeIf roots.
# No denylist → allow, with a one-line note only visible under --debug.
#
# Spawn economy is a design constraint, not polish: on this machine a
# process spawn under the tool shells costs ~0.4 s (measured 2026-09-04),
# and this fires on EVERY Bash/PowerShell call. So a non-git command is
# rejected by a bash pattern before jq runs, one jq call reads all four
# fields, CR-stripping and path normalisation are parameter expansion, and
# each scan is one git pipeline into one sed. About eight spawns on a
# commit, one on anything else.
#
# Failure side: OPEN. No `set -e` — a grep that matches nothing is the
# normal path here — and every git call is `|| true`-shaped, so a broken
# repo state or a missing tool lets the call through rather than wedging
# every commit on the machine. The tests in tests/hooks/identity-guard/
# are what make that acceptable: run them after any edit.
#
# Exit codes:
#   0 - allow
#   2 - block (PreToolUse) / feed back (PostToolUse); stderr carries the hits

set -uo pipefail

IFS= read -r -d '' INPUT || true # builtin: no cat spawn on the fast path
# Cheap pre-filter: only a shell tool's command that mentions git is worth
# a jq spawn. Both shell tools put the command under tool_input.command.
[[ "$INPUT" == *'"command"'* && "$INPUT" == *git* ]] || exit 0
command -v jq >/dev/null 2>&1 || exit 0

# One jq call, four fields, tab-separated. @tsv escapes tabs, newlines and
# backslashes inside the command, and printf %b puts them back. jq on
# Windows ends the line with CRLF; the CR is stripped by expansion.
JQ=(jq)
if command -v timeout >/dev/null 2>&1; then JQ=(timeout 5 jq); fi
RAW=$(printf '%s' "$INPUT" | "${JQ[@]}" -r \
    '[.hook_event_name, .tool_name, .cwd, .tool_input.command] | map(. // "" | tostring) | @tsv' 2>/dev/null) || exit 0
RAW=${RAW//$'\r'/}
IFS=$'\t' read -r EVENT TOOL CWD CMD_ESC <<<"$RAW"
case "$TOOL" in Bash | PowerShell) ;; *) exit 0 ;; esac
CMD=$(printf '%b' "$CMD_ESC")
[[ -n "$CMD" ]] || exit 0

# Find every `git [global opts] <subcommand>` in the command by tokenizing
# each shell segment, not by regex: an ERE with nested quantifiers over a
# command holding a Windows path sent glibc's matcher exponential
# (2026-09-04). Word-splitting ignores quoting, which is fine for locating
# the subcommand; only the tokens after it are read, and only for -a/--all
# and a push ref.
WANT_COMMIT=0
WANT_PUSH=0
COMMIT_ALL=0
PUSH_SPEC=""
set -f # no globbing while word-splitting the command
SEGS=${CMD//[;|&]/$'\n'}
while IFS= read -r seg; do
    # shellcheck disable=SC2086 # word-splitting is the point
    set -- $seg
    while [[ $# -gt 0 ]]; do
        if [[ "$1" != git && "$1" != */git && "$1" != git.exe ]]; then
            shift
            continue
        fi
        shift
        while [[ $# -gt 0 ]]; do
            case "$1" in
            -C | -c | --git-dir | --work-tree | --namespace | --exec-path | --super-prefix | --config-env)
                # Skip the option and its value; a value that opens a quote
                # and does not close it spans tokens (`-C "C:\Program Files\x"`).
                shift
                q=""
                case "${1:-}" in \"*) q='"' ;; \'*) q="'" ;; esac
                if [[ -n "$q" && (${#1} -eq 1 || "$1" != *"$q") ]]; then
                    shift
                    while [[ $# -gt 0 && "$1" != *"$q" ]]; do shift; done
                fi
                [[ $# -gt 0 ]] && shift
                ;;
            -*) shift ;;
            *) break ;;
            esac
        done
        [[ $# -gt 0 ]] || break
        case "$1" in
        commit)
            WANT_COMMIT=1
            shift
            while [[ $# -gt 0 && "$1" != -- ]]; do
                case "$1" in
                -a | --all | --include) COMMIT_ALL=1 ;;
                -m | -F | -C | -c | --message | --file | --author | --date) shift ;;
                --*) ;;
                -*a*) COMMIT_ALL=1 ;;
                esac
                shift
            done
            ;;
        push)
            WANT_PUSH=1
            shift
            n=0
            while [[ $# -gt 0 && "$1" != -- ]]; do
                case "$1" in
                -*) ;;
                *)
                    n=$((n + 1))
                    [[ $n -eq 2 ]] && PUSH_SPEC="$1"
                    ;;
                esac
                shift
            done
            ;;
        esac
        break
    done
done <<<"$SEGS"
set +f
[[ "$WANT_COMMIT" == 1 || "$WANT_PUSH" == 1 ]] || exit 0

LIST="${IDENTITY_DENYLIST:-$HOME/.config/identity-denylist.txt}"
if [[ ! -f "$LIST" ]]; then
    echo "identity-guard: no denylist at $LIST — nothing to check" >&2
    exit 0
fi

# Normalise a path for prefix comparison: lower-case, forward slashes,
# `/c/...` folded to `c:/...`, trailing slash. Pure expansion, except that
# an 8.3 short name (`USERNA~1`, which is how a cwd under %TEMP% arrives)
# compares unequal to the long form git reports, so a path carrying `~`
# goes through `cygpath -l` once — the only spawn this function makes.
# Plain `cygpath -m` keeps the short name; only `-l` expands it.
norm_path() {
    local p="$1"
    if [[ "$p" == *~* ]] && command -v cygpath >/dev/null 2>&1; then
        p=$(cygpath -lm "$p" 2>/dev/null || printf '%s' "$p")
    fi
    p="${p//\\//}"
    p="${p,,}"
    if [[ "$p" =~ ^/([a-z])(/|$) ]]; then p="${BASH_REMATCH[1]}:${p:2}"; fi
    p="${p%/}/"
    printf '%s' "$p"
}

if [[ -n "$CWD" ]]; then
    CWD_POSIX="${CWD//\\//}"
    if [[ "$CWD_POSIX" =~ ^([A-Za-z]):(/|$) ]]; then CWD_POSIX="/${BASH_REMATCH[1],,}${CWD_POSIX:2}"; fi
    cd "$CWD_POSIX" 2>/dev/null || exit 0
fi
TOP=$(git rev-parse --show-toplevel 2>/dev/null) || exit 0
TOP_NORM=$(norm_path "$TOP")

WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT
TERMS="$WORK/terms"
SCAN="$WORK/scan"
: >"$SCAN"
: >"$TERMS"

# Parse the list in bash: CRLF-tolerant, comments and blanks dropped,
# exempts applied as we go. No spawn.
while IFS= read -r line || [[ -n "$line" ]]; do
    line=${line//$'\r'/}
    line="${line%"${line##*[![:space:]]}"}" # rtrim
    [[ -z "$line" || "$line" == \#* ]] && continue
    if [[ "${line,,}" == exempt:* ]]; then
        ex="${line#*:}"
        ex="${ex#"${ex%%[![:space:]]*}"}" # ltrim
        [[ -n "$ex" && "$TOP_NORM" == "$(norm_path "$ex")"* ]] && exit 0
        continue
    fi
    printf '%s\n' "$line" >>"$TERMS"
done <"$LIST"
[[ -s "$TERMS" ]] || exit 0

# Added lines of a unified diff, minus the +++ file header. One sed.
ADDED='/^+++ /d; /^+/p'

WHAT=""
case "$EVENT" in
PreToolUse)
    if [[ "$WANT_COMMIT" == 1 ]]; then
        WHAT="staged changes"
        git diff --cached -U0 --no-color --no-ext-diff 2>/dev/null | sed -n "$ADDED" >>"$SCAN"
        if [[ "$COMMIT_ALL" == 1 ]]; then
            git diff -U0 --no-color --no-ext-diff 2>/dev/null | sed -n "$ADDED" >>"$SCAN"
        fi
    fi
    if [[ "$WANT_PUSH" == 1 ]]; then
        WHAT="${WHAT:+$WHAT and }unpushed commits"
        REF=HEAD
        # Second positional after `push` (the first is the remote); local
        # side of a refspec, leading + stripped. HEAD when it does not resolve.
        SPEC="${PUSH_SPEC%%:*}"
        SPEC="${SPEC#+}"
        if [[ -n "$SPEC" ]] && git rev-parse --verify -q "$SPEC^{commit}" >/dev/null 2>&1; then
            REF="$SPEC"
        fi
        git log --format='message %h: %s%n%b' "$REF" --not --remotes 2>/dev/null >>"$SCAN"
        git log -p -U0 --no-color --no-ext-diff --format='commit %h' "$REF" --not --remotes 2>/dev/null |
            sed -n '/^+++ /d; /^+/p; /^commit /p' >>"$SCAN"
    fi
    ;;
PostToolUse)
    [[ "$WANT_COMMIT" == 1 ]] || exit 0
    WHAT="the message on HEAD"
    git log -1 --format='%B' 2>/dev/null >>"$SCAN"
    ;;
*) exit 0 ;;
esac

HITS=$(grep -inF -m 20 -f "$TERMS" "$SCAN" 2>/dev/null)
[[ -n "$HITS" ]] || exit 0

{
    echo "identity-guard: $WHAT carry a denylisted identity string."
    echo "Denylist: $LIST (repo: $TOP)"
    echo
    echo "$HITS"
    echo
    if [[ "$EVENT" == PostToolUse ]]; then
        echo "The commit exists locally and nothing has pushed it. Reword it now —"
        echo "git commit --amend on an unpushed commit is safe — and tell the user."
    else
        echo "Genericize the text (a placeholder, a role, <client>) or, if the term"
        echo "is legitimately part of this repo, take it off the denylist. Do not"
        echo "work around the guard: once pushed, refs/pull pin it forever."
    fi
} >&2
exit 2
