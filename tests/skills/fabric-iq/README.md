# `fabric-iq` — behaviour cases

`fabric-iq` is the router `fabric-ontology`, `fabric-graph`,
`fabric-data-agent` and `fabric-operations-agent` folded into on
2026-10-12. It keeps their four globs, so its activation contract is
the fabric set's
([expected_activations.md](../fabric-triggers/expected_activations.md));
these seven cases test where it routes once a matching file is Read,
and what it says. Four are the brief's, one per item. Three more carry
the ontology edits of the 2026-10-06 `fabric-iq-ontology` follow-ups,
whose shared retest this run is; the binding case carries the fourth.

## The cases

| Case | Item | Passes when |
| --- | --- | --- |
| `ontology` | ontology | reads `ontology.md`; the binding order and cardinality rules (follow-up 04) |
| `graph` | graph model | reads `graph.md`; GQL, not Cypher |
| `agent` | data agent | reads `data-agent/data-agent.md`; the five-source limit |
| `ops` | operations agent | reads `operations-agent.md`; `shouldRun` deploys as it stands, and running costs |
| `onelake` | ontology | OneLake security enforced on bound data, not an exclusion (follow-up 03) |
| `generate` | ontology | what generation makes and leaves by hand, Read and Build, `My workspace` (follow-up 05) |
| `consume` | ontology | the built-in ontology agent among the consumers, and the MCP endpoint (follow-up 07) |

The prompts, verbatim:

```text
ontology: Read SampleOnt.Ontology/EntityTypes/8813598896083/definition.json and the binding file in its DataBindings folder. I want this entity type's Temperature and PreciseTimestamp time-series properties bound to our lakehouse table equipment1telemetry, and its Manufacturer to come from our warehouse table dim_equipment instead, joined on DisplayName. How do I set up these bindings, in what order, and what will and won't work?

graph: Read SampleGraph.GraphModel/graphType.json and SampleGraph.GraphModel/graphDefinition.json. Write a query that finds the shortest path between two customers in this graph model, and show the exact command to run it from a script against the model in our workspace.

agent: Read SampleAgent.DataAgent/Files/Config/draft/stage_config.json and the datasource.json in the sql-database-SampleSQL folder beside it. In the portal this data agent already has five data sources; the export shows only this one. Add our Finance lakehouse to it as a sixth source: walk me through it.

ops: Read SampleOA.OperationsAgent/Configurations.json. Next week we deploy this operations agent from our dev workspace to the test workspace with a deployment pipeline. What will happen to it in test, and what should I check or change in this file first? Walk me through it.

onelake: Read SampleOnt.Ontology/EntityTypes/8813598896083/DataBindings/66253a71-c26f-4c9d-877f-3af5632a4be2.json. Our security team has just turned on OneLake security for the lakehouse this binding reads. Can the ontology still bind to that lakehouse's tables, and what changes for the people and agents who query it?

generate: Read SampleOnt.Ontology/definition.json. We want a second ontology generated from our Sales semantic model, an Import-mode model that sits in My workspace today. What will generation create for us, what will be left to do by hand, and will anything block it?

consume: Read SampleOntTmdl.Ontology/database.tmdl. Once this ontology is set up, in which ways can agents and apps use it? We also want a custom agent outside Fabric to query it: what endpoint does it call?
```

The slash arm reads `SampleAgent.DataAgent/Files/Config/draft/stage_config.json`
in one message, then sends `/fabric-iq` with the `agent` question in a
second, to the same stream-json process.

## Running them

The fixtures are the fabric set's, copied from
[`../fabric-triggers/fixtures/`](../fabric-triggers/fixtures/): the five
IQ item folders, `SampleOnt.Ontology`, `SampleOntTmdl.Ontology`,
`SampleGraph.GraphModel`, `SampleAgent.DataAgent` and
`SampleOA.OperationsAgent`. Build a probe outside this repo, since
`.claude/settings.json` here collapses every platform description to
`name-only`:

- `payload/.claude/skills/`: a copy of every folder in `skills/fabric/`.
- `baseline/`: no `.claude/`, run with `--safe-mode`.
- The five item folders at each arm's root.

Run each case in each arm from that arm's directory, with
`CLAUDE_CODE_DISABLE_GIT_INSTRUCTIONS=1`, as
[`../fabric-deploy/README.md`](../fabric-deploy/README.md) does and for
its reasons:

