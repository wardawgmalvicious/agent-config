# Handoff: the Bash tool sources a snapshot, and MCP servers take their tenant from the harness

- **Written**: 2026-09-22, from the inbox note
  `~/handoff-inbox/agent-config/2026-09-22-bash-snapshot-and-mcp-credential-env.md`,
  filed by a `machine-config` session and **re-verified independently**
  in this repo the same day before this brief was written.
- **Kind**: payload edits to three files — `claude/CLAUDE.md`,
  `claude/mcp/README.md`, `claude/rules/coding-bash.md`. Mostly prose; no
  script, no skill, no fixture.
- **Consolidated 2026-09-22**: findings 5 and 6 arrived from two other
  inbox notes and are folded in here rather than briefed separately — see
  [Provenance](#provenance) for why the first of them cannot be landed
  apart from finding 1.
- **Status**: **Open, nothing landed.** The config half of finding 3 is
  already done by the user (see below); every *prose* edit here is
  outstanding. Finding 2's remedies are **unverified by anyone** and must
  ship saying so.
- **Run in**: this repo. `claude/CLAUDE.md` is deployed by copy, so an
  edit here is not live until the link script runs — see Deployment.
- **Queue**: [README.md](README.md) has the execution order. This brief
  does not carry its own position.

## Evidence status, per finding

Every finding here is an inbound handoff from another session. They do
not carry equal weight and the brief should not flatten them.

| Finding | Status |
| --- | --- |
| 1 — Bash sources a snapshot, not a profile | **Reproduced independently in three sessions**, against three different snapshot files |
| 2 — MCP servers authenticate from the harness environment | **Relayed, verified by nobody** — two sessions declined it deliberately, see below |
| 3 — user-scope MCP prose is stale | **Verified** twice, and the stale surface is *wider* than the note said |
| 4 — profile stdout captured into `PATH` | **Reproduced independently in three sessions**, at the same snapshot line in each; fix reported landed upstream, unconfirmed |
| 5 — the two tool shells act as different GitHub accounts | **Reproduced once**, 2026-09-15, by the filing session only; its *mechanism* is corrected by finding 1 and its *conclusion* confirmed by it |
| 6 — a quoted heredoc fails on apostrophes in prose | **Observed twice**, 2026-09-17 and 2026-09-22, in different sessions and different repos |

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

## 5. `claude/CLAUDE.md` § "Git identity is folder-scoped" — `gh` acts as a different account per shell

**This one cannot be landed apart from finding 1**, which is why it is a
finding here rather than a brief beside this one. The note it came from
states a mechanism finding 1 disproves and reaches a conclusion finding 1
confirms. Land them separately and `claude/CLAUDE.md` carries the
contradiction for however long separates them.

That section already says the profiles folder-scope `gh`, that
`gh auth status` reports the keyring's active account rather than the one
`gh` will act as, and to probe with `gh api user -q .login`. All of that
held up. Three things it does not say:

**The folder-scoping `gh` is a shell function, not a `gh` config
mechanism.** It lives in `configs/bash/.bashrc` and
`configs/powershell/profile.ps1` in `machine-config`, derives the account
from the repo's `user.name`, and injects a per-call `GH_TOKEN`.

**So the two tool shells act as different GitHub accounts, in the same
directory, at the same moment.** Measured 2026-09-15 in one repo:
`gh api user -q .login` returned an admin account under Bash and a
different personal account under `pwsh`.

The note attributed that to Bash being a login shell. It is not, and the
real mechanism is **sharper**: a snapshot serializes the profile's
*functions*, the `gh` wrapper is one of them, and finding 1's own
snapshot read confirms it present as `eval $'…'`. `pwsh` runs
`-NoProfile` and gets the raw binary on the keyring's active account. The
split is real and survives the correction — only its cause changes, from
"Bash sources the profile" to "the snapshot carries functions and not
exported variables".

**`GH_CONFIG_DIR` is not the tell.** It is empty in both shells, because
the wrapper works through `GH_TOKEN` instead. Reading it suggests neither
shell is scoped, which is wrong for Bash.

**Any `.ps1` that shells out to `gh` inherits the wrong account, and the
symptom is a bare `404 Not Found` on the repo itself** — not a 403 and
not a permissions message. An account without admin cannot see the repo's
settings endpoints, and GitHub reports absence rather than denial, so it
reads as a broken script or a wrong repo slug. Set the token for the run
rather than switching shells:

```powershell
$env:GH_TOKEN = (gh auth token --user <admin-account>)
try { ./scripts/some-settings-script.ps1 } finally {
    Remove-Item Env:GH_TOKEN -ErrorAction SilentlyContinue
}
```

`gh auth token --user <name>` reads a non-active account out of the
keyring, which is exactly what the bashrc wrapper does internally.
Verified 2026-09-15: the script failed with the 404, then succeeded
unchanged with `GH_TOKEN` set.

**This repo has the worked instance, and it is already half-defended.**
[`scripts/repo-settings.ps1`](../../../scripts/repo-settings.ps1) is a
`.ps1` that shells out to `gh`, and its header already refuses `-Apply`
unless `gh` acts as the repo's owner, on the stated grounds that gh is
folder-scoped here. It also aborts on a `null` merge setting rather than
recording the null as a value. So the *script* is covered; what is
missing is the general statement and the `GH_TOKEN` remedy for the next
script, which will not carry that header.

**One thing to decide while landing.** The wrapper, the `GH_CONFIG_DIR`
non-tell and the `GH_TOKEN` line belong in the `gh` paragraph under
§ "Git identity is folder-scoped". The `pwsh` half could instead sit in
§ "Local environment", where the `-NoProfile` asymmetry is established.
**One fact, one home** — pick one and cross-reference. Finding 1 is
already rewriting the Local environment paragraph, which argues for
keeping the `gh` consequence with `gh`.

**Not checked by anyone:** whether the same split hits other
profile-wrapped commands. `az` is handled separately, and nothing beyond
`gh` and `az` was tested.

---

## 6. `claude/CLAUDE.md` § "Writing files…" — a quoted heredoc fails on apostrophes in prose

The smallest item here, and the one most likely to be declined for the
slot. That section covers backslashes and warns that PowerShell
here-strings cannot be used inline in the Bash tool. It does not cover
the commoner failure: **apostrophe-rich prose breaks a `<<'EOF'`
heredoc**, surfacing as ``unexpected EOF while looking for matching `'` ``
— the body parsed as shell text rather than as heredoc content.

What worked in the filing session was a PowerShell single-quoted
here-string written to a `.ps1` and run, which left backticks, `$(...)`
and em dashes intact. What worked here was the `Write` tool.

**Observed twice, in different sessions and different repos.**
2026-09-17, writing a handoff note in a session where `Write` was
disabled. Again 2026-09-22, in this repo, writing a commit message —
which is why the commit for `13fed79` went through `Write` and
`git commit -F` rather than a heredoc.

That is the case that actually fires here: every file this repo writes is
prose full of `session's` and `peer's`, so the backslash framing the
section leads with is the rarer half of its own subject.

**Weigh the slot honestly.** Two lines at most, and the case for
`claude/CLAUDE.md` over a skill is that it fires wherever prose is
written to a file, which is everywhere. The case *against* is that the
section's existing advice — use the Write/Edit tools, which are
unaffected — is already the remedy, so this only adds the symptom to
recognize. If it is refused, land nothing and record the refusal, because
the alternative is rediscovering it a third time.

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

## Provenance

Consolidated 2026-09-22, during a sweep of the whole inbox. This brief
now carries three notes:

| Note | What it gave |
| --- | --- |
| `2026-09-22-bash-snapshot-and-mcp-credential-env.md` | findings 1–4, this brief's original scope |
| `2026-09-15-gh-account-differs-per-tool-shell.md` | finding 5, whole |
| `2026-09-17-listagents-names-cwd-not-repo.md` | finding 6 only — its other two learnings had already landed |

The third is the interesting one to record, because it shows what a
mostly-spent note looks like. Its learning 1 (`ListAgents` names a
session after its cwd, not its repo) landed in three places —
`claude/CLAUDE.md`, `commit/SKILL.md` and `learn/SKILL.md`, all carrying
`<cwd-basename>-<hash>` today. Its learning 2 (a cold probe is visible to
peers for its lifetime) landed as
[peer-coordination-open-questions.md](peer-coordination-open-questions.md)'s
answered Q3. Half of its learning 3 landed as `learn`'s *"The doorbell is
best-effort"* paragraph. Finding 6 is the residue, and the note read as
pending work for five days on the strength of it.

## The notes were deleted, and this is now their only record

All three were deleted from `~/handoff-inbox/agent-config/` on
2026-09-22 **with the user's explicit approval**, asked for and given in
the session that consolidated them. That approval is what the rule
requires — `claude/CLAUDE.md`'s, decided 2026-09-18 in
[peer-coordination-open-questions.md](peer-coordination-open-questions.md)
§ Q3 — and it is never a peer's to give, nor implied by content having
landed.

**Consolidating a note into a brief is not landing it.** Findings 1–6
are still outstanding payload edits; what changed is only where they are
written down. If any of this needs the original wording, it is in this
repo's history from the commit that added this section onward, and
nowhere else.

## Dependencies

- Sibling: [bash-snapshot-path-capture-probe.md](bash-snapshot-path-capture-probe.md)
  — non-blocking, decides finding 4's tense only.
- **Internal, and the only hard one: finding 5 must land in the same
  commit as finding 1.** Finding 1 rewrites the paragraph finding 5's
  text depends on, and finding 5 states the consequence that makes
  finding 1's mechanism worth the words. Either alone leaves
  `claude/CLAUDE.md` asserting both that Bash sources the profile and
  that it does not. Findings 2, 3, 4 and 6 are each independent and can
  land or be declined on their own.
- Touches `claude/CLAUDE.md`, which
  [peer-coordination-open-questions.md](peer-coordination-open-questions.md)
  also has a pending five-line edit against. Both are open; whichever
  lands second should re-read the section rather than trusting this
  brief's quoted line numbers.
- No skill, fixture or `paths:` glob changes, so nothing here needs
  `/test-skill` or an activation run.
