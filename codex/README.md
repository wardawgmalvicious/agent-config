# Codex payloads

Everything Codex-specific in this repo lives here. Deployment is
handled by [scripts/link-codex.ps1](../scripts/link-codex.ps1), which
keeps `CODEX_HOME` (normally `~/.codex`) real, non-Git, and
Codex-owned — it copies explicit leaf artifacts and never touches
`config.toml`, credentials, sessions, command rules, or other runtime state.
Codex also consumes this repo's shared [skills/](../skills/) via per-skill
junctions under `~/.agents/skills` (same script).

## What's here

| Path | Deployed to | Notes |
| --- | --- | --- |
| [AGENTS.md](AGENTS.md) | `CODEX_HOME/AGENTS.md` | Codex's user-scope global instructions (the analog of `claude/CLAUDE.md`). Not a mirror of the repo-root `AGENTS.md`, which is project-scope and never deployed. |
| [agents/](agents/) | `CODEX_HOME/agents/*.toml` | Custom agents (`code_reviewer`, `security_reviewer`). Validated for required keys before copying; home-only agents are preserved. |
| [hooks.json](hooks.json) | `CODEX_HOME/hooks.json` | User-scope lifecycle hook registration. Codex requires review and trust when the definition changes. |
| [hooks/](hooks/) | `CODEX_HOME/hooks/*.ps1` | PowerShell hook implementations. Home-only hook scripts are preserved. |
| [prompts/](prompts/) | `CODEX_HOME/prompts/*.md` | Custom prompts (`fabric-task`, `repo-instructions-audit`). Home-only prompts are preserved. |
| [rules/](rules/) | not deployed | Explains why Codex command rules are not equivalents of Claude path-scoped guidance. `CODEX_HOME/rules/` remains user/TUI-owned. |
| [mcp/](mcp/) | not deployed | Codex `[mcp_servers]` TOML examples mirroring the JSON templates in [mcp/](../mcp/); copy blocks into `config.toml` by hand. |
| [config-examples/](config-examples/) | not deployed | Reference `config.toml` examples (user and project scope) for rebuilding a machine by hand. |

After editing any deployed file, re-run `scripts/link-codex.ps1`
(`-Force` after reviewing reported drift). The script copies rather
than links these because `CODEX_HOME` must never contain junctions
into a Git worktree.

## Claude parity boundaries

Codex hooks closely match Claude lifecycle hooks, but event names and payloads
are not universally interchangeable. See [hooks/README.md](hooks/README.md)
for the implemented mappings and intentional omissions.

Claude's `claude/rules/*.md` files are model guidance selected by path globs.
Codex `.rules` files are experimental command-execution policy. They must not
be mirrored by filename or content; detailed coding guidance remains an
on-demand reference directed by `AGENTS.md` and skills.
