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

    $tokens | 
    ForEach-Object { Get-CostPerModel -Name $_.Name -Model $_.Model -Total $_.Total } | 
    Measure-Object -Sum | 
    Select-Object -ExpandProperty Sum   
}

Export-ModuleMember -Function Get-Cost
