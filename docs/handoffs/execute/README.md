# Open briefs — execution order

Eight items remain on the queue: four open and four deferred. Every
deferral names the trigger that would re-open it; none has fired.

| Item | State |
| --- | --- |
| [msix-packaging-skill.md](msix-packaging-skill.md) | **Open, written 2026-09-10** as the remainder of the C# rules brief, renamed from `coding-csharp-rules.md` when its two rules shipped the same day. Those rules, [coding-csharp.md](../../../claude/rules/coding-csharp.md) and [coding-xaml.md](../../../claude/rules/coding-xaml.md), took the reference WinUI repo from 2% to 80% covered. What is left is packaging — `.appxmanifest`, `.appinstaller`, signing and versioning — which is procedure-shaped and so a skill for `/author-skill`, not a rule. Nothing is drilled. One design question is left open deliberately: whether a `paths:` glob helps, when a packaging request usually arrives as words rather than as a manifest being read. Also carries three code-review findings about the reference repo's project files, which are not payload content. |
| [fabric-event-schema-set.md](fabric-event-schema-set.md) | **Open, written 2026-09-10.** The Fabric Event Schema Set item — the last unclaimed item in the `fabric-*` family's item-per-skill split, and the contract that silently drops any event not matching it. Written from a **live verification session, not documentation**: two plausible Learn URLs 404 and the surface appears genuinely undocumented, so every claim is one tenant on one date and the brief says to frame it that way. Headline finding — a doc-only edit synced from Git **did not bump the schema version**. Whether a portal edit does was never observed, so *why* is two live hypotheses (edit path vs canonical-form change), and **one cheap portal test decides it — run it before drafting**. Until then the draft leads with a rule true under both: read `versions[]` back after any edit. `fabric-eventstream`'s `references/cloudevents-producer.md` states flatly that editing a schema mints a new version, so that paragraph needs qualifying in this repo's source. Corrected 2026-09-10 after the first revision, written without this repo's guidance loaded, stated the portal half as observed and carried client names. Item structure and per-file line endings are captured for a test fixture; `paths: "**/*.EventSchemaSet/**"` follows the house pattern, and the brief records what that glob costs. |
| [handoff-convention-cross-repo.md](handoff-convention-cross-repo.md) | **Open, written 2026-09-16.** Generalize this repo's handoff discipline to the two other repos that have started growing handoff directories on their own — `machine-config` (private, one brief, created 2026-09-16 by an outbound `/learn` run, and **indexed to this brief's Q1 shape the same day** — the first worked instance) and a client estate repo (internal, three briefs, no index), the latter likely to be the second-highest-churn repo here. Measured 2026-09-16: the brief *shape* is already converging unprompted — all three estate briefs carry a `**Status:**` line that nobody standardized — so the gap is **the index**, which is the part this repo learned the hard way (order in exactly one file, no positions in filenames, a spent row invites re-execution). Proposes a minimal eight-point core plus a per-repo index and **explicitly not a shared template**, which could not span skill authoring, shell config and estate work without collapsing into generic headings. Two rules are new because briefs now cross repo boundaries: **scrubbing is decided by the destination's visibility, not the origin's**, and direction — local / outbound / inbound — has to be declared per directory, which none does today. **Q1 and Q2 were answered 2026-09-16**, the day the brief was written, and the brief's own argument against the rule form is **retracted** in its Decisions section — three of the eighteen rules are already "what belongs where" conventions. The rule form is ruled out on activation mechanics instead: `defaultMode` is `auto`, activation is keyed to the `Read` tool so `cat` fires nothing, and the trigger here is *writing* a brief into a directory that holds none — which no glob can see. Q1's answer is to **extend `/learn`** rather than add any of the three proposed forms: invariants into `skills/meta/learn/references/`, the hand-written `~/.copilot/instructions/cross-repo-handoffs.instructions.md` ported into `copilot/instructions/` so it is versioned and reaches both harnesses, and a **stub** README per handoff directory carrying direction, visibility and the index only. A `/handoff` skill was declined on measured overlap — `author-skill + learn` is already the top pair at 32.88. Q2: the inbox **widens**, routed by a directory per destination — done 2026-09-16, with `~/handoff-inbox/README.md` carrying the layout; the reader pointer landed the same day as `f931d5b`, since nothing had told a session to *read* the inbox, so it is now a paragraph in `claude/CLAUDE.md` § "Agent config source", deployed and verified against the live file. Q3 (does delete-when-spent suit a client repo) and Q4 (does an index collide with a real tracker) stay open and **do not block drafting** — each directory's stub declares them. |
| [peer-coordination-open-questions.md](peer-coordination-open-questions.md) | **Open, written 2026-09-17.** Successor to `peer-session-coordination.md`, whose three edits landed 2026-09-16 and which was closed 2026-09-17 after its own Verification section was finally run — four cold `claude -p` sessions, $6.44, and **two of the four tests failed**. Carries one piece of work and four questions. The work: **the peer channel is in the wrong skill.** It shipped in `commit` § "When another session shares this tree", but contention bites at *edit* time and a session editing a contended file never invokes `/commit` — demonstrated by a probe that struck a queue row with careful, correct work (it verified the prior edits had landed, checked inbound links and line endings, stopped short of committing) and never once called `ListAgents` while a peer was live in the tree. Where it belongs instead is undecided between three candidates; the `paths:` rule form is already ruled out on activation mechanics. Two premises of the predecessor were disproved and fixed the same day in `9055bfc`: **`ListAgents` keys on the session's cwd basename, not its repo** — a probe run in `skills/` named itself `skills-f3`, and the old claim held only because every session ever measured happened to sit at a repo root — which had licensed `commit` and `learn` to match peers by repo-name prefix and so miss any peer working in a **subdirectory**, which is where you work in a large repo; and **Q4's reasoning inverts**, $0.12 being a floor rather than a price (a one-tool-call haiku probe costs $0.099, almost all of it payload cache creation) and a cold probe being *cheaper* than reading another repo yourself, since the caller never pulls that repo into its own context. Q3 is answered: a spawned probe **is** visible to peers, for its lifetime only. Two questions are new. Whether delegating an edit to your own **subagent** differs from asking a peer, raised by a probe that correctly declined the peer and then offered the subagent for the same edit. And that **the inbox is mutable state the read-only rule never covered** — a peer refused this repo's own session a note deletion, on the grounds that a peer's word is not authorization for a delete and the call belongs to a user, and it was right. |
| [drift-fetch-subagent.md](drift-fetch-subagent.md) | **Deferred 2026-09-08 — not declined.** Its validation gate is moot rather than unmet. The baseline it asks for already exists — two inline `powerbi` runs on floor 2026-08-01 in [../../audits/2026-09-07/powerbi/](../../audits/2026-09-07/powerbi/); use `00b`, since the two disagree on the prior ref. And the context failure the agent exists to prevent has never been observed in any run, including the registry's hardest case (the 89-day `claude-code` window). `--sources` already buys per-session isolation for free and the audit ledger is already per-source, so the cheap lever is in place. Re-open on a **single-source** run that compacts mid-Phase-1 or reports files left undiffed; multi-source pressure does not count. Six corrections recorded in the brief must be applied before any drafting. |
| [item-type-skill-fabric-plan.md](item-type-skill-fabric-plan.md) | **Deferred 2026-09-03** — not declined. Step 0 answered *no*: no `*.Plan` item exists in any repo here, and the payload's only mention of Plan pushes work away from it. Waiting on a Plan item appearing, not on anything in this queue. Its carve-out debt was split off and paid separately, so what remains is the skill itself. |
| [coding-yaml-ci-rule.md](coding-yaml-ci-rule.md) | **Deferred 2026-09-10 — not declined**, and wanted. Blocked on evidence rather than on anything here: eleven `.yml`/`.yaml` files existed across every repo on this machine as of that date, which is not a corpus to measure conventions from, and `coding-markdown.md` only worked because 215 files were. The brief scopes it to CI workflow **semantics** rather than YAML syntax — permissions inheritance, mutable action tags, `pull_request_target`, expression injection, a `paths:` filter that silently skips — every one a case where the run is green and the thing you wanted did not happen. Re-open when a workflow is actually being written or debugged; the ones that already exist are not the trigger and never were. |
| [skill-portfolio-audit.md](skill-portfolio-audit.md) | **Deferred 2026-09-10 — not declined.** A skill to find similar skills before authoring, and to recommend consolidation and deprecation across the set. Every part found a cheaper home: the pre-authoring check goes into `author-skill` §2 via [`scripts/skill-overlap.py`](../../../scripts/skill-overlap.py), repos the payload does not cover are `payload-coverage.py`'s, and the outside-repo scope collapsed to the one authoritative catalog — now `drift-audit`'s `skills-for-fabric` source — because ~2,800 outside `SKILL.md` hits were mostly aggregator copies. **Listing cost is not the reason**, unlike the 2026-09-03 telemetry-skill decline: project scope removed it. Re-open when a script run needs more than its legend, or a second authoritative catalog appears. Depends on the script. |

