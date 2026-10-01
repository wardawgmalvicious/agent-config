#!/usr/bin/env bash
# Exercise skills/workflow/commit/scripts/stage-part.py against throwaway repos.
#
# Each case builds a fresh repo in a temp directory, stages part of one
# file's changes through the index, and checks what the index then holds and
# that the working tree never moved: no network, and nothing written inside
# this repo. The cases are the measurements in
# skills/workflow/commit/references/index-staging.md, so a failure here means
# a claim there has stopped holding. Three cases measure git rather than the
# script, because the reference argues from them: where `git diff` splits two
# hunks, where `git apply --unidiff-zero` puts a pure addition, and the blob
# built by hand that the reference falls back on.
#
# The script runs without PYTHONIOENCODING on purpose: stdout is cp1252 on
# Windows, and an em dash in a TAKE line has to print anyway.
#
#     bash tests/scripts/stage-part/test-stage-part.sh
#
set -u
unset PYTHONIOENCODING PYTHONUTF8

here=$(cd "$(dirname "$0")" && pwd)
repo=$(cd "$here/../../.." && pwd)
script="$repo/skills/workflow/commit/scripts/stage-part.py"
tmproot=$(mktemp -d)
trap 'rm -rf "$tmproot"' EXIT
: > "$tmproot/out.txt"

pass=0
fail=0

# A native Windows python resolves a /tmp path to C:\tmp, not %TEMP%, so
# hand it a Windows path wherever cygpath exists to make one.
native() {
    if command -v cygpath > /dev/null; then cygpath -w "$1"; else echo "$1"; fi
}

# lines <n>: "line 01" to "line <n>", one to a line
lines() {
    local i
    for ((i = 1; i <= $1; i++)); do printf 'line %02d\n' "$i"; done
}

# fixture <name> [<n>]: a fresh repo in $r holding f.txt, <n> lines (20), committed
fixture() {
    r="$tmproot/$1"
    git init -q -b main "$r"
    git -C "$r" config user.name test
    git -C "$r" config user.email test@example.invalid
    git -C "$r" config core.autocrlf false
    lines "${2:-20}" > "$r/f.txt"
    git -C "$r" add f.txt
    git -C "$r" commit -qm base
}

# mark <file> <line> <word>: append " <word>" to one line of an LF file
mark() {
    sed -i "${2}s/\$/ $3/" "$1"
}

# Git Bash's sed reads a file in text mode, so an in-place edit strips every
# CR and a `\r$` pattern matches nothing, exit 0 (GNU sed 4.9, 2026-09-30).
# -b reads it as bytes; a sed with no -b has no text mode to switch off.
SED_BIN=()
if sed -b q /dev/null 2> /dev/null; then SED_BIN=(-b); fi

# crs <file>: how many CRs it holds
crs() {
    echo $(($(tr -cd '\r' < "$1" | wc -c)))
}

# stage <path> <mode> <regex>: run the script on $r; output in out.txt, exit in $rc
stage() {
    uv run --quiet --no-project python "$(native "$script")" "$(native "$r")" "$@" \
        > "$tmproot/out.txt" 2>&1
    rc=$?
}

# taken: "<blocks taken> of <blocks>", from the last run's audit lines
taken() {
    echo "$(grep -c '^  TAKE  ' "$tmproot/out.txt") of $(grep -cE '^  (TAKE|skip)  ' "$tmproot/out.txt")"
}

# cached <path> / unstaged <path>: the changed lines, without diff headers
cached() {
    git -C "$r" diff --cached -U0 -- "$1" | grep -E '^[-+]([^-+]|$)'
}
unstaged() {
    git -C "$r" diff -U0 -- "$1" | grep -E '^[-+]([^-+]|$)'
}

# hunks <path>: how many hunks `git diff` cuts the unstaged change into
hunks() {
    git -C "$r" diff -- "$1" | grep -c '^@@'
}

# raw <path>: a hash of the working-tree bytes, no filter applied
raw() {
    git -C "$r" hash-object --no-filters -- "$1"
}

