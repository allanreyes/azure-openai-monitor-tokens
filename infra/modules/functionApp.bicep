param appName string
param location string = resourceGroup().location
param saConnectionString string
param aiConnectionString string
param aiInstrumentationKey string
param maxDailyCost string
param serviceBusNamespace string
param serviceBusAccessPolicyKey string

resource hostingPlan 'Microsoft.Web/serverfarms@2021-03-01' = {
  name: '${appName}-asp'
  location: location
  sku: {
    name: 'Y1'
    tier: 'Dynamic'
  }
  kind: 'functionapp'
}

resource functionApp 'Microsoft.Web/sites@2022-03-01' = {
  name: appName
  location: location
  kind: 'functionapp'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    serverFarmId: hostingPlan.id
    httpsOnly: true
    publicNetworkAccess: 'Enabled'
  }
}

resource functionAppConfig 'Microsoft.Web/sites/config@2022-03-01' = {
  parent: functionApp
  name: 'web'
  properties: {
    appSettings: [
      {
        name: 'AzureWebJobsStorage'
        value: saConnectionString
      }
      {
        name: 'WEBSITE_CONTENTAZUREFILECONNECTIONSTRING'
        value: saConnectionString
      }
      {
        name: 'WEBSITE_CONTENTSHARE'
        value: appName
      }
      {
        name: 'FUNCTIONS_EXTENSION_VERSION'
        value: '~4'
      }
      {
        name: 'FUNCTIONS_WORKER_RUNTIME'
        value: 'powershell'
      }
      {
        name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
        value: aiConnectionString
      }
      {
        name: 'APPINSIGHTS_INSTRUMENTATIONKEY'
        value: aiInstrumentationKey
      }
      {
        name: 'MaxDailyCost'
        value: maxDailyCost
      }
      {
        name: 'ServiceBusNamespace'
        value: serviceBusNamespace
      }
      {
        name: 'ServiceBusAccessPolicyKey'
        value: serviceBusAccessPolicyKey
      }
      {
        name: 'WEBSITE_RUN_FROM_PACKAGE'
        value: '1'
      }
      {
        name: 'WEBSITE_TIME_ZONE'
        value: 'Israel Standard Time'
      }
    ]
    ftpsState: 'FtpsOnly'
    minTlsVersion: '1.2'
    use32BitWorkerProcess: false
    cors: {
      allowedOrigins: [
        'https://portal.azure.com'
      ]
    }
  }
}

output functionAppIdentity string = functionApp.identity.principalId
