param appName string
param location string = resourceGroup().location
param saConnectionString string
param aiConnectionString string
param maxDailyCost string
param serviceBusNamespace string
param serviceBusAccessPolicyKey string

resource hostingPlan 'Microsoft.Web/serverfarms@2021-03-01' = {
  name: '${appName}-asp'
  location: location
  sku: {
    name: 'S1'
    tier: 'Standard'
  }
  kind: 'functionapp'
  properties: {
    zoneRedundant: false
  }
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
    ]
    ftpsState: 'FtpsOnly'
    minTlsVersion: '1.2'
    alwaysOn: true
    use32BitWorkerProcess: false
    cors: {
      allowedOrigins: [
        'https://portal.azure.com'
      ]
    }
  }
}
