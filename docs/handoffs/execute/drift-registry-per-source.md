---
status: open
priority: 2
needs: [registry audit briefs executed]
blocked-by: []
written: 2026-10-06
---

# Handoff: one file per drift-audit source

- **Written**: 2026-10-06, at `de236cc`, after the user asked whether the
  source registry should be split. The shape below is what they decided
  that day.
- **Kind**: a refactor of the project-scope `drift-audit` skill and of
  the places that name its registry. Every choice is made; nothing goes
  back to the user unless a check below fails.

## What changes

`.claude/skills/drift-audit/references/sources.md` keeps what every run
needs: the entry schema, the shape contracts and the checklist for adding
a source. Each registered source moves to its own file,
`references/sources/<id>.md`. The filename, less `.md`, **is** the `id`
that `--sources` matches, and nothing lists the files: a run finds them
by Glob.

```text
.claude/skills/drift-audit/references/
├── sources.md    schema, convention, shape contracts, adding a source
└── sources/
    ├── claude-code.md
    ├── fabric.md
    ├── fabric-iq-ontology.md
    ├── powerbi.md
    ├── skills-for-fabric.md
    └── vscode-agent.md
```

Decided 2026-10-06:

- **Split by source**, the user's call.
- **No pointer list in `sources.md`**, the user's pick of two; the other
  was a table checked by a script. Hand-kept lists of sources have gone
  stale here twice: `SKILL.md` § 1 records one that left out
  `fabric-iq-ontology` for five days after it was registered, and
  `.claude/skills/README.md` still reads "Fabric and Power BI What's New
  today" with six registered.
- **`sources.md` keeps its name.** The skill's `description` names
  `references/sources.md`, which stays true of the index, and a
  description edit would mean a routing retest.
- **A run takes sources in id order, alphabetical.** Claude Code's Glob
  tool returns paths by modification time, so its order would reshuffle
  a report whenever an entry was edited.
- **A fresh session executes this**, in a worktree named
  `drift-registry-per-source`, as root `CLAUDE.md` says of every brief.

**Out of scope**: moving the dated validation history (known-answer
runs, run prices, worked cases) out of the entries. That waits in
[drift-registry-evidence.md](drift-registry-evidence.md): it means
sorting sentence by sentence what a run must still follow, since "an
unusable fork answers HTTP 200 with `[]`" is history and a runtime rule
at once.

## Why

Measured 2026-10-06 at `de236cc`: the file is 44,801 bytes, and every run
reads all of it (`SKILL.md` § 1). The shared sections are 5,750 bytes;
the entries are `fabric` 1,254, `fabric-iq-ontology` 4,010,
`claude-code` 4,272, `vscode-agent` 4,544, `powerbi` 10,114 and
`skills-for-fabric` 14,857.

- **The pipeline runs one source per session, against one file.** The
  deferred `drift-fetch-subagent.md` calls per-source sessions "the
  pipeline's intended shape", and the ledger directories, the briefs and
  `--sources` all key on the id. A single-source `fabric` run, like that
  day's, reads 44.8 KB to use about 7 KB.
- **Registry repairs come out of per-source audits and land in one
  file**: `powerbi` on 2026-09-07, `skills-for-fabric` on 2026-09-10 and
  2026-09-12, and four briefs from three audits on 2026-10-06. The
  2026-09-10 brief already had to say "Re-read `sources.md` immediately
  before editing — it is shared with other registry work".
- `coding-markdown.md` says depth past `###` usually means a section
  wants its own file, and `powerbi` and `skills-for-fabric` are the two
  entries that reach `####`.

## Before starting

**Every audit brief that edits the registry is executed first.** On
2026-10-06 four were pending, all from audits of that day:

| Brief, under `docs/audits/2026-10-06/` | Edits |
| --- | --- |
| `fabric/17-repair-fabric-registry-entry.md` | the `fabric` entry |
| `powerbi/01-re-anchor-powerbi-fork-search.md` | the `powerbi` entry |
| `powerbi/02-record-powerbi-fetch-route-limits.md` | the `powerbi` entry |
| `vscode-agent/04-decide-vscode-agent-source-scope.md` | the `vscode-agent` entry, maybe `SKILL.md` § 1 and the description; the user decides first |

`/drift-update` checks a brief's quoted text at its target before
applying it, so a split landed under a pending brief stops it, and one
that lands on `main` while this is in flight conflicts at the rebase.
List every brief whose target is the registry, at either of its paths,
with its state:

