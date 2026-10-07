# Handoff: correct the instruction-load trigger set

- **Audit run**: 2026-10-06
- **Source**: `claude-code`
- **Window**: floor `2026-08-30` (base `f1af9b1f`, 2026-08-28) → head
  `fbe20e00` (2026-10-06)
- **Covers recommended actions**: 2
- **Kind**: factual correction to committed prose in six files; D-2 alone
  is a measurement for a cold probe session
- **Target**: `CLAUDE.md`, `.claude/rules/editing-rules.md`,
  `.claude/rules/activation-testing.md`,
  `.claude/rules/editing-claude-md.md`,
  `claude/rules/agent-instructions-scoping.md`, `claude/rules/README.md`

## The problem

Six files say a path-scoped rule or a nested `CLAUDE.md` loads only when
the session Reads a matching file. Since Claude Code 2.1.288 a Write or
an Edit loads them too, the load arriving with the tool's result.
Whether a skill's `paths:` glob fires on an Edit is not established.

## Evidence

- `CHANGELOG.md` 2.1.288, verbatim:
  > Fixed path-scoped `.claude/rules` and nested CLAUDE.md files not
  > loading when Write or Edit creates or changes a file in their scope
  > (previously only Read loaded them)
- https://code.claude.com/docs/en/memory#path-specific-rules, read
  2026-10-06:
  > Path-scoped rules trigger when Claude uses the Read, Write, or Edit
  > tool on a file matching the pattern, not on every tool use.

**State when this brief was written (2026-10-07, HEAD `57b30b1`).**
Another session's uncommitted edit in the main checkout already corrects
most of the targets below. It rests on an entry it added to
`docs/evidence/root-claude-md.md`, dated 2026-10-06: six cold haiku arms
on 2.1.291 in which a Write loaded a matching rule, a `sub/CLAUDE.md`
beneath it, and, with `Skill` in `--tools`, a conditional skill's
listing delta. It measured Write, not Edit, and only files inside the
working directory. It landed on `main` as `6751e6e`, "docs(rules):
record that a Write loads rules and nested CLAUDE.md", before this
directory was committed. Per target, as it landed:

| Target | In `6751e6e` |
| --- | --- |
| 1 and 3: `CLAUDE.md` table row, § "Editing conventions" | untouched |
| 2 and 4: `CLAUDE.md` § "How the pieces trigger", § "Validating a change" | corrected to Read or Write |
| 5: `.claude/rules/editing-rules.md` | corrected |
| 6: `.claude/rules/activation-testing.md` | corrected, plus a new `--tools` bullet |
| 7: `.claude/rules/editing-claude-md.md` | corrected |
| 8: `claude/rules/agent-instructions-scoping.md` | corrected |
| 9: `claude/rules/README.md` § "How they trigger" | untouched; the file's scoping entry was corrected |

## D-1 — six files name Read as the only trigger

**Symptom.** At HEAD `57b30b1`:

1. `CLAUDE.md`, the structure table's `.claude/rules/` row, last cell:
   > in sessions here only: skills immediately, a rule at its next
   > matching Read
2. `CLAUDE.md` § "How the pieces trigger":
   > which hides it from the startup listing until a matching file is
   > Read
3. `CLAUDE.md` § "Editing conventions", first bullet:
   > the Read is what loads its `.claude/rules/` guidance
4. `CLAUDE.md` § "Validating a change":
   > Activation is keyed to the Read tool, not `cat` or `Grep`
5. `.claude/rules/editing-rules.md`, first bullet:
   > A rule carries only `paths:`, and loads when a file matching it is
   > Read.
6. `.claude/rules/activation-testing.md`, first bullet:
   > Activation is keyed to the `Read` tool, not to the file
7. `.claude/rules/editing-claude-md.md`:
   > A nested `CLAUDE.md` loads on the session's own first Read beneath
   > it, never at launch, and after `/compact` only at the next Read
   > there
