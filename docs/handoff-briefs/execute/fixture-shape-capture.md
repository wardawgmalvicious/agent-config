# Handoff: capture real `.DataAgent` and `.SQLDatabase` exports

- **Written**: 2026-08-31, from the trigger-fixture work (`9d49302`).
- **Kind**: verification chore. Small, but it removes a class of silent
  error that nothing else can catch.
- **Status**: open. The user offered to spin up both items; this brief is
  the reminder and the acceptance criteria.
- **Run in**: any session, once an export exists.

## Why this matters more than it looks

Three fixtures in `tests/skills/fabric-triggers/` are built on **item-type
folder names that no live export has confirmed**:

| Fixture | Skill | Glob | Name asserted by |
| --- | --- | --- | --- |
| `SampleAgent.DataAgent/` | `fabric-data-agent` | `**/*.DataAgent/**` | the skill itself |
| `SampleSQL.SQLDatabase/` | `fabric-database` | `**/*.SQLDatabase/**/*.sql` | the skill itself |
| `SampleGraph.GraphModel/` | `fabric-graph` | `**/*.GraphModel/**` | the skill, citing fabric-cli and the `/GraphModels` REST collection |

The fixture was built from the skill's own claim about the folder name. So
**if the claim is wrong, the fixture agrees with the wrong glob instead of
catching it.** These three rows prove that glob and path are consistent
with each other; they cannot prove either is right. Every other fixture in
both trigger sets is verified against a live Git-synced repo.

A wrong item-type name has no error path — the skill simply never fires,
in every client repo, forever. Same failure mode as A1, and as the three
bugs in [rule-glob-gaps.md](rule-glob-gaps.md).

`GraphModel` is listed here too, though the user did not name it. Same
defect, same fix, and [rule-glob-gaps.md](rule-glob-gaps.md) bug 3 is
blocked on it — do not add `**/*.GraphModel/**` to
`fabric-git-serialization.md` until the name is confirmed, or the error
propagates into a second file.

## What to capture

For each item: create one in a workspace, Git-sync it, and record from the
**repo side** (not the portal):

1. The **folder name suffix** exactly as serialized — this is the whole
   point. `.DataAgent`? `.AISkill`? something else?
2. The **file list** inside it, including dotfiles.
3. `.platform` → `metadata.type` — the item type string, which may differ
   from the folder suffix.
4. Enough of each definition file's structure to build a synthetic stub.

`fab` can list a workspace's items if the portal is inconvenient — see
`fabric-cli`. Pass `-f`; per root `CLAUDE.md` it blocks on an interactive
prompt otherwise.

## Then

1. Replace the fixture folder with a synthetic file set on the real shape.
   **Do not copy the export.** Zero every GUID, drop workspace names,
   cluster URIs and connection strings. `tests/` is gitleaks-allowlisted,
   so the allowlist will not catch a real secret that lands there.
   `SampleAgent.DataAgent/SHAPE-UNKNOWN.md` is a placeholder with no shape
   claim — delete it once the real shape is in.
2. **If a name was wrong, fix the skill's `paths:` first.** That is the
   actual bug; the fixture is only how you found it. Note it in
   [skill-context-cost.md](skill-context-cost.md), whose A2 audit concluded
   all 19 globs were sound — an unverified name is a hole in that
   conclusion, and the brief should say so.
3. Re-run the static check in `tests/skills/fabric-triggers/README.md` and
   update `expected_activations.md` — including removing the row from
   "Fixtures built on an unverified shape" in the README.
4. `pre-commit run --all-files`, `/commit`.

## While you have a live item anyway

Two cheap things worth grabbing in the same sitting, since spinning the
item up is the expensive part:

- **`.DataAgent`** — the skill's body was cut 57% in `6d6dbb8` on the
  assumption its `references/` split was faithful. A real export is the
  first chance to check the configuration-layer detail against reality.
- **`.SQLDatabase`** — confirm whether the `.sqlproj` sits at the item
  root and whether object folders are `dbo/Tables/` or flat. The current
  glob (`**/*.SQLDatabase/**/*.sql`) needs at least one directory level
  between the item folder and the `.sql` file; **a flat layout would not
  match it.** That is a live bug risk, not a cosmetic one.

## Acceptance

This brief is spent when all three rows are gone from the README's
"Fixtures built on an unverified shape" section — not when the items exist
in a workspace. If only one of the three gets captured, keep the brief and
strike that row from the table above.
