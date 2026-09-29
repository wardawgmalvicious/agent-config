#!/usr/bin/env bash
# Exercise copy-copilot.ps1's port selection against throwaway repos.
#
# A live run proves little: a selection that never held a port back looks,
# from outside, like a repo every port happens to match. So each case plants
# what the selection must see through -- a vendored skill's own .py, a port
# the manifest owns that no longer matches, a client file named like a port
# -- and checks what ships and what does not. Everything is written under a
# temp directory. ~/.copilot is never a target: it keeps every port without
# asking the selection, which review covers.
#
#     bash tests/scripts/copy-copilot/test-port-selection.sh
#
set -u

here=$(cd "$(dirname "$0")" && pwd)
repo=$(cd "$here/../../.." && pwd)
tmproot=$(mktemp -d)
trap 'rm -rf "$tmproot"' EXIT
out="$tmproot/out.txt"

pass=0
fail=0

# A native Windows program resolves a /tmp path to C:\tmp, not %TEMP%, so
# hand it a Windows path wherever cygpath exists to make one.
native() {
    if command -v cygpath > /dev/null; then cygpath -w "$1"; else echo "$1"; fi
}

ports=()
for f in "$repo"/copilot/instructions/*.instructions.md; do
    name=${f##*/}
    ports+=("${name%.instructions.md}")
done

engine() {
    PYTHONIOENCODING=utf-8 uv run --quiet --no-project --with pyyaml --with wcmatch \
        python "$(native "$repo/scripts/payload-coverage.py")" --ports "$(native "$1")" \
        > "$out" 2>&1
}

# copy <CopilotDir> [switch...] -- sets $status to the script's exit code
copy() {
    local target=$1
    shift
    pwsh -NoProfile -NonInteractive -File "$(native "$repo/scripts/copy-copilot.ps1")" \
        -CopilotDir "$(native "$target")" -Payload instructions "$@" > "$out" 2>&1
    status=$?
}

report() {
    if [ "$2" = ok ]; then
        echo "ok    $1"
        pass=$((pass + 1))
    else
        echo "FAIL  $1: $2"
        sed 's/^/        /' "$out"
        fail=$((fail + 1))
    fi
}

expect_exit() {
    if [ "$status" = "$2" ]; then report "$1" ok; else report "$1" "expected exit $2, got $status"; fi
}
expect_line() {
    if grep -qF -- "$2" "$out"; then report "$1" ok; else report "$1" "no line containing '$2'"; fi
}
expect_file() {
    if [ -f "$2" ]; then report "$1" ok; else report "$1" "missing: $2"; fi
}
expect_no_file() {
    if [ -e "$2" ]; then report "$1" "still there: $2"; else report "$1" ok; fi
}
expect_content() {
    if [ "$(cat "$2" 2> /dev/null)" = "$3" ]; then report "$1" ok; else report "$1" "$2 changed"; fi
}
# expect_ports <label> <dir> <port>... -- exactly these ports' files are there
expect_ports() {
    local label=$1 dir=$2 p want got="" bad=""
    shift 2
    want=" $* "
    for p in "${ports[@]}"; do
        local listed=0 present=0
        [[ $want == *" $p "* ]] && listed=1
        [ -f "$dir/$p.instructions.md" ] && present=1 && got="$got $p"
        [ "$listed" = "$present" ] || bad=1
    done
    if [ -z "$bad" ]; then report "$label" ok; else report "$label" "wanted:$want; found:$got"; fi
}

# A C# repo that has vendored before: the manifest owns C# and M, a client
# wrote team.instructions.md and a file named like the Bicep port, and a
# vendored skill carries a .py.
fix="$tmproot/scratch"
inst="$fix/.github/instructions"
mkdir -p "$fix/.github/skills/some-skill" "$inst"
git init -q "$fix"
echo 'class Program {}' > "$fix/Program.cs"
echo 'print()' > "$fix/.github/skills/some-skill/helper.py"
echo old > "$inst/coding-csharp.instructions.md"
echo old > "$inst/coding-m.instructions.md"
echo "client's own" > "$inst/coding-bicep.instructions.md"
echo "client's own" > "$inst/team.instructions.md"
printf '{\n  "instructions": [\n    "coding-csharp",\n    "coding-m"\n  ]\n}\n' \
    > "$inst/.managed-instructions.json"