8. `claude/rules/agent-instructions-scoping.md` § "How Claude Code loads
   them":
   > A subdirectory's loads on the session's own first Read beneath it,
   > after its ancestors'. Write, Grep, Glob and Bash load nothing
9. `claude/rules/README.md` § "How they trigger":
   > When a file matching one of those globs enters Claude Code's
   > session scope (via Read, session-context, or an agent inspecting
   > the working tree), the rule is loaded into context.

**Cause.** Each was true until 2.1.288.
**Fix.** Name Read, Write and Edit as what loads a rule or a nested
`CLAUDE.md`, in whatever wording has landed by then. Target 3 is
arguable: "Read a file before changing it" stays right, since a Write's
or an Edit's load arrives after the change it should have governed, so
keep the instruction and correct only its reason. In target 9, "an
agent inspecting the working tree" is wrong too: a subagent's Read loads
into the subagent only (`agent-instructions-scoping.md`).
**Knock-on.** A root `CLAUDE.md` edit moves its evidence to
`docs/evidence/root-claude-md.md` under the same heading
(`.claude/rules/editing-claude-md.md`).

## D-2 — whether a skill's `paths:` fires on an Edit is unmeasured

**Symptom.** Rules and nested `CLAUDE.md` are documented for all three
tools. Skills are documented for none: the 2.1.288 bullet names rules
and nested files only, and the in-flight measurement covered Write.
**Cause.** No source states it.
**Fix.** A cold probe, not run in a drift-update session: the in-flight
entry's set-up with an Edit arm, one conditional skill and one rule
globbing `**/*.probe`, haiku, `--tools Edit,Skill`, and a matching file
that exists before the session starts. Read the transcript's
`skill_listing` and `nested_memory` records
(`.claude/rules/activation-testing.md`), then name Edit in the
activation wording, or record that it does not load a skill.

## Constraint on the fix

Say what each tool's evidence is: Write measured (2026-10-06, 2.1.291),
Edit documented for rules and nested files and not measured here. Do not
widen any claim to files outside the working directory: the in-flight
entry records one warm Write there that loaded nothing, not isolated.

## Sequencing note

Start from `main` at or after `6751e6e`, and re-read each target right
before editing: the staleness gate will find most quotes in D-1 gone,
and the post-fix text is that commit's. Brief 09
D-2 also edits `.claude/rules/activation-testing.md`; do not bundle the
two, since 09 waits on a probe of its own.

## Verification

1. The first command below finds no hit, and the second prints a count
   above zero for every file:

   ```bash
   grep -n -E 'next matching Read|until a matching file is Read|keyed to the `?Read`? tool|Write, Grep, Glob and Bash load|via Read, session-context' CLAUDE.md .claude/rules/*.md claude/rules/*.md
   grep -c -E 'Read`?(,| or| and) `?Writ' CLAUDE.md .claude/rules/editing-rules.md .claude/rules/activation-testing.md .claude/rules/editing-claude-md.md claude/rules/agent-instructions-scoping.md claude/rules/README.md
   ```

2. Target 3 read by eye: the instruction kept, its reason corrected.
3. `uv run scripts/lint-claude-md.py`
4. `uv run --with pyyaml scripts/lint-frontmatter.py .claude/rules/editing-rules.md .claude/rules/activation-testing.md .claude/rules/editing-claude-md.md claude/rules/agent-instructions-scoping.md claude/rules/README.md`
5. `pre-commit run --all-files`. `agent-instructions-scoping` sits under
   `deferred` in `copilot/.source-hashes.json`, with no port, so no
   stamp is due.
6. From the main checkout,
   `./scripts/link-claude.ps1 -SkillGroups workflow,social,meta`, then
   `diff claude/rules/agent-instructions-scoping.md ~/.claude/rules/agent-instructions-scoping.md`
   and the same for `README.md` — no output.
7. D-2: the probe's transcripts, cited in a dated entry in
   `docs/evidence/root-claude-md.md`.

## Provenance

