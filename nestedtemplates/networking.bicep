
@description('Specifies the location for all the resources.')
param location string = resourceGroup().location

@description('Specifies the name of the virtual network hosting the virtual machine.')
param virtualNetworkName string = 'vnet${uniqueString(resourceGroup().id)}'

@description('Specifies the address prefix of the virtual network hosting the virtual machine.')
param virtualNetworkAddressPrefix string = '10.0.0.0/16'

@description('Specifies the name of the subnet hosting the virtual machine.')
param privateEnpointSubnetName string = 'privateEnpointSubnet${uniqueString(resourceGroup().id)}'

@description('Application subnet name')
param appServiceSubnetName string = 'applicationSubnet${uniqueString(resourceGroup().id)}'

@description('Application Gateway service endpoint subnet name')
param appGWSubnetName string = 'appGWServiceEndpointSubnet${uniqueString(resourceGroup().id)}'

@description('Specifies the address prefix of the subnet hosting the Keyvault private endpoint.')
param kvPrivateEnpointSubnetAddressPrefix string = '10.0.0.0/24'

@description('Specifies the address prefix of the subnet hosting app service netwroking integration.')
param applicationSubnetSubnetAddressPrefix string = '10.0.1.0/24'

@description('Specifies the address prefix of the subnet hosting the application gateway service endpoint.')
param applicationGWSubnetSubnetAddressPrefix string = '10.0.2.0/24'

@description('name of log analytics workspace')
param lawsName string

@description('Specifies the network flow log storage account where the log will be stored')
param nflStorageAccountName string = 'nflstgacc${uniqueString(resourceGroup().id)}'

@description('Storage Account type')
@allowed([
  'Standard_LRS'
  'Standard_GRS'
  'Standard_ZRS'
])
param storageAccountType string = 'Standard_LRS'

var nsgName_var = '${virtualNetworkName}-Nsg'

resource nsg_resource 'Microsoft.Network/networkSecurityGroups@2019-08-01' = {
  name: nsgName_var
  location: location
  properties: {
  }
}

resource virtualNetwork_resource 'Microsoft.Network/virtualNetworks@2019-11-01' = {
  name: virtualNetworkName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        virtualNetworkAddressPrefix
      ]
    }
    subnets: [
      {
        name: privateEnpointSubnetName
        properties: {
          addressPrefix: kvPrivateEnpointSubnetAddressPrefix
          networkSecurityGroup: {
            id: nsg_resource.id
          }
          privateEndpointNetworkPolicies: 'Disabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
        }
      }
      {
        name: appServiceSubnetName
        properties: {
          addressPrefix: applicationSubnetSubnetAddressPrefix
          delegations: [
            {
              name: 'delegatedToAppService'
              properties: {
                serviceName: 'Microsoft.Web/serverFarms'
              }
            }
          ]
          privateEndpointNetworkPolicies: 'Enabled'
          networkSecurityGroup: {
            id: nsg_resource.id
          }
        }
      }
      {
        name: appGWSubnetName
        properties: {
          addressPrefix: applicationGWSubnetSubnetAddressPrefix
          privateEndpointNetworkPolicies: 'Enabled'
          serviceEndpoints: [
            {
              service: 'Microsoft.Web'
              locations: [
                '*'
              ]
            }
          ]
        }
      }   
    ]
  }
}

// setup diagnostic setting
resource laws_resource 'Microsoft.OperationalInsights/workspaces@2021-06-01' existing = {
  name: lawsName
}

resource virtualNetworkDiagnostic_resource 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: '${virtualNetworkName}AllDiagnostic'
  scope: virtualNetwork_resource
  properties: {
    workspaceId: laws_resource.id
    logs: [
      {
        categoryGroup: 'allLogs'
        enabled: true
      }
    ]
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
      }
    ]
  }
}

resource nsg_daignostics_resource 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: '${nsgName_var}AllDiagnostic'
  scope: nsg_resource
  properties: {
    workspaceId: laws_resource.id
    logs: [
      {
        categoryGroup: 'allLogs'
        enabled: true
      }
    ]
  }
}

resource nflStorageAccount 'Microsoft.Storage/storageAccounts@2021-06-01' = {
  kind: 'StorageV2'
  location: location
  name: nflStorageAccountName
  sku: {
    name: storageAccountType
  }
}

output virtualNetworkName_output string = virtualNetwork_resource.name
output privateEnpointSubnetName_output string = privateEnpointSubnetName
output applicationGWServiceEnpointSubnetName_output string = appGWSubnetName
output applicationSubnetName_output string = appServiceSubnetName
output nsgName_output string = nsgName_var
output nsgId_output string = nsg_resource.id
output nflStorageAccountId_output string = nflStorageAccount.id

