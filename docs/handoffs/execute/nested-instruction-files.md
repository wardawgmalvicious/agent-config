# Handoff: when a repo gets nested instruction files

- **Written**: 2026-09-24, after `5b6221b` stopped `claude/CLAUDE.md`
  loading a second time as a subdirectory file here, from a drill the same
  day of Claude Code's memory and large-codebases pages and VS Code's
  custom-instructions page.
- **Kind**: a decision, then an edit here, then possibly one skill through
  `/author-skill`. Nothing is drafted.
- **Status**: **Open, written 2026-09-24.** Probes 1–6, a new 8 and four
  cutover probes ran 2026-09-25, the docs were re-read, and all four
  decisions were answered. Next: the rule decision 2 names, then Phase 2
  with probe 7.
- **Queue**: [README.md](README.md) has the execution order. This brief
  does not carry its own position.

## The ask

The user, 2026-09-24: a fresh look at when a repo should get a nested
`CLAUDE.md` or `AGENTS.md`, this repo included but not the global payload,
and possibly a skill that makes those determinations in any repo,
"something similar to what init does but deeper".

It began from two beliefs that do not hold: that nested files are new, and
that a session reads a folder's README anyway. Both are answered below.

On 2026-09-25 the user named the root half of the ask: cut a repo's
`CLAUDE.md` over to `AGENTS.md` where that makes it tool-agnostic for
people, and not if the swap loses any capability.

## What is established

From the docs, fetched 2026-09-24 on CLI 2.1.281 and re-read as raw
markdown 2026-09-25 on 2.1.282, when every quote below still stood and
2.1.282's changelog touched no instruction loading. Re-fetch before
relying on any of it: `AGENTS.md` support shipped in 2.1.277.

- **Nested files load lazily.** `CLAUDE.md` and `CLAUDE.local.md` in the
  working directory and every directory above it load at launch; one in a
  subdirectory is "included when Claude reads files in those
  subdirectories". Start in a subdirectory and its file loads at launch,
  after its ancestors'.
- **After `/compact`** root is re-read from disk, while "nested CLAUDE.md
  files in subdirectories and rules with `paths:` frontmatter reload as
  Claude reads files they apply to."
- **A subdirectory can hold its own `.claude/rules/` and
  `.claude/skills/`**, loaded on demand too, and a `claudeMdExcludes`
  pattern of `**/<dir>/**` skips every `CLAUDE.md` and rule under it.
- **The docs' own split**, from the large-codebases page: a per-directory
  file when "directory owners maintain their own conventions; instructions
  are versioned with the code", a path-scoped rule when "you want all
  conventions in one place, or the same rule applies to many scattered
  paths".
- **`AGENTS.md` is either/or by default**, through the built-in
  `agents-md` plugin. Claude reads it only when no `CLAUDE.md`,
  `.claude/CLAUDE.md` or `CLAUDE.local.md` sits in the working directory
  or above it; `~/.claude/CLAUDE.md`, managed files and rules do not
  count. A subdirectory's `AGENTS.md` loads on a Read there only when that
  subdirectory has no `CLAUDE.md` of its own. `AGENTS.local.md`,
  `AGENTS.override.md` and `.agents/` are never read.
- **Only user settings, a `--settings` file or managed settings can
  change that.**
  `pluginConfigs["agents-md@builtin"].options.instructionFiles` takes
  `claude-md-or-agents-md` (the default), `claude-md-and-agents-md`,
  `claude-md` or `managed-only`, and "Claude Code ignores it in project
  and local settings files": a repo cannot choose for the people who
  clone it. The second value "skips an `AGENTS.md` it has already
  loaded", so one a `CLAUDE.md` imports is not read twice.
- **An `AGENTS.md` read directly differs**: InstructionsLoaded hooks do
  not fire for it, though they "fire as usual" for one a `CLAUDE.md`
  imports or symlinks to, and an `--add-dir` directory never loads one.
  On Windows, share one file through `@AGENTS.md` in a `CLAUDE.md`, not
  a symlink.
- **VS Code Copilot**'s Local agent reads `AGENTS.md` under
  `chat.useAgentsMdFile` and nested ones under
  `chat.useNestedAgentsMdFiles`, "disabled by default". The page's raw
  source, re-read 2026-09-25, marks that setting only with a `feature()`
  tag and never says "experimental". "Agent Host sessions use the
  discovery rules and file formats of the selected harness": the split a
  `machine-config` inbox note measured in VS Code 1.139.0 on 2026-09-24.
