#!/usr/bin/env bash
# Exercise scripts/audit-status.py's filing of briefs against a throwaway repo.
#
# The script files a brief whose execution log leaves nothing open under
# its directory's completed/, and every other brief at the top, moving
# files to get there; --check is the pre-commit gate that fails on one on
# the wrong side. A live run proves nothing: once this repo's ledger is
# filed it moves nothing, which is also what a rule that never fires does.
# So each case is planted here, on both sides, and must come out right.
#
# The fixture is a fake repo in a temp directory holding a copy of the
# script, since the script finds docs/audits/ from its own location --
# nothing is written inside any real repo.
#
#     bash tests/scripts/audit-status/test-placement.sh
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

fix="$tmproot/fixrepo"
src="$fix/docs/audits/2026-09-01/src"
other="$fix/docs/audits/2026-09-01/other"
mkdir -p "$fix/scripts" "$src/completed" "$other/completed"
cp "$repo/scripts/audit-status.py" "$fix/scripts/"

# expect_exit <label> <expected exit> [script arguments...]
expect_exit() {
    local label=$1 want=$2
    shift 2
    PYTHONIOENCODING=utf-8 uv run python "$(native "$fix/scripts/audit-status.py")" "$@" \
        > "$tmproot/out.txt" 2>&1
    local got=$?
    if [ "$got" = "$want" ]; then
        echo "ok    $label (exit $got)"
        pass=$((pass + 1))
    else
        echo "FAIL  $label: expected exit $want, got $got"
        sed 's/^/        /' "$tmproot/out.txt"
        fail=$((fail + 1))
    fi
}

# expect_line <label> <fixed string> [file, default the last run's output]
expect_line() {
    if grep -qF -- "$2" "${3:-$tmproot/out.txt}"; then
        echo "ok    $1"
        pass=$((pass + 1))
    else
        echo "FAIL  $1: no line containing '$2'"
        sed 's/^/        /' "${3:-$tmproot/out.txt}"
        fail=$((fail + 1))
    fi
}

# expect_no_line <label> <fixed string that must NOT appear in the last run's output>
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

# expect_path <label> <path> <present | absent>
expect_path() {
    if { [ "$3" = present ] && [ -e "$2" ]; } || { [ "$3" = absent ] && [ ! -e "$2" ]; }; then
        echo "ok    $1"
        pass=$((pass + 1))
    else
        echo "FAIL  $1: expected $3, $2"
        fail=$((fail + 1))
    fi
}

# brief <directory> <path under it> [execution log entry...]; none is unrun
brief() {
    local path="$1/$2" name
    name=$(basename "$2" .md)
    shift 2
    {
        echo "# $name"
        echo
        echo "- **Kind**: edit"
        if [ "$#" -gt 0 ]; then
            printf '\n## Execution log\n\n'
            printf -- '- %s\n' "$@"
        fi
    } > "$path"
}

echo "# report" > "$src/00-audit-report.md"
echo "# report" > "$other/00-audit-report.md"
brief "$src" 01-unrun.md
brief "$src" 02-applied.md "**Executed**: 2026-09-02 — applied"
brief "$src" 03-escalated.md "**Executed**: 2026-09-02 — escalated" "**Needs**: user — a decision"
brief "$src" 04-closed.md "**Executed**: 2026-09-02 — escalated" "**Needs**: user — a decision" \
    "**Closed**: 2026-09-03 — answered"
brief "$src" 05-already.md "**Executed**: 2026-09-02 — already-applied"
brief "$src" 06-unparsed.md "**Needs**: none"
brief "$src" completed/07-deferrals.md "**Executed**: 2026-09-02 — applied with deferrals" \
    "**Needs**: desktop — a check"
brief "$src" completed/08-unrun.md
brief "$src" completed/09-filed.md "**Executed**: 2026-09-02 — applied"
brief "$other" completed/01-unrun.md

# 1. --check names every brief on the wrong side, either way, and moves none.
expect_exit "a brief on the wrong side fails --check" 1 --check
expect_line "an applied brief at the top is misplaced" \
    "misplaced: docs/audits/2026-09-01/src/02-applied.md, whose log puts it in docs/audits/2026-09-01/src/completed/"
expect_line "a closed brief at the top is misplaced" "src/04-closed.md, whose log puts it in"
expect_line "an already-applied brief at the top is misplaced" "src/05-already.md, whose log puts it in"
expect_line "an open brief under completed/ is misplaced" \
    "misplaced: docs/audits/2026-09-01/src/completed/07-deferrals.md, whose log puts it in docs/audits/2026-09-01/src/"
