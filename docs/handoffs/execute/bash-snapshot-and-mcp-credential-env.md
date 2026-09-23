# Handoff: the Bash tool sources a snapshot, and MCP servers take their tenant from the harness

- **Written**: 2026-09-22, from the inbox note
  `~/handoff-inbox/agent-config/2026-09-22-bash-snapshot-and-mcp-credential-env.md`,
  filed by a `machine-config` session and **re-verified independently**
  in this repo the same day before this brief was written.
- **Kind**: payload edits to three files — `claude/CLAUDE.md`,
  `claude/mcp/README.md`, `claude/rules/coding-bash.md` — plus one
  correction to a second, still-unlanded inbox note. Mostly prose; no
  script, no skill, no fixture.
- **Status**: **Open, nothing landed.** The config half of finding 3 is
  already done by the user (see below); every *prose* edit here is
  outstanding. Finding 2's remedies are **unverified by anyone** and must
  ship saying so.
- **Run in**: this repo. `claude/CLAUDE.md` is deployed by copy, so an
  edit here is not live until the link script runs — see Deployment.
- **Queue**: [README.md](README.md) has the execution order. This brief
  does not carry its own position.

## Evidence status, per finding

The note is an inbound handoff from another session. Its four findings do
not carry equal weight and the brief should not flatten them.

| Finding | Status |
| --- | --- |
| 1 — Bash sources a snapshot, not a profile | **Reproduced independently in three sessions**, against three different snapshot files |
| 2 — MCP servers authenticate from the harness environment | **Relayed, verified by nobody** — two sessions declined it deliberately, see below |
| 3 — user-scope MCP prose is stale | **Verified** twice, and the stale surface is *wider* than the note said |
| 4 — profile stdout captured into `PATH` | **Reproduced independently in three sessions**, at the same snapshot line in each; fix reported landed upstream, unconfirmed |

**Three sessions, three different snapshot files.** The note was filed by
a `machine-config` session; this repo re-measured it as `agent-config-be`;
and a second agent-config session, `agent-config-d1`, had measured the
same thing independently before its own user chose to hold the note
entirely. The note's snapshot was `snapshot-bash-1790120456592-b1arcf`,
the peer's `snapshot-bash-1790121658018-wd2w9y` — different files,
identical readings, the banner at line 221 of each. That is what turns
the mechanism below from an inference drawn over one machine's five
files into a reading two sessions reached separately.

**Finding 2 was deliberately not re-verified — by either session.**
Confirming it means issuing a Fabric MCP call from a personal repo, which
authenticates from the shared `~/.azure` store and would reproduce the
cross-tenant call the note is reporting. Reproducing a tenant leak to
confirm a tenant leak is not a verification step. Two sessions reached
that independently, which is worth recording precisely because it means
the finding still rests on **one** measurement by its filer, and both
proposed remedies on none. It stays relayed, and the brief should not
imply otherwise.

---

## 1. `claude/CLAUDE.md` § "Local environment" — the `bash -c -l` paragraph is wrong

**Current text** (line 10): "**Bash is launched `bash -c -l`**, a login
shell, so it sources the profile ... and carries every function, alias
and environment pin the profile sets." Line 19 names
`shopt -q login_shell` or `/proc/$$/cmdline` as the tell. Lines 17 and 22
carry the 2026-09-14 / 2026-09-15 `$-` flip and close with "**Why is
unverified.**"

**Measured 2026-09-22, CLI 2.1.268, in three independent sessions** — all
six rows read the same in each:

| Probe | Reading |
| --- | --- |
| `AZURE_CONFIG_DIR` in Bash | **empty** |
| `shopt -q login_shell` | **no** |
| `$-` | `hmtBc` |
| `/proc/$$/cmdline` | `bash -c source ~/.claude/shell-snapshots/snapshot-bash-<id>.sh ... && eval '<command>'` |
| `type -t AzLogin` | `function` |
| `grep -c "^export " <snapshot>` | **1** — `PATH` only |

**The mechanism, and why it is the point.** The profile is not sourced
per tool call. It runs **once, at session start, in the login shell that
generates the snapshot**; that generator serializes the profile's
*functions* into the snapshot and captures `PATH` from the shell's
output. So the profile's behaviour survives into every later tool call
and its *state* does not.

