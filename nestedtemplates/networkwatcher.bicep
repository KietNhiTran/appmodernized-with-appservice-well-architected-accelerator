
@description('Specifies the location for all the resources.')
param location string

@description('Network flow log retention in days')
param flowLogsStorageRetentionDays int = 90

@description('Network security group')
param nsgId string

@description('NSG name')
param nsgName string

// @description('Networkflow log storage account identity')
// param nflStorageAccountId string

@description('name of log analytics workspace')
param lawsId string

@description('Specifies the network flow log storage account where the log will be stored')
param nflStorageAccountName string 

@description('Storage Account type')
@allowed([
  'Standard_LRS'
  'Standard_GRS'
  'Standard_ZRS'
])
param storageAccountType string = 'Standard_LRS'


var networkWatcherName = 'NetworkWatcher_${location}'
var networkFlowLogName = '${nsgName}FlowLog${uniqueString(resourceGroup().id)}'

resource nflStorageAccount 'Microsoft.Storage/storageAccounts@2021-06-01' = {
  kind: 'StorageV2'
  location: location
  name: nflStorageAccountName
  sku: {
    name: storageAccountType
  }
}

resource nfl_resource 'Microsoft.Network/networkWatchers/flowLogs@2021-05-01' = {
  name: '${networkWatcherName}/${networkFlowLogName}'
  location: location
  properties: {
    storageId: nflStorageAccount.id
    targetResourceId: nsgId
    enabled: true
    flowAnalyticsConfiguration: {
      networkWatcherFlowAnalyticsConfiguration: {
        enabled: true
        trafficAnalyticsInterval: 60
        workspaceResourceId: lawsId
      }
    }
    format: {
      type: 'JSON'
      version: 2
    }
    retentionPolicy: {
      days: flowLogsStorageRetentionDays
      enabled: true
    }
  }
}