expect_line "an unrun brief under completed/ is misplaced" "src/completed/08-unrun.md, whose log puts it in"
expect_no_line "an unrun brief at the top stays" "src/01-unrun.md, whose"
expect_no_line "an escalated brief stays at the top until closed" "03-escalated"
expect_no_line "an unparsed log stays at the top" "06-unparsed"
expect_no_line "a finished brief under completed/ stays" "09-filed"
expect_line "a missing index is still reported" "stale or missing: docs/audits/2026-09-01/src/README.md"
expect_path "--check moves nothing" "$src/02-applied.md" present

# 2. Regenerating files each brief where its log puts it, and the index
#    links each where it now sits, in number order across both sides.
expect_exit "regenerating files every brief" 0
expect_line "a move is reported" \
    "moved docs/audits/2026-09-01/src/02-applied.md -> docs/audits/2026-09-01/src/completed/02-applied.md"
expect_path "an applied brief moves under completed/" "$src/completed/02-applied.md" present
expect_path "and leaves the top" "$src/02-applied.md" absent
expect_path "a closed brief moves under completed/" "$src/completed/04-closed.md" present
expect_path "an already-applied brief moves under completed/" "$src/completed/05-already.md" present
expect_path "an open brief moves back to the top" "$src/07-deferrals.md" present
expect_path "an unrun brief moves back to the top" "$src/08-unrun.md" present
expect_path "an escalated brief stays at the top" "$src/03-escalated.md" present
expect_path "an emptied completed/ is removed" "$other/completed" absent
expect_line "the index links a filed brief under completed/" "(completed/02-applied.md)" \
    "$src/README.md"
expect_line "the index links an open brief at the top" "(07-deferrals.md)" "$src/README.md"
order=$(grep -o '^| \[0[0-9]' "$src/README.md" | tr -d '| [' | tr -d '\n')
if [ "$order" = "010203040506070809" ]; then
    echo "ok    the index keeps number order across both sides"
    pass=$((pass + 1))
else
    echo "FAIL  the index keeps number order across both sides: got $order"
    fail=$((fail + 1))
fi

# 3. The filed fixture passes, and a second run has nothing to move.
expect_exit "the filed fixture passes --check" 0 --check
expect_exit "a second run moves nothing" 0
expect_no_line "nothing is reported moved" "moved "

# 4. A brief on both sides is two copies to reconcile by hand: the run
#    stops, overwrites neither, and --check keeps failing until then.
cp "$src/completed/02-applied.md" "$src/02-applied.md"
expect_exit "a brief on both sides stops the run" 2
expect_line "the clash names both copies" \
    "both exist, so nothing moved: docs/audits/2026-09-01/src/02-applied.md and docs/audits/2026-09-01/src/completed/02-applied.md"
expect_path "the copy at the top is kept" "$src/02-applied.md" present
expect_path "the copy under completed/ is kept" "$src/completed/02-applied.md" present
expect_exit "--check fails while both exist" 1 --check

# 5. --retirable lists a finished run once a later run of its source
#    exists, and reads only. The newest run of a source is never listed,
#    finished or not, nor is a run with an open brief or one never run.
done1="$fix/docs/audits/2026-09-01/done"
done2="$fix/docs/audits/2026-09-08/done"
pend1="$fix/docs/audits/2026-09-01/pend"
pend2="$fix/docs/audits/2026-09-08/pend"
later="$fix/docs/audits/2026-09-08/src"
mkdir -p "$done1/completed" "$done2/completed" "$pend1" "$pend2" "$later"
for d in "$done1" "$done2" "$pend1" "$pend2" "$later"; do
    echo "# report" > "$d/00-audit-report.md"
done
brief "$done1" completed/01-applied.md "**Executed**: 2026-09-02 — applied"
brief "$done1" completed/02-closed.md "**Executed**: 2026-09-02 — escalated" \
    "**Closed**: 2026-09-03 — answered"
brief "$done2" completed/01-applied.md "**Executed**: 2026-09-09 — applied"
brief "$pend1" 01-unrun.md
expect_exit "--retirable lists and exits clean" 0 --retirable
expect_line "a finished run a later run supersedes is retirable" \
    "retirable: docs/audits/2026-09-01/done/  superseded by 2026-09-08"
expect_no_line "the newest run of a source is not" "2026-09-08/done"
expect_no_line "a superseded run with an open brief is not" "2026-09-01/src"
expect_no_line "a superseded run with a brief never run is not" "2026-09-01/pend"
expect_no_line "a run no later run supersedes is not" "2026-09-01/other"
expect_path "--retirable deletes nothing" "$done1/completed/01-applied.md" present

echo
echo "$pass passed, $fail failed"
[ "$fail" = 0 ]
