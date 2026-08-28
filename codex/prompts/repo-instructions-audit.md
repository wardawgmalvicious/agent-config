# Repo Instructions Audit Prompt

Use to check whether a repository has enough guidance for Codex.

```text
Audit this repository's Codex instructions.

Inspect:
- Root `AGENTS.md`
- Nested `AGENTS.md` or `AGENTS.override.md`
- `.codex/config.toml`
- `.codex/agents/*.toml`
- `.agents/skills/**/SKILL.md`
- README, docs, build scripts, test scripts, and CI config that affect agent behavior

Evaluate:
- Are setup, build, lint, test, and validation commands discoverable?
- Are coding conventions concrete and enforceable?
- Are security and production-data rules explicit?
- Are generated files, caches, secrets, and local state ignored?
- Are instructions duplicated or contradictory?
- Are Codex-native concepts used instead of Claude-only concepts?

Output:
- Findings ordered by severity.
- Specific file:line references.
- Recommended minimal edits.
- A short "good enough for Codex" checklist.

Do not modify files unless I explicitly ask after the audit.
```
