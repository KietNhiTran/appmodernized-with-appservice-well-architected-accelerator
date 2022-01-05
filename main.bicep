targetScope = 'subscription'

@description('Resource group to deploy the solution')
param resourceGroupName string

@description('Location of the resource group')
param location string

@description('SQL server admin user name')
param sqlServerAdmin string

@description('Sql Server admin password')
param sqlServerPassword string

@description('Enable zone redundant for app service and SQL db')
param enableZoneRedundant bool

resource resourceGroup_resource 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: resourceGroupName
  location: location
}

module monitoring 'nestedtemplates/monitoring.bicep' = {
  name: 'enableMonitor'
  scope: resourceGroup_resource
  params: {
    location: location
  }
}

module network 'nestedtemplates/networking.bicep' = {
  name: 'networkDeployment'
  scope: resourceGroup_resource
  params: {
    location: resourceGroup_resource.location
    lawsName: monitoring.outputs.lawsName_output
  }
}

module netwrokWatcher 'nestedtemplates/networkwatcher.bicep' = {
  name: 'netwrokWatcherFlowLowDeployment'
  scope: resourceGroup('NetworkWatcherRG')
  params: {
    location: location
    lawsId: monitoring.outputs.lawsId_output
    // nflStorageAccountId: network.outputs.nflStorageAccountId_output
    nsgId: network.outputs.nsgId_output
    nsgName: network.outputs.nsgName_output
    nflStorageAccountName: 'nflstgacc${uniqueString(resourceGroup_resource.id)}'
  }
  dependsOn: [
    network
    monitoring
  ]
}

module keyvault 'nestedtemplates/keyvault.bicep' = {
  name: 'kvdeployment'
  scope: resourceGroup_resource
  params: {
    location: resourceGroup_resource.location
    endpointSubnetName: network.outputs.privateEnpointSubnetName_output
    virtualNetworkName: network.outputs.virtualNetworkName_output
    certsArray:[
      {
        name: 'sslCert'
        value: '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'
      }
    ]
    lawsName: monitoring.outputs.lawsName_output
  }
  dependsOn: [
    network
    monitoring
  ]
}

var keyVaultPrivateEndpointName_var = '${keyvault.outputs.keyVaultName_output}KeyVaultPrivateEndpoint'
var keyVaultPublicDNSZoneForwarder_var = ((toLower(environment().name) == 'azureusgovernment') ? '.vaultcore.usgovcloudapi.net' : '.vaultcore.azure.net')
var keyVaultPrivateDnsZoneName_var = 'privatelink${keyVaultPublicDNSZoneForwarder_var}'
var keyVaultPrivateEndpointGroupName_var = 'vault'
var keyVaultFQDN_var = '${keyvault.outputs.keyVaultName_output}${keyVaultPublicDNSZoneForwarder_var}'

module ennableKVPrivateEndpoint 'nestedtemplates/privateEndpoints.bicep' = {
  name: 'kvPrivateEndpoint'
  scope: resourceGroup_resource
  params: {
    location: location
    virtualNetworkName: network.outputs.virtualNetworkName_output 
    privateEndpointServiceId: keyvault.outputs.keyVaultId_output
    privateDNSZoneName: keyVaultPrivateDnsZoneName_var
    privateEndpointFQDN: keyVaultFQDN_var
    privateEndpointSubnetName: network.outputs.privateEnpointSubnetName_output
    groupType: keyVaultPrivateEndpointGroupName_var
    privateEndpointName: keyVaultPrivateEndpointName_var
  }
  dependsOn: [
    keyvault
    network
  ]
}

module appService 'nestedtemplates/appservice.bicep' = {
  name: 'appDeployment'
  scope: resourceGroup_resource
  params: {
    keyvaultName: keyvault.outputs.keyVaultName_output
    virtualNetworkName: network.outputs.virtualNetworkName_output
    location: resourceGroup_resource.location
    appGWServiceEnpointSubnetName: network.outputs.applicationGWServiceEnpointSubnetName_output
    appServiceSubnetName: network.outputs.applicationSubnetName_output
    lawsName: monitoring.outputs.lawsName_output
    enableZoneRedundant: enableZoneRedundant
  }
  dependsOn: [
    network
    keyvault
    monitoring
    ennableKVPrivateEndpoint
  ]
}

module appGateway 'nestedtemplates/applicationGW_https.bicep' = {
  name: 'applicationGWDeployment'
  scope: resourceGroup_resource
  params: {
    appGWServiceEnpointSubnetName: network.outputs.applicationGWServiceEnpointSubnetName_output
    applicationDNSName: 'myapp${uniqueString(resourceGroup_resource.id)}'
    appServiceName: appService.outputs.appServiceName_output
    virtualNetworkName: network.outputs.virtualNetworkName_output
    certName: 'sslCert'
    keyvaultName: keyvault.outputs.keyVaultName_output
    location: location
    lawsName: monitoring.outputs.lawsName_output
  }
  dependsOn: [
    network
    appService
    keyvault
    monitoring
  ]
}

module database 'nestedtemplates/azuresql.bicep' = {
  name: 'databaseDeployment'
  scope: resourceGroup_resource
  params: {
    sqlServerAdmin: sqlServerAdmin
    sqlServerPassword: sqlServerPassword
    location: location
    enableZoneRedundant: enableZoneRedundant
    lawsName: monitoring.outputs.lawsName_output
  }
  dependsOn: [
    monitoring
  ]
}

var dbPrivateEndpointName_var = '${database.outputs.sqlName_output}DBPrivateEndpoint'
var dbPublicDNSZoneForwarder_var = environment().suffixes.sqlServerHostname
var dbPrivateDnsZoneName_var = 'privatelink${dbPublicDNSZoneForwarder_var}'
var dbPrivateEndpointGroupName_var = 'sqlServer'
var dbFQDN_var = '${database.outputs.sqlName_output}${dbPublicDNSZoneForwarder_var}'

module ennableDBPrivateEndpoint 'nestedtemplates/privateEndpoints.bicep' = {
  name: 'dbPrivateEndpoint'
  scope: resourceGroup_resource
  params: {
    location: location
    privateEndpointServiceId: database.outputs.sqlServerId_output
    groupType: dbPrivateEndpointGroupName_var
    privateEndpointName: dbPrivateEndpointName_var
    virtualNetworkName: network.outputs.virtualNetworkName_output
    privateEndpointSubnetName: network.outputs.privateEnpointSubnetName_output
    privateDNSZoneName: dbPrivateDnsZoneName_var
    privateEndpointFQDN: dbFQDN_var
  }
  dependsOn: [
    database
    network
    ennableKVPrivateEndpoint
  ]
}

output lawsName_output string = monitoring.outputs.lawsName_output
