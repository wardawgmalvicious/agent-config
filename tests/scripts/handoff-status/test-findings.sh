#!/usr/bin/env bash
# Exercise scripts/handoff-status.py's findings against a throwaway machine.
#
# The live sweep passing says nothing: on 2026-09-18 every repo on this
# machine came back with no findings, which is exactly what a sweep that
# never fires would also produce. So each finding is planted here and must
# fire, and a cleaned-up copy of the same fixture must come back quiet.
#
# The fixture is a fake repos root and a fake inbox in a temp directory,
# passed in as arguments -- no network, and nothing written inside any repo.
#
#     bash tests/scripts/handoff-status/test-findings.sh
#
set -u

here=$(cd "$(dirname "$0")" && pwd)
repo=$(cd "$here/../../.." && pwd)
tmproot=$(mktemp -d)
trap 'rm -rf "$tmproot"' EXIT

pass=0
fail=0

# A native Windows python resolves a /tmp path to C:\tmp, not %TEMP%, so
# hand it a Windows path wherever cygpath exists to make one.
native() {
    if command -v cygpath > /dev/null; then cygpath -w "$1"; else echo "$1"; fi
}

run() {
    PYTHONIOENCODING=utf-8 uv run python "$repo/scripts/handoff-status.py" \
        "$(native "$tmproot/root")" --inbox "$(native "$tmproot/inbox")" --check \
        > "$tmproot/out.txt" 2>&1
}

# expect_exit <label> <expected>
expect_exit() {
    run
    local actual=$?
    if [ "$actual" = "$2" ]; then
        echo "ok    $1 (exit $actual)"
        pass=$((pass + 1))
    else
        echo "FAIL  $1: expected exit $2, got $actual"
        sed 's/^/        /' "$tmproot/out.txt"
        fail=$((fail + 1))
    fi
}

# expect_line <label> <fixed string that must appear in the last run's output>
expect_line() {
    if grep -qF -- "$2" "$tmproot/out.txt"; then
        echo "ok    $1"
        pass=$((pass + 1))
    else
        echo "FAIL  $1: no line containing '$2'"
        sed 's/^/        /' "$tmproot/out.txt"
        fail=$((fail + 1))
    fi
}

# expect_brief <label> <brief filename> <fixed string its queue line must hold>
expect_brief() {
    local line
    line=$(grep -E -- "  ${2//./\\.} +written" "$tmproot/out.txt")
    if [[ -n "$line" && "$line" == *"$3"* ]]; then
        echo "ok    $1"
        pass=$((pass + 1))
    else
        echo "FAIL  $1: $2's line lacks '$3'"
        sed 's/^/        /' "$tmproot/out.txt"
        fail=$((fail + 1))
    fi
}

# expect_no_line <label> <fixed string that must NOT appear>
expect_no_line() {
    if grep -qF -- "$2" "$tmproot/out.txt"; then
        echo "FAIL  $1: found '$2'"
        sed 's/^/        /' "$tmproot/out.txt"
        fail=$((fail + 1))
    else
        echo "ok    $1"
        pass=$((pass + 1))
    fi
}

# One repo under a grouping directory, as repos sit here -- C:/Repos/<group>.
fix="$tmproot/root/group/fixrepo"
queue="$fix/docs/handoffs/execute"
mkdir -p "$queue/templates" "$tmproot/inbox/fixrepo" "$tmproot/inbox/fixrepo-typo"
git init -q "$fix"
cat > "$queue/README.md" <<'EOF'
# Queue

| Item | State |
| --- | --- |
| [a.md](a.md) | **Open, written 2026-09-01.** Something. |
| [gone.md](gone.md) | **Open.** Spent but never struck. |
| [2026-01-01-d.md](2026-01-01-d.md) | **Deferred.** Dated name. |
| [outside](../../../README.md) | **Not a brief.** |

See [c.md](c.md) in prose, which is not a row.

## Deferred

