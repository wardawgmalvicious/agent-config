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
echo note > "$tmproot/inbox/fixrepo/2026-09-10-note.md"
echo note > "$tmproot/inbox/loose.md"

# 1. Every finding planted above fires, and --check fails on them.
expect_exit "planted findings fail --check" 1
expect_line "a row whose brief is gone is dangling" "dangling   docs/handoffs/execute/README.md links gone.md"
expect_line "a brief linked only from prose is unindexed" "unindexed  docs/handoffs/execute/c.md"
expect_line "a note in the inbox root is loose" "loose note in ~/handoff-inbox/: loose.md"
expect_line "an inbox directory naming no repo is orphaned" "orphan inbox directory ~/handoff-inbox/fixrepo-typo/"

# 2. What the sweep must read correctly, and what it must leave alone.
expect_line "a row's state is its first bold span" "Open, written 2026-09-01"
expect_line "a row with no bold takes its heading" "Deferred                                        uncommitted  b.md"
expect_line "a dated filename is noted" "2026-01-01-d.md   (dated filename)"
expect_line "a routed note is listed under its repo" "2026-09-10-note.md"
expect_no_line "templates/ is reference material, not a brief" "t.md"
expect_no_line "a link outside docs/handoffs is not a row" "Not a brief"

# 3. The same fixture with every finding resolved passes. A dated filename
#    is left in place on purpose: it is reported, never a finding.
sed -i '/gone\.md/d' "$queue/README.md"
echo "| [c.md](c.md) | **Open.** Now indexed. |" >> "$queue/README.md"
rm "$tmproot/inbox/loose.md"
rmdir "$tmproot/inbox/fixrepo-typo"
expect_exit "resolved fixture passes --check" 0

echo
echo "$pass passed, $fail failed"
[ "$fail" = 0 ]
