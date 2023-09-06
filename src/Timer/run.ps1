param($Timer)

Write-Host "PowerShell timer trigger function started: $((Get-Date).ToUniversalTime())"

if ($Timer.IsPastDue) {
    Write-Host "PowerShell timer is running late!"
}

$subs = Get-AzSubscription | Where-Object { $_.Name.Contains("allan") } #Temp filter to speed up testing

$anomaly = [System.Collections.ArrayList]@()

foreach ($sub in $subs) {
    
    Set-AzContext -Subscription $sub
    
    $res = Get-AzResource -ResourceType Microsoft.CognitiveServices/accounts | Where-Object { $_.Kind -eq "OpenAI" } 
    $startTime = (Get-Date).AddDays([int]$env:DaysAgo * -1)

    foreach ($oai in $res) {
        Write-Host "Getting total tokens for $($oai.ResourceId) since $startTime"
        
        $trx = Get-AzMetric -MetricName TokenTransaction `
            -ResourceId $oai.ResourceId `
            -StartTime $startTime `
            -AggregationType Total `
            -TimeGrain 12:00:00 `
            -WarningAction:SilentlyContinue
        
        $total = $trx.Data | 
        Select-Object -ExpandProperty Total | 
        Measure-Object -Sum | 
        Select-Object -ExpandProperty Sum
             
        Write-Host "Total tokens: $total / $($env:MaxTokens)"

        if ([int]$total -gt [int]$env:MaxTokens) {
            $anomaly += [PSCustomObject]@{
                ResourceId    = $oai.ResourceId
                Subscription  = $sub.Name
                ResourceGroup = $oai.ResourceGroupName
                Name          = $oai.Name
                Tokens        = $total
            }
        }       
    }
}

Write-Host "Found $($anomaly.Count) anomalies"

if ($anomaly.Count -gt 0) {

    # Build HTML Email body
    $tableRows = ""

    foreach ($Row in $anomaly) {
        $link = "https://portal.azure.com/#/resource$($Row.ResourceId)/billing"
        $tableRows += "<tr>"
        $tableRows += "<td>$($Row.Subscription)</td>"
        $tableRows += "<td>$($Row.ResourceGroup)</td>"
        $tableRows += "<td><a href='$($link)'>$($Row.Name)</a></td>"
        $tableRows += "<td>$($Row.Tokens)</td>"
        $tableRows += "</tr>"
    } 

    $template = @"
<table style='font-family: Arial, Helvetica, sans-serif; font-size: 12px;border-collapse: collapse;' border='1' cellpadding='5' align='center'>
    <tr style='background-color: #f2f2f2;'><th>Subscription</th>
    <th>ResourceGroup</th>
    <th>Name</th>
    <th>Tokens</th>
</tr>
${tableRows}
</table>
"@

    $payload = @{
        Subject = "Azure OpenAI services exceeding maxTokens of $($env:MaxTokens) within $($env:DaysAgo) days, as of $((Get-Date).ToUniversalTime()) UTC"
        To      = $env:EmailTo
        body    = $template
    }

    Write-Host "Sending email to $($env:EmailTo) with $($anomaly.Count) anomalies"
    Invoke-RestMethod $env:SendEmailUrl -Method Post -Body ($payload | ConvertTo-Json ) -ContentType "application/json"
}

Write-Host "PowerShell timer trigger function completed: $((Get-Date).ToUniversalTime())"
