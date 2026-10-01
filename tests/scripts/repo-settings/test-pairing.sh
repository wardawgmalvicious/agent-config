#!/usr/bin/env bash
# Exercise repo-settings.ps1's pairing of -Repo with a snapshot, offline.
#
# Every personal repo's snapshot is a file in this repo, so -Repo naming one
# repo while -Path holds another's is easy to type, and the script once obeyed
# it: a crossed -Export overwrote the wrong file, and a crossed -Apply patched
# the wrong repo. Each case plants a pair and checks what ran.
#
# gh is gh-stub.ps1, copied into a temp bin/ put first on PATH. It answers
# from canned files and logs every call, so a refusal is shown to come before
# the first gh call, and no case reaches GitHub; case 0 stops the run unless
# the stub is what answers. The fixtures' owner, fixture_owner, could own
# nothing there anyway: a GitHub login takes an underscore only inside a
# managed enterprise. Nothing is written inside any repo.
#
#     bash tests/scripts/repo-settings/test-pairing.sh [script.ps1]
#
# The argument runs the cases against another copy of the script, which is
# how the version before the pairing guard was shown to fail them. A run
# takes about two minutes, nearly all of it one pwsh start per case.
#
set -u

here=$(cd "$(dirname "$0")" && pwd)
repo=$(cd "$here/../../.." && pwd)
script=${1:-$repo/scripts/repo-settings.ps1}
tmproot=$(mktemp -d)
trap 'rm -rf "$tmproot"' EXIT
bin="$tmproot/bin"
out="$tmproot/out.txt"
mkdir -p "$bin/api"
cp "$here/gh-stub.ps1" "$bin/gh.ps1"

pass=0
fail=0

# A native Windows program resolves a /tmp path to C:\tmp, not %TEMP%, so
# hand it a Windows path wherever cygpath exists to make one.
native() {
    if command -v cygpath > /dev/null; then cygpath -w "$1"; else echo "$1"; fi
}

# run [argument...] -- sets $status; the output is in $out, the calls in calls.log
run() {
    rm -f "$bin/calls.log"
    PATH="$bin:$PATH" pwsh -NoProfile -NonInteractive -File "$(native "$script")" "$@" \
        > "$out" 2>&1
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
# pwsh shows a thrown refusal in its error view, coloured even into a file
# and wrapped to the console's width under a "|" gutter, so a phrase can
# break across lines. Text is matched with the colour and gutter stripped,
# every line joined, and each run of spaces squeezed to one.
flat() {
    sed -E 's/\x1b\[[0-9;]*m//g; s/^ *\| ?//' "$out" | tr '\r\n' '  ' | tr -s ' '
}
expect_exit() {
    if [ "$status" = "$2" ]; then report "$1" ok; else report "$1" "expected exit $2, got $status"; fi
}
expect_line() {
    if flat | grep -qF -- "$2"; then report "$1" ok; else report "$1" "no line containing '$2'"; fi
}
expect_no_line() {
    if flat | grep -qF -- "$2"; then report "$1" "found '$2'"; else report "$1" ok; fi
}
# expect_calls <label> <the stub's calls, one per line; empty for none>
expect_calls() {
    local got
    got=$(tr -d '\r' 2> /dev/null < "$bin/calls.log")
    if [ "$got" = "$2" ]; then report "$1" ok; else report "$1" "calls were: ${got:-none}"; fi
}
expect_same() {
    if cmp -s "$2" "$3"; then report "$1" ok; else report "$1" "$2 changed"; fi
}
expect_no_file() {
    if [ -e "$2" ]; then report "$1" "written: $2"; else report "$1" ok; fi
}
expect_value() {
    if [ "$2" = "$3" ]; then report "$1" ok; else report "$1" "expected '$3', got '$2'"; fi
}

# snapshot <owner/name> <description> <file> -- a snapshot of that repo, in
# the shape of this repo's own
snapshot() {
    jq -b --arg r "$1" --arg d "$2" '._repo = $r | .repository.description = $d' \
        "$repo/.github/repo-settings.json" > "$3"
}

# serve <owner/name> <snapshot> -- the stub answers for that repo with the
# snapshot's values, shaped as GitHub's endpoints return them
serve() {
    local dir="$bin/api/repos/$1" i n
    rm -rf "$dir"
    mkdir -p "$dir/actions/permissions" "$dir/rulesets"
    jq -b --arg r "$1" '.repository + {full_name: $r, topics,
        security_and_analysis: (.security_and_analysis | map_values({status: .}))}' \
        "$2" > "$dir.json"
    jq -b '{enabled: .dependabot.security_updates, paused: false}' "$2" \
        > "$dir/automated-security-fixes.json"
    if [ "$(jq -b '.dependabot.alerts' "$2")" = true ]; then
        : > "$dir/vulnerability-alerts.204"
    fi
    jq -b '{enabled: .private_vulnerability_reporting}' "$2" \
        > "$dir/private-vulnerability-reporting.json"
    jq -b '.actions.permissions' "$2" > "$dir/actions/permissions.json"
    jq -b '.actions.workflow_permissions' "$2" > "$dir/actions/permissions/workflow.json"
    jq -b '[.rulesets | keys[] | {id: (. + 1)}]' "$2" > "$dir/rulesets.json"
    n=$(jq -b '.rulesets | length' "$2")
    for ((i = 0; i < n; i++)); do
        jq -b --argjson i "$i" '.rulesets[$i] + {id: ($i + 1)}' "$2" \
            > "$dir/rulesets/$((i + 1)).json"
    done
}

