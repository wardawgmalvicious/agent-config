<#
.SYNOPSIS
    Register a DAXEvaluationLog trace on a connected Power BI Desktop msmdsrv instance.

.DESCRIPTION
    Subscribes to event class 135 (DAXEvaluationLog) and accumulates each event into
    a synchronized ArrayList. Dot-source this script: $trace, $evalEvents, and $job
    are left in the caller's scope. Cleanup is the caller's responsibility.

.NOTES
    Prerequisites:
      - msmdsrv reachable on localhost
      - $server is a connected Microsoft.AnalysisServices.Tabular.Server instance
        (port discovery + connection: see SKILL.md section
        "Discovering Running PBID Instances")

.EXAMPLE
    . ./setup-evaluateandlog-trace.ps1
    # ... run DAX with EVALUATEANDLOG-wrapped expressions; events land in $evalEvents
    # cleanup:
    $trace.Stop(); Unregister-Event $job.Name; $trace.Drop()
#>

$trace = $server.Traces.Add("EvalLog_" + [guid]::NewGuid().ToString("N").Substring(0,8))
$te = $trace.Events.Add([Microsoft.AnalysisServices.TraceEventClass]::DAXEvaluationLog)
$te.Columns.Add([Microsoft.AnalysisServices.TraceColumn]::TextData)
$te.Columns.Add([Microsoft.AnalysisServices.TraceColumn]::EventClass)
$trace.Update()

$evalEvents = [System.Collections.ArrayList]::Synchronized((New-Object System.Collections.ArrayList))
$job = Register-ObjectEvent -InputObject $trace -EventName "OnEvent" -MessageData $evalEvents -Action {
    $Event.MessageData.Add($Event.SourceEventArgs) | Out-Null
}
$trace.Start()