```bash
for f in $(grep -rl 'Target\*\*: `[^`]*drift-audit/references/sources\.md' docs/audits/); do
  echo "== $f"; grep -E '^(- )?\*\*(Executed|Closed|Needs)\*\*' "$f" | tail -n 3
done
```

A brief with no `Executed` line blocks. One executed with deferrals
blocks only if its last `Needs` line is an edit to registry text. On
2026-10-06 the two of those still open did not: `2026-09-07/powerbi/01`
waits on a re-run of that audit, and `2026-09-10/skills-for-fabric/06`
on a decision about `SKILL.md` § 4a. If a brief blocks for long,
re-point its target to the new file with whoever is working it, rather
than move text out from under it.

`2026-10-06/fabric/18-decide-table-source-fetch-strategy.md` ends in an
edit to `SKILL.md` § 4, which this brief touches only at that section's
first line. It does not block; re-read `SKILL.md` before editing it.

Then, from the main checkout and before entering the worktree:

```bash
grep -c '^### `' .claude/skills/drift-audit/references/sources.md   # 6 on 2026-10-06
```

That count drops if `vscode-agent/04` retired its source. Take the
allowlist baseline too: *Verification*, check 2, printed six ids on
2026-10-06.

## The move

For each `` ### `<id>` — <label> `` section under `## Registered sources`:

1. Create `references/sources/<id>.md`. Its H1 is that heading at level
   one, `` # `<id>` — <label> ``, and its `####` headings become `##`.
2. Move the body **verbatim**. Measured 2026-10-06 on git 2.55.0 in a
   scratch repo: plain `git blame` gave every moved line to the split
   commit, and `git blame -C` traced each to the commit that wrote it,
   with the index reworded in the same commit. Only a line edited in the
   move loses its history, which `coding-markdown.md` says costs most in
   a file of dated measurements.
3. Leave each entry's mentions of other entries as they are. With the
   filename as the id, "the `fabric` entry" names `sources/fabric.md`
   unambiguously, and rewording it would cost the line its history.

Then, in `sources.md`:

- The intro's "Adding a domain to the audit is an entry here" and "Each
  `id` below is what `--sources` accepts" say that each file under
  `sources/` is one source, its filename less `.md` the `id`.
- The schema's `id` row adds that the id is the filename, and its
  `label` row that the label is the file's H1, after the id.
- `## Registered sources` keeps its heading, since a heading is an
  address, and holds the convention: one file per source, found by a
  Glob of `references/sources/*.md` and taken in id order, with no list,
  and why.
- *Adding a source* step 2, "Add the entry above", becomes creating
  `sources/<id>.md`.
- *Shape contracts* stays as it is.

## The silent break: `scripts/skill-overlap.py`

`allowlist()` reads the source ids from the `` ### `<id>` `` headings in
`sources.md`, at lines 160–166. After the move it finds none **and still
exits 0**: the `lint-skill-routing` hook runs on the split commit and
passes with the ids gone from the allowlist, and no fixture covers that
arm (`tests/scripts/skill-overlap/README.md`). Read them from the
filenames instead, and fail on finding none, since a glob over a moved
directory is as silently empty as the regex is now:

```python
    # drift-audit source ids: one registry file per source, named for its id.
    sources = sorted((REPO / ".claude/skills/drift-audit/references/sources").glob("*.md"))
    if not sources:
        sys.exit("skill-overlap: no drift-audit sources found; did the registry move?")
    for f in sources:
        out.setdefault(f.stem, "drift-audit source id")
```

The move, this fix and the `SKILL.md` § 1 edit go in one commit: any of
them without the others leaves the allowlist or the skill reading
nothing.

## Other edits

Line numbers are at `de236cc`; find each by its text.

- `.claude/skills/drift-audit/SKILL.md`, the body only:
  - § 1, line 20: read `sources.md`, then `references/sources/<id>.md`
    for each selected source, or every file there with no `--sources`.
  - § 1, line 24: drop the enumeration "As registered today: …"; keep
    the fetch exceptions it carries (`claude-code` and
    `skills-for-fabric` github-mcp-only in practice, `powerbi`'s own
    strategy); and reword its "don't restate that set" to cover a list
    as well as a count, keeping its 2026-09-02 evidence.
  - § 2, line 37: an unknown id lists the valid ones, the filenames.
  - § 4, line 51, and the § 7 template, line 156: "registry order"
    becomes id order.
  - § 8, line 216: the fields come from the source's file.
- `.claude/skills/drift-update/SKILL.md:144-145`: "most often
  `.claude/skills/drift-audit/references/sources.md`" names the
  directory, `.claude/skills/drift-audit/references/`.
- `.claude/skills/drift-handoff/SKILL.md:41`: `<source-id>` is the
  filename, less `.md`, of the source's file under `references/sources/`.
- `.claude/skills/README.md:75-77`: the registry is `sources.md` and one
  file per source, widening the audit is a file there, and "Fabric and
  Power BI What's New today" goes.
- `docs/handoffs/execute/drift-fetch-subagent.md:234` and `:345`: the
  agent reads `sources.md` for the shape contracts and `sources/<id>.md`
  for its source's entry.

Leave alone:

- `docs/audits/`, a dated ledger. It already cites this file at an older
  path, `skills/workflow/drift-audit/references/sources.md`.
- `.claude/skills/drift-handoff/references/brief-format.md:184` and
  `:223`, a worked example that already carries an older path of its own.
- `scripts/README.md`'s `skill-overlap.py` entry, which names
  "drift-audit source ids" as a category, not how they are found.

## Verification

In the worktree, with the new files staged.

**1. Every entry's body moved intact.** Each row must show two equal,
nonzero counts and `identical`. The base is the commit this branch left
`main` at, so the check reads the same before and after committing. Run
before any move, on 2026-10-06, it printed `6 entries` and
`N -> 0  DIFFERS` on every row, so a missing file cannot pass.

```bash
r=.claude/skills/drift-audit/references
b=$(git merge-base HEAD main)
ids=$(git show "$b:$r/sources.md" | grep -o '^### `[a-z0-9-]*`' | tr -d '#` ')
echo "$(echo "$ids" | wc -w) entries at $b"
old() { git show "$b:$r/sources.md" | awk -v h="### \`$1\`" 'index($0, h) == 1 {on = 1; next} on && /^##(#)? / {on = 0} on' | grep -v -e '^#' -e '^$'; }
new() { git show ":$r/sources/$1.md" | grep -v -e '^#' -e '^$'; }
for id in $ids; do
  printf '%-20s %4s -> %4s  ' "$id" "$(old "$id" | wc -l)" "$(new "$id" | wc -l)"
  diff -q <(old "$id") <(new "$id") >/dev/null && echo identical || echo DIFFERS
done
```

**2. The allowlist still holds every id.** Before the move, on
2026-10-06, this printed all six:

```bash
uv run --quiet --with pyyaml python - <<'EOF'
import importlib.util, sys
sys.path.insert(0, "scripts")
spec = importlib.util.spec_from_file_location("skill_overlap", "scripts/skill-overlap.py")
m = importlib.util.module_from_spec(spec)
spec.loader.exec_module(m)
print(sorted(k for k, v in m.allowlist().items() if v == "drift-audit source id"))
EOF
```

**3. The rest:**

- `git diff --cached -- .claude/skills/drift-audit/references/sources.md`
  shows the six sections gone and only the edits under *The move*.
- `bash tests/scripts/skill-overlap/test-routing.sh`. It does not cover
  the source arm, which is why check 2 exists.
- `uv run --with pyyaml scripts/lint-frontmatter.py` on each of the
  three `SKILL.md` files.
- `grep -rn 'references/sources\.md' .claude/ scripts/ docs/handoffs/`:
  every hit means the index, bar the worked example left alone above.
- After committing, `git blame -C` on a dated line in
  `sources/powerbi.md` names the commit that measured it, not the split.
- Two runs of the worktree's own `/drift-audit`, which a worktree loads
  in place of the main checkout's copy:
  - `/drift-audit --sources nope` lists the ids from the filenames and
    stops.
  - `/drift-audit <today> --sources fabric-iq-ontology` reads
    `sources.md` and `sources/fabric-iq-ontology.md` and no other
    entry. A floor of today keeps the window near empty and the run
    short.
- `pre-commit run --all-files`.

## Landing

As `docs/handoffs/CLAUDE.md` says: from the main checkout, with no push,
and this brief deleted in the commit that finishes the work, its name
dropped from the `blocked-by` of `drift-registry-evidence.md`. Before the
fast-forward, make sure no `/drift-audit`, `/drift-handoff` or
`/drift-update` session is live in the main checkout: the skill is
project scope, so the merge reaches those sessions at once.

`skill-status.py` will then read `drift-update` as `retest-behaviour`,
from the one-line edit at `:144-145`; it was `current`, stamped
2026-09-30. `drift-audit` and `drift-handoff` were already `untested`.
