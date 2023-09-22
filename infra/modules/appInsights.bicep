param appName string
param location string = resourceGroup().location

resource appInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: appName
  location: location
  kind: 'web'
  properties: {
    Application_Type: 'web'
    WorkspaceResourceId: workspace.id
  }
}

resource workspace 'Microsoft.OperationalInsights/workspaces@2022-10-01' = {
  name:  'log-${appName}'
  location: location
  properties: {
    sku: {
      name: 'PerGB2018'
    }
  }
}

output aiConnectionString string = appInsights.properties.ConnectionString
output aiInstrumentationKey string = appInsights.properties.InstrumentationKey
