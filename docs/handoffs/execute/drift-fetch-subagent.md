# Subagent handoff brief: drift-fetch

Last verified: 2026-09-07

> Subagents are Claude Code-only (not part of the Agent Skills open standard). Subagents cannot spawn other subagents. The `memory:` field requires Claude Code v2.1.33 or later.

## Status

**Deferred 2026-09-08 — not declined, and not waiting on the validation
gate this brief specifies.** That gate is moot rather than unmet.

The context failure the agent exists to prevent **has never been
observed.** Nothing in `drift-audit` or the whole `docs/audits/` ledger
records a run that compacted, exhausted its budget, or reported files
left undiffed — including the registry's hardest case, the 89-day
`claude-code` window (85 commits, 77 version sections, 1713 bullets
against a ~590 KB file), which completed inline and whose numbers the
registry now quotes as its own evidence. §4's three existing controls —
blob-SHA narrowing, the delta-ordered 150 KB budget, and the `changelog`
on-disk two-ref diff — are the mechanism, not workarounds waiting to be
replaced, and they are more precise than an isolated window because they
act *before* the fetch rather than after it.

The cheaper lever also already exists. `--sources <id,id>` is documented,
tested, and in the skill's `argument-hint`; **one source per session buys
the same context isolation** with no payload, no return-block fidelity
risk, and Phases 2–4 running against the entries themselves rather than a
paraphrase of them. The artifact layout already assumes this —
`/drift-handoff` writes one `docs/audits/<date>/<source-id>/` directory
per run, and the 2026-09-07 `powerbi` run was a single-source session
that produced a 13-brief ledger. Per-source sessions are the pipeline's
intended shape, not a workaround for a missing subagent.

**Re-open on one specific observation:** a `/drift-audit` run that
degrades on a **single-source** invocation — compacting mid-Phase-1, or
naming files left undiffed against the 150 KB budget. Multi-source
pressure does not count, because `--sources` answers that for free.

Nothing below is withdrawn on the merits; the structure is sound and the
two calls worth keeping are §4 staying the single source of the mechanics
and the description being written to suppress routing. But the
corrections in the next section were measured after the brief was written
and **must be applied before any drafting** — three of them are internal
contradictions that would send a drafter down a path the registry already
rules out.

## Corrections — measured 2026-09-08

1. **The A/B baseline already exists, and the two runs disagree.**
   [`docs/audits/2026-09-07/powerbi/`](../../audits/2026-09-07/powerbi/)
   holds two inline runs on floor 2026-08-01 — the exact window the Notes
   propose. Use **`00b-audit-report-rerun.md`**, not `00`: they resolve
   different prior refs (`443eb78f` vs `f1f53694`) because the by-path
   base-resolution fix landed between them, and `00` therefore encodes
   the superseded rule.

2. **The `tools:` list cannot execute `powerbi` at all.** It omits
   `mcp__github-mcp__search_repositories` and
   `mcp__microsoft-learn-mcp__microsoft_docs_fetch`, both of which are in
   `drift-audit`'s `allowed-tools`. The `powerbi` entry's primary route
   *is* a repository search (steps 2–3, plus the exact-name filter), and
   its documented fallback is the Learn page via `microsoft-learn-mcp`.
   As specified, the frontmatter contradicts the validation plan in the
   Notes.

3. **"The parent picks the path; the agent does not re-decide it"
   contradicts §4.** Body-structure item 2 says that; §4 opens with **"An
   entry may override both"** — and `powerbi` is exactly that entry. An
   agent holding the parent's choice follows §4b into
   `raw.githubusercontent.com/MicrosoftDocs/powerbi-docs/...` and gets a
   404. The input contract needs: *unless the source's registry entry
   defines its own strategy, which wins.*

4. **The stated reason `powerbi` is runnable is wrong.** The Notes claim
   its `sections` list lets the WebFetch fallback do targeted re-fetch.
   The registry says the opposite explicitly — the takedown "breaks § 4b
   as well as § 4a, which is the non-obvious part," because §4b builds
   raw URLs from the same dead `repo`. Its real fallback is
   `microsoft-learn-mcp`, which returns full pages, so §4b's completeness
   check does not apply. The conclusion (start with `powerbi`) survives;
   the justification does not.

