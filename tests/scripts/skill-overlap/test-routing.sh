#!/usr/bin/env bash
# Exercise scripts/skill-overlap.py's routing gate against throwaway payloads.
#
# Routing is the one signal that is a bug by default, so it is the one that can
# gate a commit -- and a gate is only worth having if its NEGATIVE case is
# proved. The repo passing says nothing: it passes today because every
# description routes to a skill that exists, which is exactly what a gate that
# never fires would also produce.
#
# Each case builds a minimal payload in a temp directory and runs the script
# against it. REPO is derived from the script's own location, so a copy of
# scripts/ beside a skills/ tree is a complete fixture -- no session, no
# network, and nothing written inside this repo.
#
#     bash tests/scripts/skill-overlap/test-routing.sh
#
set -u

here=$(cd "$(dirname "$0")" && pwd)
repo=$(cd "$here/../../.." && pwd)
tmproot=$(mktemp -d)
trap 'rm -rf "$tmproot"' EXIT

pass=0
fail=0

# make_payload <dir> -- a fixture repo holding only what the script reads.
make_payload() {
    mkdir -p "$1/scripts" "$1/skills/test" "$1/.claude/skills" "$1/claude/rules"
    cp "$repo/scripts/_skill_inventory.py" "$repo/scripts/skill-overlap.py" "$1/scripts/"
}

# make_skill <dir> <name> <description> [body]
make_skill() {
    mkdir -p "$1/skills/test/$2"
    {
        echo "---"
        echo "name: $2"
        echo "description: $3"
        echo "---"
        echo
        echo "${4:-Body.}"
    } > "$1/skills/test/$2/SKILL.md"
}

# check <label> <expected-exit> <payload-dir>
check() {
    local label=$1 expected=$2 dir=$3 actual
    PYTHONIOENCODING=utf-8 uv run --with pyyaml python "$dir/scripts/skill-overlap.py" \
        routing > "$dir/out.txt" 2>&1
    actual=$?
    if [ "$actual" = "$expected" ]; then
        echo "ok    $label (exit $actual)"
        pass=$((pass + 1))
    else
        echo "FAIL  $label: expected exit $expected, got $actual"
        sed 's/^/        /' "$dir/out.txt"
        fail=$((fail + 1))
    fi
}

# 1. A description routing to a skill that EXISTS passes.
d="$tmproot/resolves"
make_payload "$d"
make_skill "$d" fabric-alpha "Alpha."
make_skill "$d" fabric-beta "Hand off to \`fabric-alpha\` when the model is ready."
check "description routes to an installed skill" 0 "$d"

# 2. A description routing to a skill that does NOT exist fails. This is the
#    case the gate exists for, and the case the live repo cannot demonstrate.
d="$tmproot/dangling"
make_payload "$d"
make_skill "$d" fabric-alpha "Alpha."
make_skill "$d" fabric-beta "Hand off to \`fabric-missing-thing\` for the rest."
check "description routes to a missing skill" 1 "$d"

# 3. The same missing name in PROSE is reported and does not fail. A body may
#    discuss a skill that was deliberately not installed; a description may not.
d="$tmproot/body-only"
make_payload "$d"
make_skill "$d" fabric-alpha "Alpha." "See \`fabric-missing-thing\` for background."
check "prose mentions a missing skill" 0 "$d"

# 4. A recorded override in a description does not fail, even though the name
#    resolves to nothing. powerbi-report-planning was left unvendored on
#    purpose in 1fa3061.
d="$tmproot/accepted"
make_payload "$d"
make_skill "$d" fabric-alpha "Plan it with \`powerbi-report-planning\` first."
check "description names an accepted override" 0 "$d"

# 5. An allowlisted non-skill name does not fail. The rule arm is used here
#    because a rule file is the cheapest derived source to build.
d="$tmproot/allowlisted"
make_payload "$d"
printf -- '---\npaths:\n  - "**/*.md"\n---\nRule.\n' > "$d/claude/rules/fabric-made-up-rule.md"
make_skill "$d" fabric-alpha "Conventions live in \`fabric-made-up-rule\`."
check "description names a derived allowlist entry" 0 "$d"

echo
echo "$pass passed, $fail failed"
[ "$fail" = 0 ]
