using namespace System.Net

param($Request, $TriggerMetadata)

$resId = $Request.Query.ResourceId
$startTime = (Get-Date).AddDays([int]$env:DaysAgo * -1)

Write-Host "Getting total tokens for $resId since $startTime"

$result = Get-AzMetric -MetricName TokenTransaction `
    -ResourceId $resId `
    -StartTime $startTime `
    -AggregationType Total `
    -TimeGrain 12:00:00 `
    -WarningAction:SilentlyContinue

$total = $result.Data | 
    Select-Object -ExpandProperty Total | 
    Measure-Object -Sum | 
    Select-Object -ExpandProperty Sum

Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
    StatusCode = [HttpStatusCode]::OK
    Body = $total
})
