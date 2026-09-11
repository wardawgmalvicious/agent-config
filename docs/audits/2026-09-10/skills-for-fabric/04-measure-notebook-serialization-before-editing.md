# Handoff: measure Fabric's notebook serialization before changing the git-serialization rule

- **Audit run**: 2026-09-10
- **Source**: `skills-for-fabric`
- **Window**: floor `2026-08-06` (diff base `912e06e0`) → head `65902bae`
  (2026-09-04)
- **Covers recommended actions**: 5
- **Kind**: **measurement, then a decision.** No edit is authorized until
  the measurement is in. If an edit follows, it lands in a user-scope
  rule copied to `~/.claude/rules` and loaded in every Fabric Git-synced
  repo on this machine.
- **Target** (only after measuring):
  `claude/rules/fabric-git-serialization.md`

## The problem

This repo and upstream disagree about how Fabric serializes notebook
source, and neither side has documentation behind it. Our rule says
`notebook-content.*` parts **end with** a newline, and that line endings
must be left untranslated (`-text`). Upstream says Fabric exports
`notebook-content.py`, `pipeline-content.json` and `.platform` with LF
line endings and **no** final newline, and pins those item types with
`text eol=lf`. Learn confirms the LF half only.

So one side is wrong about the final newline — or the behaviour differs
by notebook format, or it changed. A measurement settles it; Learn
cannot.

## Evidence

**Our rule** — `claude/rules/fabric-git-serialization.md` lines 43–49:

> Fabric re-serializes an item's definition files whenever the item is
> committed from the portal, and its canonical form for JSON and SQL
> parts (`pipeline-content.json`, `variables.json`, eventstream/report
> JSON, Warehouse `.sql` scripts) **has no final newline** — a trailing
> newline added locally is stripped on the next portal round-trip,
> producing a whitespace-only diff. TMDL, `notebook-content.*`, and
> `.kql` parts *do* end with a newline.

and lines 89–92:

> `-text` (no translation at all), **not** `text eol=lf` — forcing LF
> strips the portal's CRLF lines and restarts the ping-pong from the
> other side.

The CRLF lines that advice protects are Warehouse-specific: the `GO` /
`ALTER TABLE` constraint block in table DDL and the auto-generated view
header (lines 69–71).

**Upstream** — `microsoft/skills-for-fabric` `CHANGELOG.md`,
`[0.3.13] - 2026-08-20` (release commit `22cafc90`), under Added:

> **`skills/git-integration-operations-cli`** -- guidance for avoiding
> formatting-only diffs on Git sync. Fabric re-serializes item source
> (`notebook-content.py`, `pipeline-content.json`, `.platform`) to its
> canonical form (LF, no trailing final newline) on export, ...

The reference it added,
`plugins/fabric-skills/skills/git-integration-operations-cli/references/git-integration-concepts.md`,
section "Avoiding formatting-only diffs" (in the `22cafc90` patch),
verbatim in the parts that matter:

> For affected item source files (such as `notebook-content.py`,
> `pipeline-content.json`, and `.platform`), the observed export uses
> **LF** line endings and **no trailing final newline**. This is
> operationally observed behavior, not a documented platform guarantee;
> verify it with a representative workspace commit before applying the
> workaround across a repository.

```gitattributes
# .gitattributes — normalize to LF so Git never churns on CRLF
*.Notebook/**            text eol=lf
*.DataPipeline/**        text eol=lf
*.SparkJobDefinition/**  text eol=lf
.platform                text eol=lf
```

> The per-cell notebook rule ... is separate and still applies: inside
> an `.ipynb` payload, every `source` line ends with `\n` **except** the
> last line of a cell.

**Learn** —
[Basic concepts in Git integration](https://learn.microsoft.com/fabric/cicd/git-integration/git-integration-process),
Considerations and limitations, item 8.2, verbatim:

> Committing a file that uses *CRLF* line breaks. The service uses *LF*
> (line feed) line breaks. If you had item files in the Git repo with
> *CRLF* line breaks, when you commit from the service these files are
> changed to *LF*.

Learn says nothing about final newlines. Searched 2026-09-10 across the
notebook source-control, source-code-format and Git-integration-process
pages.

| Claim | Our rule | Upstream (observed) | Learn |
| --- | --- | --- | --- |
| `notebook-content.*` final newline | yes | no | silent |
| `pipeline-content.json` final newline | no | no | silent |
| `.platform` final newline | no (as JSON) | no | silent |
| Line endings | mixed CRLF/LF in Warehouse DDL | LF | service uses LF |
| `.gitattributes` | `-text` | `text eol=lf` per item type | — |

## What to measure

In a Git-synced Fabric workspace repo on this machine — and keep that
repo's name, and any client name, out of anything committed as a result:

1. Find portal-written notebook parts:
   `find <repo> -path '*.Notebook/notebook-content.*'`. Prefer a file
   whose last change came from a portal commit rather than a local edit
   (`git log -1 --format='%h %ad %s' -- <file>`). If unsure, commit a
   trivial change from the portal first.
2. Final byte: `tail -c 1 <file> | od -An -c` — `\n` means a final
   newline.
3. CR presence: `grep -c $'\r' <file>` — non-zero means CRLF lines.
4. Repeat 2–3 on a `.platform` and a `pipeline-content.json` as controls;
   both sides already agree those have no final newline.
5. If both `.py` and `.ipynb` notebooks exist, measure both — the format
   may be the whole difference.
6. Re-check a Warehouse table `.sql` for the CRLF lines the `-text`
   advice exists to protect.

Record the results with the date.

## Decision after measuring — put it back to the user

- Notebook parts end **without** a newline: lines 48–49 are wrong for
  notebooks. Correct them in place.
- Notebook parts end **with** one: upstream is wrong or format-specific.
  No change, or a dated note recording the measurement.
- `-text` versus `text eol=lf`: a per-item-type split — `eol=lf` for
  Notebook, DataPipeline and SparkJobDefinition, `-text` where the portal
  writes CRLF lines — is possible, but it is a policy change. Decide it
  only if step 6 re-confirms the Warehouse CRLF lines.

## Constraint on the fix

- Don't let Learn's general "the service uses LF" override the rule's
  Warehouse-specific CRLF measurement without re-measuring.
- Upstream labels its claim observed, not guaranteed, and ours is
  equally a measurement. Whatever lands, date it.

## Knock-on

The rule's one-line summary also appears in `claude/CLAUDE.md` ("EOF
newlines, mixed CRLF/LF, the auto-generated view header,
`.gitattributes -text`") and in `claude/rules/README.md`. If the policy
changes, both follow.

## Verification (if an edit follows)

1. Measurement results recorded, with date, in the commit message or
   the rule itself.
2. `uv run --with pyyaml scripts/lint-frontmatter.py claude/rules/fabric-git-serialization.md`
3. `./scripts/link-claude.ps1 -SkillGroups workflow` from `pwsh` — rules
   deploy by copy and are not live until this runs — then
   `diff claude/rules/fabric-git-serialization.md ~/.claude/rules/fabric-git-serialization.md`
   returns nothing.
4. `pre-commit run --all-files`

## Provenance

First `/drift-audit --sources skills-for-fabric` run, 2026-09-10, from a
0.3.13 `git-integration-operations-cli` bullet. The audit's finding
is itself labelled unconfirmed — "not a finding by the registry's
standard" — which is why this brief is a measurement rather than an
edit.
