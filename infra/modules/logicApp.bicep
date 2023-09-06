param location string = resourceGroup().location
param logicAppName string
param emailFrom string

resource connectionsOffice365 'Microsoft.Web/connections@2016-06-01' = {
  name: 'office365'
  location: location
  properties: {
    displayName: emailFrom
    api: {
      name: 'office365'
      displayName: 'Office 365 Outlook'
       id: subscriptionResourceId('Microsoft.Web/locations/managedApis', location, 'office365')
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
        manual: {
          type: 'Request'
          kind: 'Http'
          inputs: {
            schema: {
              properties: {
                Body: {
                  type: 'string'
                }
                Subject: {
                  type: 'string'
                }
                To: {
                  type: 'string'
                }
              }
              type: 'object'
            }
          }
        }
      }
      actions: {
        Response: {
          runAfter: {
            'Send_an_email_(V2)': [
              'Succeeded'
            ]
          }
          type: 'Response'
          kind: 'Http'
          inputs: {
            statusCode: 200
          }
        }
        'Send_an_email_(V2)': {
          runAfter: {}
          type: 'ApiConnection'
          inputs: {
            body: {
              Body: '@triggerBody()?[\'Body\']'
              Importance: 'Normal'
              Subject: '@triggerBody()?[\'Subject\']'
              To: '@triggerBody()?[\'To\']'
            }
            host: {
              connection: {
                name: '@parameters(\'$connections\')[\'office365\'][\'connectionId\']'
              }
            }
            method: 'post'
            path: '/v2/Mail'
          }
        }
      }
      outputs: {}
    }
    parameters: {
      '$connections': {
        value: {
          office365: {
            connectionId: connectionsOffice365.id
            id: subscriptionResourceId('Microsoft.Web/locations/managedApis', location, 'office365')
          }
        }
      }
    }
  }
}

var logicAppUrl = listCallbackURL('${resourceId('Microsoft.Logic/workflows', logicAppName)}/triggers/manual', '2016-06-01').value
output logicAppUrl string = logicAppUrl
