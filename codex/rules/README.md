# Command rules

Codex `.rules` files are execution policy, not Claude-style instruction
documents. They control which commands may run outside the sandbox through
`prefix_rule(...)` decisions such as `allow`, `prompt`, and `forbidden`.

This repository intentionally does not deploy a `.rules` file:

- Codex and the TUI may write machine-specific allow-list entries to
  `CODEX_HOME/rules/default.rules`.
- Permission decisions are security-sensitive and should not be inferred from
  the Claude language-guidance files.
- The linker preserves `CODEX_HOME/rules/` as user-owned state.

When a durable command policy is actually needed, author and test it
explicitly with `codex execpolicy check`; do not copy Markdown files or
Claude `paths:` frontmatter into this directory.

The Claude files under `claude/rules/` remain path-scoped coding guidance.
Codex has no direct file-glob instruction loader, so `codex/AGENTS.md` carries
the cross-language summary and tells Codex when to read the detailed source
guidance on demand.

Official references:

- [Codex rules](https://learn.chatgpt.com/docs/agent-configuration/rules)
- [Custom instructions with AGENTS.md](https://learn.chatgpt.com/docs/agent-configuration/agents-md)
