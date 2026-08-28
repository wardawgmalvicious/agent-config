<#
.SYNOPSIS
    Link this repo's durable Codex content without linking CODEX_HOME itself.

.DESCRIPTION
    Keeps CODEX_HOME (normally ~/.codex) as a real, Codex-owned directory and
    manages only explicit leaf artifacts:

    - One junction per repo skill under ~/.agents/skills, the user-scope skill
      location shared by Codex and GitHub Copilot.
    - codex/AGENTS.md -> CODEX_HOME/AGENTS.md as a plain copy, when the repo
      source exists.
    - codex/agents/*.toml -> CODEX_HOME/agents/*.toml as plain copies, when
      repo sources exist.
    - codex/prompts/*.md -> CODEX_HOME/prompts/*.md as plain copies, when
      repo sources exist.

    The script deliberately never links or copies config.toml, auth.json,
    sessions, databases, caches, plugins, CODEX_HOME/skills, or any other
    Codex-managed state. It refuses to operate when CODEX_HOME itself is a
    reparse point or a Git working-tree root.

    Existing correct skill junctions and equal mirror files are left alone.
    Stale per-skill junctions are repaired. Real items at managed paths and
    drifted mirror files are reported unless -Force is passed. Home-only
    skills and custom agents are preserved; removed repo items are not pruned
    because ownership cannot be proven safely without a manifest.

.PARAMETER Force
    Replace real items that collide with repo skill names and overwrite
    drifted managed copies. Never overrides the CODEX_HOME safety checks and
    never touches Codex runtime state.

.PARAMETER CodexDir
    Codex's state directory. Defaults to CODEX_HOME when set, otherwise
    ~/.codex. Mainly useful for isolated testing.

.PARAMETER AgentsDir
    The shared agents directory containing user skills. Defaults to ~/.agents.
    Mainly useful for isolated testing.

.EXAMPLE
    ./scripts/link-codex.ps1

.EXAMPLE
    ./scripts/link-codex.ps1 -Force
#>
[CmdletBinding()]
param(
    [switch]$Force,
    [string]$CodexDir,
    [string]$AgentsDir = (Join-Path $HOME '.agents')
)

$ErrorActionPreference = 'Stop'

if ([string]::IsNullOrWhiteSpace($CodexDir)) {
    if ([string]::IsNullOrWhiteSpace($env:CODEX_HOME)) {
        $CodexDir = Join-Path $HOME '.codex'
    }
    else {
        $CodexDir = $env:CODEX_HOME
    }
}

$CodexDir = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($CodexDir)
$AgentsDir = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($AgentsDir)

$repoRoot = Split-Path -Parent $PSScriptRoot
$skillsSource = Join-Path $repoRoot 'skills'
$skillsDestination = Join-Path $AgentsDir 'skills'
$globalAgentsSource = Join-Path $repoRoot 'codex\AGENTS.md'
$codexAgentsSource = Join-Path $repoRoot 'codex\agents'
$codexPromptsSource = Join-Path $repoRoot 'codex\prompts'
$script:DriftCount = 0
$script:ManagedCopyCount = 0

function Get-LinkTarget {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [System.IO.FileSystemInfo]$Item
    )

    # PowerShell 7.1+ exposes LinkTarget; Windows PowerShell 5.1 exposes
    # Target, which may be an array.
    if ($Item.PSObject.Properties['LinkTarget'] -and $Item.LinkTarget) {
        return $Item.LinkTarget
    }
    if ($Item.PSObject.Properties['Target'] -and $Item.Target) {
        return @($Item.Target)[0]
    }
    return $null
}

function Test-SamePath {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$First,

        [Parameter(Mandatory)]
        [string]$Second
    )

    return [IO.Path]::GetFullPath($First).TrimEnd('\') -ieq
        [IO.Path]::GetFullPath($Second).TrimEnd('\')
}

function Test-PathsOverlap {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$First,

        [Parameter(Mandatory)]
        [string]$Second
    )

    $firstPath = [IO.Path]::GetFullPath($First).TrimEnd('\')
    $secondPath = [IO.Path]::GetFullPath($Second).TrimEnd('\')
    $separator = [IO.Path]::DirectorySeparatorChar

    return $firstPath -ieq $secondPath -or
        $firstPath.StartsWith($secondPath + $separator, [StringComparison]::OrdinalIgnoreCase) -or
        $secondPath.StartsWith($firstPath + $separator, [StringComparison]::OrdinalIgnoreCase)
}

function Get-GitWorkTreeAncestor {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Path
    )

    # DirectoryInfo can represent a path that does not exist, so this check
    # stays read-only and runs before the script creates CODEX_HOME.
    $candidate = [IO.DirectoryInfo]::new([IO.Path]::GetFullPath($Path))
    while ($candidate) {
        if (Test-Path -LiteralPath (Join-Path $candidate.FullName '.git')) {
            return $candidate.FullName
        }
        $candidate = $candidate.Parent
    }
    return $null
}

function Get-ReparsePointAncestor {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Path
    )

    $candidate = [IO.DirectoryInfo]::new([IO.Path]::GetFullPath($Path))
    while ($candidate) {
        $item = Get-Item -Force -LiteralPath $candidate.FullName -ErrorAction SilentlyContinue
        if ($item -and ($item.Attributes -band [IO.FileAttributes]::ReparsePoint)) {
            return $item.FullName
        }
        $candidate = $candidate.Parent
    }
    return $null
}

function Test-RepairableLink {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [System.IO.FileSystemInfo]$Item
    )

    if (-not ($Item.Attributes -band [IO.FileAttributes]::ReparsePoint)) {
        return $false
    }

    $linkType = if ($Item.PSObject.Properties['LinkType']) { $Item.LinkType } else { $null }
    $target = Get-LinkTarget -Item $Item
    return $linkType -in 'Junction', 'SymbolicLink' -and -not [string]::IsNullOrWhiteSpace($target)
}

function Test-CodexAgentFile {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Path
    )

    $content = Get-Content -Raw -LiteralPath $Path
    foreach ($requiredKey in 'name', 'description', 'developer_instructions') {
        $escapedKey = [Regex]::Escape($requiredKey)
        if ($content -notmatch "(?m)^\s*$escapedKey\s*=") {
            throw "Codex agent is missing required key '$requiredKey': $Path"
        }
    }
}

function Initialize-ManagedDirectory {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Path,

        [Parameter(Mandatory)]
        [string]$DisplayName
    )

    # Normalize a copy-destination directory under CODEX_HOME: detach a link
    # (its target survives), replace a file, or create the directory. Returns
    # $false when the path needs manual attention and copies must not proceed.
    $item = Get-Item -Force -LiteralPath $Path -ErrorAction SilentlyContinue

    if ($item -and ($item.Attributes -band [IO.FileAttributes]::ReparsePoint)) {
        if (-not (Test-RepairableLink -Item $item)) {
            Write-Warning ("$Path is an unsupported reparse point. It was " +
                'left untouched; reconcile it manually.')
            $script:DriftCount++
            return $false
        }
        if (-not $Force) {
            $oldTarget = Get-LinkTarget -Item $item
            Write-Warning ("$Path is linked to $oldTarget. Re-run with " +
                '-Force to detach the link without deleting its target.')
            $script:DriftCount++
            return $false
        }
        $item.Delete()
        New-Item -ItemType Directory -Path $Path | Out-Null
        Write-Host "Normalized $DisplayName directory (-Force; old target preserved)"
        return $true
    }

    if ($item -and -not $item.PSIsContainer) {
        if (-not $Force) {
            Write-Warning ("$Path is a file. Move it aside or re-run with " +
                '-Force to DELETE it.')
            $script:DriftCount++
            return $false
        }
        Remove-Item -LiteralPath $Path -Force
        New-Item -ItemType Directory -Path $Path | Out-Null
        Write-Host "Replaced $DisplayName file with a directory (-Force)"
        return $true
    }

    if (-not $item) {
        New-Item -ItemType Directory -Path $Path | Out-Null
        Write-Host "Created $Path"
    }
    return $true
}

function Copy-ManagedFile {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Source,

        [Parameter(Mandatory)]
        [string]$Destination,

        [Parameter(Mandatory)]
        [string]$DisplayName
    )

    $existing = Get-Item -Force -LiteralPath $Destination -ErrorAction SilentlyContinue
    if ($existing -and ($existing.Attributes -band [IO.FileAttributes]::ReparsePoint)) {
        if (-not (Test-RepairableLink -Item $existing)) {
            Write-Warning ("$Destination is an unsupported reparse point. " +
                'It was left untouched; reconcile it manually.')
            $script:DriftCount++
            return
        }
        $oldTarget = Get-LinkTarget -Item $existing
        if ($existing.PSIsContainer) {
            if (-not $Force) {
                Write-Warning ("$Destination is a linked directory -> $oldTarget. " +
                    'Re-run with -Force to detach it without deleting the target.')
                $script:DriftCount++
                return
            }
            $existing.Delete()
            Copy-Item -LiteralPath $Source -Destination $Destination
            Write-Host "Replaced linked directory with $DisplayName (-Force)"
            $script:ManagedCopyCount++
            return
        }

        # Detach a file link while preserving its current bytes. Normal hash
        # comparison below then reports drift instead of silently choosing
        # either side. A broken link has no home content to preserve.
        if (Test-Path -LiteralPath $Destination -PathType Leaf) {
            $destinationBytes = [IO.File]::ReadAllBytes($Destination)
            $existing.Delete()
            [IO.File]::WriteAllBytes($Destination, $destinationBytes)
            Write-Host "Normalized $DisplayName (was a link -> $oldTarget)"
            $script:ManagedCopyCount++
            $existing = Get-Item -Force -LiteralPath $Destination
        }
        else {
            $existing.Delete()
            Copy-Item -LiteralPath $Source -Destination $Destination
            Write-Host "Normalized $DisplayName (was a broken link -> $oldTarget)"
            $script:ManagedCopyCount++
            return
        }
    }

    if ($existing -and $existing.PSObject.Properties['LinkType'] -and
        $existing.LinkType -eq 'HardLink') {
        # A hard link has no ReparsePoint flag. Preserve the home-side bytes
        # while replacing only its directory entry, then apply drift rules.
        $destinationBytes = [IO.File]::ReadAllBytes($Destination)
        Remove-Item -LiteralPath $Destination -Force
        [IO.File]::WriteAllBytes($Destination, $destinationBytes)
        Write-Host "Normalized $DisplayName (was a hard link)"
        $script:ManagedCopyCount++
        $existing = Get-Item -Force -LiteralPath $Destination
    }

    if ($existing -and $existing.PSIsContainer) {
        if (-not $Force) {
            Write-Warning ("$Destination is a directory, not a managed file. " +
                'Move it aside or re-run with -Force to DELETE it.')
            $script:DriftCount++
            return
        }
        Remove-Item -LiteralPath $Destination -Recurse -Force
        Copy-Item -LiteralPath $Source -Destination $Destination
        Write-Host "Replaced $DisplayName directory with a file (-Force)"
        $script:ManagedCopyCount++
        return
    }

    if (-not $existing) {
        Copy-Item -LiteralPath $Source -Destination $Destination
        Write-Host "Copied  $DisplayName (home copy was missing)"
        $script:ManagedCopyCount++
        return
    }

    if ((Get-FileHash -LiteralPath $Source).Hash -eq
        (Get-FileHash -LiteralPath $Destination).Hash) {
        Write-Host "OK      $DisplayName (in sync)"
        return
    }

    if ($Force) {
        Copy-Item -LiteralPath $Source -Destination $Destination -Force
        Write-Host "Pushed  $DisplayName repo -> home (-Force)"
        $script:ManagedCopyCount++
        return
    }

    Write-Warning ("$DisplayName differs between repo and home. Reconcile " +
        "($Source | $Destination), or re-run with -Force to overwrite home.")
    $script:DriftCount++
}

# Validate every root before creating or deleting anything. Destination roots
# must not overlap this repository or live anywhere inside another worktree.
if (Test-PathsOverlap -First $CodexDir -Second $repoRoot) {
    throw "Refusing Codex home that overlaps this repository: $CodexDir"
}
if (Test-PathsOverlap -First $AgentsDir -Second $repoRoot) {
    throw "Refusing shared agents root that overlaps this repository: $AgentsDir"
}
if (Test-PathsOverlap -First $CodexDir -Second $AgentsDir) {
    throw 'Refusing overlapping Codex and shared agents roots.'
}

$codexReparseAncestor = Get-ReparsePointAncestor -Path $CodexDir
if ($codexReparseAncestor) {
    throw "Refusing Codex home beneath reparse point: $codexReparseAncestor"
}
$agentsReparseAncestor = Get-ReparsePointAncestor -Path $AgentsDir
if ($agentsReparseAncestor) {
    throw "Refusing shared agents root beneath reparse point: $agentsReparseAncestor"
}

$codexGitRoot = Get-GitWorkTreeAncestor -Path $CodexDir
if ($codexGitRoot) {
    throw "Refusing Codex home inside Git worktree ${codexGitRoot}: $CodexDir"
}
$agentsGitRoot = Get-GitWorkTreeAncestor -Path $AgentsDir
if ($agentsGitRoot) {
    throw "Refusing shared agents root inside Git worktree ${agentsGitRoot}: $AgentsDir"
}

# CODEX_HOME mixes durable configuration with credentials and high-churn
# runtime state. It must never be redirected wholesale into a repository.
$codexRoot = Get-Item -Force -LiteralPath $CodexDir -ErrorAction SilentlyContinue
if ($codexRoot) {
    if (-not $codexRoot.PSIsContainer) {
        throw "Codex home is not a directory: $CodexDir"
    }
    if ($codexRoot.Attributes -band [IO.FileAttributes]::ReparsePoint) {
        $rootTarget = Get-LinkTarget -Item $codexRoot
        throw "Refusing linked Codex home: $CodexDir -> $rootTarget"
    }
}
else {
    New-Item -ItemType Directory -Path $CodexDir | Out-Null
    Write-Host "Created $CodexDir"
}

Write-Host 'SKIP    config.toml and Codex runtime state (home-owned)'
Write-Host 'SKIP    CODEX_HOME/skills (Codex system-managed)'

# Codex and GitHub Copilot both discover personal skills under
# ~/.agents/skills. Keep that shared root real and link each repo skill
# individually so other providers can coexist.
if (-not (Test-Path -LiteralPath $skillsSource -PathType Container)) {
    throw "Repo skills directory not found: $skillsSource"
}

$agentsRoot = Get-Item -Force -LiteralPath $AgentsDir -ErrorAction SilentlyContinue
if ($agentsRoot) {
    if (-not $agentsRoot.PSIsContainer) {
        throw "Shared agents path is not a directory: $AgentsDir"
    }
    if ($agentsRoot.Attributes -band [IO.FileAttributes]::ReparsePoint) {
        throw "Refusing linked shared agents root: $AgentsDir"
    }
}
else {
    New-Item -ItemType Directory -Path $AgentsDir | Out-Null
    Write-Host "Created $AgentsDir"
}

$skillsRoot = Get-Item -Force -LiteralPath $skillsDestination -ErrorAction SilentlyContinue
if ($skillsRoot) {
    if (-not $skillsRoot.PSIsContainer) {
        throw "Shared skills path is not a directory: $skillsDestination"
    }
    if ($skillsRoot.Attributes -band [IO.FileAttributes]::ReparsePoint) {
        throw "Refusing linked shared skills root: $skillsDestination"
    }
}
else {
    New-Item -ItemType Directory -Path $skillsDestination | Out-Null
    Write-Host "Created $skillsDestination"
}

$repoSkills = @(Get-ChildItem -LiteralPath $skillsSource -Directory)
foreach ($skill in $repoSkills) {
    $target = $skill.FullName
    $link = Join-Path $skillsDestination $skill.Name
    $existing = Get-Item -Force -LiteralPath $link -ErrorAction SilentlyContinue

    if ($existing) {
        if ($existing.Attributes -band [IO.FileAttributes]::ReparsePoint) {
            if (-not (Test-RepairableLink -Item $existing)) {
                Write-Warning ("$link is an unsupported reparse point. It was " +
                    'left untouched; reconcile it manually.')
                $script:DriftCount++
                continue
            }
            $currentTarget = Get-LinkTarget -Item $existing
            if ($currentTarget -and (Test-SamePath -First $currentTarget -Second $target)) {
                Write-Host "OK      skill $($skill.Name)"
                continue
            }
            $existing.Delete()
            Write-Host "Relink  skill $($skill.Name) (was -> $currentTarget)"
        }
        else {
            if (-not $Force) {
                $itemType = if ($existing.PSIsContainer) { 'directory' } else { 'file' }
                Write-Warning ("$link is a real $itemType, not a junction. Move it " +
                    'aside, or re-run with -Force to DELETE it and link the repo skill.')
                $script:DriftCount++
                continue
            }
            if ($existing.PSIsContainer) {
                Remove-Item -LiteralPath $link -Recurse -Force
            }
            else {
                Remove-Item -LiteralPath $link -Force
            }
            Write-Host "Removed real item $link (-Force)"
        }
    }

    New-Item -ItemType Junction -Path $link -Target $target | Out-Null
    Write-Host "Linked  skill $($skill.Name) -> $target"
}

# Root AGENTS.md is repository-scoped and already loads in this repo. Only
# the deliberately authored codex/AGENTS.md may be deployed to user scope.
if (Test-Path -LiteralPath $globalAgentsSource -PathType Leaf) {
    $agentsOverride = Join-Path $CodexDir 'AGENTS.override.md'
    if (Test-Path -LiteralPath $agentsOverride) {
        Write-Warning ("$agentsOverride shadows the managed global AGENTS.md. " +
            'The override is preserved; remove or reconcile it explicitly.')
        $script:DriftCount++
    }
    Copy-ManagedFile -Source $globalAgentsSource `
        -Destination (Join-Path $CodexDir 'AGENTS.md') `
        -DisplayName 'AGENTS.md'
}
else {
    Write-Host 'SKIP    global AGENTS.md (codex/AGENTS.md is not present)'
}

# Codex custom agents use TOML, unlike the Claude agent markdown in agents/.
# Copy files individually so home-only agents can coexist.
$repoAgentFiles = @()
if (Test-Path -LiteralPath $codexAgentsSource -PathType Container) {
    $repoAgentFiles = @(Get-ChildItem -LiteralPath $codexAgentsSource -Filter '*.toml' -File)
}

if ($repoAgentFiles.Count -eq 0) {
    Write-Host 'SKIP    Codex custom agents (codex/agents/*.toml is not present)'
}
else {
    foreach ($agentFile in $repoAgentFiles) {
        Test-CodexAgentFile -Path $agentFile.FullName
    }

    $codexAgentsDestination = Join-Path $CodexDir 'agents'
    if (Initialize-ManagedDirectory -Path $codexAgentsDestination -DisplayName 'agents') {
        foreach ($agentFile in $repoAgentFiles) {
            Copy-ManagedFile -Source $agentFile.FullName `
                -Destination (Join-Path $codexAgentsDestination $agentFile.Name) `
                -DisplayName "agent $($agentFile.Name)"
        }
    }
}

# Codex discovers custom prompts as CODEX_HOME/prompts/*.md. Copy files
# individually so home-only prompts can coexist.
$repoPromptFiles = @()
if (Test-Path -LiteralPath $codexPromptsSource -PathType Container) {
    $repoPromptFiles = @(Get-ChildItem -LiteralPath $codexPromptsSource -Filter '*.md' -File)
}

if ($repoPromptFiles.Count -eq 0) {
    Write-Host 'SKIP    Codex custom prompts (codex/prompts/*.md is not present)'
}
else {
    $codexPromptsDestination = Join-Path $CodexDir 'prompts'
    if (Initialize-ManagedDirectory -Path $codexPromptsDestination -DisplayName 'prompts') {
        foreach ($promptFile in $repoPromptFiles) {
            Copy-ManagedFile -Source $promptFile.FullName `
                -Destination (Join-Path $codexPromptsDestination $promptFile.Name) `
                -DisplayName "prompt $($promptFile.Name)"
        }
    }
}

if ($script:DriftCount -gt 0) {
    Write-Host "`nDone with $script:DriftCount item(s) needing attention (see warnings above)."
    exit 1
}

Write-Host ("`nDone. $($repoSkills.Count) skills verified; " +
    "$script:ManagedCopyCount managed file(s) updated.")
exit 0
