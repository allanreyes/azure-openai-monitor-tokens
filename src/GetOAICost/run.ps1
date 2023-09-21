using namespace System.Net

param($Request, $TriggerMetadata)

if (!$Request.Query.ResourceId -or !$Request.Query.StartDate) {
    $body = "Missing parameters. Please pass ResourceId and StartDate (yyyy-MM-dd) query string parameters"
}
else {
    $startTime = ([datetime]::parseexact($Request.Query.StartDate, 'yyyy-MM-dd', $null)).ToUniversalTime()
    $resourceId = $Request.Query.ResourceId
    Write-Host "Getting cost for $resourceId on $startTime"
    $body = Get-Cost -ResourceId $resourceId -StartTime $startTime

}

Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
        StatusCode = [HttpStatusCode]::OK
        Body       = $body
    })