5. **Reading the contract from disk imports claims about the *parent's*
   tool scope.** This is the unpriced cost of the otherwise-correct
   decision not to restate §4. The `powerbi` entry says *"Use `WebFetch`,
   not a shell `curl`: § 3 keeps this skill read-only and Bash is
   deliberately outside its tool scope"* — false for an agent that has
   `Bash`. §4c ends *"do not write it to disk"*, which both the
   `changelog` on-disk diff and the scratchpad carve-out cross. The body
   needs one explicit precedence line: instructions reasoning from the
   parent's tool scope do not transfer; the agent's own tool list and
   scratchpad rule govern.

6. **`maxTurns: 30` is an unlisted silent-failure mode.** Failure item 6
   covers 404s, renames, oversized listings and exhausted budgets — not a
   turn cap. A `maxTurns` stop mid-fetch returns a partial entry set
   shaped exactly like a complete one. Add a `turns used / complete:
   yes|no` line to the return block, or drop the cap.

Also stale: the portability caveat records `github-mcp` failing to
connect (`Authorization header is badly formatted`, 2026-09-07). It
connects normally as of 2026-09-08 — verified with `get_me`. The
WebFetch-fallback requirement it justifies still stands on the `powerbi`
takedown alone, but not on that observation.

## Artifact path

**Personal scope** — `claude/agents/drift-fetch.md` in this repo, deployed by
`scripts/link-claude.ps1` to `~/.claude/agents/drift-fetch.md`.

`claude/agents/` is **copied**, not junctioned, so the agent is not live until
`./scripts/link-claude.ps1 -SkillGroups workflow` runs. It must sit directly
under `claude/agents/` — the directory is flat.

Personal rather than project scope because `/drift-audit` is junctioned into
user scope and fires from a session in any repo; a project-scoped agent would
be invisible to exactly the invocations that need it.

## Scope

`drift-fetch` executes **one source's** Phase 1 fetch-and-diff for
`/drift-audit` and returns the extracted entry set. It is launched explicitly
by the `/drift-audit` skill body — once per selected registry source, in
parallel where more than one is selected — and is **never** routed by
description and never invoked directly by the user. It runs in the foreground
(the parent blocks on its result), carries no memory across invocations, and
writes nothing to the repository.

The problem it solves is context, not capability. `/drift-audit` §4 already
carries two workarounds for doing byte-level diffing in the main conversation:
a ~150 KB per-source budget with a "name what you left undiffed" rule, and a
`changelog` exemption whose stated purpose is keeping a ~590 KB `CHANGELOG.md`
out of the conversation. Both exist because raw patches and full-file reads
share a context window with the Phase 2 artifact sweep, the Phase 3 drills, and
the report. A subagent gives the raw bytes their own window that dissolves on
return, leaving the parent only the extracted entries. The saving is the raw
diff material, **not** the findings — the entry set must come back in full
because Phase 2 and Phase 3 consume it and re-fetching is what this is avoiding.

## Frontmatter

```yaml
---
name: drift-fetch  # required; max 64 chars; lowercase letters/numbers/hyphens
description: Phase 1 fetch-and-diff worker for /drift-audit. Launched by that skill once per registry source; not a user entry point — a user asking for an audit wants /drift-audit, which owns the window resolution, artifact mapping, drilling and report. Given one source id and a floor date, resolves HEAD, lists the window, picks a diff strategy, and returns the extracted added/removed entries with provenance. Fetches and reads only; never edits a skill, rule, CLAUDE.md or MCP template.  # required; no formal cap — it's a routing hint, not Agent Skills metadata. Still, long descriptions cost context; keep concise but specific enough to route reliably
tools: Read, Grep, Glob, Bash, WebFetch, mcp__github-mcp__list_commits, mcp__github-mcp__get_commit, mcp__github-mcp__get_file_contents  # optional; comma-separated bare tool names. Fine-grained Bash control (e.g. Bash(git add *)) via tools is NOT shown in docs examples — use a PreToolUse hook or permissions.allow rules for that
model: inherit  # optional; sonnet / opus / haiku / full model ID / inherit (default when omitted)
maxTurns: 30  # optional; integer cap on agentic turns before stopping
effort: max  # optional; low / medium / high / xhigh / max; availability model-dependent
color: cyan  # optional; red / blue / green / yellow / purple / orange / pink / cyan. NOT arbitrary strings
---
```

Fields deliberately **not** set, with reasons — each is a live option a later
edit might want:

- `disallowedTools` — the `tools` allowlist already excludes `Write`, `Edit`,
  `MultiEdit` and `NotebookEdit`. A deny list restating that adds a second
  place to keep in sync.