- [b.md](b.md) — no bold, so the heading is the state.
EOF
for f in a b c 2026-01-01-d templates/t; do echo "# $f" > "$queue/$f.md"; done
# Instruction files a directory keeps for its readers, not briefs.
echo "# rules" > "$fix/docs/handoffs/CLAUDE.md"
echo "# rules" > "$queue/AGENTS.md"
# The ledger of declined learnings, a record at the tree's root and not a
# brief. A file of that name anywhere else is a brief like any other.
echo "# Declined" > "$fix/docs/handoffs/declined.md"
echo "# declined" > "$queue/declined.md"
echo note > "$tmproot/inbox/fixrepo/2026-09-10-note.md"
echo note > "$tmproot/inbox/loose.md"

# Briefs that state their own state in frontmatter, and so need no row.
# fm <name> <frontmatter line>...
fm() {
    local name=$1
    shift
    { echo "---"; printf '%s\n' "$@"; echo "---"; echo; echo "# $name"; } > "$queue/$name.md"
}
fm f "status: open" "priority: 1" "needs: []" "blocked-by: []" "written: 2026-09-20"
fm u "status: open" "priority: 2" "needs: [user]" "written: 2026-09-21"
fm k "status: open" "priority: 2" "blocked-by: [f.md]" "written: 2026-09-22"
fm bad "status: maybe" "priority: 1" "written: 2026-09-23"
fm dep "status: deferred" "priority: 3" "written: 2026-09-24"
fm m "status: open" "priority: 3" "blocked-by: [missing.md]" "written: 2026-09-25"
# shellcheck disable=SC2016 # the backtick is literal, and the point
fm tick "status: open" "priority: 3" 'reopen-when: `x` opens with a backtick' "written: 2026-09-26"
# A colon then a space mid-value, where the opening is fine; and a list item.
fm colon "status: open" "priority: 3" "reopen-when: a typo reaches a run: what-if" \
    "written: 2026-09-26"
fm item "status: open" "priority: 3" "needs: [desktop, a run: what-if]" "written: 2026-09-26"
# A worktree named after f claims it. A worktree needs a commit to branch from.
git_t() { git -c user.name=t -c user.email=t@example.com "$@"; }
git_t -C "$fix" commit -q --allow-empty -m init
add_worktree() {
    git -C "$fix" worktree add -q "$(native "$fix/.claude/worktrees/$1")" -b "$1" 2> /dev/null
}
add_worktree f
# How each claim holds its brief. f's worktree is fresh and unlocked. The live
# pid is this shell's own, its Windows pid under Git Bash, as Claude Code
# records one; no Windows or Linux process has pid 999999999. merged's branch
# commits and the main checkout fast-forwards to it; park's never lands.
for name in hold stale bare park merged; do
    fm "$name" "status: open" "priority: 3" "written: 2026-09-27"
    add_worktree "$name"
done
live=$(cat "/proc/$$/winpid" 2> /dev/null || echo "$$")
git -C "$fix" worktree lock --reason "claude session hold (pid $live)" \
    "$(native "$fix/.claude/worktrees/hold")"
git -C "$fix" worktree lock --reason "claude session stale (pid 999999999)" \
    "$(native "$fix/.claude/worktrees/stale")"
git -C "$fix" worktree lock "$(native "$fix/.claude/worktrees/bare")"
git_t -C "$fix/.claude/worktrees/park" commit -q --allow-empty -m unlanded
git_t -C "$fix/.claude/worktrees/merged" commit -q --allow-empty -m landed
git_t -C "$fix" merge -q --ff-only merged

