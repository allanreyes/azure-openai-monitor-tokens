param appName string
param location string = resourceGroup().location
param saConnectionString string
param aiConnectionString string
param maxTokens string
param daysAgo string
param emailTo string
param sendEmailUrl string

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
        name: 'MaxTokens'
        value: maxTokens
      }
      {
        name: 'DaysAgo'
        value: daysAgo
      }
      {
        name: 'SendEmailUrl'
        value: sendEmailUrl
      }
      {
        name: 'EmailTo'
        value: emailTo
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
