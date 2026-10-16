#!/usr/bin/env bash
# Exercise scripts/link-claude.ps1's ignore check against throwaway repos.
#
# Each case runs a copy of the script from a fake payload repo in a temp
# directory: two fixture skills in one group, alpha, and a file in each
# directory a full run copies. So every junction a run makes points at a
# fixture, never at this repo's skills/, whose files a recursive delete
# over a junction could reach (test-activation.ps1 unlinks its own one by
# one for that reason); here removing the temp directory is the whole
# cleanup. The fake repo is no linked worktree either, so the script's
# worktree guard never fires and the suite runs the same from one.
#
# Each case deploys into a scratch git repo that ignores the payload one
# way, or not at all, and checks the exit, the line the script printed and
# what landed. Case 0 holds the help block, which carries the check's
# reasoning and drops silently on one bad line. No network, and nothing
# written outside the temp directory.
#
#     bash tests/scripts/link-claude/test-ignore-check.sh [link-claude.ps1]
#
# The argument runs the cases against another copy of the script, which is
# how the version before the check was shown to fail 24 of 41, and a copy
# that asks for each directory without its trailing slash 8, case 5's
# junction linked among them (2026-10-16).
#
set -u

here=$(cd "$(dirname "$0")" && pwd)
repo=$(cd "$here/../../.." && pwd)
script=${1:-$repo/scripts/link-claude.ps1}
tmproot=$(mktemp -d)
trap 'rm -rf "$tmproot"' EXIT
out="$tmproot/out.txt"
: > "$out"

pass=0
fail=0

# A native Windows program resolves a /tmp path to C:\tmp, not %TEMP%, so
# hand pwsh a Windows path wherever cygpath exists to make one.
native() {
    if command -v cygpath > /dev/null; then cygpath -w "$1"; else printf '%s\n' "$1"; fi
}

payload="$tmproot/payload"
mkdir -p "$payload/scripts" "$payload/skills/alpha/one" "$payload/skills/alpha/two"
cp "$script" "$payload/scripts/link-claude.ps1"
for d in agents hooks rules mcp; do
    mkdir -p "$payload/claude/$d"
    printf 'fixture\n' > "$payload/claude/$d/fixture.md"
done
printf 'fixture\n' > "$payload/claude/CLAUDE.md"
printf '{}\n' > "$payload/claude/settings.json"
for s in one two; do
    printf -- '---\nname: %s\ndescription: fixture\n---\n' "$s" > "$payload/skills/alpha/$s/SKILL.md"
done

# mkrepo <name>: a fresh repo at $tmproot/<name> with one empty commit, in $r
mkrepo() {
    r="$tmproot/$1"
    git init -q -b main "$r"
    git -C "$r" config user.name test
    git -C "$r" config user.email test@example.invalid
    git -C "$r" commit -q --allow-empty -m base
}

# run <claude-dir> [argument...]: the copy, deploying group alpha into
# <claude-dir>; output in $out, exit in $rc
run() {
    local dir=$1
    shift
    pwsh -NoProfile -NonInteractive -File "$(native "$payload/scripts/link-claude.ps1")" \
        -ClaudeDir "$(native "$dir")" -SkillGroups alpha "$@" > "$out" 2>&1
    rc=$?
}

# pwsh shows a thrown refusal in its error view, coloured even into a file
# and wrapped under a "|" gutter, so a phrase can break across lines. Text
# is matched with the colour and gutter stripped, every line joined, and
# each run of spaces squeezed to one, as tests/scripts/repo-settings does.
flat() {
    sed -E 's/\x1b\[[0-9;]*m//g; s/^ *\| ?//' "$out" | tr '\r\n' '  ' | tr -s ' '
}
says() { flat | grep -qF -- "$1"; }
silent_on() { ! says "$1"; }

is() {
    [[ "$1" == "$2" ]] && return
    printf '        expected %q\n        got      %q\n' "$2" "$1"
    return 1
}

# linked <claude-dir>: both fixture skills reachable through its junctions
linked() { [[ -f "$1/skills/one/SKILL.md" && -f "$1/skills/two/SKILL.md" ]]; }

# check <label> <predicate> <args...>: one ok or FAIL line
check() {
    local label=$1
    shift
    if "$@"; then
        echo "ok    $label"
        pass=$((pass + 1))
    else
        echo "FAIL  $label"
        sed 's/^/        | /' "$out"
        fail=$((fail + 1))
    fi
}

echo "0. The help block parses"
pwsh -NoProfile -NonInteractive -Command \
    "(Get-Help '$(native "$payload/scripts/link-claude.ps1")').Description.Text" > "$out" 2>&1
check "Get-Help reads the description, the ignore check's paragraph with it" \
    says 'MUST IGNORE EVERY PATH THE RUN WRITES'

echo "1. A repo that ignores none of it is refused before any write"
mkrepo none
run "$r/.claude" -SkillsOnly
check "exit 1" is "$rc" 1
check "it names each junction's path" says '.claude/skills/one/, .claude/skills/two/'
check "and the line to add" says 'Ignore /.claude/skills/ in its .gitignore or .git/info/exclude'
check "and says nothing was written" says 'Nothing was linked or copied.'
check "no junction is made" test ! -e "$r/.claude/skills"
check "and git sees nothing under .claude" is "$(git -C "$r" status --porcelain -uall -- .claude)" ""

