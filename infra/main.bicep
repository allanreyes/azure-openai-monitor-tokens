targetScope = 'subscription'

param suffix string
param location string = deployment().location
param maxDailyCost string
param emailFrom string

var resourceGroupName = 'rg-${suffix}'
var appName = 'fn-${suffix}-${uniqueString(rg.id)}'
var storageName = 'sa${uniqueString(rg.id)}'
var logicAppName = 'la-${suffix}-${uniqueString(rg.id)}'

resource rg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: resourceGroupName
  location: location
}

module storageAccount './modules/storageAccount.bicep' = {
  name: 'sa-${suffix}'
  scope: rg
  params: {
    location: location
    storageName: storageName
  }
}

module appInsights './modules/appInsights.bicep' = {
  name: 'appInsights-fn-${suffix}'
  scope: rg
  params: {
    appName: 'fn-${suffix}-${uniqueString(rg.id)}'
    location: location
  }
}

module functionApp './modules/functionApp.bicep' = {
  name: 'fn-${suffix}'
  scope: rg
  params: {
    appName: appName
    location: location
    saConnectionString: storageAccount.outputs.saConnectionString
    aiConnectionString: appInsights.outputs.aiConnectionString
    maxDailyCost: maxDailyCost
    serviceBusAccessPolicyKey: serviceBus.outputs.serviceBusAccessPolicyKey
    serviceBusNamespace: 'sb-${suffix}-${uniqueString(rg.id)}'
  }
}

module logicApp './modules/logicApp.bicep' = {
  name: 'la-${suffix}'
  scope: rg
  params: {
    location: location
    emailFrom: emailFrom
    logicAppName: logicAppName
  }
}

module serviceBus 'modules/serviceBus.bicep' = {
  name: 'sb-${suffix}'
  scope: rg
  params: {
    location: location
    serviceBusNamespace: 'sb-${suffix}-${uniqueString(rg.id)}'
    queueName: 'alerts'
  }
}

output appName string = appName
