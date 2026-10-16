# Handoff: decide whether to act on Marketplace skill installs into ~/.claude/skills

- **Audit run**: 2026-10-16
- **Source**: `vscode-agent`
- **Window**: floor `c642b585` (2026-10-01, the 2026-10-06 run's head) →
  head `e6026c88` (2026-10-16)
- **Covers recommended actions**: 5
- **Kind**: a **decision**, flag-only, on an Experimental VS Code feature
  that can write a skill directory into `~/.claude/skills`. The audit
  proposes no edit until a VS Code profile here turns it on. The
  decision is the user's: `/drift-update` puts it back to the user
  rather than executing it.
- **Target**: none until decided

## The problem

VS Code 1.141's docs added a Customization Marketplace (Experimental)
that installs a whole skill package into a user or workspace skills
directory, and `~/.claude/skills/` is one of the personal skill
locations VS Code lists. A skill installed there is a real directory
beside this payload's junctions: `link-claude.ps1`'s prune skips it, and
the post-deploy check in root `CLAUDE.md` does not look for it. Nothing
is known to be installed, and the feature is off until a setting turns
it on.

## Evidence

**The docs.** `microsoft/vscode-docs`,
`docs/agent-customization/agent-skills.md` at head `e6026c88`, § "Install
a skill from the Customization Marketplace (Experimental)", added in
`4fe6b0340` ("VS Code release 1.141 (#10431)", 2026-10-06), verbatim:

```text
Use the Customization Marketplace to find and install complete skill packages from configured sources:

1. Turn on the `setting(chat.customizations.marketplace.enabled)` setting.
1. Open the Agent Customizations editor and select **Discover**.
1. From the source menu, select **GitHub Feed**, and then search for a skill by name or add `@type:skill` to your search.
1. Select a skill and review its publisher, source, and included files.
1. Select **Install**, and then choose the user or workspace skills directory where you want to store the skill.

{% data variables.product.prodname_vscode_shortname %} doesn't overwrite an existing skill at the selected destination. If another supported location contains a skill with the same name, both skills appear on the **Skills** page. The source or publisher image identifies the Marketplace installation, and **Copy Relative Path** shows its exact location.

Marketplace ownership applies to the exact installed skill directory. Deleting a Marketplace-installed skill from the **Skills** page uninstalls only that skill and doesn't remove a same-name local skill in another location.
```

The same page's locations table, at head:

```text
| Personal skills, stored in your home directory | `~/.copilot/skills/`, `~/.claude/skills/`, `~/.agents/skills/` |
```

**Its default.** Step 1 says to turn the setting on.
`docs/agents/reference/ai-settings.md` at head has no row for
`chat.customizations.marketplace.enabled`, so the docs state no default
outright. Whether any VS Code profile on this machine sets it was not
checked.

**Why an install would go unseen here.**

- `scripts/link-claude.ps1:736-748`, the skills prune, opens: "Only ever
  touch a junction whose target resolves inside this repo's skills/ tree
  — a real directory, or a link into another repo, belongs to someone
  else." Line 741 skips every entry that is not a reparse point:
  `if (-not ($item.Attributes -band [IO.FileAttributes]::ReparsePoint)) { continue }`.
  `.claude/rules/deploy-scripts.md` records the same skip keeping Claude
  Code's own `synced/` and `.trash/`.
- Root `CLAUDE.md` § "Commands" checks a deploy with
  `ls ~/.claude/skills | grep -E '^(fabric|pbir|pbid|pbip|powerbi|msix)-'`,
  "after any deploy: must print nothing", which looks for platform
  prefixes only.
- Claude Code finds a skill one level deep,
  `<skills-root>/<name>/SKILL.md` (`.claude/rules/deploy-scripts.md`), so
  it would list an installed one like any user-scope skill.

## The decision

Put to the user:

- **A — no edit now**, the audit's proposal. Revisit when a VS Code
  profile here turns `chat.customizations.marketplace.enabled` on,
  starting from this brief's evidence.
- **B — record it now**: name a Marketplace install among what the
  prune leaves and the deploy check misses. `.claude/rules/deploy-scripts.md`
  already lists what the prune leaves. The audit chose no home and
  wrote no text, so on B scope the edit as a task of its own.

## What to change

On A, nothing outside this directory: record the answer in this brief's
execution log. On B, nothing from this brief directly; the scoped task
carries the edit and its verification.

## Verification

On A:

1. `git status --short` — nothing changed outside
   `docs/audits/2026-10-16/vscode-agent/`.
2. Optional, if A's premise is in doubt: read, without editing, whether
   any VS Code profile sets the key. Each profile keeps its own
   `settings.json`, Default's at `%APPDATA%\Code\User\settings.json` and
   the rest under `%APPDATA%\Code\User\profiles\<id>\`
   (`~/.claude/rules/vscode-scoping.md`).

Either way:

3. `uv run scripts/audit-status.py --check`.
4. `pre-commit run --all-files`.

## Provenance

Recommended action 5 of the 2026-10-16 `/drift-audit vscode-agent` run,
flag-only, from its MCP / tooling / CLI bucket. The audit read the
section in its base-to-head diff of `agent-skills.md` and the prune in
`scripts/link-claude.ps1`. The landing that added the section and the
missing settings row were read from the run's scratchpad clone while
this brief was written.
