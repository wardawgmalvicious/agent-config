#!/usr/bin/env bash
# Exercise skills/fabric-ai/fabric-iq/scripts/data-agent-eval.py without asking any agent: its
# usage errors, which must exit 2 before it signs in, and its grader, through `regrade` on a
# results file built here.
#
# Each grader case is one stored reply and one `expect` value, and the first word of its id is
# the verdict the grader owes it. uv resolves the script's pinned dependencies on the first run,
# which needs the package index once; the cache serves them after that. DATA_AGENT_EVAL points
# the test at another copy of the script.
#
#     bash tests/scripts/data-agent-eval/test-data-agent-eval.sh
#
set -u

here=$(cd "$(dirname "$0")" && pwd)
repo=$(cd "$here/../../.." && pwd)
script="${DATA_AGENT_EVAL:-$repo/skills/fabric-ai/fabric-iq/scripts/data-agent-eval.py}"
tmproot=$(mktemp -d)
trap 'rm -rf "$tmproot"' EXIT

pass=0
fail=0

# check <label> <got> <want>
check() {
    if [ "$2" = "$3" ]; then
        pass=$((pass + 1))
    else
        fail=$((fail + 1))
        echo "FAIL: $1: got '$2', want '$3'"
    fi
}

# refuses <label> <cases file text> [run options...]: exit 2, before any sign-in
refuses() {
    local label=$1 body=$2
    shift 2
    printf '%s\n' "$body" > "$tmproot/cases.yaml"
    uv run --quiet "$script" run ws agent "$tmproot/cases.yaml" "$@" > "$tmproot/out.txt" 2>&1
    check "$label: exit" "$?" 2
}

refuses "a case with no question" "- id: a"
refuses "one id twice" $'- {id: a, question: x}\n- {id: a, question: y}'
refuses "an --only id no case has" "- {id: a, question: x}" --only b
refuses "a tolerance that is not a number" "- {question: x, tolerance: lots}"
refuses "a mapping, not a list" "question: x"
refuses "the draft over MCP" "- {question: x}" --route mcp --stage sandbox

cat > "$tmproot/results.json" <<'EOF'
{"run": {}, "cases": [
{"id": "pass-exact", "reply": "Order value last month was $4,812,345.67.", "expect": [4812345.67]},
{"id": "pass-millions", "reply": "It was $4.8 million.", "expect": [4812345.67]},
{"id": "pass-suffix", "reply": "It was about $4.8M.", "expect": [4812345.67]},
{"id": "pass-rounded", "reply": "It was $4,812,000.", "expect": [4812345.67]},
{"id": "pass-whole-millions", "reply": "It was $5 million.", "expect": [4812345.67]},
{"id": "fail-other-month", "reply": "It was $4,291,102.14.", "expect": [4812345.67]},
{"id": "fail-too-coarse", "reply": "It was $4.7 million.", "expect": [4812345.67]},
{"id": "pass-tolerance", "reply": "It was $4.7 million.", "expect": [4812345.67], "tolerance": 0.02},
{"id": "fail-round-hundred", "reply": "There are about 900 items.", "expect": [940]},
{"id": "fail-round-thousand", "reply": "There were 1,000 orders.", "expect": [1234]},
{"id": "pass-percent-share", "reply": "Margin was 12.5%.", "expect": [0.125]},
{"id": "pass-percent-points", "reply": "Margin was 12.5%.", "expect": [12.5]},
{"id": "fail-percent", "reply": "Margin was 12.4%.", "expect": [0.125]},
{"id": "pass-magnitude", "reply": "Sales fell by 1,234 on last year.", "expect": [-1234]},
{"id": "fail-sign", "reply": "Change: -1,234.", "expect": [1234]},
{"id": "pass-parentheses", "reply": "Change: (1,234)", "expect": [-1234]},
{"id": "fail-inside-a-word", "reply": "Item Q3 sold 5 units.", "expect": [3]},
{"id": "pass-after-a-figure", "reply": "Values: 4,812,345.67, 1,234", "expect": [1234]},
{"id": "pass-table-cell", "reply": "| Sep 2026 | 4,812,345.67 |", "expect": [4812345.67]},
{"id": "pass-text-case", "reply": "The top customer was **ACME Corp.**", "expect": ["Acme Corp"]},
{"id": "fail-text-longer-word", "reply": "The top customer was Acme Corporation.", "expect": ["Acme Corp"]},
{"id": "fail-code-longer", "reply": "Item ZX40BX led.", "expect": ["ZX40B"]},
{"id": "pass-month", "reply": "The lowest month was February 2024.", "expect": ["2024-02-01T00:00:00"]},
{"id": "pass-month-short", "reply": "The lowest month was Feb 2024.", "expect": ["2024-02-01T00:00:00"]},
{"id": "fail-month", "reply": "The lowest month was March 2024.", "expect": ["2024-02-01T00:00:00"]},
{"id": "pass-date-us", "reply": "The first order was on 10/15/2026.", "expect": ["2026-10-15"]},
{"id": "pass-date-iso", "reply": "The first order was on 2026-10-15.", "expect": ["2026-10-15"]},
{"id": "fail-date", "reply": "The first order was on October 16, 2026.", "expect": ["2026-10-15"]},
{"id": "pass-text-number", "reply": "It came to $1,234.", "expect": ["$1,234"]},
{"id": "pass-moved", "reply": "It was 120.", "truth_before": [{"[V]": 100}], "truth_after": [{"[V]": 120}]},
{"id": "fail-one-row-of-two", "reply": "Acme had 5 orders.", "truth_before": [{"C[Name]": "Acme", "[N]": 5}, {"C[Name]": "Bolt", "[N]": 3}], "truth_after": [{"C[Name]": "Acme", "[N]": 5}, {"C[Name]": "Bolt", "[N]": 3}]},
{"id": "review-no-rows", "reply": "It was 120.", "truth_before": [], "truth_after": []},
{"id": "review-nothing", "reply": "I cannot forecast."},
{"id": "error-ask", "reply": "", "expect": [1], "ask_error": "TimeoutError: no reply"}
]}
EOF

uv run --quiet "$script" regrade "$tmproot/results.json" > "$tmproot/out.txt" 2>&1
check "regrade with failures: exit" "$?" 1
cases=$(grep -c '"id"' "$tmproot/results.json")
lines=$(grep -c '^\[[a-z]*\] ' "$tmproot/out.txt")
check "regrade prints one verdict line per case" "$lines" "$cases"
while read -r verdict id; do
    check "$id" "$verdict" "${id%%-*}"
done < <(sed -n 's/^\[\([a-z]*\)\] \([^ ]*\).*/\1 \2/p' "$tmproot/out.txt")
grep -q 'the truth moved during the question' "$tmproot/out.txt"
check "a moved truth is marked" "$?" 0

echo
echo "$pass passed, $fail failed"
[ "$fail" = 0 ]