- `permissionMode` — inherits the parent. `claude/settings.json` sets
  `defaultMode: auto` at user scope, which is right for a read-and-fetch job.
  See the open question below: `security-reviewer` records that the Task tool's
  `mode` parameter is deprecated and ignored, and it is not established here
  whether the **frontmatter** field is honoured.
- `skills` — preloading `drift-audit` would inject its whole body, including
  the read-only refusal script and the report format, neither of which this
  agent uses. It reads §4 from disk instead (see Body structure outline).
- `mcpServers` — `github-mcp` is a project-scope server from the repo's
  `.mcp.json`; scoping a second copy onto the agent would create a second token
  binding, and this repo already documents `gh`/`github-mcp` identity
  divergence as a live hazard.
- `memory` — every run is defined by its window and its floor. There is no
  cross-run state; blob-SHA narrowing is computed live at both refs.
- `background` — the parent blocks on the result, so background is wrong.
- `isolation` — a worktree isolates repo writes, and this agent makes none.
- `initialPrompt` — only applies when an agent runs as a main session via
  `--agent`, which this one never should.

### On `Bash`, and a correction to the scoping conversation

The scoping discussion claimed drift-fetch could carry "no write tools, which
is stronger than today's prose-only enforcement." That is **half right and
needs qualifying before drafting.**

`Bash` is not optional. The registry's `changelog` contract requires the long-
window path to be an **on-disk two-ref diff** — "provided both refs are diffed
on disk and only the new region enters context." That needs a shell to fetch to
files and diff them, and the `claude-code` source is the one that most needs
this agent. So write capability re-enters through `Bash`, and the guarantee is:

- **Enforced by the tool list** — no `Edit`/`Write`/`MultiEdit` on any repo
  artifact.
- **Enforced by the body contract only** — that `Bash` writes nothing outside
  the session scratchpad.

That is still strictly better than the parent's position (§3 of `drift-audit`
concedes "the body prompt is the only enforcement"), because the agent's tool
list is real enforcement and its context cannot leak into an editing turn. It
is not the absolute the scoping claimed. If the body-only half is judged
insufficient, the repo already has the mechanism: `security-reviewer`'s
`PreToolUse` write-scope guard in `claude/hooks/`. Listed as an open question
below rather than assumed, because a hook is payload that has to be maintained.

## Description char count

478 chars.

No formal cap applies, but this one is doing unusual work: most of its length
is spent telling the router **not** to pick it. A short description like
"fetches and diffs a docs source" would auto-route on any drift-shaped request
and bypass `/drift-audit` entirely, which loses window resolution, artifact
mapping, drilling and the report. Re-count after drafting.

## Body structure outline

1. **Role statement** — one source, one window, one entry set. Fetch and
   extract; do not map to artifacts, do not drill upstream docs, do not write a
   report, do not edit anything. Those are the parent's phases and doing them
   here duplicates work the parent will redo.
2. **Inputs expected in the launch prompt** — source `id`, floor date, prior
   ref if one was given, and which fetch path the parent already chose
   (`github-mcp` or WebFetch). The parent picks the path once per run so all
   sources agree; the agent does not re-decide it.
3. **Read the contract from disk, do not restate it** — `Read`
   `skills/workflow/drift-audit/references/sources.md` for the source's entry
   and the Shape contract, and `skills/workflow/drift-audit/SKILL.md` §4 for
   the fetch mechanics, sizing rules, budget and escape hatch. This section is
   the single most important structural decision in the brief: the agent body
   holds the **loop and the return contract**, and §4 stays the **only** copy
   of the mechanics. Restating §4 in the agent body would create two sources of
   truth that drift silently — and §4 has already been corrected twice by
   measurement (the `changelog` exemption inverting on a long window, the
   `vscode-agent` rename breaking `list_commits`).
4. **Execute §4 for this one source** — resolve HEAD, list the window with
   minimal fields, narrow by blob SHA at both refs, spend the budget in delta
   order, pick and if necessary switch strategy. Extract per the source's
   `shape`, apply its `filter` first, strip `drill.strip` anchors before
   storing any URL.
5. **Return format** — a single structured block, specified below. It is the
   agent's whole product; anything not in it is lost when the context
   dissolves.
6. **Failure and anomaly reporting** — a 404 on a `path`, a renamed directory,
   an oversized listing, an exhausted budget, or a source the registry marks
   github-mcp-only when the parent chose WebFetch. Each is reported as a named
   condition in the return block, never as a silent omission and never as an
   improvised substitution. The `vscode-agent` rename is the worked case: an
   empty listing across a path move must be reported as "diff across two paths
   required," not as "no prior state."