is() {
    [[ "$1" == "$2" ]] && return
    printf '        expected %q\n        got      %q\n' "$2" "$1"
    return 1
}

matches() {
    [[ "$1" =~ $2 ]] && return
    printf '        no match for /%s/ in %q\n' "$2" "$1"
    return 1
}

# check <label> <predicate> <args...>: one ok or FAIL line
check() {
    local label=$1
    shift
    if "$@"; then
        echo "ok    $label"
        pass=$((pass + 1))
    else
        echo "FAIL  $label"
        sed 's/^/        | /' "$tmproot/out.txt"
        fail=$((fail + 1))
    fi
}

echo "1. Two changes one unchanged line apart, LF"
fixture lf
mark "$r/f.txt" 5 alpha
mark "$r/f.txt" 7 beta
before=$(raw f.txt)
check "git diff holds both in one hunk" is "$(hunks f.txt)" 1
stage f.txt include alpha
check "include exits 0" is "$rc" 0
check "two blocks, one taken" is "$(taken)" "1 of 2"
check "the index takes alpha alone" is "$(cached f.txt)" $'-line 05\n+line 05 alpha'
check "the working tree never moved" is "$(raw f.txt)" "$before"
git -C "$r" commit -qm alpha
stage f.txt include beta
check "the next commit's run takes beta" is "$(cached f.txt)" $'-line 07\n+line 07 beta'
git -C "$r" commit -qm beta
check "status is empty after the last commit" is "$(git -C "$r" status --short)" ""

echo "2. The same edit in a .ps1 checked out CRLF, under this repo's .gitattributes"
fixture crlf
cp "$repo/.gitattributes" "$r/.gitattributes"
lines 20 | sed 's/$/\r/' > "$r/x.ps1"
git -C "$r" add .gitattributes x.ps1
git -C "$r" commit -qm ps1
sed "${SED_BIN[@]}" -i -e '5s/\r$/ alpha\r/' -e '7s/\r$/ beta\r/' "$r/x.ps1"
before=$(raw x.ps1)
check "the fixture reads i/lf w/crlf" matches "$(git -C "$r" ls-files --eol -- x.ps1)" '^i/lf +w/crlf '
check "the working tree holds 20 CRs" is "$(crs "$r/x.ps1")" 20
stage x.ps1 include alpha
check "include exits 0" is "$rc" 0
check "two blocks, one taken" is "$(taken)" "1 of 2"
check "numstat 1 1" is "$(git -C "$r" diff --cached --numstat -- x.ps1)" $'1\t1\tx.ps1'
check "the index stays LF" matches "$(git -C "$r" ls-files --eol -- x.ps1)" '^i/lf '
check "the working tree never moved" is "$(raw x.ps1)" "$before"

echo "3. Exclude, LF"
fixture exclude
mark "$r/f.txt" 5 alpha
mark "$r/f.txt" 7 beta
stage f.txt exclude alpha
check "exclude exits 0" is "$rc" 0
check "the index takes beta alone" is "$(cached f.txt)" $'-line 07\n+line 07 beta'

echo "4. Where git diff splits two hunks, at its default three lines of context"
for gap in 6 7; do
    fixture "gap$gap" 30
    mark "$r/f.txt" 5 alpha
    mark "$r/f.txt" $((6 + gap)) beta
    check "$gap unchanged lines apart: git diff cuts $((gap - 5)) hunk(s)" is "$(hunks f.txt)" $((gap - 5))
    stage f.txt include alpha
    check "$gap unchanged lines apart: the script takes alpha alone" is "$(cached f.txt)" $'-line 05\n+line 05 alpha'
done

echo "5. A second run builds on the first"
fixture twice
mark "$r/f.txt" 5 alpha
mark "$r/f.txt" 7 beta
stage f.txt include alpha
stage f.txt include beta
check "the second run sees one block" is "$(taken)" "1 of 1"
check "the index holds both" is "$(git -C "$r" diff --cached --numstat -- f.txt)" $'2\t2\tf.txt'
git -C "$r" restore --staged -- f.txt
check "restore --staged starts the path over" is "$(git -C "$r" diff --cached --name-only)" ""

