---
paths:
  - "**/*.ps1"
  - "**/*.psm1"
  - "**/*.psd1"
---

# PowerShell Coding Conventions

Applies to PowerShell scripts, modules, and data files. Target is
PowerShell 7+ (`pwsh`), not Windows PowerShell 5.1 — write 5.1-compatible
code only for the bootstrap catch-22 case, where a script must run before
pwsh itself is installed.

If a project-scope `.claude/rules/coding-powershell.md` exists, that file
supersedes this one.

## Baseline

- 4-space indent. No tabs. UTF-8 **without** BOM (pwsh 7 default) —
  but PSScriptAnalyzer's `PSUseBOMForUnicodeEncodedFile` fires on any
  file containing non-ASCII bytes, so one em dash or arrow in a comment
  forces `utf8BOM` to lint clean. Keep comments ASCII and stay BOM-free.
  (Verified Aug 2026, PSSA 1.25.0.)
- ~100 column soft limit.
- **No aliases in scripts.** `Get-ChildItem`, not `ls` / `gci` / `dir`.
  Aliases are for the interactive prompt only.
- Approved verbs only — check with `Get-Verb`. Unapproved verbs raise a
  warning on module import and read as non-idiomatic everywhere else.
- `[CmdletBinding()]` on any function or script taking parameters.
- Comment the **why**, not the what. A dense block explaining why a
  workaround exists is worth more than a line-by-line narration, and is
  the single most valuable thing to preserve when editing these scripts.

## Naming

- **Functions**: `Verb-Noun`, PascalCase, approved verb —
  `Write-Status`, `Test-WingetPackageInstalled`, `ConvertTo-MsysPath`.
- **Parameters**: PascalCase — `$PackageId`, `$OldRoot`, `$Execute`.
- **Local variables**: camelCase — `$packages`, `$oldQualifier`,
  `$blockers`.
- **Script-scope state**: `$script:PascalCase` — `$script:Failures`.
- Full words. `$sourcePath`, not `$srcPth`.

## Script structure

Entry-point scripts open with comment-based help, then `param`, then
preferences, then `#region` blocks:

```powershell
<#
.SYNOPSIS
    One line on what this does.
.DESCRIPTION
    What it deliberately does NOT do, and why, is often the more useful
    half here.
.PARAMETER Execute
    Actually perform the changes. Without it, this is a dry run.
.EXAMPLE
    pwsh -NoProfile -File .\Do-Thing.ps1 -Execute
#>
[CmdletBinding()]
param(
    [string]$OldRoot = 'C:\Default',
    [switch]$Execute
)

$ErrorActionPreference = 'Stop'
$script:Failures = @()

#region Pre-flight
# ...
#endregion
```

## Status output

Scripts that change machine state report through bracketed-level helpers
rather than bare `Write-Host`:

```powershell
function Step { param($m) Write-Host "`n=== $m" -ForegroundColor Cyan }
function Ok   { param($m) Write-Host "  [ok]   $m" -ForegroundColor Green }
function Plan { param($m) Write-Host "  [plan] $m" -ForegroundColor Yellow }
function Fail { param($m) Write-Host "  [FAIL] $m" -ForegroundColor Red
                $script:Failures += $m }
```

Levels in use across these repos: `ok`, `plan`, `warn`, `FAIL`,
`INSTALL`, `SKIP`, `EXPORT`, `INFO`.

**Report `SKIP` explicitly.** A step that silently does nothing when
already-correct is indistinguishable from a step that never ran. Count
the no-ops and say so — `"3 shim(s) already point at C:\Repos"`.

## Idempotency and dry-run

- **Default to reporting; require a switch to mutate.** `-Execute` (or
  `-WhatIf` via `SupportsShouldProcess`) to apply. The dry run must
  enumerate exactly what the real run would touch.
- Every step is skip-if-already-done, and says which branch it took.
- **Guard clauses that `return` must not block a re-run from reaching
  later steps.** A pre-flight that aborts when the first step's work is
  already done makes the whole script non-resumable, so a partial run
  can never be finished — it just no-ops. If steps can fail
  independently (elevation, a held file), detect the already-done state
  and continue in a resume mode instead of returning.
- `-Force` overrides guards; never make it override correctness checks.

## Error handling

**`try`/`catch` does not catch non-terminating cmdlet errors.** Most
cmdlet failures are non-terminating: the error prints, the `catch` never
fires, and the script continues into a broken state. Either set
`$ErrorActionPreference = 'Stop'` at the top or pass `-ErrorAction Stop`
on the call being guarded.

```powershell
# Bad — catch never fires, script continues
try { Get-Item $path } catch { Fail 'not found' }