7. **Scope refusals** — if the launch prompt asks for artifact mapping, a
   drill, a report, or an edit, return the entry set and state plainly that the
   request belongs to the parent's Phase 2/3/4.

### Return block shape

```text
source: <id> (<label>)
fetch path: <github-mcp | webfetch>
window: <floor-date> → head <sha> (<date>), prior ref <sha-or-floor>
commits in window: <n>
strategy: <per-commit patch | two-ref get_file_contents | on-disk two-ref diff>
  — chosen because <count / size / escape-hatch reason>
budget: <kb spent> of ~150 KB; files left undiffed: <names | none>

added entries:
  - <heading or version> :: <feature/entry key>
    fields: <per shape — table cells, prose paragraph, changelog bullet>
    links: <anchor-stripped URLs into drill.host>
    code/syntax: <verbatim, or none>
removed entries:
  - <same shape> — <suspected GA promotion | deprecation | unknown>
filtered out: <n> entries (bucket (d) candidates, not drilled)
anomalies: <named conditions, or none>
```

The `filtered out` count is a count on purpose — §4c says a filtered entry is
"a count, not a bullet." Returning the bullets would reimport exactly the
volume the filter exists to suppress (418 of 1713 bullets passed on the
measured 89-day `claude-code` run).

## Changes from source proposal

Derived from this session's scoping conversation. Four departures, all
tightening:

1. **`Bash` is included, and the "no write tools" claim is qualified.** The
   scoping said the agent could carry no write capability at all. The
   `changelog` on-disk diff requires a shell. See the frontmatter note above.
2. **§4 is not moved into the agent body.** The scoping implied the agent
   would own the fetch mechanics. Having it `Read` §4 from disk instead keeps
   one source of truth and makes the change to `drift-audit` a small
   delegation pointer rather than a body rewrite.
3. **The description is written to suppress routing, not enable it.** Not
   considered during scoping. A normally-written description would let this
   agent intercept audit requests and silently skip Phases 2–4.
4. **"Additive, changes no invocation surface" is now precise.** The user-
   facing surface is unchanged — `/drift-audit <ref> --sources <ids>` still
   works identically. But `drift-audit` does need two edits: `Agent` (Task)
   added to its `allowed-tools`, and §4 gaining a delegation step. It is
   additive to the *pipeline*, not a zero-diff change to the skill.

## Tag

`personal`

## Portability caveats

- **Claude Code only by construction.** Subagents are not part of the Agent
  Skills open standard. A consumer cherry-picking `drift-audit` gets a skill
  that references an agent they do not have — so §4's delegation step must be
  written as a preferred path with the existing inline behaviour as the
  fallback, not as a hard dependency.
- **Subagents cannot nest.** If `/drift-audit` is itself ever run inside a
  subagent or a workflow agent, `drift-fetch` cannot be launched from there and
  §4 must fall back to inline fetching. Another reason the delegation step is a
  preference rather than a requirement.
- **`github-mcp` is the preferred path and is currently failing to connect** in
  this repo (`Authorization header is badly formatted`, observed 2026-09-07).
  The agent must work on the WebFetch fallback, including the completeness
  check and targeted per-section re-fetch, or it is untestable while that is
  broken.
- **GitHub Copilot reads `~/.claude/agents` once `chat.agentFilesLocations`
  names it, but ignores hook matchers.** If the optional `PreToolUse` write
  guard is added, it will run far wider there than under Claude Code — the same
  trap root `CLAUDE.md` records for the `security-reviewer` guard.
- **Frontmatter surface is moving.** `maxTurns`, `effort` and `permissionMode`
  on subagents all need re-verification against current docs before drafting
  (post-draft checklist item 1). No `memory:` field is used, so the v2.1.33
  floor does not apply here.

## Cross-reference dependencies

- `skills/workflow/drift-audit/SKILL.md` — **(a) already converted, but
  requires edit.** Add `Agent` to `allowed-tools`; add a delegation step at the
  top of §4 with the inline path retained as fallback. §4's contents are
  otherwise unchanged and remain the single source of the mechanics.
- `skills/workflow/drift-audit/references/sources.md` — **(a) already
  converted, no edit.** Read by the agent at runtime. Its Shape contracts and
  per-source fields are the agent's input.
