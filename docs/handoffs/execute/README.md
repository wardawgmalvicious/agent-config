# Open briefs — execution order

Three items remain on the queue: one ready, two deferred.

| Item | State |
| --- | --- |
| [copilot-workflow-skill-port.md](copilot-workflow-skill-port.md) | **Open, written 2026-09-09**, and now small. The Claude-side half — splitting `skills/workflow/` by scope — was **executed the same day**: seven repo-specific skills moved to `.claude/skills/` at project scope, `code-review` and `commit` stayed deployable, and neither script needed a code change. What remains is one judgment call (does a client repo want this repo's `commit` and `code-review`, given `commit` describes three guards that exist only on this machine) and one `copy-copilot.ps1` invocation. Still carries the premise correction worth reading before any Copilot slash-command work: `SKILL.md` **is** slash-invocable there, Copilot Chat's own claim that it is not was wrong, and the real cause was a `model:` key silently blocking dispatch. |
| [drift-fetch-subagent.md](drift-fetch-subagent.md) | **Deferred 2026-09-08 — not declined.** Its validation gate is moot rather than unmet. The baseline it asks for already exists — two inline `powerbi` runs on floor 2026-08-01 in [../../audits/2026-09-07/powerbi/](../../audits/2026-09-07/powerbi/); use `00b`, since the two disagree on the prior ref. And the context failure the agent exists to prevent has never been observed in any run, including the registry's hardest case (the 89-day `claude-code` window). `--sources` already buys per-session isolation for free and the audit ledger is already per-source, so the cheap lever is in place. Re-open on a **single-source** run that compacts mid-Phase-1 or reports files left undiffed; multi-source pressure does not count. Six corrections recorded in the brief must be applied before any drafting. |
| [item-type-skill-fabric-plan.md](item-type-skill-fabric-plan.md) | **Deferred 2026-09-03** — not declined. Step 0 answered *no*: no `*.Plan` item exists in any repo here, and the payload's only mention of Plan pushes work away from it. Waiting on a Plan item appearing, not on anything in this queue. Its carve-out debt was split off and paid separately, so what remains is the skill itself. |

This is the **only** place the execution order lives — each brief carries
its own dependencies but not its position — so read this before starting a
session here.

Waves 1–18 are spent, closed between 2026-08-31 and 2026-09-03 (14
deferred, as above). Their briefs are deleted and their outcomes live in
the artifacts they changed, per the [lifecycle](#lifecycle) below. This
file was pruned to the open work on 2026-09-03 rather than letting the
struck rows accumulate; `git log -p -- docs/handoffs/execute/README.md`
has them in full if a closed decision ever needs re-reading.

## Filenames are stable; order lives here

`/drift-handoff` numbers its output `01-`, `02-`, … and `/drift-update`
walks that order. That works there because a
`docs/audits/<date>/<source-id>/` directory is a **fixed whole**: written
in one pass, executed in one pass, kept together afterwards as a dated
ledger, and its briefs do not cite each other. Numbers are safe where
nothing is ever removed.

`execute/` is the opposite on all three counts. Briefs here are committed,
deleted **individually** as each is spent, and cross-linked by filename —
so the filename is the link target and has to be the stable thing.
Numbering would mean re-linking on every deletion, choosing each time
between renumber-and-relink churn and a queue that reads `05, 07, 09, 10`.
If a brief needs to know it is blocked, that is a dependency and belongs
in the brief. A position is a fact about the queue and belongs here.

## Re-measure a row before acting on it

The queue's two most expensive lessons, and the only ones that still
apply to work not yet done:

- **Wave 17's evidence was never true.** The row specified an MCP template
  as the work; that template had shipped five days *before* the row was
  written, in an ordinary refactor nobody thought to check the queue
  against. Executing it as written would have produced a duplicate entry
  and no new capability.
- **Wave 14's evidence rotted in under two hours.** A grep the brief used
  as its baseline went from zero hits to five between the step 0 answer
  being committed and a re-run the same day — and the new hits pushed
  *away* from the work rather than toward it, so re-running the grep
  without reading it would have inverted the conclusion.

The interval is not the signal, and neither case was detectable without
going and looking. The trap is structural: rows are written *about*
payload directories, but nothing links the two, so a commit outside the
queue can silently satisfy or invalidate a row. **Re-run a row's own
evidence before executing it** — and if it has moved, record which
direction.

## A brief can be a decision rather than an edit

[item-type-skill-fabric-plan.md](item-type-skill-fabric-plan.md) opens
with a recommendation rather than an edit list. `/drift-update` treats a
decision-kind brief as something to put back to the user rather than
execute, and the same applies here. Landing a **no** is a real outcome —
record the reasoning in the commit that deletes the brief, or the question
gets re-opened by whoever notices the gap next.

Six such briefs are spent: five "yes" and one "no", so the column has not
been a rubber stamp. **Defer** is a third outcome, and the only one that
leaves a file behind — don't read the surviving brief as an unanswered
question. Delete it only if the workload is abandoned upstream or ruled
out outright, and record which.

## Before touching any `paths:` glob

Run the static check — `./scripts/test-activation.ps1 -Set fabric
-StaticOnly`, then `-Set pbip`. Every glob bug this queue ever contained
was found that way and none was findable any other way: the linter checks
glob *syntax*, and these were all well-formed globs that were wrong about
the world. Derive skill counts the same way rather than restating a total
here — each figure is owned by its set's `expected_activations.md`, and
the last one that got duplicated into prose drifted three ways at once.

## Lifecycle

Unchanged from [../README.md](../README.md): **once the change lands, the
brief is deleted**, and git history is the archive. Deleting one is not
just an `rm` — **re-point whatever linked to it in the same commit**, and
the test is that no surviving brief still says "read it there" about a
file that is gone.

When the last brief goes, this file is left as a heading and these
conventions. That is its correct resting state, not a sign something was
lost.