echo "6. A peer's uncommitted edit one unchanged line from yours"
fixture peer
mark "$r/f.txt" 5 alpha
mark "$r/f.txt" 7 peer
stage f.txt include alpha
check "yours is staged alone" is "$(cached f.txt)" $'-line 05\n+line 05 alpha'
check "theirs stays on disk, unstaged" is "$(unstaged f.txt)" $'-line 07\n+line 07 peer'

echo "7. A peer's uncommitted edit on the line next to yours"
fixture adjacent
mark "$r/f.txt" 5 alpha
mark "$r/f.txt" 6 peer
stage f.txt include alpha
check "one block of both, taken whole" is "$(taken)" "1 of 1"
check "its TAKE line reads -2 +2" is "$(grep -c '^  TAKE  -2 +2 ' "$tmproot/out.txt")" 1
check "theirs is staged with yours" is "$(cached f.txt)" $'-line 05\n-line 06\n+line 05 alpha\n+line 06 peer'

echo "8. By hand: a blob for two changes that touch (git, not the script)"
fixture byhand
mark "$r/f.txt" 5 alpha
mark "$r/f.txt" 6 beta
before=$(raw f.txt)
git -C "$r" cat-file blob :f.txt > "$tmproot/next"
mark "$tmproot/next" 5 alpha
sha=$(git -C "$r" hash-object -w --path=f.txt "$(native "$tmproot/next")")
git -C "$r" update-index --cacheinfo "100644,$sha,f.txt"
check "the index takes alpha alone" is "$(cached f.txt)" $'-line 05\n+line 05 alpha'
check "the working tree never moved" is "$(raw f.txt)" "$before"
fixture byhand-crlf
cp "$repo/.gitattributes" "$r/.gitattributes"
lines 20 | sed 's/$/\r/' > "$r/x.ps1"
git -C "$r" add .gitattributes x.ps1
git -C "$r" commit -qm ps1
sed "${SED_BIN[@]}" -i -e '5s/\r$/ alpha\r/' -e '6s/\r$/ beta\r/' "$r/x.ps1"
git -C "$r" cat-file blob :x.ps1 | sed -e 's/$/\r/' -e '5s/\r$/ alpha\r/' > "$tmproot/next"
check "the copy is written CRLF" is "$(crs "$tmproot/next")" 20
sha=$(git -C "$r" hash-object -w --path=x.ps1 "$(native "$tmproot/next")")
git -C "$r" update-index --cacheinfo "100644,$sha,x.ps1"
check "and stages LF through --path" matches "$(git -C "$r" ls-files --eol -- x.ps1)" '^i/lf '
check "and takes alpha alone" is "$(git -C "$r" diff --cached --numstat -- x.ps1)" $'1\t1\tx.ps1'
fixture byhand-noattr
git -C "$r" cat-file blob :f.txt | sed -e 's/$/\r/' -e '5s/\r$/ alpha\r/' > "$tmproot/next"
sha=$(git -C "$r" hash-object -w --path=f.txt "$(native "$tmproot/next")")
git -C "$r" update-index --cacheinfo "100644,$sha,f.txt"
check "with no attributes, a copy written CRLF changes every line" is "$(git -C "$r" diff --cached --numstat -- f.txt)" $'20\t20\tf.txt'
fixture newfile
lines 5 > "$r/new.txt"
lines 2 > "$tmproot/first"
sha=$(git -C "$r" hash-object -w --path=new.txt "$(native "$tmproot/first")")
git -C "$r" update-index --add --cacheinfo "100644,$sha,new.txt"
check "a new file's first two lines are staged" is "$(git -C "$r" diff --cached --numstat -- new.txt)" $'2\t0\tnew.txt'
check "and its other three wait on disk" is "$(git -C "$r" diff --numstat -- new.txt)" $'3\t0\tnew.txt'