# Good
try { Get-Item $path -ErrorAction Stop } catch { Fail "not found: $path" }
```

`-ErrorAction SilentlyContinue` **hides** an error, it does not ignore
one: `$?` is still `False` and `$Error` is still populated. Use it only
where absence is an expected outcome you are about to test for.

For multi-step machine scripts, prefer **accumulating** failures and
printing a summary over throwing on the first one — a half-applied
change the user cannot see is worse than a complete report with three
`[FAIL]` lines.

## JSON

**Use `ConvertFrom-Json -AsHashtable` for any JSON you did not author.**
Without the switch, a document whose keys differ only in casing throws
outright — the keys are treated as case-insensitive and the collision is
an error, not a last-one-wins merge. Real files hit this: `~/.claude.json`
carries both `C:/Users/...` and `c:/Users/...` project keys, which is
enough to make a plain `ConvertFrom-Json` fail on a perfectly valid file.

```powershell
# Bad — throws on a file with C:/... and c:/... keys
$null = $raw | ConvertFrom-Json

# Good
$json = $raw | ConvertFrom-Json -AsHashtable
```

Two consequences worth knowing:

- `-AsHashtable` emits an **`OrderedHashtable` with case-sensitive keys**
  (PowerShell 7.3+). Lookups that worked case-insensitively against the
  `PSCustomObject` will start missing. Match the literal casing.
- Duplicate keys are still last-one-wins; only *casing* collisions differ.

When a script validates JSON before overwriting a file, that validation
must use the same switch — otherwise the gate rejects good content and
the write is silently abandoned.

Docs: [ConvertFrom-Json](https://learn.microsoft.com/powershell/module/microsoft.powershell.utility/convertfrom-json)
(Example 4) and [about_Case-Sensitivity](https://learn.microsoft.com/powershell/module/microsoft.powershell.core/about/about_case-sensitivity#special-cases)
§7. Verified pwsh 7.6, Aug 2026.

## Windows and system operations

- **Check elevation in pre-flight, not at the point of failure.**
  `Set-ScheduledTask`, service changes, and machine-scope registry writes
  need admin. Failing at step five of six leaves a half-applied state and
  a confusing error.

  ```powershell
  $isAdmin = ([Security.Principal.WindowsPrincipal](
      [Security.Principal.WindowsIdentity]::GetCurrent())).IsInRole(
      [Security.Principal.WindowsBuiltInRole]::Administrator)
  ```

- **`-NoProfile` when a script touches profiles**, or anything else the
  current session loaded at startup. A script that rewrites
  `profile.ps1` must not be running under the copy it is replacing.
- Prefer `Test-Path` guards over `-ErrorAction SilentlyContinue` when
  absence is an expected, meaningful state.
- Registry paths use PSDrive prefixes (`HKLM:\SOFTWARE\...`), never raw
  `HKEY_LOCAL_MACHINE\...`.

## Strings and quoting

- Backtick (`` ` ``) is the escape character. Backslash is **not** — a
  Windows path in a double-quoted string needs no escaping.
- Single-quote unless interpolation is needed. `'C:\Repos\Personal'`
  is literal; `"$HOME\Repos"` interpolates.
- Here-strings: `@'...'@` literal, `@"..."@` interpolating. **The closing
  delimiter must be at column 0** — indenting it is a parse error.
- Escape `$` inside an interpolating string as `` `$ ``, e.g. a regex
  replacement referencing a named group: ``"`${d}:/$NewLeaf/"``.

## Anti-patterns

- Aliases in scripts (`ls`, `%`, `?`, `cat`).
- `try`/`catch` without `-ErrorAction Stop` — see above.
- `Write-Host` for data. It writes to the host, not the pipeline; use
  `Write-Output` for values and reserve `Write-Host` for the deliberate
  human-facing status lines described above.
- `New-Item -Force` on an existing file — it truncates the content.
- Mutating with no dry-run path.
- `Read-Host`, `Get-Credential`, `Out-GridView`, `pause` in anything that
  may run non-interactively (scheduled tasks, CI, agent sessions).
- Swallowing errors with `-ErrorAction SilentlyContinue` and no
  follow-up test.
- `$_` reused inside nested `ForEach-Object` blocks — bind the outer one
  to a named variable first.
