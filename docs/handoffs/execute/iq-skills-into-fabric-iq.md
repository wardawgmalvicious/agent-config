---
status: open
priority: 2
needs: []
blocked-by: []
written: 2026-10-09
---

# Handoff: fold the four Fabric IQ skills into one fabric-iq skill

- **Written**: 2026-10-09, on the user's decision in
  [platform-skill-portfolio.md](platform-skill-portfolio.md) to fold
  these skills now rather than archive them, data agents being likely to
  return to client work. Measured at `9535085`.
- **Kind**: a restructure, done by hand, then `/test-skill fabric-iq`. A
  new router, `skills/fabric/fabric-iq/`, whose references hold the four
  bodies as they stand. The three held edits below are the only content
  change; nothing else is drilled, and `/author-skill` does not apply.
- **Not after the pilot**: the user held the notebook and PBIR routers
  for [fabric-deploy-skill.md](fabric-deploy-skill.md)'s result, not
  this one. No client session uses these skills, so its routing risks
  no client work.

## Why

- **Learn groups them.** The IQ (preview) workload's items are ontology,
  Power BI semantic model, planning, graph, data agent and operations
  agent ("What is Fabric IQ?", `learn.microsoft.com/fabric/iq/overview`,
  read 2026-10-09). "Get started with Fabric IQ" adds an integration,
  Fabric IQ in Microsoft 365 Copilot Chat.
- **Nothing uses them.** No client repo holds an IQ item (2026-10-08),
  and the four have two lifetime invocations between them, one each for
  `fabric-ontology` and `fabric-operations-agent`.
- **One home for what waits.** The deferred
  [item-type-skill-fabric-plan.md](item-type-skill-fabric-plan.md) and
  [copilot-chat-power-bi-skill.md](copilot-chat-power-bi-skill.md)
  join `fabric-iq` as references when they reopen, rather than as
  skills.
- **Listing**: the router keeps its items' globs, so startup stays at
  nothing. On activation it lists one entry of at most 500 characters,
  where the four list up to 4,958: `fabric-data-agent` 1,010,
  `fabric-graph` 1,004, `fabric-ontology` 1,461,
  `fabric-operations-agent` 1,483.

## Shape

### Files

| Today | After |
| --- | --- |
| `fabric-data-agent/` whole: `SKILL.md`, `references/` (six topic files and `REFERENCE.md`), `assets/` | `fabric-iq/references/data-agent/`, its `SKILL.md` renamed `data-agent.md` |
| `fabric-graph/SKILL.md` | `fabric-iq/references/graph.md` |
| `fabric-graph/references/REFERENCE.md` | `fabric-iq/references/graph-reference.md` |
| `fabric-ontology/SKILL.md` | `fabric-iq/references/ontology.md` |
| `fabric-ontology/references/REFERENCE.md` | `fabric-iq/references/ontology-reference.md` |
| `fabric-operations-agent/SKILL.md` | `fabric-iq/references/operations-agent.md` |
| `fabric-operations-agent/references/REFERENCE.md` | `fabric-iq/references/operations-agent-reference.md` |
| none | `fabric-iq/SKILL.md`, the router |

Move each with `git mv`, so `git log --follow` keeps its history. Strip
each moved file's frontmatter and re-point its relative links, which
`grep -n ']('` on each finds: `ontology-reference.md` cites
`../SKILL.md`, now `ontology.md`. The data agent moves whole, so its own
`references/` and `assets/` keep their places inside it and their links
hold.

### The router

1. **Pick the item.** One table, by the job and by the folder suffix:
   a shared business vocabulary bound to data, `.Ontology`; GQL over a
   labeled property graph, `.GraphModel`; natural-language Q&A over a
   domain, `.DataAgent`; watching live data and acting on it,
   `.OperationsAgent`.
2. **What crosses items, once**: an ontology grounds both agents and can
   generate a graph, and the tenant settings each item needs.
3. **Read the item's reference first.**

The router stays short; the references hold the depth.

### Frontmatter

- `name: fabric-iq`.
- `paths:` the four items' globs together: `**/*.DataAgent/**`,
  `**/*.GraphModel/**`, `**/*.Ontology/**`, `**/*.OperationsAgent/**`.
  No repo holds an IQ item, so a startup entry would buy nothing; this
  was the session's default on 2026-10-09, not the user's call, and
  theirs to reverse.
- The entry, `description` plus any `when_to_use`, at most 500
  characters, trigger vocabulary and no facts: Fabric IQ, ontology,
  entity types, data binding, graph model, GQL, data agent, operations
  agent, and the four suffixes.
- `disable-model-invocation: false`, `# model: inherit` and `effort`
  commented, as repo policy.

## The held edits

`platform-skill-portfolio.md` held these for its Part 1 from 2026-10-08,
each to be made if its skill stayed. They stay as references, so make
them, as a commit before the fold, so the move shows no content change.

1. **The renamed tenant setting.** `fabric-data-agent` names the
   service-principal tenant setting by its old title, *Service
   principals can use Fabric APIs*, at `SKILL.md:45` and
   `references/authentication.md:15` (2026-10-08). The admin portal now
   titles it *Service principals can call Fabric public APIs*, as the
   other skills say, while Learn's own data agent page keeps the old
   title. Correct both, saying so.