# An audit ledger directory, which audit-status.py knows by its report.
# stamp <name> <execution log entry>...
audits="$fix/docs/audits/2026-09-01/src"
mkdir -p "$audits"
echo "# report" > "$audits/00-audit-report.md"
stamp() {
    local name=$1
    shift
    { echo "# $name"; echo; echo "## Execution log"; echo; printf -- '- %s\n' "$@"; } \
        > "$audits/$name.md"
}
stamp 01-asks "**Executed**: 2026-09-02 — escalated" "**Needs**: user — a decision"
stamp 02-bare "**Executed**: 2026-09-02 — escalated"
stamp 03-done "**Executed**: 2026-09-02 — applied"
stamp 04-closed "**Executed**: 2026-09-02 — escalated" "**Closed**: 2026-09-03 — answered"
stamp 05-waits "**Executed**: 2026-09-02 — applied with deferrals" "**Needs**: desktop, a CLI — why"
stamp 06-free "**Executed**: 2026-09-02 — deferred" "**Needs**: none — a session can act"
echo "# 07-unrun" > "$audits/07-unrun.md"
# Its log says whether a brief is open, wherever audit-status.py has filed it.
mkdir -p "$audits/completed"
stamp completed/08-filed "**Executed**: 2026-09-02 — applied"
stamp completed/09-misfiled "**Executed**: 2026-09-02 — escalated" "**Needs**: user — still open"

# 1. Every finding planted above fires, and --check fails on them.
expect_exit "planted findings fail --check" 1
expect_line "a row whose brief is gone is dangling" "dangling   docs/handoffs/execute/README.md links gone.md"
expect_line "a brief linked only from prose is unindexed" "unindexed  docs/handoffs/execute/c.md"
expect_line "a note in the inbox root is loose" "loose note in ~/handoff-inbox/: loose.md"
expect_line "an inbox directory naming no repo is orphaned" "orphan inbox directory ~/handoff-inbox/fixrepo-typo/"
expect_line "an open audit brief with no Needs line is a finding" \
    "audit       docs/audits/2026-09-01/src/02-bare.md: escalated and not closed"

# 2. What the sweep must read correctly, and what it must leave alone.
expect_line "a row's state is its first bold span" "Open, written 2026-09-01"
expect_line "a row with no bold takes its heading" "Deferred                                        uncommitted  b.md"
expect_line "a dated filename is noted" "2026-01-01-d.md   (dated filename)"
expect_line "a routed note is listed under its repo" "2026-09-10-note.md"
expect_no_line "templates/ is reference material, not a brief" "t.md"
expect_no_line "a CLAUDE.md is an instruction file, not a brief" "CLAUDE.md"
expect_no_line "an AGENTS.md is an instruction file, not a brief" "AGENTS.md"
expect_no_line "the decline ledger at the tree's root is not a brief" \
    "unindexed  docs/handoffs/declined.md"
expect_line "a declined.md anywhere else is still a brief" \
    "unindexed  docs/handoffs/execute/declined.md"
expect_no_line "a link outside docs/handoffs is not a row" "Not a brief"

# 3. Frontmatter: its briefs group and sort, and each bad value is a finding.
expect_no_line "a brief with frontmatter needs no row" "unindexed  docs/handoffs/execute/f.md"
expect_line "an open, unblocked brief is ready" "    ready"
expect_line "a worktree named after a brief puts it in flight" "touched uncommitted  in flight"
expect_brief "a fresh, unlocked worktree is parked, not merged" f.md "in flight (parked)"
expect_brief "a lock whose pid is alive is held" hold.md "in flight (held)"
expect_brief "a lock whose pid is gone is parked, lock stale" stale.md \
    "in flight (parked, lock stale)"
expect_brief "a lock naming no pid is held" bare.md "in flight (held)"
expect_brief "a commit that never landed is parked" park.md "in flight (parked)"
expect_brief "a committed branch the main checkout holds is merged" merged.md \
    "in flight (merged)"
expect_line "needs: [user] waits on the user" "needs user"
expect_line "a blocker that exists blocks" "blocked by f.md"
expect_line "an unknown status is a finding" "frontmatter docs/handoffs/execute/bad.md: status is maybe"
expect_line "deferred with no trigger is a finding" \
    "frontmatter docs/handoffs/execute/dep.md: a deferred brief needs reopen-when"
expect_line "a blocker that is gone is a finding" \
    "blocker     docs/handoffs/execute/m.md: blocked-by names missing.md, which does not exist"
