param($Timer)

Write-Host "PowerShell timer trigger function started: $((Get-Date).ToUniversalTime())"

if ($Timer.IsPastDue) {
    Write-Host "PowerShell timer is running late!"
}

$query = @"
resources 
| where type contains 'microsoft.cognitiveservices' and kind == 'OpenAI'
| join kind=inner (resourcecontainers 
| where type == 'microsoft.resources/subscriptions' and properties.state == 'Enabled') on subscriptionId
"@

$resources = (Search-AzGraph -Query $query -UseTenantScope) | 
    Select-Object -ExpandProperty id
Write-Host "Found $($resources.Count) resources to monitor"

$startTime = (Get-Date -AsUTC).AddDays(-1) # 24 hours ago
Write-Host "Getting cost of each resource starting from $startTime (Last 24 UTC hours)"

foreach ($resource in $resources) {
    $line = Get-Cost -ResourceId $resource -StartDate $startTime
    Write-Host "Resource: $resource"
    
    if ($line.TotalCost -gt $env:MaxDailyCost) {
        Write-Host "Total cost: $($line.TotalCost) <<< Exceeds max cost of $($env:MaxDailyCost) >>>"

    } else {
        Write-Host "Total cost: $($line.TotalCost)"
    }
}


#     $payload = @{
#         Subject = "Azure OpenAI services exceeding maxTokens of $($env:MaxTokens) within $($env:DaysAgo) days, as of $((Get-Date).ToUniversalTime()) UTC"
#         To      = $env:EmailTo
#         body    = $template
#     }

#     Write-Host "Sending email to $($env:EmailTo) with $($anomaly.Count) anomalies"
#     Invoke-RestMethod $env:SendEmailUrl -Method Post -Body ($payload | ConvertTo-Json ) -ContentType "application/json"
# }

Write-Host "PowerShell timer trigger function completed: $((Get-Date).ToUniversalTime())"
