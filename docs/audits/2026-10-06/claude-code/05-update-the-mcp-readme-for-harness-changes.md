# Handoff: update the MCP README for harness changes

- **Audit run**: 2026-10-06
- **Source**: `claude-code`
- **Window**: floor `2026-08-30` (base `f1af9b1f`, 2026-08-28) → head
  `fbe20e00` (2026-10-06)
- **Covers recommended actions**: 6
- **Kind**: factual correction to `claude/mcp/README.md` from documented
  changes in D-1 and D-2; D-3 is a docs lookup with an open question,
  and D-4 and D-5 are measurements that gate their own edits
- **Target**: `claude/mcp/README.md`,
  `claude/rules/claude-config-scoping.md`

## The problem

`claude/mcp/README.md` was last checked against the harness between
2.1.251 and 2.1.282. Since then Claude Code fixed an HTTP timeout its
timeout section reasons around, documented a per-request timer and a
helper retry, began asking every stdio server for a newer protocol, and
announced two config keys, `alwaysLoad` and `bareElicitationCapability`,
that its MCP docs page does not describe. A hazard the README and
`claude-config-scoping.md` both warn about was also reported fixed.

## D-1 — the timeout section predates a fix and a documented timer

**Symptom.** § "Per-server timeout — deliberately absent":
> `timeout` is left out too, because the default is not 60 seconds.
> Claude Code overrides the MCP SDK's 60s default with
> `timeout ?? MCP_TOOL_TIMEOUT ?? 1e8` — roughly **27.8 hours** — so a
> slow stdio start, such as `npx` fetching `@azure/mcp` on first launch,
> has no deadline worth raising.

and it closes:
> Verified against Claude Code **2.1.251** (2026-08-31) by reading the
> shipped config schema and round-tripping a scratch `.mcp.json`
> through `claude mcp get`.

**Cause.**

- `CHANGELOG.md` 2.1.274:
  > Fixed Streamable HTTP MCP tool calls timing out after about 5
  > minutes even when a longer per-server `timeout` was set
- https://code.claude.com/docs/en/mcp, read 2026-10-06:
  > The per-server `timeout` is a hard wall-clock limit per tool call,
  > and progress notifications from the server don't extend it. Values
  > below 1000 are ignored and fall through to `MCP_TOOL_TIMEOUT`, or to
  > its default of about 28 hours when that variable is unset. For an
  > HTTP, SSE, or claude.ai connector server there is also a second,
  > per-request timer that covers each request through to the server's
  > first response byte. Claude Code sets that timer to the greatest of
  > three values: 60 seconds, the tool timeout that applies to the
  > server, and `MCP_TIMEOUT`.

  > If a tool call returns `401 Unauthorized` or `403 Forbidden`, Claude
  > Code automatically re-runs the helper under the same rule,
  > reconnects with the fresh headers, and retries the call once.

**Fix.** Rewrite the section's reasoning for http servers: the
~28-hour default holds per call, but an http server also carries the
per-request timer, and before 2.1.274 a Streamable HTTP call stopped at
about five minutes whatever `timeout` said. Re-read the section's
"capped at 300000 ms" clause for `request_timeout_ms` in that light,
and keep "Never put it in a template". Add the helper's 401/403 re-run
where the README describes the helper, § "Prerequisites (project
scope)", whose "Claude Code does not cache the result" stays true.

## D-2 — every stdio server is now asked for the 2026-07-28 protocol

**Symptom.** § "Prerequisites (project scope)" lists the `npx`, `uvx`
and `dnx` stdio servers with no word on protocol negotiation.
**Cause.**

- `CHANGELOG.md` 2.1.292:
  > Changed local (stdio) MCP server connections to negotiate protocol
  > version 2026-07-28 by default on every install, including Bedrock,
  > Vertex and Foundry; `MCP_PROTOCOL_NEGOTIATION=legacy` opts out

  > Improved startup with local (stdio) MCP servers that ignore the
  > newer protocol check: after one slow connect they are remembered for
  > 7 days and connected the older way without the wait
- The MCP docs page, read 2026-10-06, still describes the stdio default
  as rolling out to 2.1.285 and later in sessions that fetch feature
  flags, and says `MCP_PROTOCOL_NEGOTIATION` set to `legacy` "keeps
  every server" on the earlier handshake.

**Fix.** One or two sentences under the prerequisites: since 2.1.292
every stdio server is asked for the 2026-07-28 protocol; one that
ignores the question costs one slow connect and is then remembered for
seven days; `MCP_PROTOCOL_NEGOTIATION=legacy` keeps every server on the
old handshake. Cite the changelog for 2.1.292, since the docs lag it.