```powershell
claude -p '<prompt>' --output-format stream-json --verbose --tools Skill,Read --strict-mcp-config --model claude-opus-5-5 --effort xhigh --max-budget-usd 3
```

Add `--safe-mode` on the baseline. The skill is conditional, so a
payload arm reaches it only through its first `Read`: the stream's
`commands_changed` record witnesses that, and a `Skill` call naming
`fabric-iq` follows. The slash arm pipes two stream-json user messages,
45 seconds apart, into one `claude -p --input-format stream-json`
process launched from PowerShell, since Git Bash rewrites a leading `/`.

Read the `init` record for `tools` (2 on every arm) and
`slash_commands`, which must drop on the baseline; then the `Skill` and
`Read` calls, and the first `result`.

## Result, 2026-10-12

The router held on all seven cases. One run per arm, on 2.1.293, Opus
5.5 at `xhigh`, against `ccf0270`:

| Case | Router | Baseline |
| --- | --- | --- |
| `ontology` | pass: `ontology.md` read; one static binding, static before time series, exact key match, and the new experience's secondary sources joined on a shared column | partial: the old experience's rules, unaided; "Bindings don't do joins", wrong for the new |
| `graph` | pass: `graph.md` read; GQL with `ANY SHORTEST`, `?beta=true`, continuation and `status.code` | partial: GQL too, not Cypher; `?preview=true`, no status or continuation handling |
| `agent` | pass: `data-agent.md` read; the five-source limit, the same-region rule, Fabric IQ Data MCP to join agents | pass on the limit, unaided; none of the rest |
| `ops` | pass: `operations-agent.md` read; `shouldRun` carried by the deploy, 0.46 CU-hours per running hour | partial: arrives stopped; no meter |
| `onelake` | pass: binding still works, the exclusion withdrawn in September 2026, access to bound data enforced | fail: "Probably not", the withdrawn rule |
| `generate` | pass: `My workspace`, Read and Build, metrics from DAX measures, the four hand follow-ups | partial: `My workspace` and Import mode; "DAX measures … aren't copied over" |
| `consume` | pass: the built-in ontology agent first of seven consumers, and the `ontologyEndpoint` MCP path | fail: "no query endpoint of its own"; the retired Assistants route |

Every payload arm shows `commands_changed` after its first `Read`, then
`Skill` naming `fabric-iq`, then the item's reference. Two co-routed:
`ops` also invoked `fabric-deploy`, and `onelake` `fabric-security`.
`init` gave `tools` 2 on every arm, and `slash_commands` 80 on the
payload against 58 on the baseline. The slash arm's second turn listed
81, `fabric-iq` among them, and `/fabric-iq` expanded with no `Skill`
call, read `data-agent.md` and answered as the `agent` payload did.
`ops`'s payload called `Glob` once and was refused, "No such tool
available", so the allowlist held.

The same commit's real path, `./scripts/test-activation.ps1 -Set fabric`,
passed: 74 of 74 fixtures read, every activation delta matched, skills
and rules.

**A prompt flaw**: `ontology` names its binding file by folder, so both
arms tried to `Read` the folder and failed; name the file in a rerun.

**Listing**: the router's entry is 391 characters, all description,
against the four skills' 4,958.

**Cost**: router arms $4.63, baseline arms $1.14, the slash arm $0.54.

**Found, not fixed**:

- `graph.md` and `graph-reference.md` carry no path-search syntax,
  `ANY SHORTEST` or a path mode; the `graph` payload said so before
  writing it from the standard.
- `ontology-reference.md`'s troubleshooting table still prescribes
  `Support group by in GQL`, which `ontology.md` and `data-agent.md`
  retire; the `consume` payload caught it. The row follows Learn's
  troubleshooting page, which still says it (2026-10-12).

**What the run cannot show**: variance, with one run per arm; and the
client repos' listing, which runs to its cap, while this probe lists
the Fabric group alone.

## Not yet measured

Use in client work. No client repo holds an IQ item (2026-10-12); once
one does, `uv run --with pyyaml python scripts/skill-telemetry.py
triggers` says whether `fabric-iq` is invoked when IQ work happens.
Discount this run's own arms, which sit in this machine's transcripts.
