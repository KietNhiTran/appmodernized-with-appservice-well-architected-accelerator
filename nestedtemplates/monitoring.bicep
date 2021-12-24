@description('The location in which all resources should be deployed.')
param location string = resourceGroup().location

@description('Log Analytics Workspace name')
param wsName string = 'laws${uniqueString(resourceGroup().id)}'


resource logWorkspace 'Microsoft.OperationalInsights/workspaces@2021-06-01' = {
  location: location
  name: wsName
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: 120
    features: {
      searchVersion: 1
      legacy: 0
      enableLogAccessUsingOnlyResourcePermissions: true
    }
  }
}


output lawsName_output string = logWorkspace.name
output lawsId_output string = logWorkspace.id
