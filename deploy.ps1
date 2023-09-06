### Use Windows PowerShell instead of PowerShell Core because of the AzureAD module dependency
### Uncomment these lines if you're not deploying using Azure Cloud Shell
# Install-Module Az.Accounts -Scope CurrentUser -Force -AllowClobber
# Install-Module Az.Resources -Scope CurrentUser -Force -AllowClobber
# Connect-AzAccount
# az login
###

# Deploy Azure resources
Write-Host "Which Azure location would you like to deploy to? (Default: canadaeast)" -ForegroundColor Yellow
$location = Read-Host
$location = [string]::IsNullOrEmpty($location) ? "canadaeast" : $location

Write-Host "What suffix would you like to use for your resources? (Default: oaimonitor)" -ForegroundColor Yellow
$suffix = Read-Host
$suffix = [string]::IsNullOrEmpty($suffix) ? "oaimonitor" : $suffix

Write-Host "What's the maximum number of tokens? (Default: 1000000)" -ForegroundColor Yellow
$maxTokens = Read-Host
$maxTokens = [string]::IsNullOrEmpty($maxTokens) ? "1000000" : $maxTokens

Write-Host "Look back how many days? (Default: 30)" -ForegroundColor Yellow
$daysAgo = Read-Host
$daysAgo = [string]::IsNullOrEmpty($daysAgo) ? "30" : $daysAgo

$loggedInUser = az account show --query user.name -o tsv
Write-Host "What email address should the notification come from? (Default: $($loggedInUser))" -ForegroundColor Yellow
$emailFrom = Read-Host
$emailFrom = [string]::IsNullOrEmpty($emailFrom) ? $loggedInUser : $emailFrom

Write-Host "What email address should the notification go to? (Default: $($loggedInUser))" -ForegroundColor Yellow
$emailTo = Read-Host
$emailTo = [string]::IsNullOrEmpty($emailTo) ? $loggedInUser : $emailTo

$params = @{ 
    suffix    = $suffix
    maxTokens = $maxTokens
    daysAgo   = $daysAgo
    emailFrom = $emailFrom 
    emailTo   = $emailTo
}

Write-Host "----------------------------------------"
Write-Host "Deploying Azure resources..."

$deployment = New-AzSubscriptionDeployment -Name "$($params.suffix)-deployment" `
    -Location $location `
    -TemplateFile ".\infra\main.bicep" `
    -TemplateParameterObject $params 

if ($deployment.ProvisioningState -ne "Succeeded") {
    Write-Warning "Deployment failed or has timed out."
    return
}

$functionAppName = $deployment.Outputs["appName"].Value

Write-Host "Deploying function app code..."
Set-Location -Path src
func azure functionapp publish $functionAppName --powershell 
