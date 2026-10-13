# `fabric-rest-api` — behaviour cases

`fabric-rest-api` took in `fabric-auth`, `fabric-cli` and
`fabric-gotchas` on 2026-10-12, as `references/auth.md`, `cli.md` and
`gotchas.md`, the last recast as an index from a symptom to the
reference or skill that owns its fix. It is unconditional, so it has no
activation contract; these four cases test that its router reaches each
reference, and that the answer keeps what the old skill carried.

## The cases

| Case | Passes when |
| --- | --- |
| `spn` | names the tenant setting and a workspace role, not more API permissions, after reading `references/auth.md` |
| `fab` | reads `references/cli.md`; mints `FAB_TOKEN` for the Power BI audience, with `FAB_TOKEN_ONELAKE` beside it |
| `err` | the index names the error's owner, `fabric-variable-library`, and the answer carries its two causes and the `FILL-ME` placeholder |
| `lro` | answers from the body, reading no reference |

The prompts, verbatim:

```text
spn: Our Azure DevOps pipeline calls the Microsoft Fabric REST API as a service principal. Its Entra app registration has the Fabric API permissions Workspace.ReadWrite.All and Item.ReadWrite.All, granted with admin consent, and the pipeline gets its token for https://api.fabric.microsoft.com/.default. GET https://api.fabric.microsoft.com/v1/workspaces/{workspaceId}/items still answers 401, and sometimes 403. What exactly do I need to change for this to work?

fab: I installed the Fabric CLI, fab, with uv, and I am already signed in with az login. Give me the exact commands to list the semantic models in our workspace named Sales Analytics, from a script that runs with no browser.

err: Update from Git on our Fabric workspace fails, and the error names our variable library item: InvalidContent (first issue: ValueMismatch). What causes it, and how do I fix it so the next sync passes?

lro: In a Python script I call POST https://api.fabric.microsoft.com/v1/workspaces/{workspaceId}/items/{itemId}/getDefinition. Sometimes it answers 202 Accepted with an empty body. Show me the code that waits for the operation to finish and returns the definition parts.
```

`err` names a glob-scoped owner on purpose: `fabric-variable-library`
answers `Unknown skill` until a `.VariableLibrary` file is read, so the
case also tests the index's line on reaching such an owner.

## Running them

Build a probe outside this repo, since `.claude/settings.json` here
collapses every platform description to `name-only`:

- `router/.claude/skills/`: a copy of every folder in `skills/fabric/`.
- `old/.claude/skills/`: the same at the commit before the fold,
  exported with `git archive c45e5cc skills/fabric`.
- `baseline/`: no `.claude/`, run with `--safe-mode`.

Run each case in each arm from that arm's directory, with
`CLAUDE_CODE_DISABLE_GIT_INSTRUCTIONS=1`, as
[`../fabric-deploy/README.md`](../fabric-deploy/README.md) does and for
its reasons:

```powershell
claude -p '<prompt>' --output-format stream-json --verbose --tools Skill,Read --strict-mcp-config --model claude-opus-5-5 --effort xhigh --max-budget-usd 3
```

Add `--safe-mode` on the baseline. The slash arm is
`/fabric-rest-api <fab prompt>` in the router arm, launched from
PowerShell, since Git Bash rewrites a leading `/`. All 13 runs can go at
once: `--tools Skill,Read` leaves no arm a way to see another.

Read the `init` record for `tools` (2 on every arm) and
`slash_commands`, which must drop on the baseline and lose every Fabric
skill; then the `Skill` and `Read` calls, and the first `result`.

## Result, 2026-10-12

The router held: it routed as the four did on every case. One run per
arm, on 2.1.293, Opus 5.5 at `xhigh`, against the fold's fourth commit,
which the arms read as `6fb7c79` in the brief's worktree before its
rebase:

| Case | Router | The old four, at `c45e5cc` | Baseline |
| --- | --- | --- | --- |
| `spn` | pass: `auth.md`, then `gotchas.md`, read; the tenant setting scoped to a security group, a workspace role, and the API permissions removed, quoting Learn | pass: `Skill fabric-auth`; the same | partial: the setting and the role, unaided; it says to leave the API permissions in place, where Learn advises adding none |
| `fab` | pass: `cli.md` and `auth.md` read; `FAB_TOKEN` for the Power BI audience, both tokens, and `fab auth status` warned off | pass: `Skill fabric-cli`; the same | fail: `FAB_TOKEN` minted for `api.fabric.microsoft.com`, which `fab` rejects, and `fab auth status` offered as the check, which crashes without `FAB_TOKEN_AZURE` |
| `err` | pass: `gotchas.md`, then `fabric-variable-library/SKILL.md`, read by path; both causes, dated 2026-08-06, and `FILL-ME` | pass: `Skill fabric-gotchas`, then the same `SKILL.md` by path; the same | fail: diagnosed a type mismatch; named neither cause |
| `lro` | pass: answered from the body, no reference read; the `'{}'` body against a 411, and polling the base URL since `Location` can name a regional host | pass: `Skill fabric-rest-api`; the same | pass, unaided: the polling pattern |

The slash arm made no `Skill` call and read `cli.md` and `auth.md`
straight from the inlined body, which witnesses the expansion, and kept
the Power BI audience.

`init` gave `tools` 2 on every arm, and `slash_commands` 77 on the
router, six unconditional Fabric skills among them, 80 on the old arm,
nine, and 58 on the baseline, none.

`fab` and `err` separate from the baseline; `spn` separates only on
Learn's advice to add no API permissions, and `lro` witnesses routing
only.

**The glob-scoped hop**: the router's `err` arm read the owner's
`SKILL.md` by path, as the index's opening says to. The old arm made the
same hop from `fabric-gotchas`, which says nothing of the kind, so this
run shows the hop works, not that the line is needed.

**Listing**: the router's entry is 1,010 characters, 580 of description
and 430 of `when_to_use`, against the four's 3,507.

**Cost**: router arms $1.86 with the slash arm, old-four arms $1.21,
baseline arms $0.43.

**What the run cannot show**: variance, with one run per arm; whether
an error with no owner reachable by path routes as well; and the client
repos' listing, which runs to its cap, while this probe lists the Fabric
group alone.

## Not yet measured

Use in client work. After a few weeks of client sessions, run
`uv run --with pyyaml python scripts/skill-telemetry.py triggers`: is
`fabric-rest-api` invoked when auth, CLI or error work happens? Before
the fold, on 2026-10-12, each of the four was listed in 109 sessions,
with 2 Skill-tool dispatches for `fabric-auth`, 1 for `fabric-cli`, 3
for `fabric-gotchas` and 3 for `fabric-rest-api`. Discount this run's
own arms, which sit in this machine's transcripts too: the old arms add
one dispatch to each of the four, and the router arms four to
`fabric-rest-api`.
