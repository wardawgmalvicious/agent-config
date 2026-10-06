# Handoff: ask machine-config whether its profile audit checks `chat.useClaudeHooks`

- **Audit run**: 2026-10-06
- **Source**: `vscode-agent`
- **Window**: floor `2026-09-01` (diff base `28f76f5f`, 2026-08-28) →
  head `c642b585` (2026-10-01)
- **Covers recommended actions**: 3
- **Kind**: an **edit** outside this repo, at most one note to
  `~/handoff-inbox/machine-config/`, and likely none: the answer was
  found while this brief was written (see Evidence).
- **Target**: `~/handoff-inbox/machine-config/`, a new note, or nothing

## The problem

VS Code's docs now gate Claude-format hooks in the Local harness on
`chat.useClaudeHooks`, off by default. `claude/rules/vscode-scoping.md`
`:107-111` says machine-config's `scripts/vscode-profiles.ps1 -Audit`
has reported "any profile leaving a Claude location or switch on" since
2026-09-24, but nothing in this repo records whether
`chat.useClaudeHooks` is one of those switches. The audit's action is
to ask machine-config through its inbox.

## Evidence

**The docs.** The hooks page, § "Local hook file locations" (`91b05da`,
2026-09-21; live site checked 2026-10-06): "User, Claude format |
`~/.claude/settings.json` | Requires chat.useClaudeHooks". The source
markdown adds "which is off by default".

**The answer, found on 2026-10-06 while this brief was written.**
machine-config's `configs/vscode/profiles/profiles.psd1:109-124`
already lists the switch:

```powershell
    # The on/off switches for the rest of the payload, each mapped to VS Code's
    # default, which is what a profile that leaves one unset gets. A switch is
    # flagged when that effective value is not false. useClaudeMdFile defaults
    # ON: CLAUDE.md from the workspace, .claude/ and ~/.claude. useClaudeHooks
    # defaults off, and gates whether Claude-format hooks run at all.
    # (lines 114-120, on the Local harness, omitted here)
    ClaudeSwitches      = @{
        'chat.useClaudeMdFile' = $true
        'chat.useClaudeHooks'  = $false
    }
```

It arrived in `13c7b89` (2026-09-24), "feat(profiles): audit flags a
profile that lets Copilot read Claude's files".
`scripts/vscode-profiles.ps1` passes `ClaudeSwitches` to
`Find-ClaudeInheritance` for Default (`:401-417`) and for each named
profile (`:456-464`).

## What to change

1. Re-read `ClaudeSwitches` in machine-config's
   `configs/vscode/profiles/profiles.psd1`. Read only.
2. **If it still lists `'chat.useClaudeHooks'`**, write no note: the
   question is answered. Say so in this brief's execution log, citing
   the file and `13c7b89`.
3. **Only if it does not**, read `~/handoff-inbox/README.md`, then write
   one note to `~/handoff-inbox/machine-config/` asking whether the
   audit should check `chat.useClaudeHooks`, quoting the docs line above
   with its date.

## Constraint on the fix

- **Never edit machine-config from here.** A change to another repo
  goes through its inbox (`~/.claude/CLAUDE.md` § "Agent config
  source").
- **Do not message a machine-config session.** The inbox is the route
  unless the user starts a coordination.

## Verification

1. Answered case:
   `grep -n "chat.useClaudeHooks" /c/Repos/Personal/machine-config/configs/vscode/profiles/profiles.psd1`
   prints the `ClaudeSwitches` line, and this brief added no file under
   `~/handoff-inbox/machine-config/`.
2. Note case: `uv run scripts/handoff-status.py` lists the new note in
   machine-config's inbox.

## Provenance

The 2026-10-06 audit raised this question from `vscode-scoping.md`
`:107-111` without reading machine-config. Reading its manifest the
same day answered it. The brief stays because the report lists the
action (`00-audit-report.md`, recommended action 3), and every action
takes exactly one brief.
