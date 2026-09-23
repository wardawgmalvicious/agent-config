# Open briefs — execution order

Thirteen items remain on the queue: nine open and four deferred. Every
deferral names the trigger that would re-open it; none has fired.

| Item | State |
| --- | --- |
| [msix-packaging-skill.md](msix-packaging-skill.md) | **Open, written 2026-09-10** as the remainder of the C# rules brief, renamed from `coding-csharp-rules.md` when its two rules shipped the same day. Those rules, [coding-csharp.md](../../../claude/rules/coding-csharp.md) and [coding-xaml.md](../../../claude/rules/coding-xaml.md), took the reference WinUI repo from 2% to 80% covered. What is left is packaging — `.appxmanifest`, `.appinstaller`, signing and versioning — which is procedure-shaped and so a skill for `/author-skill`, not a rule. Nothing is drilled. One design question is left open deliberately: whether a `paths:` glob helps, when a packaging request usually arrives as words rather than as a manifest being read. Also carries three code-review findings about the reference repo's project files, which are not payload content. |
| [fabric-event-schema-set.md](fabric-event-schema-set.md) | **Open, written 2026-09-10.** The Fabric Event Schema Set item — the last unclaimed item in the `fabric-*` family's item-per-skill split, and the contract that silently drops any event not matching it. Written from a **live verification session, not documentation**: two plausible Learn URLs 404 and the surface appears genuinely undocumented, so every claim is one tenant on one date and the brief says to frame it that way. Headline finding — a doc-only edit synced from Git **did not bump the schema version**. Whether a portal edit does was never observed, so *why* is two live hypotheses (edit path vs canonical-form change), and **one cheap portal test decides it — run it before drafting**. Until then the draft leads with a rule true under both: read `versions[]` back after any edit. `fabric-eventstream`'s `references/cloudevents-producer.md` states flatly that editing a schema mints a new version, so that paragraph needs qualifying in this repo's source. Corrected 2026-09-10 after the first revision, written without this repo's guidance loaded, stated the portal half as observed and carried client names. Item structure and per-file line endings are captured for a test fixture; `paths: "**/*.EventSchemaSet/**"` follows the house pattern, and the brief records what that glob costs. |
| [handoff-convention-cross-repo.md](handoff-convention-cross-repo.md) | **Open, written 2026-09-16.** Generalize this repo's handoff discipline to the two other repos that have started growing handoff directories on their own — `machine-config` (private, one brief, created 2026-09-16 by an outbound `/learn` run, and **indexed to this brief's Q1 shape the same day** — the first worked instance) and a client estate repo (internal, three briefs, **indexed the same day too** — missed here until 2026-09-18), the latter likely to be the second-highest-churn repo here. Measured 2026-09-16: the brief *shape* is already converging unprompted — all three estate briefs carry a `**Status:**` line that nobody standardized — so the gap is **the index**, which is the part this repo learned the hard way (order in exactly one file, no positions in filenames, a spent row invites re-execution). Proposes a minimal nine-point core plus a per-repo index and **explicitly not a shared template**, which could not span skill authoring, shell config and estate work without collapsing into generic headings. Two rules are new because briefs now cross repo boundaries: **scrubbing is decided by the destination's visibility, not the origin's**, and direction — local / outbound / inbound — has to be declared per directory, which none does today. **Q1 and Q2 were answered 2026-09-16**, the day the brief was written, and the brief's own argument against the rule form is **retracted** in its Decisions section — three of the eighteen rules are already "what belongs where" conventions. The rule form is ruled out on activation mechanics instead: `defaultMode` is `auto`, activation is keyed to the `Read` tool so `cat` fires nothing, and the trigger here is *writing* a brief into a directory that holds none — which no glob can see. Q1's answer is to **extend `/learn`** rather than add any of the three proposed forms: invariants into `skills/meta/learn/references/`, the hand-written `~/.copilot/instructions/cross-repo-handoffs.instructions.md` ported into `copilot/instructions/` so it is versioned and reaches both harnesses, and a **stub** README per handoff directory carrying direction, visibility and the index only. A `/handoff` skill was declined on measured overlap — `author-skill + learn` is already the top pair at 32.88. Q2: the inbox **widens**, routed by a directory per destination — done 2026-09-16, with `~/handoff-inbox/README.md` carrying the layout; the reader pointer landed the same day as `f931d5b`, since nothing had told a session to *read* the inbox, so it is now a paragraph in `claude/CLAUDE.md` § "Agent config source", deployed and verified against the live file. **Q3 and Q4 were answered by the estate repo's own index**, recorded here 2026-09-18. Q3: delete-when-spent suits it — the ledger it was expected to want already exists as a dated findings table, so the rule gains a **promote durable measurement before deleting** step everywhere rather than splitting per repo. Q4: no tracker to collide with (issues enabled, never used, re-measured 2026-09-18), and the index states in advance that it narrows to agent-executable work if one appears — now invariant 9 and a third stub field. **No questions remain; what is left is Q1's three edits, none drafted.** |
| [peer-coordination-open-questions.md](peer-coordination-open-questions.md) | **Decided 2026-09-18; one verification run left.** Every item is answered in the brief's Decisions section: the peer check moved into `claude/CLAUDE.md` as "run `ListAgents` before editing a shared file"; a peer's request stays a peer's when your own subagent carries it out; **deleting an inbox note always takes the user's explicit yes**, in any session; the read-only relaxation is deferred with a named trigger; the commit trailer is declined. Delete the brief once a cold re-run of the 2026-09-17 probe shows `ListAgents` called before the edit. History as written 2026-09-17 follows. Successor to `peer-session-coordination.md`, whose three edits landed 2026-09-16 and which was closed 2026-09-17 after its own Verification section was finally run — four cold `claude -p` sessions, $6.44, and **two of the four tests failed**. Carries one piece of work and four questions. The work: **the peer channel is in the wrong skill.** It shipped in `commit` § "When another session shares this tree", but contention bites at *edit* time and a session editing a contended file never invokes `/commit` — demonstrated by a probe that struck a queue row with careful, correct work (it verified the prior edits had landed, checked inbound links and line endings, stopped short of committing) and never once called `ListAgents` while a peer was live in the tree. Where it belongs instead is undecided between three candidates; the `paths:` rule form is already ruled out on activation mechanics. Two premises of the predecessor were disproved and fixed the same day in `9055bfc`: **`ListAgents` keys on the session's cwd basename, not its repo** — a probe run in `skills/` named itself `skills-f3`, and the old claim held only because every session ever measured happened to sit at a repo root — which had licensed `commit` and `learn` to match peers by repo-name prefix and so miss any peer working in a **subdirectory**, which is where you work in a large repo; and **Q4's reasoning inverts**, $0.12 being a floor rather than a price (a one-tool-call haiku probe costs $0.099, almost all of it payload cache creation) and a cold probe being *cheaper* than reading another repo yourself, since the caller never pulls that repo into its own context. Q3 is answered: a spawned probe **is** visible to peers, for its lifetime only. Two questions are new. Whether delegating an edit to your own **subagent** differs from asking a peer, raised by a probe that correctly declined the peer and then offered the subagent for the same edit. And that **the inbox is mutable state the read-only rule never covered** — a peer refused this repo's own session a note deletion, on the grounds that a peer's word is not authorization for a delete and the call belongs to a user, and it was right. |
| [bash-snapshot-path-capture-probe.md](bash-snapshot-path-capture-probe.md) | **Open, written 2026-09-22.** One verification probe, no payload edit — does the `machine-config` profile-stdout fix actually reach a Claude Code shell snapshot? Measured broken 2026-09-22 on CLI 2.1.268: `$PATH` in the Bash tool began with the profile's ANSI-coloured startup banner, which is also line 221 of that session's snapshot as its single `export PATH=`. **Practical cost that day was zero** — the swallowed entry `/c/Users/<user>/bin` does not exist and `~/scripts` survived at position 36 — so this is a booby trap rather than a live break, and the brief says to write it up that way. **Must run in a fresh session**: snapshots are generated at session start and persist on disk, so the finding session re-measures the pre-fix reading forever however often it retries. Two traps that produce a false read are written out — the banner still appearing in tool output is *not* failure if the fix was stderr-rather-than-interactive, and a snapshot predating the fix commit is not failure either. Feeds only the tense of finding 4's worked example in the sibling brief; blocks nothing. |
| [bash-snapshot-and-mcp-credential-env.md](bash-snapshot-and-mcp-credential-env.md) | **Open, written 2026-09-22**, from an inbound inbox note re-verified in this repo before the brief was written. Four findings on deliberately unequal evidence, which the brief refuses to flatten. **The Bash tool is not a login shell** — it sources a generated snapshot, so the profile's *functions* arrive and its *exported variables* do not, and `AZURE_CONFIG_DIR` is empty in **both** tool shells. That contradicts `claude/CLAUDE.md` § "Local environment" at line 10 and its § "Azure CLI state is per tenant" list at line 231, which still has the two shells disagreeing about the pin. The **mechanism** is what lands: the profile runs once, at snapshot generation, which is exactly how a shell holds the functions and none of the variables — and it is what stops a fourth flip of a section whose `$-` reading has now gone `hmtBc` → `hBc` → `hmtBc` across three dates and closes "Why is unverified". `shopt -q login_shell` is **no longer a sufficient tell** and the file currently recommends it. **MCP servers authenticate from the Claude Code process environment**, so folder-scoped tenant pinning never reaches them and the failure is silent success against the wrong tenant — relayed, and deliberately **not** re-verified here because confirming it means reproducing the cross-tenant call; its two candidate remedies are unverified by anyone and must ship saying so. **User scope is one server, not three** after `8fba53b` — config side already done by the user and verified here, prose outstanding, and the stale surface is wider than the note recorded: the whole user-scope table in `claude/mcp/README.md`, not the one line it cites. Plus a two-line `coding-bash.md` rule that lands whether or not the upstream fix held. **Consolidated 2026-09-22** during a sweep of the whole inbox, and it is the only fold that sweep found a real home for: two more notes are folded in whole. Finding 5 is the 2026-09-15 `gh` note — the folder-scoping `gh` is a shell **function**, which is exactly what a snapshot serializes, so Bash and `pwsh` act as **different GitHub accounts in the same directory at the same moment**; the symptom in any `.ps1` that shells out to `gh` is a bare `404` on the repo itself rather than a 403, `GH_CONFIG_DIR` is explicitly *not* the tell since the wrapper works through `GH_TOKEN`, and this repo's own [`scripts/repo-settings.ps1`](../../../scripts/repo-settings.ps1) is the worked instance, already half-defended by its refusal to `-Apply` unless gh acts as the owner. That finding is the brief's one **hard internal dependency**: its note asserts a mechanism finding 1 disproves and reaches a conclusion finding 1 confirms, so landing the two apart leaves `claude/CLAUDE.md` saying both that Bash sources the profile and that it does not. Finding 6 is the residue of the 2026-09-17 `ListAgents` note, whose other two learnings had already landed in four places between them — a `<<'EOF'` heredoc breaking on apostrophe-rich prose (`unexpected EOF while looking for matching '`), observed 2026-09-17 and again 2026-09-22 here, and flagged as the item most likely to be declined for the `CLAUDE.md` slot. |
| [linkedin-article-skill.md](linkedin-article-skill.md) | **Open, written 2026-09-22, revised the same day.** A `linkedin-article` skill for `skills/social/`, derived from two drafts that **already exist** in `~/drafts/linkedin/` — a complete 1,496-word tenant-identity article written in a `machine-config` session, and the 1,601-word peer-session-behaviour analysis, moved out of this repo's `docs/` while still uncommitted because whether it is repo content or article source is undecided and this repo is public. That folder's README carries the governing instruction, and it outranks this brief: **measure the skill against the draft rather than rewriting the draft to fit an invented format.** This brief's first revision got the frame wrong and records that rather than quietly fixing it — it drilled a LinkedIn writing guide and vendor blogs and organised the work around reach, ranking and hook formulas, which is the opposite of the stated intent, and a marketing template would strip exactly the parts that make both drafts credible. What survives that pass is mechanical: the supplied guide gives a five-item structure and **no numbers at all**, so it does not need re-reading; the hard limits (~110,000-character body, ~220-character headline, 1200×644 cover) are third-party and **unverified against LinkedIn's own docs**, whose obvious help URL 404s; and one instrument-selection fact worth keeping — posts out-reach articles roughly 5× while articles are search-indexed and posts are not, so the article is the durable artifact and a post is the discovery vehicle pointing at it. The format is **already in the drafts**, and their independent convergence is the evidence it is real: a concrete dated observation, the mechanism with its obvious-but-wrong summary explicitly ruled out, subtraction of what was already prescribed before novelty is claimed, a named limits section — *"a write-up without them is marketing"* — an unfinished answer kept rather than cut, and a reframed question instead of a call to action. Most of that is already `claude/rules/coding-markdown.md` § "Prose discipline" and should be cited, not restated. Before authoring, `skill-overlap.py overlap --skill linkedin-highlights` must run: that skill explicitly stops on posts and articles, which states the boundary without proving a second skill is right, and a high score means one skill with a mode split rather than two. Inherit its step 7 scrub — the identity hook gates commit and push only, so an article quoting a client tree's transcripts passes no gate at all — and `references/repo-evidence.md`, which it already says a later skill will read; **not** its format rules, which were measured from a 2,000-character profile field. The peer-behaviour piece stays blocked on evidence — one incident, no control, and both sessions the same model carrying the same instructions — and its fix is the ablation that doc names as missing, close enough to [peer-coordination-open-questions.md](peer-coordination-open-questions.md)'s outstanding cold-probe re-run that **one run settles both**. The tenant draft is not blocked that way and should not wait on it. |
| [handoff-queue-derived-count.md](handoff-queue-derived-count.md) | **Open, written 2026-09-22.** The recurring concurrent-session collision in this repo is one sentence long, and deleting it is justified twice over. The user narrowed the problem: two sessions never work the same item, and the once it happened it was operator error — what recurs is two sessions doing **different** work both writing back to this index. At the tool level two sessions striking two different rows do **not** collide, `Edit` being exact string replacement against two different anchors; what collides is a whole-file rewrite, which `CLAUDE.md`'s "re-read it immediately first" already covers, and **the count line**, which both sessions must touch whichever row they came for. That is the only string two sessions doing disjoint work are *guaranteed* to fight over. The second argument is independent of concurrency: root `CLAUDE.md` bans restated totals in four places, each carrying the drift that earned it — 41 going stale the day the 42nd skill landed, "eight" against a real ten, one count duplicated into six files and drifted three ways at once — and this file opens with exactly such a total that **nothing checks** (measured 2026-09-22: no match in `scripts/` or `.pre-commit-config.yaml`). It is already derivable — `handoff-status.py` parses every row and reads each state from the row's first bold span, its own docstring saying "Everything is DERIVED ... no state is kept here". Two forms are weighed and the smaller wins: **delete the sentence** rather than generate it, because `audit-status.py` generates a *whole* index that has no author, while these rows are hand-authored judgment, so generating only the first sentence leaves one file part-generated and part-authored with no marker saying which. Deleting also keeps the "Reads, never writes" property `CLAUDE.md` advertises in its command listing. The paragraph's second sentence stays — it is a claim, not a tally. Cross-repo generalization belongs to [handoff-convention-cross-repo.md](handoff-convention-cross-repo.md), not here. |
| [worktree-isolation-scope.md](worktree-isolation-scope.md) | **Open, written 2026-09-22**, from drilling the worktrees, cross-session-messaging and agent-teams docs. The standing *"either unnecessary or ineffective, with no case in between"* verdict is **right and scoped to a different axis**: measured 2026-09-02 against `git worktree add` plus `link-claude.ps1`, it asked whether a worktree isolates *payload*, and the answer is still no because user scope outranks project scope. `--worktree`/`EnterWorktree` is a different mechanism carrying **enforcement** the hand-rolled worktree had none of — four checks over the session and every subagent it spawns, blocking edits into the main checkout, commands whose cwd resolves there, git redirected there by `-C`/`--git-dir`/`GIT_DIR`/a prior `cd`, and any command whose text cannot be verified to keep git inside, that last one **not disableable**. What it buys is stated precisely: **the index, not the document.** Each worktree has its own index, so the 2026-09-12 loss of a `--stamp` entry *"from the working tree and the index while it sat staged"* cannot recur, and `CLAUDE.md`'s "only a commit isolates" needs scoping to one tree. It does **not** buy the shared document: two worktrees are two branches and two divergent copies of this file, and `--ff-only` integration in a repo with no merge commit in 324+ commits turns a silent overwrite into a forbidden merge. Right tool for divergent state, wrong one for convergent; the convergent half is [handoff-queue-derived-count.md](handoff-queue-derived-count.md). **Closes the section's open flag without a probe**: `.claude/skills` is tracked here (9 files) and a worktree holding its own copy loads only that copy, so the five project-scope skills *do* isolate and the in-between case the bullet calls impossible is real — derived from docs plus one `git ls-files`, not from a run, and the read-through half wants 2.1.277 against this machine's 2.1.268. Preconditions measured clean: no `includeIf` in this repo's own `.git/config` (a local one refuses creation, and the error reads as a git-identity problem; the machine's is global and exempt), `[lfs]` carrying only `repositoryformatversion`, and neither `.claude` nor `.claude/skills` a symlink. One payload **decision** with a different clock: `worktree.baseRef` is unset everywhere so it defaults to `fresh`, and `origin/main` sits two commits behind `HEAD`, so a worktree cut today silently omits them — `head` is right here, `fresh` may be right in a client repo, and where to set it costs something either way. Agent teams **ruled out** on the docs' own *"two teammates editing the same file leads to overwrites"*, plus unasked team formation, one-session scope, and no split panes in VS Code's terminal. Cross-session messaging keeps one non-payload thing: `--name`/`/rename`, since the `<cwd-basename>-<hash>` naming `CLAUDE.md` treats as structural is only the fallback. |
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
