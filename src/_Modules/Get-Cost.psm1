function Get-Cost {
    param(
        [string] $ResourceId,
        [string] $StartDate
    )
    
    $startTime = ([datetime]::parseexact($StartDate, 'yyyy-MM-dd', $null)).ToUniversalTime()
    $endTime = $startTime.AddDays(1)

    Write-Host "Getting cost for $ResourceId on $StartDate"

    $metrics = Get-AzMetric -MetricName TokenTransaction, ProcessedPromptTokens, GeneratedTokens  `
        -ResourceId $ResourceId `
        -StartTime $startTime `
        -EndTime $endTime `
        -AggregationType Total `
        -TimeGrain 1.00:00:00 `
        -Dimension "FeatureName" `
        -WarningAction:SilentlyContinue

    $tokens = @()
    foreach ($metric in $metrics) {
        foreach ($ts in $metric.Timeseries) {
            $tokens += [PSCustomObject]@{
                Name  = $metric.Name.Value
                Model = $ts.Metadatavalues[0].Value
                Total = [int]$ts.Data.Total
            }
        }
    }

    $total = 0.0
    $components = @()

    foreach($token in $tokens){
        $line = Get-CostPerModel -Name $token.Name -Model $token.Model -Total $token.Total
        if($line.Cost -gt 0){
            $components += @{
                Model = $token.Model
                Tokens = $token.Total
                Cost = $line.Cost
                Metric = $line.Metric
            }
        }
        $total += $line.Cost
    }

    [PSCustomObject]@{
        TotalCost = $total
        Components = $components | Sort-Object -Property Model, Metric
    }
}

Export-ModuleMember -Function Get-Cost
