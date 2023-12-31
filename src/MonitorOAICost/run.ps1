param($Timer)

Write-Host "PowerShell timer trigger function started: $((Get-Date).ToUniversalTime())"

if ($Timer.IsPastDue) {
    Write-Host "PowerShell timer is running late!"
}

$threshold = [float]$env:MaxDailyCost
Write-Host "Finding resources that exceed MaxDailyCost of $threshold"

$query = @"
resources 
| where type contains 'microsoft.cognitiveservices' and kind == 'OpenAI'
| join kind=inner (resourcecontainers 
| where type == 'microsoft.resources/subscriptions' and properties.state == 'Enabled') on subscriptionId
"@

$resources = (Search-AzGraph -Query $query -UseTenantScope) | 
    Select-Object -ExpandProperty id
Write-Host "Found $($resources.Count) resources to monitor"

$startTime = [datetime]::Today
Write-Host "Getting cost of each resource starting from $startTime"

foreach ($resource in $resources) {
    $line = Get-Cost -ResourceId $resource -StartTime $startTime
    $name = $resource -Split "/" | Select-Object -Last 1
    $log = "$name >>> $($line.TotalCost)"
    if ($line.TotalCost -gt $threshold ) {
        Write-Warning "$log <<< Exceeds max cost of $threshold"
        Send-ServiceBusMessage -ResourceId $resource
    } else {
        Write-Host $log
    }
}

Write-Host "PowerShell timer trigger function completed: $((Get-Date).ToUniversalTime())"