The 2026-10-06 `claude-code` run read the 2.1.288 bullet in its
changelog diff and the memory docs the same day. The Write measurement
is another session's, found uncommitted in the working tree while this
brief was being written, landed as `6751e6e`, and not re-run here.

## Execution log

- **Executed**: 2026-10-07 — applied with deferrals (D-1 applied, D-2
  escalated)
- **Session**: fresh (no audit or handoff run in this session; the whole
  pass, in its own worktree)
- **Files changed**: `CLAUDE.md`, `claude/rules/README.md`,
  `docs/evidence/root-claude-md.md`
- **Verification**: the staleness gate matched this brief's table:
  targets 1, 3 and 9 still carried their quotes, 2 and 4 to 8 held
  `6751e6e`'s post-fix text, and no commit had touched a target since.
  Target 9's quote spans lines 19–20, so step 1's pattern could not see
  it even before the fix. Step 1 — **failed as written, on two artifacts
  the user accepted** (Deviations): the first command's one hit is
  `claude/rules/agent-instructions-scoping.md:51`, and the second counts
  1 to 3 in five files and 0 in `.claude/rules/editing-rules.md`. Step 2
  — **passed**: target 3 keeps "Read a file before changing it", with
  the corrected reason. Step 3 — **passed**: `lint-claude-md.py`, root at
  200 of 200. Step 4 — **passed**: `lint-frontmatter.py` on the five
  rule files, exit 0. Step 5 (`pre-commit run --all-files`) runs once at
  the end of the run.
- **Deferred**: step 6 needs the deployed payload, which the worktree
  cannot reach: from the main checkout after the landing,
  `link-claude.ps1 -SkillGroups workflow,social,meta`, then the two
  diffs. Step 7 is D-2's.
- **Open question**: D-2, put to the user, who chose a fresh session of
  its own for the probe, as the brief's **Fix** describes it.
- **Deviations**: step 1's two results are pattern artifacts, put to the
  user, who accepted them as such, so neither spot was edited. Line 51
  reads "next matching Read or Write", `6751e6e`'s own correction, which
  the pattern written for target 1 also matches. `editing-rules.md`'s
  "Read / or Written" wraps across a line; with the lines joined, the
  second command's pattern finds it once. Three notes. Target 9's
  "session-context" went with the parenthetical, since the fix names the
  documented triggers and it is none of them. Targets 1 and 3 each got a
  dated entry under their heading in the root ledger, the **Knock-on**.
  Target 3 stays three lines, since root sits at its cap.
- **Needs**: a cold probe session, the landing — D-2's Edit probe, in
  the session that also runs brief 04's D-1, cited in a dated
  root-ledger entry, then Edit named in the activation wording or
  recorded as loading no skill (step 7); and step 6's deploy and two
  diffs, run on `main`.
- **Needs**: a cold probe session — D-2's Edit probe, in the session
  that also runs brief 04's D-1, cited in a dated root-ledger entry, then
  Edit named in the activation wording or recorded as loading no skill
  (step 7). Step 6 is done: `link-claude.ps1` ran on `main` at
  `4d473d7`, and both deployed files match the repo (`diff`,
  2026-10-07).
- **Closed**: 2026-10-07 — by the cold probe session that also ran brief
  04's D-1. D-2's six haiku `claude -p` arms on 2.1.291 are cited in the
  root ledger's 2026-10-07 entry under § "Validating a change" (step 7):
  an Edit fires a skill's `paths:`, even one refused for want of a
  `Read`, and loads a rule or nested `CLAUDE.md` only once it applies.
  Edit is now named in root's § "How the pieces trigger" and
  § "Validating a change" and in `.claude/rules/activation-testing.md`,
  which also gained the refused-Edit split. The **Fix**'s design cannot
  apply an Edit, since a file present before the session starts is
  refused until it is Read, so two arms had Edit create their file, and
  the refusals answered the skill question themselves. Steps 3, 4 and 5
  passed again, and step 1 returned the two artifacts accepted above,
  unchanged.
