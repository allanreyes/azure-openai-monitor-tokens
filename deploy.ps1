0### Use Windows PowerShell instead of PowerShell Core because of the AzureAD module dependency
### Uncomment these lines if you're not deploying using Azure Cloud Shell
# Install-Module Az.Accounts -Scope CurrentUser -Force -AllowClobber
# Install-Module Az.Resources -Scope CurrentUser -Force -AllowClobber
# Connect-AzAccount
# Get-AzContext
# az login
###

$target = Get-AzContext
$subName = $target.Subscription.Name
$subId = $target.Subscription.Id
$deployment = @{}
$params = @{}

# Key = prompt, default value, to be included in params
$prompts = [PSCustomObject]@{
    subscription = "Which subscription would you like to deploy to? Enter Subscription ID (Default: $subName)", "$subId", $false
    location = "Which Azure location would you like to deploy to? (Default: canadaeast)", "canadaeast", $true
    suffix = "What suffix would you like to use for your resources? (Default: oaimonitor)", "oaimonitor", $true 
    maxDailyCost = "What's the daily budget for each Azure Open AI service? (Default: 100)", "100", $true 
    organizationName = "What's the name of your Azure DevOps organization? (Default: Contoso)", "Contoso", $true
    projectName = "What's the name of your Azure DevOps project? (Default: OpenAI Monitor)", "OpenAI Monitor", $true
    buildDefinitionId = "What's the Build Definition Id of your Send Alert pipeline in Azure DevOps?", "999999999", $true
}

$prompts.PSObject.Properties | ForEach-Object {
    Write-Host $_.Value[0] -ForegroundColor Yellow
    $prompt = Read-Host
    if([string]::IsNullOrEmpty($prompt)){ $prompt = $_.Value[1]}
    if($_.Value[2]){ 
        $params += @{ $_.Name = $prompt }
    } else {
        $deployment += @{ $_.Name = $prompt }
    }
}

# Switch to correct subscription
Set-AzContext $deployment.subscription | out-null
az account set --subscription $deployment.subscription | out-null

Write-Host "----------------------------------------"
Write-Host "Deploying Azure resources to resource group 'rg-$($params.suffix)' in subscription $($deployment.subscription) ... "

$deployment = New-AzSubscriptionDeployment -Name "$($params.suffix)-deployment" `
    -Location $params.location `
    -TemplateFile ".\infra\main.bicep" `
    -TemplateParameterObject $params 

if ($deployment.ProvisioningState -ne "Succeeded") {
    Write-Warning "Deployment failed or has timed out."
    return
}

$functionAppName = $deployment.Outputs["appName"].Value
# Giving it a few seconds to make sure the function app is ready

Start-Sleep -Seconds 20
Write-Host "Deploying function app code..."
Set-Location -Path 'src'
func azure functionapp publish $functionAppName --powershell 
Set-Location -Path '..\'

Write-Host "----------------------------------------"

$identity = $deployment.Outputs["functionAppIdentity"].Value
$roleDef = Get-AzRoleDefinition "Reader"
Write-Host "Granting Reader role to function app identity..."

Write-Host "Add reader role to individual subscriptions? (y/n)" -ForegroundColor Yellow
$prompt = Read-Host

#Subscriptions
if($prompt.ToLower() -eq "y"){

    Write-Host "Enter a keyword that's part of the subscription name to filter results:" -ForegroundColor Yellow
    $prompt = Read-Host
    $subs = Get-AzSubscription -WarningAction:SilentlyContinue | Where-Object { $_.Name -like "*$prompt*" }
    foreach ($sub in $subs) {
        Write-Host "Give the function app Reader role to the following subscription: $($sub.Name)? (y/n)" -ForegroundColor Yellow
        $response = Read-Host
        if($response.ToLower() -eq "y"){
            New-AzRoleAssignment -ObjectId $identity `
                -RoleDefinitionId $roleDef.Id `
                -Scope $sub.Id
        }
    }
} else {
#Management Groups
    Write-Host "Enter a keyword that's part of the management group's name to filter results:" -ForegroundColor Yellow
    $prompt = Read-Host
    $mgs = Get-AzManagementGroup -WarningAction:SilentlyContinue | Where-Object { $_.Name -like "*$prompt*" }

    foreach ($mg in $mgs) {
        Write-Host "Give the function app Reader role to the following management group: $($mg.DisplayName)? (y/n)" -ForegroundColor Yellow
        $response = Read-Host
        if($response.ToLower() -eq "y"){
            New-AzRoleAssignment -ObjectId $identity `
                -RoleDefinitionId $roleDef.Id `
                -Scope $mg.Id
        }
    }
}

Write-Host "----------------------------------------"