git -C "$fix" add -A

# 1. The engine: Program.cs selects the C# port and no other.
engine "$fix/.github"
expect_line "Program.cs selects the C# port" "ship  coding-csharp"
ships=$(grep -c '^  ship  ' "$out")
if [ "$ships" = 1 ]; then report "and no other port" ok; else report "and no other port" "$ships ship"; fi
expect_line "a vendored skill's own .py selects nothing" "hold  coding-python"
expect_line "the audit names the carried port matching nothing" \
    "audit: carried, matching nothing: coding-m"

# 2. -WhatIf shows the selection and writes nothing.
copy "$fix/.github" -WhatIf
expect_exit "-WhatIf succeeds" 0
expect_line "-WhatIf names the held port" "Held    coding-m.instructions.md"
expect_file "-WhatIf prunes nothing" "$inst/coding-m.instructions.md"
expect_content "-WhatIf copies nothing" "$inst/coding-csharp.instructions.md" old

# 3. A plain run: the manifest drops the port that no longer matches, and
#    nothing the client wrote is touched, even under a held port's name.
copy "$fix/.github"
expect_exit "a plain run succeeds" 0
expect_line "the held, owned port is pruned" "Pruned  coding-m.instructions.md (held back)"
expect_ports "only the C# port and the client's Bicep-named file remain" "$inst" \
    coding-csharp coding-bicep
expect_content "the client's Bicep-named file is untouched" \
    "$inst/coding-bicep.instructions.md" "client's own"
expect_file "the client's own instruction is untouched" "$inst/team.instructions.md"
if grep -q '"coding-m"' "$inst/.managed-instructions.json"; then
    report "the manifest no longer owns M" "it still lists coding-m"
else
    report "the manifest no longer owns M" ok
fi

# 4. -AllInstructions ships every port, and still will not clobber the
#    client's file, so the collision fails the run as it always has.
copy "$fix/.github" -AllInstructions
expect_exit "-AllInstructions reports the collision" 1
expect_line "-AllInstructions says why" "every port ships (-AllInstructions)"
# Every port's file is there, Bicep's being still the client's.
expect_ports "-AllInstructions ships every other port" "$inst" "${ports[@]}"
expect_content "the collision leaves the client's file alone" \
    "$inst/coding-bicep.instructions.md" "client's own"

# 5. The next plain run prunes back to what matches.
copy "$fix/.github"
expect_exit "the next plain run succeeds" 0
expect_ports "it prunes back to the C# port" "$inst" coding-csharp coding-bicep
expect_content "and still leaves the client's file alone" \
    "$inst/coding-bicep.instructions.md" "client's own"

# 6. Nothing to match against: every port ships, and the run says why.
empty="$tmproot/empty"
git init -q "$empty"
engine "$empty/.github"
expect_line "a repo with no tracked files selects every port" \
    "no tracked files outside the target's own payload; every port ships"
if git -C "$tmproot" rev-parse > /dev/null 2>&1; then
    echo "skip  a target outside git: $tmproot is inside a repository"
else
    mkdir -p "$tmproot/loose"
    copy "$tmproot/loose/.github"
    expect_exit "a target outside git succeeds" 0
    expect_line "and says why every port ships" "every port ships: not inside a git repository"
    expect_ports "and ships every port" "$tmproot/loose/.github/instructions" "${ports[@]}"
fi

# 7. With uv off PATH the run stops before writing anything, never falling
#    back to every port. Git's /usr/bin and System32 are enough for pwsh.
mkdir -p "$tmproot/nouv"
git init -q "$tmproot/nouv"
PATH="/usr/bin:/c/Windows/System32" "$(command -v pwsh)" -NoProfile -NonInteractive \
    -File "$(native "$repo/scripts/copy-copilot.ps1")" \
    -CopilotDir "$(native "$tmproot/nouv/.github")" -Payload instructions > "$out" 2>&1
status=$?
if [ "$status" != 0 ]; then report "no uv fails the run" ok; else report "no uv fails the run" "exit 0"; fi
expect_line "and says how to proceed" "pass -AllInstructions"
expect_no_file "and writes nothing" "$tmproot/nouv/.github"

echo
echo "$pass passed, $fail failed"
[ "$fail" = 0 ]
