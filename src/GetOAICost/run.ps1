using namespace System.Net

param($Request, $TriggerMetadata)

if (!$Request.Query.ResourceId -or !$Request.Query.StartDate) {
    $body = "Missing parameters. Please pass ResourceId and StartDate (yyyy-MM-dd) query string parameters"
}
else {
    $body = Get-Cost -ResourceId $Request.Query.ResourceId -StartDate $Request.Query.StartDate
}

Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
        StatusCode = [HttpStatusCode]::OK
        Body       = $body
    })