## D-3 — `alwaysLoad: false` may weaken the scope argument

**Symptom.** § "What belongs at which scope":
> Every user-scope server loads its whole tool surface into every
> session on the machine, including sessions in repos where it can do
> nothing useful.

**Cause.** `CHANGELOG.md` 2.1.287: "Changed MCP server `alwaysLoad:
false` to defer all of that server's tools behind tool search"; 2.1.285
honours a tool's own `_meta['anthropic/alwaysLoad']`. The MCP docs page,
fetched 2026-10-06, does not mention `alwaysLoad`.
**Fix.** A docs lookup first: search
https://code.claude.com/docs/llms.txt and the tool-search page for
`alwaysLoad`. Only a page that documents the key licenses an edit.
**Open question.** If it is documented, does per-server deferral change
the README's scope rule, or only add a lever beside it? Deferral cuts
the tool-surface cost the scope test weighs; it does not touch the
tenant binding that moved `fabric-core` and `azure-mcp` to project
scope.

## D-4 — the hosted endpoints are unprobed since URL elicitation

**Symptom.** The hosted Fabric entries in the project template were
last measured connecting on 2.1.268 (2026-09-14). Since 2.1.287 Claude
Code offers URL elicitation on the 2025-11-25 protocol and warns that
some servers stop connecting.
**Cause.** `CHANGELOG.md` 2.1.287:
> Added URL prompts from MCP servers on the 2025-11-25 protocol, for
> example to sign in. If a server no longer connects after this update,
> add "bareElicitationCapability": true to its MCP config entry

The MCP docs page, fetched 2026-10-06, does not mention the key.
**Fix.** A measurement in a tenant the user picks: probe one hosted
endpoint alone on the current CLI, as the README's "Do not batch-probe"
paragraph says, with `AZURE_CONFIG_DIR` pinned first (`claude/CLAUDE.md`
§ "Azure CLI state is per tenant, and pinned by folder"). If it
connects, record the version and leave the templates alone; if it fails
where it connected on 2.1.268, retry with the key, and only then
propose it for the template.
**Open question.** Which tenant and which endpoint.

## D-5 — the `~/.claude.json` revert hazard may be fixed

**Symptom.** README § "If you script an edit to `~/.claude.json`
yourself":
> And a live session rewrites this file from memory on its own
> schedule, so a write made while one is open can be reverted when it
> exits.

`claude/rules/claude-config-scoping.md` § "`~/.claude.json` is runtime
state, not payload":
> **A live session rewrites it from memory on its own schedule**, so an
> edit made while a session is open can be silently reverted when that
> session exits.

**Cause.** `CHANGELOG.md` 2.1.259:
> Fixed concurrent sessions silently reverting each other's
> `~/.claude.json` changes — workspace trust no longer resets and
> MCP/project state is no longer lost when running many sessions at
> once

It names sessions reverting sessions; a script writing while a session
is open is not named.
**Fix.** A measurement, after a backup: while a session is open, add a
scratch key to `~/.claude.json` from a script using the two
`ConvertFrom-Json` switches the README names, end the session, and
check the key. Relax both passages only if the write survives, and keep
"back up first" either way.

## Sequencing note

Brief 06 D-1 edits `claude/rules/claude-config-scoping.md` too, in
another section. Re-read the file before editing it.

## Verification

1. `grep -n -E "2\.1\.274|per-request" claude/mcp/README.md` — the
   timeout section names both.
2. `grep -n "MCP_PROTOCOL_NEGOTIATION" claude/mcp/README.md` — a hit.
3. D-3 to D-5: each edit made cites the page or probe that licensed it,
   with its date; none is made without one.
4. `uv run --with pyyaml scripts/lint-frontmatter.py claude/rules/claude-config-scoping.md`,
   if it changed.
5. `pre-commit run --all-files`.
6. From the main checkout,
   `./scripts/link-claude.ps1 -SkillGroups workflow,social,meta`, then
   `diff claude/mcp/README.md ~/.claude/mcp/README.md` — no output.

## Provenance

Found in the 2026-10-06 `claude-code` run's changelog diff. The MCP
docs page was fetched that day through WebFetch, which answers through a
small model: the passages above are the ones it returned as quotes, so
re-read them on the page before quoting them in the README.

## Execution log

- **Executed**: 2026-10-07 — applied with deferrals (D-1 and D-2
  applied; D-3 answered, D-4 and D-5 escalated)
- **Session**: fresh (no audit or handoff run in this session; the whole
  pass, in its own worktree)
- **Files changed**: `claude/mcp/README.md`
- **Open question**: three, put to the user. D-3: deferral adds a lever
  beside the scope rule and does not change it. D-4: a session of its
  own, in a tenant the user picks then, which stays out of this log.
  D-5: a session of its own.
- **Verification**: every quote D-1 and D-2 rely on was in place
  (README lines 127, 561 and 563). Step 1 — **passed**: `2.1.274` and
  `per-request` in the timeout section, lines 556–569. Step 2 —
  **passed**: `MCP_PROTOCOL_NEGOTIATION=legacy` at line 127. Step 3 —
  **holds**: this run made no D-3 to D-5 edit. D-3's lookup is the MCP
  page's raw markdown, `code.claude.com/docs/en/mcp.md`, fetched
  2026-10-07, which documents `alwaysLoad` under § "Exempt a server from
  deferral", where the audit's fetch the day before found nothing.
  Step 4 does not apply: `claude-config-scoping.md` is unchanged. Step 5
  (`pre-commit run --all-files`) runs once at the end of the run.
- **Deferred**: step 6 needs the deployed payload: from the main
  checkout after the landing, `link-claude.ps1 -SkillGroups
  workflow,social,meta`, then the diff.
- **Deviations**: none to the edits. Notes. D-1's docs passages were
  re-read on that raw page with `curl`, not WebFetch, as **Provenance**
  asks, and the README cites them as read 2026-10-07. The page carries
  two facts the brief's quote stopped short of, both used: an unset
  `MCP_TOOL_TIMEOUT`'s 28 hours never enters the per-request comparison,
  so with no `timeout` set that timer is 60 seconds unless `MCP_TIMEOUT`
  is longer, and stdio servers have no such timer. The "capped at 300000
  ms" clause is now dated to the 2.1.251 bundle and marked not re-read
  since 2.1.274, as nothing in reach re-establishes it. D-3's page shows
  more than the brief foresaw: with `ENABLE_TOOL_SEARCH` unset, every
  MCP tool is deferred by default, and `alwaysLoad: true` exempts a
  server.
- **Needs**: tenant, a session of its own, the landing — D-3's edit per
  the answer: the scope section's tool-surface sentence corrected to the
  default deferral, with `alwaysLoad: true` named as what loads a whole
  surface, and the binding argument kept (step 3: cite the page); D-4's
  one-endpoint probe with `AZURE_CONFIG_DIR` pinned, recording only the
  CLI version and the result; D-5's write-while-open probe of
  `~/.claude.json`, after a backup, relaxing both passages only if the
  key survives (brief 06 also edits `claude-config-scoping.md`);
  step 6's deploy and diff, on `main`; and an adjacent finding, unbriefed:
  with no `timeout` set, an `http` server's per-request timer is 60
  seconds to the first byte, so whether that cuts off a slow hosted
  Fabric call, and so whether "deliberately absent" still holds for
  `http` servers, is unmeasured.
- **Needs**: tenant, a session of its own — D-3's edit per the answer,
  the scope section's tool-surface sentence corrected to the default
  deferral, with `alwaysLoad: true` named as what loads a whole surface
  and the binding argument kept (step 3: cite the page); D-4's
  one-endpoint probe with `AZURE_CONFIG_DIR` pinned, recording only the
  CLI version and the result; D-5's write-while-open probe of
  `~/.claude.json`, after a backup, relaxing both passages only if the
  key survives; and the adjacent finding, the 60-second first-byte timer
  on an `http` server with no `timeout`, unmeasured against a slow
  hosted Fabric call. Step 6 is done: `link-claude.ps1` ran on `main` at
  `4d473d7`, and the deployed README matches the repo (`diff`,
  2026-10-07).
- **Needs**: tenant, a session of its own — D-4's one-endpoint probe with
  `AZURE_CONFIG_DIR` pinned, recording only the CLI version and the
  result; D-5's write-while-open probe of `~/.claude.json`, after a
  backup, relaxing both passages only if the key survives; and the
  adjacent finding, the 60-second first-byte timer on an `http` server
  with no `timeout`, unmeasured against a slow hosted Fabric call. D-3
  is done in `3e56c38` (2026-10-07; step 3: the MCP page's raw
  markdown, § "Exempt a server from deferral", read that day): the
  README's scope sentence, and `claude-config-scoping.md` § "The MCP
  scope test", which said the same, now say a server's tools are
  deferred by default, name `alwaysLoad: true` as what loads a whole
  surface, and keep the binding argument. Step 6 for both files is done:
  `link-claude.ps1` ran on `main` at `3e56c38`, and each deployed copy
  diffs clean against the repo. D-5 waits for a session of its
  own, the user's call that day, after auto mode refused this session's
  probe, a `claude -p` child held open while a script wrote the key, as
  creating an agent.
