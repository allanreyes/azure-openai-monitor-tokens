targetScope = 'subscription'

param suffix string
param location string = deployment().location
param maxDailyCost string
param buildDefinitionId string
param organizationName string
param projectName string

var resourceGroupName = 'rg-${suffix}'
var appName = 'fn-${suffix}-${uniqueString(rg.id)}'
var storageName = 'sa${uniqueString(rg.id)}'
var logicAppName = 'la-${suffix}-${uniqueString(rg.id)}'
var serviceBusNamespace = 'sb-${suffix}-${uniqueString(rg.id)}'

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
    aiInstrumentationKey: appInsights.outputs.aiInstrumentationKey
    maxDailyCost: maxDailyCost
    serviceBusAccessPolicyKey: serviceBus.outputs.serviceBusAccessPolicyKey
    serviceBusNamespace: serviceBusNamespace
  }
}

module logicApp './modules/logicApp.bicep' = {
  name: 'la-${suffix}'
  scope: rg
  params: {
    location: location
    logicAppName: logicAppName
    buildDefinitionId: buildDefinitionId
    organizationName: organizationName
    projectName: projectName
  }
}

module serviceBus 'modules/serviceBus.bicep' = {
  name: 'sb-${suffix}'
  scope: rg
  params: {
    location: location
    serviceBusNamespace: serviceBusNamespace
    queueName: 'alerts'
  }
}

output appName string = appName
output functionAppIdentity string = functionApp.outputs.functionAppIdentity
