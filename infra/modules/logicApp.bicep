param location string = resourceGroup().location
param logicAppName string
param organizationName string
param projectName string
param buildDefinitionId string

resource connectionServicebus 'Microsoft.Web/connections@2016-06-01' = {
  name: 'servicebus'
  location: location
  properties: {
    displayName: 'Azure Service Bus'   
    api: {
      name: 'servicebus'
      displayName: 'Service Bus'
      id: subscriptionResourceId('Microsoft.Web/locations/managedApis', location, 'servicebus')
    }
  }
}

resource connectionsAzureDevOps 'Microsoft.Web/connections@2016-06-01' = {
  name: 'azureDevOps'
  location: location
  properties: {
    displayName: 'Azure DevOps'
    api: {
      name: 'visualstudioteamservices'
      displayName: 'Azure DevOps'
      id: subscriptionResourceId('Microsoft.Web/locations/managedApis', location, 'visualstudioteamservices')
    }
  }
}

resource workflows_la_credsalert_name_resource 'Microsoft.Logic/workflows@2019-05-01' = {
  name: logicAppName
  location: location
  properties: {
    state: 'Enabled'
    definition: {
      '$schema': 'https://schema.management.azure.com/providers/Microsoft.Logic/schemas/2016-06-01/workflowdefinition.json#'
      contentVersion: '1.0.0.0'
      parameters: {
        '$connections': {
          defaultValue: {}
          type: 'Object'
        }
      }
      triggers: {
        'When_one_or_more_messages_arrive_in_a_queue_(auto-complete)': {
          recurrence: {
            frequency: 'Second'
            interval: 60
          }
          evaluatedRecurrence: {
            frequency: 'Second'
            interval: 60
          }
          splitOn: '@triggerBody()'
          type: 'ApiConnection'
          inputs: {
            host: {
              connection: {
                name: '@parameters(\'$connections\')[\'servicebus\'][\'connectionId\']'
              }
            }
            method: 'get'
            path: '/@{encodeURIComponent(encodeURIComponent(\'alerts\'))}/messages/batch/head'
            queries: {
              maxMessageCount: 20
              queueType: 'Main'
            }
          }
        }
      }
      actions: {
        Queue_a_new_build: {
          runAfter: {}
          type: 'ApiConnection'
          inputs: {
            body: {
              parameters: '{\n"resourceId": "@{decodeBase64(triggerBody()?[\'ContentData\'])}"\n}'
            }
            host: {
              connection: {
                name: '@parameters(\'$connections\')[\'visualstudioteamservices\'][\'connectionId\']'
              }
            }
            method: 'post'
            path: '/@{encodeURIComponent(\'${projectName}\')}/_apis/build/builds'
            queries: {
              account: organizationName
              buildDefId: buildDefinitionId
            }
          }
        }
      }
      outputs: {}
    }
    parameters: {
      '$connections': {
        value: {
          servicebus: {
            connectionId: connectionServicebus.id
            id: subscriptionResourceId('Microsoft.Web/locations/managedApis', location, 'servicebus')
          }
          visualstudioteamservices: {
            connectionId: connectionsAzureDevOps.id
            id: subscriptionResourceId('Microsoft.Web/locations/managedApis', location, 'visualstudioteamservices')
          }
        }
      }
    }
  }
}
