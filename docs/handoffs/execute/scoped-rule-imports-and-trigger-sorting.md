---
status: open
priority: 3
needs: []
blocked-by: []
written: 2026-09-30
---

# Handoff: what a `paths:` rule cannot defer, and cannot reach

- **Written**: 2026-09-30, from findings 1 and 3 of an inbox note of
  2026-09-29. Its session, in a client Fabric repo, was trimming a root
  `AGENTS.md`, which the repo's `CLAUDE.md` imports and Copilot reads
  directly, by moving gotchas about one kind of file into
  `paths:`-scoped homes.
- **Kind**: a probe added to `scripts/test-instruction-loading.py`, then
  edits to `claude/rules/agent-instructions-scoping.md` and
  `.claude/rules/editing-claude-md.md`. Nothing is drafted.

The note's other findings went elsewhere: 2 and 4 to
[copilot-client-repo-findings.md](copilot-client-repo-findings.md), and
5 to `claude/rules/fabric-git-serialization.md`, where it has landed.

## 1. An `@`-import inside a `paths:` rule loads at launch

**The import is hoisted out of its rule.** The imported file loads at
launch in every session, while the rule's own text still waits for a
matching Read. So a scoped rule cannot defer a long document by
importing it, and a rule that exists to send Claude to another file has
to name that file in text.

**Probed** 2026-09-29 by the note's session, on Claude Code 2.1.282, in
a scratch directory holding three files:

- `.claude/rules/probe.md`: `paths: ["**/*.probe"]`, a token line, and
  an import of `../../docs/target.md`;
- `docs/target.md`: a second token line;
- `sample.probe`: one line.

Two cold sessions ran `claude -p --model haiku --tools Read
--strict-mcp-config`, each asked to quote every token line in its
context. One made no tool call; the other read `sample.probe` first.

| Session | Launch `instructions` attachment | Attachment on the Read |
| --- | --- | --- |
| No Read | the import's token | none |
| Read `sample.probe` | the import's token | `nested_memory` for `probe.md`, the rule's token only |

The transcripts were the witness, sessions `1ca7c551` and `7e172d5d`
under that scratch directory's project folder, and each model's answer
agreed with its transcript. `cleanupPeriodDays` is 15, so both are gone
after 2026-10-14. Not re-run here.

**What the payload says**, at `0b1e82c`: that an `@import` loads at
launch, as a reason not to use one in place of a root file's content, in
`.claude/rules/editing-claude-md.md` and in the 2026-09-24 entry of
`docs/evidence/root-claude-md.md` § "Preamble". Neither covers an
import inside a scoped rule, and `agent-instructions-scoping.md` § "How
Claude Code loads them" has no bullet on imports.

**Edits**, the probe first:

- `scripts/test-instruction-loading.py` gains the case, so the claim
  re-runs with the rest after a CLI upgrade. Its file kinds are an
  instruction file, one that imports `AGENTS.md`, and text. This needs
  a fourth: a rule with `paths:` frontmatter, a marker and an import,
  expected as `nested_memory` on the Read while its target arrives in
  the launch record.
- `agent-instructions-scoping.md` § "How Claude Code loads them", beside
  the bullet on a rule with no `paths:`: one bullet saying the import
  loads at launch while the rule waits, dated with its CLI version, and
  that a rule sending Claude to another file names it in text.
- `.claude/rules/editing-claude-md.md`: "Never an unscoped rule or an
  `@import`: both load at launch anyway" can say that this holds inside
  a scoped rule too. Its evidence goes to the root ledger, under the
  heading it came from.

## 2. Sort a gotcha by what triggers the mistake, not the file it concerns

The rule's table sends guidance about one kind of file to a `paths:`
rule, and says that home fails silently when "the glob is wrong, or only
Grep, `cat` or a new file touch it". The client repo's trim met one more
case. Its root file held 15 gotchas of the fails-silently kind. 12 were
weighed for a `paths:` home and 8 moved behind one. **4 stayed at root,
though each concerns one kind of file, because the mistake is made
without any Read of that kind of file**:

- adding a new file inside an item folder the portal owns, a Write,
  which loads no rule;
- forgetting the follow-up command after live DDL;
- a live rename or drop in a database whose schema file syncs only
  additively;
- a materialized view created by a sync, which arrives empty.

An edit to an existing file always qualifies for a `paths:` home, since
Edit needs a prior Read. Counted 2026-09-29 by that session in its own
root file, and not re-counted here.

**Edit.** The `paths:` row's "Fails silently when" cell gains the case:
the mistake is a live command or a sync, which touches no file. The
table is already wide, so the addition stays a clause.

## Not checked

- Whether Claude Code's memory page documents the hoisting. The note
  cites no doc, so the claim rests on one probe on one CLI version.
- An import in a user-scope rule, or one naming a file outside the
  repo.
- What the import costs after `/compact`, when root is re-read and a
  `paths:` rule waits for its next Read.

## Verification

- `uv run scripts/test-instruction-loading.py <the new probe>` passes
  twice, in fresh sessions, then the whole set: a FAIL elsewhere means
  the loader moved under `nested-instruction-files.md` too.
- `uv run --with pyyaml scripts/lint-frontmatter.py` on both rules.
- After the merge, `./scripts/link-claude.ps1 -SkillGroups
  workflow,social,meta` from the main checkout, never bare, then `cmp`
  the deployed `~/.claude/rules/agent-instructions-scoping.md` against
  the repo's.
- The rule has no Copilot port, deferred in
  `copilot/.source-hashes.json`, so no port follows.
- `pre-commit run --all-files`.

## Scrubbing

This repo is public. The note was genericized; "a client Fabric repo" is
the citation, and its four gotchas are given by kind.

## Re-measure before acting

- `claude --version`: 2.1.282 on 2026-09-29. The probe is the check,
  and it is cheap.
- `git log -1 --format=%h -- claude/rules/agent-instructions-scoping.md`:
  `833acb0` on 2026-09-30.
- [nested-instruction-files.md](nested-instruction-files.md), whose
  tables this rule now owns, and whose § "Re-measure before acting"
  carries the same trim as input for its Phase 3.