login() { printf '%s\n' "$1" > "$bin/login.txt"; }

# 0. The stub, not gh, must answer: a crossed -Apply against the script before
#    the guard would otherwise be a real write. Stop unless it does.
login stub_probe
rm -f "$bin/calls.log"
PATH="$bin:$PATH" pwsh -NoProfile -NonInteractive -Command 'gh api user -q .login' \
    > "$out" 2>&1
if [ "$(tr -d '\r' < "$out")" != stub_probe ] || [ ! -s "$bin/calls.log" ]; then
    echo "FAIL  gh is not the stub here; stopping before any case can reach GitHub"
    sed 's/^/        /' "$out"
    exit 1
fi
echo "ok    gh is the stub"

login fixture_owner
snapshot fixture_owner/alpha alpha "$tmproot/alpha.saved"
snapshot fixture_owner/beta beta "$tmproot/beta.json"
serve fixture_owner/alpha "$tmproot/alpha.saved"

# 1. A crossed pair -- -Repo names beta, -Path holds alpha's snapshot -- is
#    refused in every mode, before the first gh call, and alpha's file stands.
for mode in -Check -Apply -Export; do
    cp "$tmproot/alpha.saved" "$tmproot/alpha.json"
    serve fixture_owner/beta "$tmproot/beta.json"
    run "$mode" -Repo fixture_owner/beta -Path "$(native "$tmproot/alpha.json")"
    expect_exit "a crossed $mode is refused" 1
    expect_line "and names whose snapshot it is" \
        "is the snapshot of fixture_owner/alpha, not fixture_owner/beta"
    expect_calls "and calls no gh" ""
    expect_same "and leaves the file alone" "$tmproot/alpha.json" "$tmproot/alpha.saved"
done
# -Path alone leaves -Repo on this repo, which crosses the same way.
cp "$tmproot/alpha.saved" "$tmproot/alpha.json"
run -Check -Path "$(native "$tmproot/alpha.json")"
expect_exit "-Path alone, holding another repo's snapshot, is refused" 1
expect_line "and names whose snapshot it is" "is the snapshot of fixture_owner/alpha, not "
expect_calls "and calls no gh" ""

# 2. A file that names no repo pairs with nothing: refused in every mode, and
#    never overwritten. Its description is not alpha's, so an overwrite with
#    alpha's live settings would show; alpha is served afresh each time, since
#    an -Apply that got through would have written the file's into it.
jq -b 'del(._repo) | .repository.description = "unnamed"' "$tmproot/alpha.saved" \
    > "$tmproot/unnamed.saved"
for mode in -Check -Apply -Export; do
    cp "$tmproot/unnamed.saved" "$tmproot/unnamed.json"
    serve fixture_owner/alpha "$tmproot/alpha.saved"
    run "$mode" -Repo fixture_owner/alpha -Path "$(native "$tmproot/unnamed.json")"
    expect_exit "a $mode on a file naming no repo is refused" 1
    expect_line "and says why" "it names no repo in a _repo key"
    expect_calls "and calls no gh" ""
    expect_same "and leaves the file alone" "$tmproot/unnamed.json" "$tmproot/unnamed.saved"
done