2. **The ontology outage.** `fabric-data-agent`'s ontology paragraph
   (`SKILL.md:21`) says nothing of what Learn's data-agent ontology page
   warned of on 2026-10-08: a data agent may fail to add an ontology in
   the new experience (known issue 1987). Add it, dated, if the page
   still warns
   ([brief 07](../../audits/2026-10-06/fabric/completed/07-update-data-agent-consumption-surfaces.md)).
3. **Four unverified graph claims.** `fabric-graph` carries claims its
   audit brief put out of scope as unverified: the source formats, the
   create and update timeout, the per-workspace cap and the unsupported
   return types, at `references/REFERENCE.md:408-418` (2026-10-08), and
   the graph-type DDL example in `SKILL.md`. The timeout claim fails:
   Learn's graph performance page says "The 20-minute Query API timeout
   doesn't apply to refresh jobs." Verify the rest against Learn and
   correct what fails. The claims and what the audit read are in the
   Constraint of
   [brief 03](../../audits/2026-10-06/fabric/03-rewrite-graph-gql-support-and-query-api.md),
   which stays open on its own re-check. The DDL example's lead-in
   (`SKILL.md:42` on 2026-10-09) goes with it: it warns that a model
   will invent syntax unless the example is copied exactly. A client
   prompt audit of 2026-10-08 proposed calling the example exact, the
   very claim this edit checks, so word the lead-in to what the check
   finds.

## The rename trap

Nothing errors when a skill name goes stale. Change each of these in
the commit that folds:

- `.claude/settings.json` `skillOverrides`: four entries out,
  `fabric-iq` in. `lint-skill-overrides` fails until then.
- `tests/skills/fabric-triggers/expected_activations.md`: the four
  skills' rows become `fabric-iq`'s. Recompute the `Tokens` cells as
  that set's README says, then run
  `./scripts/test-activation.ps1 -Set fabric -StaticOnly`.
- `tests/skills/.tested.json`: the four stamps go; `/test-skill` writes
  `fabric-iq`'s.
- `skills/README.md`: one bullet for four.
- Other skills' mentions, counted 2026-10-09. Outside the four,
  `fabric-ai-functions`, `fabric-semantic-model-ai-instructions` and
  `fabric-semantic-model-audit` name `fabric-data-agent`,
  `fabric-eventhouse` names `fabric-graph`, and
  `fabric-semantic-model-audit` names `fabric-ontology`: re-point each to
  `fabric-iq`, wherever its own fold has moved it. Mentions among the
  four become reference links. A name backticked in a description fails
  `scripts/skill-overlap.py routing`.
- The drift registry: the `artifacts` list of
  `.claude/skills/drift-audit/references/sources/fabric-iq-ontology.md`
  (lines 37-39) and the counterpart row at `skills-for-fabric.md:167`
  point at `skills/fabric/fabric-iq/`. The source keeps its id, which
  names its ledger under `docs/audits/`.
- **The open `fabric-iq-ontology` follow-ups**: 03, 04, 05 and 07 of
  2026-10-06 each wait on one shared `/test-skill fabric-ontology`
  retest. Give `/test-skill fabric-iq` an ontology case for each edit
  they made, and once it passes, close each with a `**Closed**:` line
  naming this brief. 11 waits on the next
  `/drift-audit --sources fabric-iq-ontology` run and stays.
- Open briefs naming the four: re-point them.
  `copilot-chat-power-bi-skill.md` reopens once this lands, by its
  `reopen-when`; `item-type-skill-fabric-plan.md` waits for client
  work, not for this. `docs/audits/` stays as written.

```bash
grep -rnE 'fabric-data-agent|fabric-graph|fabric-ontology|fabric-operations-agent' --exclude-dir=audits --exclude-dir=.git .
```

**Client repos**: relink each with exactly the groups it holds; the
relink prunes four dangling junctions and adds `fabric-iq`.
[platform-persona-groups.md](platform-persona-groups.md), which runs
after this, later moves `fabric-iq` into a `fabric-ai` group of its own.

## Verify

1. The static check passes, and
   `uv run --with pyyaml scripts/lint-frontmatter.py skills/fabric/fabric-iq/SKILL.md`
   is clean.
2. `/test-skill fabric-iq`, behaviour, against a `--safe-mode`
   baseline, each case after a fixture of its item is Read:

   | Case | Prompt, in short | Passes when |
   | --- | --- | --- |
   | Ontology | bind an entity type to a lakehouse table | reads `ontology.md`; the binding order and cardinality rules |
   | Graph | query this graph model for shortest paths | reads `graph.md`; GQL, not Cypher |
   | Data agent | add a sixth data source to this agent | reads `data-agent/data-agent.md`; the five-source limit |
   | Operations agent | deploy this agent to test | reads `operations-agent.md`; `shouldRun` deploys running, and running costs |

3. **Listing**: the activated entry against the four's 4,958.
4. `pre-commit run --all-files`.

## Re-measure before acting

- The held edits' line numbers, and whether Learn's pages still say
  what each edit cites.
- Whether `/triage` has applied the client prompt audit's hunks to any
  of the four; re-read before moving.
- Whether a client repo now holds an IQ item. If one does, ask the user
  whether `fabric-iq` should be always listed instead.

## Scrubbing

Client repos are named by kind, and no workspace, item or tenant is
named.
