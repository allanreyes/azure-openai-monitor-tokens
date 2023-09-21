using namespace System.Net

param($Request, $TriggerMetadata)

if (!$Request.Query.ResourceId -or !$Request.Query.StartDate) {
    $body = "Missing parameters. Please pass ResourceId and StartDate (yyyy-MM-dd) query string parameters"
}
else {
    $startTime = ([datetime]::parseexact($Request.Query.StartDate, 'yyyy-MM-dd', $null)).ToUniversalTime()
    Write-Host "Getting cost for $($Request.Query.ResourceId) on $startTime"
    $body = Get-Cost -ResourceId $Request.Query.ResourceId -StartTime $startTime 
}

Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
        StatusCode = [HttpStatusCode]::OK
        Body       = $body
    })