echo "9. A -U0 hunk subset under git apply --unidiff-zero (git, not the script)"
fixture unidiff
{ lines 3; echo A1; echo A2; lines 10 | tail -n 7; echo B1; lines 20 | tail -n 10; } > "$r/f.txt"
git -C "$r" diff -U0 -- f.txt > "$tmproot/full.patch"
check "git diff -U0 cuts two hunks" is "$(grep -c '^@@' "$tmproot/full.patch")" 2
awk '/^@@/ { n++ } n != 1' "$tmproot/full.patch" > "$tmproot/sub.patch"
git -C "$r" apply --cached --unidiff-zero "$(native "$tmproot/sub.patch")" > "$tmproot/out.txt" 2>&1
check "the second hunk alone applies, exit 0" is "$?" 0
check "and puts B1 at line 13, two below the 11 it belongs at" is "$(git -C "$r" cat-file blob :f.txt | grep -n B1)" "13:B1"
git -C "$r" reset -q -- f.txt
stage f.txt include B1
check "the script puts B1 at line 11" is "$(git -C "$r" cat-file blob :f.txt | grep -n B1)" "11:B1"

echo "10. What the script refuses"
fixture refuse
lines 3 > "$r/new.txt"
stage new.txt include line
check "a path not in the index, exit 2" is "$rc:$(grep -c 'not in the index' "$tmproot/out.txt")" "2:1"
printf 'a\0b\n' > "$r/bin.dat"
git -C "$r" add bin.dat
git -C "$r" commit -qm bin
printf 'a\0c\n' > "$r/bin.dat"
stage bin.dat include .
check "a binary file, exit 2" is "$rc:$(grep -c 'is binary' "$tmproot/out.txt")" "2:1"
mark "$r/f.txt" 5 alpha
stage f.txt inlcude alpha
check "a misspelt mode, exit 2 with the usage" is "$rc:$(grep -c '^usage:' "$tmproot/out.txt")" "2:1"
stage f.txt include '('
check "a regex that does not compile, exit 2" is "$rc:$(grep -c 'bad regex' "$tmproot/out.txt")" "2:1"
stage f.txt include zeta
check "no block taken, exit 1, the index untouched" is "$rc:$(git -C "$r" diff --cached --name-only)" "1:"
git -C "$r" checkout -q -- f.txt
stage f.txt include line
check "no change from the index, exit 1" is "$rc:$(grep -c 'no change from the index' "$tmproot/out.txt")" "1:1"
fixture unmerged
git -C "$r" switch -qc other
mark "$r/f.txt" 5 theirs
git -C "$r" commit -qam theirs
git -C "$r" switch -q main
mark "$r/f.txt" 5 ours
git -C "$r" commit -qam ours
git -C "$r" merge -q other > /dev/null 2>&1
stage f.txt include ours
check "an unmerged path, exit 2" is "$rc:$(grep -c 'unmerged' "$tmproot/out.txt")" "2:1"
r="$tmproot/norepo"
mkdir "$r"
export GIT_CEILING_DIRECTORIES
GIT_CEILING_DIRECTORIES=$(native "$tmproot")
stage f.txt include line
unset GIT_CEILING_DIRECTORIES
check "outside a repo, git's own code and message" is "$rc:$(grep -c 'not a git repository' "$tmproot/out.txt")" "128:1"

echo "11. Output and paths"
fixture unicode
sed -i '5s/$/ — dash/' "$r/f.txt"
stage f.txt include dash
check "an em dash prints with no PYTHONIOENCODING" is "$rc:$(grep -c 'line 05 — dash' "$tmproot/out.txt")" "0:1"
if command -v cygpath > /dev/null; then
    fixture backslash
    mkdir "$r/sub"
    lines 20 > "$r/sub/g.txt"
    git -C "$r" add sub/g.txt
    git -C "$r" commit -qm sub
    mark "$r/sub/g.txt" 5 alpha
    stage 'sub\g.txt' include alpha
    check "a backslashed path stages on Windows" is "$(cached sub/g.txt)" $'-line 05\n+line 05 alpha'
fi

echo
echo "$pass passed, $fail failed"
[ "$fail" = 0 ]