# shellcheck disable=SC2016 # the backticks are literal
expect_line "a value YAML would misread is a finding" \
    'frontmatter docs/handoffs/execute/tick.md: `reopen-when` would not parse as plain YAML'
# shellcheck disable=SC2016 # the backticks are literal
expect_line "the finding names an opening it met" \
    'tick.md: `reopen-when` would not parse as plain YAML: it opens with '"'\`'"
expect_line "the finding names a colon mid-value, not the opening" \
    "colon.md: \`reopen-when\` would not parse as plain YAML: it holds ': '"
expect_line "a list item's finding names the item and its case" \
    "item.md: \`needs\` item 'a run: what-if' would not parse as plain YAML: it holds ': '"

# 4. Audit follow-ups: an open outcome with no Closed line is listed by its
#    Needs, an unrun brief under its directory, and the rest not at all.
expect_line "Needs: user waits on the user" "2026-09-01/src/01-asks.md  needs user"
expect_line "a Needs line splits on commas" "2026-09-01/src/05-waits.md  needs desktop, a CLI"
expect_no_line "a Needs line stops at a dash" "— why"
expect_line "Needs: none is listed" "2026-09-01/src/06-free.md"
expect_no_line "Needs: none needs nothing" "06-free.md  needs"
expect_no_line "an applied brief is not open" "03-done"
expect_no_line "a closed brief is not open" "04-closed"
expect_no_line "a brief filed under completed/ is not open" "08-filed"
expect_line "an open brief is listed wherever it sits" \
    "2026-09-01/src/completed/09-misfiled.md  needs user"
expect_line "an unrun brief counts under its directory" "2026-09-01/src/  1 brief(s)"

# 5. --no-inbox leaves the inbox alone, so one repo can be checked by itself.
PYTHONIOENCODING=utf-8 uv run python "$repo/scripts/handoff-status.py" \
    "$(native "$fix")" --no-inbox --check > "$tmproot/out.txt" 2>&1
expect_no_line "--no-inbox reports no loose note" "loose note"
expect_no_line "--no-inbox lists no inbox" "inbox:"

# 6. From a linked worktree the repo keeps its main checkout's name, which
#    keys its inbox directory: named for the worktree, that directory read as
#    an orphan and its notes went uncounted (2026-09-30).
PYTHONIOENCODING=utf-8 uv run python "$repo/scripts/handoff-status.py" \
    "$(native "$fix/.claude/worktrees/f")" --inbox "$(native "$tmproot/inbox")" \
    > "$tmproot/out.txt" 2>&1
expect_line "a worktree is named for its main checkout" "== fixrepo =="
expect_line "a worktree lists its repo's notes" "2026-09-10-note.md"
expect_no_line "a worktree's repo inbox is no orphan" "orphan inbox directory ~/handoff-inbox/fixrepo/"

# 7. The same fixture with every finding resolved passes. A dated filename
#    is left in place on purpose: it is reported, never a finding.
sed -i '/gone\.md/d' "$queue/README.md"
echo "| [c.md](c.md) | **Open.** Now indexed. |" >> "$queue/README.md"
rm "$tmproot/inbox/loose.md"
rmdir "$tmproot/inbox/fixrepo-typo"
fm bad "status: open" "priority: 1" "written: 2026-09-23"
fm dep "status: deferred" "priority: 3" "reopen-when: a trigger fires" "written: 2026-09-24"
fm m "status: open" "priority: 3" "blocked-by: []" "written: 2026-09-25"
fm tick "status: open" "priority: 3" "written: 2026-09-26"
fm colon "status: open" "priority: 3" "written: 2026-09-26"
fm item "status: open" "priority: 3" "needs: [desktop]" "written: 2026-09-26"
fm declined "status: open" "priority: 3" "written: 2026-09-28"
stamp 02-bare "**Executed**: 2026-09-02 — escalated" "**Needs**: tenant"
expect_exit "resolved fixture passes --check" 0

echo
echo "$pass passed, $fail failed"
[ "$fail" = 0 ]
