function  Send-ServiceBusMessage() {
    param(
        [string] $ResourceId
    )
    
    [Reflection.Assembly]::LoadWithPartialName("System.Web")| out-null

    $sbNamespace = $env:ServiceBusNamespace
    $queueName = "alerts"
    $sbAccessPolicyName = "RootManageSharedAccessKey"
    $sbAccessPolicyKey = $env:ServiceBusAccessPolicyKey 
        
    $uri = "https://$sbNamespace.servicebus.windows.net/$queueName/messages"
    $uriEnc = [System.Web.HttpUtility]::UrlEncode($uri)
    $expires = ([DateTimeOffset]::Now.ToUnixTimeSeconds()) + 3000
    $signatureString = $uriEnc + "`n" + [string]$expires
    $hmac = New-Object System.Security.Cryptography.HMACSHA256
    $hmac.key = [Text.Encoding]::ASCII.GetBytes($sbAccessPolicyKey)   
   
    
    $signature = $hmac.ComputeHash([Text.Encoding]::ASCII.GetBytes($signatureString)) 
    $signature = [Convert]::ToBase64String($signature)
    $signature = [System.Web.HttpUtility]::UrlEncode($signature) 

    $SASToken = "SharedAccessSignature sr=$uriEnc&sig=$signature&se=$expires&skn=$sbAccessPolicyName"

    # Duplicate detection is enabled with a window of 24 hours so notification is sent only once per day
    # Need to hash the resource ID to make it fit the 128 character limit of message Id    
    $alertResetTime = (Get-Date -AsUTC).AddHours(3).ToString("yyyyMMdd") # TODO: This is not correct, Israel Time can be +3 or +2 depends on date
    $messageId = "$(Get-Hash -textToHash $ResourceId)-$($alertResetTime)"
    $headers = @{
        Authorization = $SASToken
        BrokerProperties = @{ MessageId = $messageId } | ConvertTo-Json -Compress
    }

    Invoke-RestMethod -Method Post -Uri $uri -Body $ResourceId -Headers $headers -ContentType "application/json"
}