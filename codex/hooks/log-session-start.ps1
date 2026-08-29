<#
.SYNOPSIS
    Log selected Codex SessionStart metadata as JSONL.

.DESCRIPTION
    Reads one Codex hook event from standard input and appends a reduced event
    to CODEX_HOME/logs/session-started.jsonl. The hook is observability-only:
    it emits no stdout or stderr and fails open on malformed input or local
    filesystem errors.
#>
[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'

try {
    $rawInput = [Console]::In.ReadToEnd()
    if ([string]::IsNullOrWhiteSpace($rawInput)) {
        exit 0
    }

    $event = $rawInput | ConvertFrom-Json -AsHashtable
    $codexDir = if ([string]::IsNullOrWhiteSpace($env:CODEX_HOME)) {
        Join-Path $HOME '.codex'
    }
    else {
        $env:CODEX_HOME
    }

    $logDirectory = Join-Path $codexDir 'logs'
    if (-not (Test-Path -LiteralPath $logDirectory -PathType Container)) {
        New-Item -ItemType Directory -Path $logDirectory | Out-Null
    }

    $entry = [ordered]@{
        ts = [DateTimeOffset]::UtcNow.ToString('o')
        session_id = $event['session_id']
        cwd = $event['cwd']
        source = $event['source']
        model = $event['model']
        hook_event_name = $event['hook_event_name']
    }
    $line = $entry | ConvertTo-Json -Compress -Depth 4
    $logPath = Join-Path $logDirectory 'session-started.jsonl'
    $utf8NoBom = [Text.UTF8Encoding]::new($false)
    [IO.File]::AppendAllText($logPath, $line + [Environment]::NewLine, $utf8NoBom)
}
catch {
    # Observability hooks must not interrupt or add context to the session.
}

exit 0
