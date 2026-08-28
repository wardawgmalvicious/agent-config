# Codex payloads

Everything Codex-specific in this repo lives here. Deployment is
handled by [scripts/link-codex.ps1](../scripts/link-codex.ps1), which
keeps `CODEX_HOME` (normally `~/.codex`) real, non-Git, and
Codex-owned — it copies explicit leaf artifacts and never touches
`config.toml`, credentials, sessions, or other runtime state. Codex
also consumes this repo's shared [skills/](../skills/) via per-skill
junctions under `~/.agents/skills` (same script).

## What's here

| Path | Deployed to | Notes |
| --- | --- | --- |
| [AGENTS.md](AGENTS.md) | `CODEX_HOME/AGENTS.md` | Codex's user-scope global instructions (the analog of `claude/CLAUDE.md`). Not a mirror of the repo-root `AGENTS.md`, which is project-scope and never deployed. |
| [agents/](agents/) | `CODEX_HOME/agents/*.toml` | Custom agents (`code_reviewer`, `security_reviewer`). Validated for required keys before copying; home-only agents are preserved. |
| [prompts/](prompts/) | `CODEX_HOME/prompts/*.md` | Custom prompts (`fabric-task`, `repo-instructions-audit`). Home-only prompts are preserved. |
| [mcp/](mcp/) | not deployed | Codex `[mcp_servers]` TOML examples mirroring the JSON templates in [mcp/](../mcp/); copy blocks into `config.toml` by hand. |
| [config-examples/](config-examples/) | not deployed | Reference `config.toml` examples (user and project scope) for rebuilding a machine by hand. |

After editing any deployed file, re-run `scripts/link-codex.ps1`
(`-Force` after reviewing reported drift). The script copies rather
than links these because `CODEX_HOME` must never contain junctions
into a Git worktree.