echo "2. The line in .gitignore lets it link, and git sees no junction"
printf '/.claude/skills/\n' > "$r/.gitignore"
run "$r/.claude" -SkillsOnly
check "exit 0" is "$rc" 0
check "it reports the check" says 'OK ignore check (git ignores all 2 path(s)'
check "both skills are linked" linked "$r/.claude"
check "git status shows .gitignore alone" is "$(git -C "$r" status --porcelain -uall)" "?? .gitignore"
git -C "$r" add -A
check "git add -A stages nothing under .claude" is "$(git -C "$r" diff --cached --name-only -- .claude)" ""
git -C "$r" reset -q

echo "3. A re-run once the line is gone is refused, and leaves the links alone"
rm "$r/.gitignore"
run "$r/.claude" -SkillsOnly
check "exit 1" is "$rc" 1
check "it names both paths again" says '.claude/skills/one/, .claude/skills/two/'
check "the earlier run's links stand" linked "$r/.claude"

echo "4. Every ignore shape that covers the paths passes"
# shape <label> <file> <line>...: a fresh repo whose <file> holds those lines,
# deployed into
n=0
shape() {
    local label=$1 file=$2
    shift 2
    n=$((n + 1))
    mkrepo "shape$n"
    printf '%s\n' "$@" >> "$r/$file"
    run "$r/.claude" -SkillsOnly
    check "$label: exit 0, both linked" is "$rc:$(linked "$r/.claude" && echo linked)" "0:linked"
}
shape "/.claude/skills/ in .git/info/exclude" .git/info/exclude '/.claude/skills/'
shape ".claude/* in .gitignore" .gitignore '.claude/*'
shape "a directory-only line per skill" .gitignore '/.claude/skills/one/' '/.claude/skills/two/'
shape "a line per skill without the slash" .gitignore '/.claude/skills/one' '/.claude/skills/two'

echo "5. A negated line that re-includes one skill is refused for that skill alone"
mkrepo negated
printf '%s\n' '/.claude/skills/*' '!/.claude/skills/two/' > "$r/.gitignore"
run "$r/.claude" -SkillsOnly
check "exit 1" is "$rc" 1
check "it names the re-included skill" says '.claude/skills/two/'
check "and not the ignored one" silent_on '.claude/skills/one/'
check "no junction is made" test ! -e "$r/.claude/skills"

echo "6. A run without -SkillsOnly checks the copies too"
mkrepo full
printf '/.claude/skills/\n' > "$r/.gitignore"
run "$r/.claude"
check "with only the junctions ignored: exit 1" is "$rc" 1
check "it names each copied directory and file" \
    says '.claude/agents/, .claude/hooks/, .claude/rules/, .claude/mcp/, .claude/CLAUDE.md, .claude/settings.json.'
check "and points a project at -SkillsOnly" says "A project's .claude takes -SkillsOnly"
check "and neither the ignored junctions" silent_on '.claude/skills/one/'
check "nor their line" silent_on 'Ignore /.claude/skills/'
check "nothing is copied" test ! -e "$r/.claude/agents"
printf '.claude/*\n' > "$r/.gitignore"
run "$r/.claude"
check "with .claude/* ignored: exit 0" is "$rc" 0
check "the copies land" test -f "$r/.claude/agents/fixture.md"
check "and git sees .gitignore alone" is "$(git -C "$r" status --porcelain -uall)" "?? .gitignore"

echo "7. A .claude below the top level takes its own prefix"
mkrepo nested
mkdir -p "$r/sub"
printf '/.claude/skills/\n' > "$r/.gitignore"
run "$r/sub/.claude" -SkillsOnly
check "a line anchored at the top misses it: exit 1" is "$rc" 1
check "it names the path from the top level" says 'sub/.claude/skills/one/'
check "and the line that would cover it" says 'Ignore /sub/.claude/skills/'
printf '/sub/.claude/skills/\n' >> "$r/.gitignore"
run "$r/sub/.claude" -SkillsOnly
check "with that line: exit 0, both linked" is "$rc:$(linked "$r/sub/.claude" && echo linked)" "0:linked"

echo "8. A target in no working tree skips the check"
plain="$tmproot/plain"
mkdir -p "$plain"
if git -C "$plain" rev-parse --show-toplevel > /dev/null 2>&1; then
    echo "skip  in no working tree: the temp directory sits inside one"
else
    run "$plain/.claude" -SkillsOnly
    check "exit 0, both linked" is "$rc:$(linked "$plain/.claude" && echo linked)" "0:linked"
    check "and it says it skipped the check" says 'Skipped ignore check ('
fi

echo "9. A git that cannot read the target stops the run"
mkrepo dotgit
run "$r/.git/probe" -SkillsOnly
check "a -ClaudeDir inside .git: exit 1" is "$rc" 1
check "it says git could not read it" says 'git could not read'
check "no junction is made" test ! -e "$r/.git/probe/skills"

echo
echo "$pass passed, $fail failed"
[ "$fail" = 0 ]