- `skills/workflow/drift-handoff/SKILL.md` — **(c) unaffected.** It reads the
  report from the conversation; the report is still produced by the parent.
- `skills/workflow/drift-update/SKILL.md` — **(c) unaffected.**
- `claude/hooks/` + `claude/settings.json` — **(b) pending, conditional.** Only
  if the open question below is answered in favour of a hook guard.
- `scripts/link-claude.ps1` — **(c) external, no edit.** Already copies
  `claude/agents/`; a new file there needs no script change, only a run.

## Claude Code's post-draft checklist

1. Re-verify frontmatter fields against current docs before writing — the subagent surface is still moving (notably `memory:`, `skills:`, `initialPrompt:`).
2. Re-count description chars after drafting (Windows + Edit-tool fragility).
3. `cat` the full agent file after any edit — an edit landing inside the frontmatter can leave YAML that still parses, into the wrong shape, with nothing warning.
4. Confirm the agent file lives directly under `claude/agents/` (no subdirectories — the directory is flat).
5. If routing via description, read the filled description aloud to check it's specific enough to distinguish from bundled agents.

## Notes

**Validation plan — and it has a ready-made baseline.** The `powerbi` source
has not been audited since 2026-08-01, which is the ideal test window: run
`/drift-audit --sources powerbi 2026-08-01` **inline first**, keep the report,
then re-run it delegated and diff the two entry sets. Step 5 of the registry's
own "Adding a source" checklist is this exact discipline — "run against a
window you already know the answer for" — and an A/B against a known-good
inline run is the only way to prove the agent extracts the same entries rather
than plausible-looking ones.

`powerbi` is a good first source for a second reason: it is `table` shape, one
file, with a `sections` list, so the WebFetch fallback can do targeted
re-fetch. That makes it runnable while `github-mcp` is down — though note the
A/B then validates the *fallback* path, and the `github-mcp` path needs its own
run once the connection is fixed.

Do **not** validate first against `claude-code`. It is the source that most
needs this agent and the one whose contract is hardest — github-mcp-only, a
per-bullet filter requiring real judgment ("`Fixed Grep and Glob not applying
Read(...) deny rules`" is a permissions finding wearing a bugfix prefix), and
a strategy that inverts by window length. Prove the mechanism on `powerbi`,
then earn `claude-code`.

**Open question — is the body-only `Bash` scope sufficient?** Two answers, both
defensible: accept it (the agent has no repo-editing tools and its context
never becomes an editing turn), or add a `PreToolUse` guard on the
`security-reviewer` pattern confining its writes to the scratchpad. This brief
does not decide it. Recommendation: **accept it for the first draft**, and
revisit only if a run is observed writing outside the scratchpad — a hook is
payload with its own deployment step and its own Copilot matcher trap, and
adding it pre-emptively costs more than the risk it retires.

**A measurable success criterion, so this is falsifiable.** The agent is worth
keeping only if the parent's context after Phase 1 is materially smaller for
the same entry set. Capture the inline run's context cost against the delegated
run's on the same window. If the entry set has to come back nearly whole
anyway — which is the honest risk on a `table` source with few rows — then
`powerbi` will show little benefit and the real case rests on `claude-code`
and `vscode-agent`. Record that result either way; a source-shape-dependent
answer is a legitimate outcome and should be written into §4's delegation step
as a condition rather than papered over.

## Confidence

- **Structure: H.** The one-source-per-invocation boundary follows the
  registry's own unit of work, and the return block is a direct transcription
  of what §4c already specifies as Phase 1's output.
- **Field specs: M.** `tools`, `model` and `color` are settled. `maxTurns`,
  `effort` and `permissionMode` on subagents are unverified against current
  docs, and the `permissionMode` question is sharpened by
  `security-reviewer`'s note that the Task tool's `mode` parameter is
  deprecated and ignored — which says nothing about the frontmatter field
  either way. Checklist item 1 is load-bearing here.
- **Body content: M-H.** The workflow and refusals are clear. The unproven
  part is the return block's fidelity: whether a subagent reliably returns
  table cells and code snippets verbatim enough for Phase 3 to drill from,
  rather than paraphrasing them. That is exactly what the `powerbi` A/B tests,
  and it is the single result that decides whether this ships.
- **Payoff: M.** The context saving is real on `claude-code` and
  `vscode-agent` by measurement. On a small `table` source it may be marginal.
  Held deliberately at M until the A/B says otherwise.
