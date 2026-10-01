<#
.SYNOPSIS
    A stand-in for gh, for tests/scripts/repo-settings/ only.

.DESCRIPTION
    The suite copies this file into a temp directory as gh.ps1 and puts that
    directory first on PATH, so repo-settings.ps1 calls it in place of gh.
    It never reaches the network: it answers from the api/ tree beside it
    and appends each call to calls.log there, which is how a case shows
    that a refusal came before the first gh call.

      api user -q .login        login.txt
      api -X GET <path>         api/<path>.json, printed; api/<path>.204,
                                an empty success; anything else is gh's
                                HTTP 404
      api -X POST graphql       api/graphql.json
      api -X PATCH repos/<owner>/<name>
                                merges the body into that repo's .json,
                                so a re-check sees the write
      any other write           logged only

    No param block and no [CmdletBinding()]: gh's own flags (-X, -H, -q)
    must arrive in $args, as they would at the real binary.
#>
$here = $PSScriptRoot
$log = Join-Path $here 'calls.log'
$body = @($input) -join "`n"

if ($args.Count -ge 2 -and $args[0] -eq 'api' -and $args[1] -eq 'user') {
    Add-Content -LiteralPath $log -Value 'GET user'
    Get-Content -LiteralPath (Join-Path $here 'login.txt')
    exit 0
}
if ($args.Count -lt 4 -or $args[0] -ne 'api' -or $args[1] -ne '-X') {
    Add-Content -LiteralPath $log -Value "UNSUPPORTED $args"
    Write-Output "gh stub: unsupported call: $args"
    exit 2
}

$method = $args[2]
$endpoint = $args[3]
Add-Content -LiteralPath $log -Value "$method $endpoint"
$file = Join-Path (Join-Path $here 'api') $endpoint

if ($method -eq 'GET' -or $endpoint -eq 'graphql') {
    if (Test-Path -LiteralPath "$file.json") { Get-Content -LiteralPath "$file.json" -Raw; exit 0 }
    if (Test-Path -LiteralPath "$file.204") { exit 0 }
    Write-Output 'gh: Not Found (HTTP 404)'
    exit 1
}
if ($method -eq 'PATCH' -and $endpoint -match '^repos/[^/]+/[^/]+$' -and
    (Test-Path -LiteralPath "$file.json")) {
    $state = Get-Content -LiteralPath "$file.json" -Raw | ConvertFrom-Json -AsHashtable
    $patch = $body | ConvertFrom-Json -AsHashtable
    foreach ($key in $patch.Keys) { $state[$key] = $patch[$key] }
    $state | ConvertTo-Json -Depth 20 | Set-Content -LiteralPath "$file.json"
}
exit 0
