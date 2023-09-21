param location string = resourceGroup().location
param serviceBusNamespace string
param queueName string

resource serviceBus 'Microsoft.ServiceBus/namespaces@2021-06-01-preview' = {
  name: serviceBusNamespace
  location: location
  sku: {
    name: 'Standard'
  }
  resource Identifier 'Queues' = {
    name: queueName
    properties: {
      requiresDuplicateDetection: true
      duplicateDetectionHistoryTimeWindow: 'PT24H'
    }
  }
}
resource serviceBusAccessPolicy 'Microsoft.ServiceBus/namespaces/authorizationRules@2021-06-01-preview' existing = {
  parent: serviceBus
  name: 'RootManageSharedAccessKey'
}

var serviceBusAccessPolicyKey = serviceBusAccessPolicy.listKeys().primaryConnectionString
output serviceBusAccessPolicyKey string = serviceBusAccessPolicyKey