Re-measured 2026-09-11: none of the three open rows then listed has moved, and none
of the four deferral triggers has fired.

This is the **only** place the execution order lives — each brief carries
its own dependencies but not its position — so read this before starting a
session here.

Waves 1–18 are spent, closed between 2026-08-31 and 2026-09-03 (14
deferred, as above). Their briefs are deleted and their outcomes live in
the artifacts they changed, per the [lifecycle](#lifecycle) below. This
file was pruned to the open work on 2026-09-03 rather than letting the
struck rows accumulate; `git log -p -- docs/handoffs/execute/README.md`
has them in full if a closed decision ever needs re-reading.

## Audit briefs are a second queue

`/drift-handoff` writes to `docs/audits/`, not here, and `/drift-update`
walks those briefs in their own numbered order — so an unexecuted audit
run is pending work this table does not list. A brief there with no
`## Execution log` section has not been executed, and each directory's
generated `README.md` says which those are in one table — read it before
opening briefs.

**A stamped brief can still be pending.** `/drift-update` stamps every
brief it escalates, so the next run skips it and the rule above reads it
as done, while the work its answer implies — or a deferral it recorded —
lives only in that brief's log. Found 2026-09-11: everything below had
been stranded that way. Entries are grouped by what each needs, not
ordered; delete one in the commit that lands its work. Deferred re-checks
are not listed — the next audit of that source is what performs them.
Read a brief's log to its end before listing it: a decision can sit in a
subsection after the stamp, as powerbi 07's 2026-09-08 decline did.
When a row's work lands, append a `**Closed**: <date> — <how>` line to
that brief's log in the same commit that deletes the row, so the
directory index shows the brief as `closed` rather than open forever.

| Needs | Audit briefs |
| --- | --- |
| A person driving Power BI Desktop | [powerbi 04](../../audits/2026-09-07/powerbi/04-catalog-new-visual-formatting-properties.md) with [10](../../audits/2026-09-07/powerbi/10-supply-drilled-evidence-for-matrix-properties.md) and [13](../../audits/2026-09-07/powerbi/13-propagate-new-formatting-to-authoring-skills.md) D-1 · [06](../../audits/2026-09-07/powerbi/06-verify-pbip-autodetect-vs-reload-bridge.md), which also needs the `powerbi-desktop` bridge CLI · [02](../../audits/2026-09-07/powerbi/02-retire-fluent2-preview-framing.md)'s 1280×720 carve-out |
| A model export with AI instructions set | [skills-for-fabric 05](../../audits/2026-09-10/skills-for-fabric/05-add-lsdl-refresh-to-ai-instructions.md)'s TMDL collision |
| A Git-synced Fabric repo to measure in | [skills-for-fabric 04](../../audits/2026-09-10/skills-for-fabric/04-measure-notebook-serialization-before-editing.md) |
| One open question settled, then lint code | [skills-for-fabric 08](../../audits/2026-09-10/skills-for-fabric/08-decide-catalog-budget-and-reference-lints.md): the **catalog listing-budget check only**. Its reference-lint half landed 2026-09-15 as `scripts/skill-overlap.py routing`, wired into pre-commit as `lint-skill-routing`, which settles that half's open question — what counts as a reference is a backticked platform-prefixed name, with every non-skill class derived or excluded by path. What is left needs the budget itself, and that must come from Claude Code's docs rather than upstream's numbers |

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

## A brief in `execute/` is not necessarily in this table

`/author-skill` writes its brief to `docs/handoffs/execute/<name>.md` and
says it **stays queued**, but it never edits this file — so a brief can
sit in the directory while the table above does not mention it. Measured
2026-09-10: the `linkedin-highlights` brief was written, spent and
deleted without ever appearing here.

That is usually harmless. An author-test-land cycle finishing in a
sitting or two would add a row and strike it the same day, and the brief
is discoverable by `ls` throughout. It matters when the cycle **stalls**,
because the brief is then invisible to the instruction above to read this
file before starting a session — the one hole in this file's claim to own
the order.

So add a row when a brief in `execute/` **outlives the session that wrote
it**, and not before. Same-day work does not need one.

Since 2026-09-12 `/test-skill` deletes the brief at its last step, so a
skill brief here beside a skill that exists means the test has not run.
Before that, nothing removed one: the `fabric-catalog-governance` brief
outlived its test by a day with no row here and no reader. The test
state itself is never tracked in this file. Derive it, at the start of
a session here and alongside reading this table:

```bash
uv run --with pyyaml scripts/skill-status.py --stale
```

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

Seven such briefs are spent: five "yes" and two "no", so the column has
not been a rubber stamp. **Defer** is a third outcome, and the only one that
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