**Write the mechanism, not a third contradictory reading.** This section
has now flipped three times — `$-` read `hmtBc` on 2026-09-14, `hBc` on
2026-09-15, and `hmtBc` again today — and the file currently tells the
reader to "re-check rather than assuming either state is permanent",
which is the right instinct with no explanation attached. The snapshot is
the explanation: it is exactly how a shell can hold the profile's
functions while holding none of its variables, which is what made every
previous probe ambiguous. Landing the mechanism is what stops the fourth
flip.

**Three specific corrections:**

- The `bash -c -l` claim goes. Bash is **not** a login shell per call.
- `shopt -q login_shell` is **no longer a sufficient tell** and the file
  currently recommends it. A `no` now means "snapshot" rather than "no
  profile at all" — the opposite conclusion from the one a reader would
  draw. `/proc/$$/cmdline` survives as the tell, because the `source
  <snapshot>` line is unambiguous.
- The operational consequence, which is the part that costs debugging
  time: **treat both tool shells as carrying no environment the profile
  set.** Calling `AzLogin` in Bash works; inheriting its tenant pin does
  not. § "Azure CLI state is per tenant" (line 231, "Three things follow
  for a tool call") currently says the two shells *disagree* about the
  pin, with bash pinned and `pwsh` not. Both are unpinned. That list
  needs correcting in the same pass or the two sections will contradict
  each other.

**Docs are silent.** `code.claude.com` documents that the snapshot
captures "functions, aliases, and shopt options" and says nothing about
environment variables or login-vs-non-login selection. The note cites
five corroborating GitHub issues (#57435, #25398, #68066, #24564
and #68349) — cite them **as issues, not as specification**.

---

## 2. `claude/mcp/README.md` — `headersHelper` never sees a folder-scoped pin

**The gap.** The existing text says the hosted Fabric endpoints need "a
live `az login`". It never says **which** login. Measured by the filing
session: an MCP call from a personal repo returned a **client tenant's**
workspace list, with no error.

**Why.** MCP servers are spawned by the Claude Code process and inherit
**its** environment, which has no `AZURE_CONFIG_DIR` — finding 1, one
layer down. `az` then falls back to the shared `~/.azure`, which is the
one store nothing manages: `AzLogin` only ever writes into
`~/.azure-tenants/<name>/`. Every `headersHelper` shells out to
`az account get-access-token` per connection and inherits the same
unpinned environment.

**The generalization worth landing**, because it is larger than Fabric:
any per-client isolation a shell profile enforces is enforced **for
shells only**. Agents and MCP servers sit outside it, and the failure is
silent success against the wrong tenant rather than an error.

**The `env` field is not the fix** — per the MCP docs it applies to
server processes, primarily stdio, and not to `headersHelper`. The two
candidate remedies are pinning `AZURE_CONFIG_DIR` in the environment
Claude Code itself is launched with, or setting it inline inside the
helper command. **Neither has been run by anyone.** Ship both as
candidates, explicitly marked unverified, or ship neither. Do not present
either as known-good.

**Destinations:** the `headersHelper` / credential section of
[claude/mcp/README.md](../../../claude/mcp/README.md), and a short
cross-reference in `claude/CLAUDE.md` § "Azure CLI state is per tenant,
and pinned by folder" — its "Three things follow for a tool call" list is
exactly where a reader looks for "and none of this reaches an MCP
server", and it is the same list finding 1 already corrects.

---

## 3. User scope is one server, not three — and the stale surface is wider than the note said

**Already done, config side.** The user moved `azure-mcp` and
`fabric-core` to the project template in `8fba53b` and deployed the
global prune. Verified 2026-09-22 — template and live agree:

```text
jq -r '.mcpServers | keys[]' claude/mcp/.mcp.global.template.json  → microsoft-learn-mcp
jq -r '.mcpServers | keys[]' ~/.claude.json                        → microsoft-learn-mcp
```

Nothing needs reconciling. **The prose is the whole of what drifted.**

**`claude/CLAUDE.md` line 471**, heading `### User-scope MCP servers are
deliberately three`. Rewrite the heading and paragraph rather than
patching. Now false: the count; the list naming `azure-mcp` and
`fabric-core`; and the carve-out "`fabric-core` is the one Fabric
exception ... it earns it by being bound to no workspace". The sentence
that survives is now the whole rule — "**Everything else Fabric and
Power BI is project scope**."

**`claude/mcp/README.md` is staler than the note recorded.** The note
cites line 103. In fact the entire **"Servers (user scope)"** table still
carries `fabric-core` and `azure-mcp` rows, including `fabric-core`'s
"Bound to no workspace, which is what puts it at user scope" and
`azure-mcp`'s prerequisites pointer. Three rows must become one, and the
`fabric-core`/`azure-mcp` detail moves to the project-template section
rather than being deleted.

**Capture the reasoning, because it is finding 2 in one sentence:** a
server bound to no *workspace* is still bound to a *tenant*, so user
scope gave every repo on the machine a Fabric client answering from
whichever login the shared store happened to hold. Project scope makes a
personal repo **fail closed** — no server, no tools, nothing to point at
the wrong tenant. That is the argument the rewritten section should lead
with; the count is a detail under it.

**One undocumented behaviour worth a line.** The filing session kept
`fabric-core` and `azure-mcp` connected and callable for hours *after*
they were removed from `~/.claude.json`, because servers connect at
session start. The docs say `.mcp.json` is read at session start and
require a restart after editing, but are **silent on mid-session
removal**. So a config change is invisible until restart, and a session
can act through a server the config no longer defines. Observed here, not
documented — frame it that way.

---

## 4. `claude/rules/coding-bash.md` — a sourced profile must not print to stdout

**The rule**, and it is small: a sourced profile writes diagnostics to
**stderr**, or prints only when interactive (`[[ $- == *i* ]]`). The
consequence that earns it a line is specific — **a profile's stdout can
be captured into the `PATH` of every future agent tool call**, because
the snapshot generator captures `PATH` by reading the shell's output.

**Destinations:** § "Output streams" (line 141) as a profile carve-out,
and a matching entry under § "Anti-patterns" (line 209), "diagnostics on
stdout from a sourced profile". The file already carves out shell
profiles as a distinct shape and already says stdout is for data; what is
missing is only the profile-specific consequence. One or two lines.

**The code fix is not this repo's** — the offending `printf`s live in
`machine-config`, which has been told and reports them corrected. Only
the **rule** belongs here, and it lands whether or not that fix holds.

**Verification of the fix is
[bash-snapshot-path-capture-probe.md](bash-snapshot-path-capture-probe.md)**,
a sibling brief. It does not block this one; it only decides whether the
worked example ships in present or past tense.

---

## The sibling inbox note must be corrected in the same pass

`~/handoff-inbox/agent-config/2026-09-15-gh-account-differs-per-tool-shell.md`
is **still unlanded** and its line 25 reads "Bash is a login shell and
gets [the wrapper]". That framing is finding 1's error, and it happens to
reach the right answer: the folder-scoping `gh` wrapper works in Bash
because it is a **function**, and functions are exactly what the snapshot
serializes. Land finding 1 without touching that note and the two will
disagree in the payload.

Correct the mechanism in that note, or land the two together. **Do not
delete either note** — see below.

## Deployment

`claude/CLAUDE.md`, `claude/rules/` and `claude/mcp/` all deploy by
**copy**, so none of these edits is live in any session until:

```powershell
./scripts/link-claude.ps1 -SkillGroups workflow,social,meta -Force
```

Never bare, and `-Force` is required for the two copied files. Confirm
the prune held by name afterwards:
`ls ~/.claude/skills | grep -E '^(fabric|pbir|pbid)-'` must come back
empty.

## Do not delete the inbox notes

Both `2026-09-22-bash-snapshot-and-mcp-credential-env.md` and
`2026-09-15-gh-account-differs-per-tool-shell.md` stay in
`~/handoff-inbox/agent-config/` until their content has landed **and the
user has explicitly approved the delete** — in this session or any other,
on anyone's word including the filing peer's. That rule is
`claude/CLAUDE.md`'s, decided 2026-09-18 in
[peer-coordination-open-questions.md](peer-coordination-open-questions.md)
§ Q3.

## Dependencies

- Sibling: [bash-snapshot-path-capture-probe.md](bash-snapshot-path-capture-probe.md)
  — non-blocking, decides finding 4's tense only.
- Touches `claude/CLAUDE.md`, which
  [peer-coordination-open-questions.md](peer-coordination-open-questions.md)
  also has a pending five-line edit against. Both are open; whichever
  lands second should re-read the section rather than trusting this
  brief's quoted line numbers.
- No skill, fixture or `paths:` glob changes, so nothing here needs
  `/test-skill` or an activation run.