# 3. Nor is a file that is not a snapshot at all overwritten.
printf 'notes, not settings\n' > "$tmproot/notes.txt"
cp "$tmproot/notes.txt" "$tmproot/notes.saved"
run -Export -Repo fixture_owner/alpha -Path "$(native "$tmproot/notes.txt")"
expect_exit "-Export over a file that is not JSON is refused" 1
expect_line "and says why" "it is not JSON"
expect_same "and leaves the file alone" "$tmproot/notes.txt" "$tmproot/notes.saved"

# 4. A first -Export to a fresh path is allowed, makes its directory and names
#    its repo; -Check then pairs with it and passes. -Export may overwrite its
#    own snapshot, and a name pairs case-insensitively, as GitHub's do.
serve fixture_owner/beta "$tmproot/beta.json"
fresh="$tmproot/fresh/beta.json"
run -Export -Repo fixture_owner/beta -Path "$(native "$fresh")"
expect_exit "a first -Export to a fresh path succeeds" 0
expect_value "the snapshot names its repo" "$(jq -b -r '._repo' "$fresh" 2> /dev/null)" \
    fixture_owner/beta
expect_value "and holds that repo's settings" \
    "$(jq -b -r '.repository.description' "$fresh" 2> /dev/null)" beta
run -Check -Repo fixture_owner/beta -Path "$(native "$fresh")"
expect_exit "-Check against it passes" 0
expect_line "every setting matches" "setting(s) already match"
run -Export -Repo fixture_owner/beta -Path "$(native "$fresh")"
expect_exit "-Export over its own snapshot succeeds" 0
run -Check -Repo FIXTURE_OWNER/Beta -Path "$(native "$fresh")"
expect_exit "a name pairs case-insensitively" 0

# 5. -Path defaults from -Repo: another repo's file is under
#    .github/repo-settings/. Read only here, so nothing is written in the repo.
run -Check -Repo fixture_owner/gamma
expect_exit "-Check with no snapshot fails" 1
expect_line "-Path defaults from -Repo" '.github\repo-settings\gamma.json'
expect_calls "before any gh call" ""
run -Check -Repo gamma
expect_exit "-Repo without an owner is refused" 1
expect_line "and says what it takes" "-Repo takes owner/name"

# 6. Only the owner's repos: -Export and -Apply refuse under another account,
#    after asking who gh is and before reading or writing anything else.
login someone_else
mkdir -p "$tmproot/other"
run -Export -Repo fixture_owner/beta -Path "$(native "$tmproot/other/beta.json")"
expect_exit "-Export under another account is refused" 1
expect_line "and says why" "Refusing to snapshot a repo it does not own"
expect_calls "after asking only who gh is" "GET user"
expect_no_file "and writes nothing" "$tmproot/other/beta.json"
run -Apply -Repo fixture_owner/beta -Path "$(native "$fresh")"
expect_exit "-Apply under another account is refused" 1
expect_calls "after asking only who gh is" "GET user"
login fixture_owner

# 7. A matching pair still applies, to -Repo alone, and its re-check passes.
jq -b '.repository.description = "beta, edited in the UI"' "$tmproot/beta.json" \
    > "$tmproot/beta-ui.json"
serve fixture_owner/beta "$tmproot/beta-ui.json"
run -Check -Repo fixture_owner/beta -Path "$(native "$fresh")"
expect_exit "drift fails -Check" 1
expect_line "and is named" "[drift] repository.description"
run -Apply -Repo fixture_owner/beta -Path "$(native "$fresh")"
expect_exit "-Apply on a matching pair succeeds" 0
expect_line "and its re-check passes" "live settings match the file"
expect_value "it wrote to -Repo alone" \
    "$(tr -d '\r' 2> /dev/null < "$bin/calls.log" | grep -v -e '^GET ' -e '^POST graphql$')" \
    "PATCH repos/fixture_owner/beta"

# 8. This repo's bare run is unchanged: -Repo from origin, -Path its own file,
#    and every setting matching when GitHub holds what the file says.
origin=$(git -C "$repo" remote get-url origin | sed -E 's#^.*github\.com[:/]##; s#\.git$##')
serve "$origin" "$repo/.github/repo-settings.json"
run
expect_exit "a bare run succeeds" 0
expect_line "it checks this repo" "Repo $origin -- mode Check"
expect_line "against its own file" '.github\repo-settings.json'
expect_line "every setting matches" "setting(s) already match"

echo
echo "$pass passed, $fail failed"
[ "$fail" = 0 ]