- **What already does part of this.** `/init` with `CLAUDE_CODE_NEW_INIT=1`
  "asks which artifacts to set up: CLAUDE.md files, skills, and hooks",
  explores with a subagent and presents a proposal before writing.
  `/doctor`'s checkup "proposes trims for a checked-in CLAUDE.md", cutting
  what Claude can derive from the code. `/import` copies another agent's
  instruction files in. Two official plugins are installed:
  `claude-md-management`, whose `claude-md-improver` skill audits
  `CLAUDE.md` files, and `claude-code-setup`, whose
  `claude-automation-recommender` recommends hooks, skills and MCP
  servers. `3212938` disabled both on 2026-08-31 for zero lifetime uses
  and their listing cost, not for anything they got wrong.

Probed here the same day, in the entry closing § "Editing conventions" in
[root-claude-md.md](../../evidence/root-claude-md.md): a nested load shows
as a `nested_memory` attachment on the Read, a `claudeMdExcludes` pattern
must not name the drive, and the InstructionsLoaded hook log recorded none
of the nested loads, so the transcript is the only witness.

Measured in a client Fabric repo, 2026-09-24, across its 53 transcripts,
about two weeks' worth since `cleanupPeriodDays` is 15. Its root file is
281 lines and links three folder READMEs; one path-scoped rule has
covered two of those folders since 2026-09-22 and links one README.

| Folder holds | README | Sessions working there | Opened it | Before any other file there |
| --- | --- | --- | --- | --- |
| Per-object contract files | 305 lines | 7 | 6 | 3 |
| Column docstrings | 68 lines | 1 | 0 | 0 |
| Eventhouse definitions | 86 lines | 1 | 1 | 1 |

One contract session made 52 Reads and Edits there before it opened the
README, and the one session there after the rule landed never opened it.
Whether the user prompted any of the opens was not checked. **A README is
Claude's choice to open; a nested file is not.** Both of that repo's
workspace sync-root folders already hold a `Readme.md`, so a markdown file
at a workspace root coexists with Git sync. Inside an item folder is
untested.

## Probed 2026-09-25

Each ran as one cold `claude -p --model haiku` session on 2.1.282, in its
own `git init` scratch repo, every instruction file carrying a unique
marker line, tools pinned by `--tools` and the launching session's
`CLAUDE*` variables stripped. The transcript is the witness, and every
tool call in it was checked against the path it was meant to touch.
Control C0, an `AGENTS.md` at root and in `sub/` with no `CLAUDE.md`,
loaded both (`46eae3f2`), so the negatives below are real; it also showed
that `~/.claude/CLAUDE.md`, the only instruction file above the scratch
root, does not count.

`uv run scripts/test-instruction-loading.py` re-runs every probe here but
7 and checks each against its expected loads, record kind included. Its
first full run, the same day in fresh sessions, passed all of them.

1. **A root `CLAUDE.md` silences every `AGENTS.md`**, nested ones
   included, by default. In a repo like this one a nested `AGENTS.md` is
   dead text to Claude Code. **Holds**: neither root's nor `sub/`'s
   loaded (`f6b8d746`).
2. **In a repo rooted on `AGENTS.md`, a nested `CLAUDE.md` turns root off
   for anyone who starts there**: launched in that folder, a `CLAUDE.md`
   sits in the working directory, so root's `AGENTS.md` is not read.
   **Holds**, and a Read at root did not bring it back (`0e85e2ae`).
   Launched at root, both load, `sub/CLAUDE.md` on its Read (`2031480e`).
3. **A root `CLAUDE.md` holding `@AGENTS.md` silences nested `AGENTS.md`
   files**, by 1, though its own import loads. **Holds** (`786fd841`).
4. Does a `CLAUDE.md` that `claudeMdExcludes` skips still count for 1–3?
   **No**: with 1's root `CLAUDE.md` excluded, root's and `sub/`'s
   `AGENTS.md` both loaded (`89c97e19`).
5. On a Read in `a/b/`, do `a/CLAUDE.md` and `a/b/CLAUDE.md` both load,
   and in which order? **Both, `a/` first**, in one flush; a later Read
   in `a/` added nothing (`4344b55c`).
6. Does a subagent's Read load a nested file into the subagent, the
   parent, or neither? **The subagent only**, a general-purpose one that
   loaded root's `CLAUDE.md` at its start; the parent got the nested file
   on its own first Read there (`97cb1923`).
