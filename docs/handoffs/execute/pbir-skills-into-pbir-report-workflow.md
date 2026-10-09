---
status: open
priority: 2
needs: []
blocked-by: [fabric-deploy-skill.md]
written: 2026-10-09
---

# Handoff: fold the PBIR skills and powerbi-report-design into pbir-report-workflow

- **Written**: 2026-10-09, on the user's decision in
  [platform-skill-portfolio.md](platform-skill-portfolio.md). Measured
  at `9535085`.
- **Kind**: a restructure, done by hand, then
  `/test-skill pbir-report-workflow`. Eight skills become its
  references as they stand: `pbir-cli`, the six file-level skills
  (`pbir-visual-json`, `pbir-filters`, `pbir-pages`, `pbir-themes`,
  `pbir-bookmarks`, `pbir-conditional-formatting`), and
  `powerbi-report-design`, which stops being vendored.
  `pbip-project-structure` stays a skill, since it covers the semantic
  model side too. No platform fact is added, so `/author-skill` does not
  apply.
- **After the pilot**: [fabric-deploy-skill.md](fabric-deploy-skill.md)
  tests the router shape first, and this is its second wave's PBIR item,
  widened by the user.

## Why

- **Report work runs through the `pbir` CLI under this skill.** The
  2026-10-06 session that scaffolded a report in the main client repo
  invoked `pbir-report-workflow` three times and ran 72 `pbir` commands,
  six of them `pbir new`, with no Read, Write or Edit of a report file.
  The file-level skills' globs fire on those three tools alone, so none
  could appear. The one client session that Read `page.json` and
  `pages.json` (the sandbox repo, 2026-10-01) activated `pbir-pages` and
  `pbir-filters` and invoked neither.
- **It is the platform skill most used**: 33.7m tokens over seven days
  in a client repo (its `/skill-doctor`, 2026-10-08).
- **Listing**: 2,488 characters at startup today, `pbir-report-workflow`
  991, `pbir-cli` 822 and `powerbi-report-design` 675, plus 7,644 more
  when all six globs fire: `pbir-visual-json` 1,292, `pbir-filters`
  1,304, `pbir-pages` 1,170, `pbir-themes` 1,262, `pbir-bookmarks`
  1,284, `pbir-conditional-formatting` 1,332. After, one entry.
- **The trade**: hand-editing report JSON no longer surfaces a file's
  guidance by itself. The router must be invoked first, and its body
  must say which reference to read before which hand edit.

## Shape

### Files

| Today | After |
| --- | --- |
| `pbir-cli/SKILL.md`, the verb index | `pbir-report-workflow/references/pbir-cli.md` |
| `pbir-cli/references/REFERENCE.md`, the full command reference | `references/pbir-cli-commands.md` |
| each file-level skill's `SKILL.md` | `references/<file>.md`: `visual-json`, `filters`, `pages`, `themes`, `bookmarks`, `conditional-formatting` |
| each file-level skill's `references/REFERENCE.md`, a Learn link bundle | appended to its moved file, then removed |
| `powerbi-report-design/` whole: `SKILL.md`, `references/` (14 topic files), `assets/base.json`, `LICENSE.upstream` | `references/design/`, its `SKILL.md` renamed `design.md`; its own `references/` and `assets/` keep their places inside it, so their links hold |

Move each with `git mv`, so `git log --follow` keeps its history. Strip
each moved file's frontmatter and re-point its relative links, which
`grep -n ']('` on each finds. `pbir-report-workflow`'s own
`references/REFERENCE.md` stays.

### Ending the vendoring

`powerbi-report-design` came verbatim from `microsoft/skills-for-fabric`
v0.3.13, commit `b8d541c`, MIT-licensed, per its "Local vendoring note".

- Keep `LICENSE.upstream` beside the moved files and the attribution
  line, since MIT asks that the notice travel with the copy. Drop the
  note's re-sync instruction: upstream fixes now arrive only by hand.
- Its text hands off to `powerbi-report-authoring`, which
  `platform-skill-portfolio.md` Part 1 archives. Re-point each hand-off
  to the router's own build steps; that is the only wording change.
- In `.claude/skills/drift-audit/references/sources/skills-for-fabric.md`,
  "Vendored files — check path history, not the changelog" (lines
  56-93 on 2026-10-09), the `artifacts` list (line 33) and the bucket
  rule naming the vendored skills (lines 18-19) lose
  `powerbi-report-design`. Part 1 removes `powerbi-report-authoring`
  from the same places, so whichever lands second removes the section,
  nothing then being vendored.

### The router

`pbir-report-workflow`'s workflow, its `Step` sections (twelve on
2026-10-09), stays the body, and gains:

1. **Before a hand edit of report JSON**, one table, the file to the
   reference: `visual.json` to `visual-json.md`, and to
   `conditional-formatting.md` for conditional formatting; `page.json`
   and `pages.json` to `pages.md`; a `filterConfig` to `filters.md`;
   theme JSON to `themes.md`; bookmarks to `bookmarks.md`.
2. **The CLI**: the verb index in `pbir-cli.md`, flags in
   `pbir-cli-commands.md`.
3. **Design**: tone, chart choice, colour, typography, layout,
   accessibility, or a redesign or critique, in `design/design.md`.

Its mentions of the folded skills by name become those links.

### Frontmatter

- Still always listed, with no `paths:`.
- The entry, `description` plus `when_to_use`, at most today's 991
  characters, and the pilot's 500 if its result supports it. It gains
  trigger words from `pbir-cli` (the `pbir` CLI, its verbs) and from
  `powerbi-report-design` (redesign, restyle, brand, chart choice,
  accessibility), and states no facts.
- `disable-model-invocation: false`, `# model: inherit` and `effort`
  commented, as repo policy.

## The rename trap

Nothing errors when a skill name goes stale. Change each of these in
the commit that folds:

- `.claude/settings.json` `skillOverrides`: the eight entries go.
- `tests/skills/pbip-triggers/expected_activations.md`: the six
  file-level skills leave every row, and `pbip-project-structure` stays.
  Recompute the `Tokens` cells as that set's README says, re-point its
  own mentions of `pbir-pages` and `pbir-conditional-formatting`, then
  run `./scripts/test-activation.ps1 -Set pbip -StaticOnly`.
- `tests/skills/.tested.json`: the six file-level stamps go; the
  frontmatter edit makes `pbir-report-workflow`'s stale.
- `skills/README.md`: eight bullets fold into the router's.
- Other skills' mentions, counted 2026-10-09. Outside the nine,
  `fabric-rest-api` and `pbip-project-structure` name `pbir-cli`,
  `pbip-project-structure` names `pbir-pages`, and `fabric-gotchas`
  names `pbir-filters`: re-point each to `pbir-report-workflow`.
  `powerbi-report-authoring` names two of them, if Part 1 has not yet
  archived it. Every other mention sits among the nine and becomes a
  reference link. A name backticked in a description fails
  `scripts/skill-overlap.py routing`.
- `.claude/skills/author-skill/SKILL.md:330` quotes a description that
  names `pbir-themes`, as history: leave it.
- Open briefs naming the eight:
  [pbir-august-formatting-properties.md](pbir-august-formatting-properties.md)
  waits for this one and already names the moved files. `docs/audits/`
  stays as written.

```bash
grep -rnE 'pbir-(cli|visual-json|filters|pages|themes|bookmarks|conditional-formatting)|powerbi-report-design' --exclude-dir=audits --exclude-dir=.git .
```

**Client repos**: relink each with exactly the groups it holds; the
relink prunes the eight dangling junctions. The main client repo's
`"off"` for `powerbi-report-design` then names nothing, which is
harmless and that repo's to tidy.

## Verify

1. The static check passes, and
   `uv run --with pyyaml scripts/lint-frontmatter.py skills/powerbi/pbir-report-workflow/SKILL.md`
   is clean.
2. `/test-skill pbir-report-workflow`, behaviour, against a
   `--safe-mode` baseline:

   | Case | Prompt, in short | Passes when |
   | --- | --- | --- |
   | Scaffold | build a report on a published model | the workflow's steps, through the `pbir` CLI |
   | Hand edit | make a page fit to width by editing its `page.json` | reads `references/pages.md` first; `displayOption` as a string |
   | Filter | add a relative date filter to a visual by hand | reads `references/filters.md` |
   | Design | restyle a report to a brand palette, or critique its charts | reads `references/design/design.md` |
   | CLI | list every visual on a page | a `pbir` discovery verb, per `pbir-cli.md` |

3. **Listing**: the new entry against the 2,488 and 7,644 characters
   above.
4. `pre-commit run --all-files`.

## Re-measure before acting

- The pilot's result, in `fabric-deploy-skill.md`. If its router routed
  worse than the pair it replaced, stop and put this brief back to the
  user, who decided it before that result.
- `pbir --version` (0.9.32 was current on 2026-10-07): `pbir-cli.md`
  names its verbs.
- Whether `/triage` has applied the client prompt audit's hunks to any
  of the nine, or `pbir-august-formatting-properties.md` has landed in
  them; re-read before moving.

## Not checked

- Whether a reference is read more often than its skill was invoked:
  `skill-telemetry.py triggers` after a few weeks of report work.
- What upstream changed in `powerbi-report-design` after the
  registry's last vendored-path check, which found nothing through
  upstream's 0.3.15.

## Scrubbing

Client repos are named by kind, and no workspace, report, model or
tenant is named.
