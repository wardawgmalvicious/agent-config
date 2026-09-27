---
paths:
  - "**/CLAUDE.md"
  - "**/CLAUDE.local.md"
  - "**/AGENTS.md"
  - "**/.claude/rules/**/*.md"
  - "**/.github/copilot-instructions.md"
  - "**/.github/instructions/**/*.md"
---

# Agent instruction files: what goes where

Applies when editing a repo's agent instructions: a `CLAUDE.md` at any
depth, an `AGENTS.md`, a `.claude/rules/` file, or Copilot's files under
`.github/`. The question is rarely what to write and usually where,
because each home loads on its own trigger and each misses in silence:
the guidance is on disk, correct, and never read.

If a project-scope `.claude/rules/agent-instructions-scoping.md` exists,
that file supersedes this one. The loader behaviour below was probed on
Claude Code 2.1.282 on 2026-09-25; `AGENTS.md` support needs 2.1.277.

## Where a piece of guidance lives

| Guidance is… | Home | Fails silently when |
| --- | --- | --- |
| Needed before any Read: commands, repo-wide conventions | root `CLAUDE.md` | it passes ~200 lines and adherence drops |
| About one file kind, wherever it sits | `.claude/rules/` file with `paths:` | the glob is wrong, or only Grep, `cat` or a new file touch it |
| About one directory, kept by its owners | nested `CLAUDE.md` | the session never Reads there itself (below), or has compacted and not Read there since |
| A procedure asked for in words | skill | its description never matches |
| Must hold before the agent acts | hook or `permissions.deny` | the hook itself fails open |
| Long reference for people | README, or a short nested `CLAUDE.md` of `@README.md` | the agent never opens it |
| Long form more than one tool needs | one doc each tool's file points at, by code span in Copilot's | a Copilot file links it (below) |
| Derivable from the code | nowhere | never; `/doctor` proposes cutting it |

**A README is the agent's choice to open; a nested file is not.** In a
client Fabric repo, 5 of 9 sessions that worked in a folder with a
README opened it late or never, one after 52 Reads and Edits there
(2026-09-24). What a session must know before touching a folder goes in
a rule or a nested file, and the README keeps the rest.

## How Claude Code loads them

- **Root and every ancestor `CLAUDE.md` and `CLAUDE.local.md` load at
  launch.** A subdirectory's loads on the session's own first Read
  beneath it, after its ancestors'. Write, Grep, Glob and Bash load
  nothing, and a subagent's Read loads it into the subagent only.
- **After `/compact`** root is re-read at once, while nested files and
  `paths:` rules return only at the next matching Read.
- **A `.claude/rules/` file with no `paths:` loads at launch**, like root.
  A user-scope rule and a same-named project rule both load; neither
  overrides the other unless its text says so.
- **`AGENTS.md` is either/or.** Claude reads it only when no `CLAUDE.md`,
  `.claude/CLAUDE.md` or `CLAUDE.local.md` sits in the working directory
  or above it; `~/.claude/CLAUDE.md`, managed files, rules, and a
  `CLAUDE.md` that `claudeMdExcludes` skips do not count. So a root
  `CLAUDE.md` silences every `AGENTS.md` in the repo, nested ones
  included. `AGENTS.local.md`,
  `AGENTS.override.md` and `.agents/` are never read.
- **A repo cannot change that for the people who clone it.**
  `pluginConfigs["agents-md@builtin"].options.instructionFiles` is read
  from user, managed and `--settings` files, and ignored in project and
  local settings.
- **The transcript is the only reliable witness.** A nested `CLAUDE.md`
  arrives as a `nested_memory` attachment on the Read, a nested
  `AGENTS.md` as `hook_additional_context`. The InstructionsLoaded hook
  never fires for an `AGENTS.md` read directly, and missed two of four
  confirmed rule loads in one test (2026-09-01).
- **A `claudeMdExcludes` pattern stays driveless**, `**/<dir>/**`: one
  naming the drive misses whenever the letter's case differs from how the
  Read spelled the path (2026-09-24).

## Naming a nested file

| Root holds | Nested files are | Because |
| --- | --- | --- |
| `CLAUDE.md` | `CLAUDE.md` | no `AGENTS.md` is read |
| `AGENTS.md` only | `AGENTS.md` | a nested `CLAUDE.md` switches root off for any session launched beneath it |
| `CLAUDE.md` of `@AGENTS.md` | `CLAUDE.md`, importing a sibling `AGENTS.md` where other tools need it | a nested `AGENTS.md` alone is never read |

An instruction file kept as a test fixture or sample is live: Read, it
loads into that session like any other. Inside a Fabric item folder is
untested; a markdown file at a workspace's Git sync root coexists with
sync.

## Sharing one file with other tools

**Never cut a root `CLAUDE.md` over to a bare `AGENTS.md`.** With no
`CLAUDE.md` beside it, it loses five things, each silently:

1. A teammate's `CLAUDE.local.md` counts as a `CLAUDE.md`, and switches
   the project's `AGENTS.md` off for them.
2. It is not read before 2.1.277, in the first session after upgrading
   from an earlier release, with the `agents-md` plugin disabled, before
   2.1.281 on Bedrock or with telemetry off, or under `claude-md` or
   `managed-only`, which a client's managed settings can set. Each leaves
   the session with no project instructions.
3. InstructionsLoaded hooks do not fire for it.
4. An `--add-dir` directory's `AGENTS.md` never loads.
5. An `@path` import outside the repo loads only if external imports
   were already approved for the project, and nothing prompts.

**Use the import form instead**, the memory docs' own recipe: shared
content in `AGENTS.md`, and a `CLAUDE.md` that is `@AGENTS.md` followed
by the Claude-only lines. Everything then loads through a `CLAUDE.md`,
so none of the five applies, and the form nests. The cost is upkeep:
every level needs both files, and whatever keys on `CLAUDE.md`, a length
cap or a rule's glob, has to follow the content. On Windows import, never
symlink. An opening import trips markdownlint MD041, and
`<!-- markdownlint-disable-file MD041 -->` at the file's end silences it
at no context cost. It pays only where people use other tools, and two
conditions hold it together (a client Fabric repo, 2026-09-26):

- **Copilot's files point at shared long form by code span, never a
  Markdown link.** Under `chat.includeReferencedInstructions` a link in
  `copilot-instructions.md` or an applied `*.instructions.md` loads its
  target in full, 64 KB there, while links in `AGENTS.md` and `CLAUDE.md`
  are not followed. A code span holds under either value.
- **`chat.useClaudeMdFile` stays `false`.** On, Copilot also reads the
  `CLAUDE.md`, Claude-only lines included, and `~/.claude/CLAUDE.md` with
  it. VS Code's sources are additive, so a fact kept in both `AGENTS.md`
  and a Copilot file is read twice: give each fact one home.

**Every VS Code claim here is the Local agent harness.** In 1.139.1
`chat.useAgentsMdFile`, `chat.useNestedAgentsMdFiles` (off by default)
and `chat.useClaudeMdFile` each say they are "only used by the Local
agent harness" (2026-09-26); what the Agent Host harness reads is not
established. GitHub.com's Copilot agent differs again: it reads the
nearest `AGENTS.md` anywhere in the repo, else one root `CLAUDE.md` or
`GEMINI.md`, with no setting involved (docs.github.com, 2026-09-25).
