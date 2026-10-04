# VS Code workspace config

Ordinary workspace config, live for this repo only:

| File | Role |
| --- | --- |
| [settings.json](settings.json) | Schema binding for `claude/settings.json`, fixture file associations, markdown link validation. |
| [tasks.json](tasks.json) | The commands from [CLAUDE.md](../CLAUDE.md#commands), in their safe form — notably `link-claude.ps1` with `-SkillGroups workflow,social,meta`, never bare. |
| [extensions.json](extensions.json) | Extension recommendations matched to the file types actually in the repo. |

Everything else in `.vscode/` is gitignored; this README and the three
files above are explicitly un-ignored in [.gitignore](../.gitignore).

Line endings are **not** configured here — [.gitattributes](../.gitattributes)
is authoritative at commit time and root [.editorconfig](../.editorconfig)
covers the editor side, so `files.eol` is deliberately absent from
[settings.json](settings.json).

## No `mcp.json`

VS Code reads the root [.mcp.json](../.mcp.json) itself, the same file
Claude Code does, so this repo keeps one server list and no
`.vscode/mcp.json` (2026-10-04). The VS Code-schema template that sat
here went with it. What VS Code's own agents make of `${VAR}` and
`headersHelper` in `.mcp.json`, and how to check which servers a window
registered, is in [claude/mcp/README.md](../claude/mcp/README.md).