7. **Worktrees here.** A main-checkout Read under `.claude/worktrees/<n>/`
   should load that worktree's root `CLAUDE.md` as a nested file, a second
   and possibly different copy of root. `**/claude/CLAUDE.md` covers the
   worktree's payload copy, not its root. **Not run**: it needs a worktree
   and a branch here, and waits on the user.
8. Added 2026-09-25, as the Phase 1 table's nested-file row rested on it:
   does a first touch by Write, Grep, Glob or Bash load a folder's
   `CLAUDE.md`? **No**, none did; the first Read in each folder loaded its
   file (`0d43c6ff`).

In C0 and 4, `sub/AGENTS.md` arrived not as a `nested_memory` attachment
but as `hook_additional_context`, `hookEvent` `PostToolUse`, its content
opening `Contents of <path>\AGENTS.md:`, which fits InstructionsLoaded
not firing for one. A transcript check keyed on `nested_memory` would
miss it; root's `AGENTS.md` shows in the launch `instructions` record,
like a `CLAUDE.md`.

The worktree probe of 2026-09-24 bears on 7 without settling it: a
`--worktree` session did not load the main checkout's root `CLAUDE.md`
above it ([root-claude-md.md](../../evidence/root-claude-md.md),
§ "Branching and concurrent sessions"), though the memory page orders
content "from the filesystem root down". Whether the upward walk stops at
a git root or only at Claude Code's own worktrees is open, and 7 asks the
downward case.

## Cutting root over to `AGENTS.md`

**A full cutover loses capability, so the user's own test rules it out;
a `CLAUDE.md` of `@AGENTS.md` loses none that was found.** Read and
probed 2026-09-25 on 2.1.282.

An `AGENTS.md` with no `CLAUDE.md` loses five things, each silently, by
the memory page:

1. Anyone's `CLAUDE.local.md` counts as a `CLAUDE.md`, so a teammate's
   personal notes switch the project's `AGENTS.md` off for them.
2. It is not read at all before 2.1.277, in the first session after an
   upgrade from 2.1.276 or earlier, with the `agents-md` plugin
   disabled, before 2.1.281 on Bedrock or with telemetry off, or under
   `claude-md` or `managed-only`, which a client's managed settings can
   set. Each leaves the session with no project instructions.
3. InstructionsLoaded hooks do not fire for it.
4. An `--add-dir` directory's `AGENTS.md` never loads.
5. An `@path` import outside the repo loads only if external imports were
   already approved for the project, with no prompt.

What it does not lose, probed: it comes back after `/compact` as a
`CLAUDE.md` does, root at the next prompt and a nested one at the next
Read (`k1` beside `k0`), and `disableAllHooks` does not silence a nested
one (`h1`). Each `/compact` probe resumes its session in a new process
per step, so compaction and restart were not told apart; the two files
behaved alike.

The docs' own "Share one file with other coding tools" keeps the content
in `AGENTS.md` and a `CLAUDE.md` of `@AGENTS.md` beside it, Claude-only
lines below the import. Everything then loads through a `CLAUDE.md`, so
none of the five applies, and InstructionsLoaded fires "as usual" for
the import. It nests too: a `sub/CLAUDE.md` of `@AGENTS.md` loaded both
files as `nested_memory` on a Read there, and both came back after
`/compact` (`k2`). Its costs are upkeep. Every level needs both files,
since a nested `AGENTS.md` with no `CLAUDE.md` beside it stays silent
(probe 3). And whatever here keys on `CLAUDE.md` would have to follow
the content: `lint-claude-md.py`'s cap, and the `**/CLAUDE.md` glob in
`editing-claude-md.md`.

It pays only where people use other tools. This repo's root is about
skills, hooks and deploys, which no other tool can use, and an
`AGENTS.md` here would hand Copilot the instructions this machine's VS
Code profiles deliberately keep from it. The client repo keeps a root
`CLAUDE.md` and a `.github/copilot-instructions.md`, two root files for
two tools; how far they overlap was not compared.

## Phase 1: the strategy

A decision table, tested against the probes, for where a piece of
guidance lives. This is the starting draft, not adopted:

| Guidance is… | Home | Fails silently when |
| --- | --- | --- |
| Needed before any Read: commands, repo-wide conventions | root file | it passes ~200 lines and adherence drops |
| About one file kind, wherever it sits | `paths:` rule | the glob is wrong, or Grep, `cat` or a new file touch it |
| About one directory, kept by its owners | nested file | the session never Reads there itself: Write, Grep, Glob, Bash and a subagent's Read all miss it (6, 8); and after `/compact`, until the next Read |
| A procedure asked for in words | skill | the description never matches |
| Must hold before Claude acts | hook or `permissions.deny` | the hook itself fails open ([hooks-fail-open-on-blocked-timeout.md](hooks-fail-open-on-blocked-timeout.md)) |
| Long reference for people | README, or a nested `CLAUDE.md` of `@README.md` if short | Claude never opens it (above) |
| Derivable from the code | nowhere | never; `/doctor` cuts it |

Which name a nested file takes, now that 1–3 hold:

| Root holds | Nested files are | Because |
| --- | --- | --- |
| `CLAUDE.md` | `CLAUDE.md` | no `AGENTS.md` is read |
| `AGENTS.md` only | `AGENTS.md` | a nested `CLAUDE.md` drops root for sessions started there |
| `CLAUDE.md` of `@AGENTS.md` | `CLAUDE.md`, importing a sibling `AGENTS.md` where other tools need it | a nested `AGENTS.md` is ignored |

Excluding a `CLAUDE.md` through `claudeMdExcludes` takes it out of that
count (4): the `AGENTS.md` files beside and below it load in its place.

Where the strategy lives is Decision 2. Wherever it lands, it settles two
artifacts that already take a side:
[project-CLAUDE-template.md](../../project-CLAUDE-template.md) says "drop
it in as `AGENTS.md` instead if that is what the repo's tooling reads",
and [README.md](../../../README.md) § "Tool support" says to reinstate a
root `AGENTS.md` "if a tool that reads `AGENTS.md` comes back", which is
now half true: Claude Code reads one, but never beside a root
`CLAUDE.md`.

## Phase 2: this repo, minus the payload

The standing ban is `.claude/rules/editing-claude-md.md`: "Never an
unscoped rule, an `@import` or a subdirectory `CLAUDE.md` … the third on
any Read beneath it". It came from the 2026-09-24 trim, whose entry is in
§ "Preamble" of the ledger, and which moved guidance about kinds of file
into rules. For that shape of guidance it stays right. The only question is
whether a directory here holds guidance of the other shape.

Out of bounds, whatever Phase 1 concludes:

- **Anything under `claude/`.** `claude/CLAUDE.md` is the user-scope
  payload and stays excluded. `link-claude.ps1` copies `claude/rules/`
  whole, so a `claude/rules/CLAUDE.md` would deploy as a rule with no
  `paths:` and load in every session on the machine; the rules README
  carries `paths:` for exactly that reason.
- **Inside `skills/<group>/<name>/`**, a junctioned skill directory, so
  the file would ship with the skill.
- **At or above `tests/**/fixtures/`**, where fixture tests need a clean
  context (`editing-rules.md`).
- **`AGENTS.md`**, by 1.

Candidates, to measure rather than assume: `docs/handoffs/execute/`,
whose README root tells a session to read first, the same kind of
pointer the client measurement found unreliable; `docs/audits/`; and
`scripts/`. The measure is this repo's own transcripts: in sessions that
edited a brief, was the queue README Read before it?

A nested file here also needs `editing-claude-md.md` amended in the same
commit, since its `**/CLAUDE.md` glob would load it on every nested Read
while its text speaks only of root and the payload, and a cap decision,
since `lint-claude-md.py` caps two named files. Probe 7 decides whether
`claudeMdExcludes` gains `**/.claude/worktrees/**`.

## Phase 3: the skill, if Decision 1 says so

Through `/author-skill`, whose steps 1 and 2 must weigh these before a
name is chosen:

- **`learn`**, whose Step 3 destination table has root files, rules and
  skills but no row for a nested file or an `AGENTS.md`. A row there may
  be most of the value.
- **The built-ins and the two disabled plugins.** Read
  `claude-md-improver` and run `CLAUDE_CODE_NEW_INIT=1` `/init` on a
  scratch repo before claiming a gap; neither has been tried here.

"Deeper than init", as proposals for `/author-skill` to keep or cut:

1. **Evidence from the repo's own transcripts**: per folder, which
   sessions worked there, whether they opened its README, which nested
   files and rules loaded, and how often they compacted; a nested
   `AGENTS.md` shows only as `hook_additional_context`. The measurement
   above is the worked example; its scratch script was not kept. It
   reaches back only `cleanupPeriodDays`.
