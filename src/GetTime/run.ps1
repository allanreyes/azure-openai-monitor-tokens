using namespace System.Net


param($Request, $TriggerMetadata)


$body = Get-Date

Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
    StatusCode = [HttpStatusCode]::OK
    Body = $body
})