2. **A cross-tool inventory**: `CLAUDE.md`, `AGENTS.md`,
   `.github/copilot-instructions.md`, `.github/instructions/` with its
   `applyTo` globs and `.cursor/rules/`, with 1–3 applied to what it
   finds.
3. **Placement by the Phase 1 table**, "nowhere" and "hook" included,
   with a root file over 200 lines sorted section by section into where
   each part goes.
4. **Platform checks**, Fabric first: no file inside an item folder until
   that is tested.
5. **It proposes, then edits on approval.** It acts on the repo it runs
   in, whose guidance is that repo's business, not the inbox's (`learn`
   Step 0).

It acts on any repo, so it belongs in `skills/`, probably `meta`: upkeep
of agent configuration that must run in client repos, kept from Copilot.
Its name cannot contain `claude`.

Pilot it on the client repo above, then here. There it should re-find
what was proposed by hand on 2026-09-24: move root's section on the
contract folder into the rule that already covers it, and fold each
README's must-know lines into that rule. A draft that misses both has
failed its pilot. Its fixtures would hold instruction files of their own,
which load as nested files in any session here that Reads them, so
`/test-skill` has to isolate them.

## Decisions for the user

1. **A skill at all: deferred 2026-09-25, not declined.** Re-open when
   `CLAUDE_CODE_NEW_INIT=1` `/init` and the disabled `claude-md-improver`
   have been tried on a scratch repo and leave a gap. Until then Phase 3
   waits, and the strategy stands alone in the home 2 picks.
2. **Where the strategy lives: a user-scope rule, answered 2026-09-25.**
   Not `learn`: its Step 0 hands a repo's own `CLAUDE.md` and
   `.claude/rules/` back to that repo, which is where every placement
   question arises. Not a skill, by 1. A rule in `claude/rules/`, the
   sibling of `claude-config-scoping.md`, provisionally
   `agent-instructions-scoping.md`, scoped to the instruction files
   themselves: `**/CLAUDE.md`, `**/CLAUDE.local.md`, `**/AGENTS.md`,
   `**/.claude/rules/*.md`, `**/.github/copilot-instructions.md` and
   `**/.github/instructions/*.md`. It carries the Phase 1 tables, the
   import form and the cutover's five losses, kept short, since it loads
   on every Read of an instruction file in every repo. One row in
   `learn`'s Step 3 table routes a loader learning to it; whether it gets
   a Copilot port is `copilot-payload.md`'s call. It fires on the Read
   before any edit to an instruction file, but not when a first nested
   file is created, which no glob sees (`editing-rules.md`): closing that
   is what the skill deferred in 1 would do.
3. **The machine's `instructionFiles`: the default, answered 2026-09-25.**
   `claude-md-and-agents-md` in `claude/settings.json` would change what
   every repo on this machine loads, while no git repo two levels under
   `C:/Repos` tracked an `AGENTS.md` that day, and the import form of 4
   works under any value.
4. **A `CLAUDE.md` of `@AGENTS.md`: answered 2026-09-25.** Not this repo,
   by § "Cutting root over to `AGENTS.md`". Client repos explore it,
   starting with the client Fabric repo, which keeps a root `CLAUDE.md`
   and a `.github/copilot-instructions.md` apart by design today, already
   drifted. A note went to its inbox the same day, and what it learns
   comes back through `/learn`.

## Scrubbing

This repo is public. The client repo, its folder names, its source
systems and its session ids stay out of every commit (`author-skill`
§ 4), and "a client Fabric repo" is the citation. The user named it on
2026-09-24; ask for it rather than recording it here.

## Re-measure before acting

- `uv run scripts/test-instruction-loading.py`: a FAIL means the loader
  changed under a conclusion here.
- `claude --version`: `AGENTS.md` needs 2.1.277, and `/memory` lists one
  only from 2.1.280, by the memory page; no changelog entry says so.
  2.1.282 on 2026-09-25.
- The three doc pages above, last re-read 2026-09-25. The VS Code page's
  source now sits under `docs/agent-customization/` in
  `microsoft/vscode-docs`.
- The client repo's root file and rules. Three sessions were live there
  when this was written. On 2026-09-25 root had grown one line, still
  beside one rule and no nested file, and the repo also tracks a
  `.github/copilot-instructions.md` and eleven `.github/instructions/`
  files: input for Phase 3's cross-tool inventory.
