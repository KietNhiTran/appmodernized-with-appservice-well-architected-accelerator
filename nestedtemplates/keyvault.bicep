@description('Specifies the name of the key vault.')
param keyVaultName string = 'vault${uniqueString(resourceGroup().id)}'

@description('Specifies the location for all the resources.')
param location string = resourceGroup().location

@description('Specifies the Azure Active Directory tenant ID that should be used for authenticating requests to the key vault. Get it by using Get-AzSubscription cmdlet.')
param tenantId string = subscription().tenantId

@description('Name of veritual network where the private endpoint will be created')
param virtualNetworkName string

@description('Name of veritual network where the private endpoint will be created')
param endpointSubnetName string

@allowed([
  'standard'
  'premium'
])
@description('Specifies whether the key vault is a standard vault or a premium vault.')
param skuName string = 'standard'

@allowed([
  true
  false
])
@description('Specifies whether Azure Virtual Machines are permitted to retrieve certificates stored as secrets from the key vault.')
param enabledForDeployment bool = true

@allowed([
  true
  false
])
@description('Specifies whether Azure Disk Encryption is permitted to retrieve secrets from the vault and unwrap keys.')
param enabledForDiskEncryption bool = true

@allowed([
  true
  false
])
@description('Specifies whether Azure Resource Manager is permitted to retrieve secrets from the key vault.')
param enabledForTemplateDeployment bool = true

@allowed([
  true
  false
])
@description('Specifies whether the \'soft delete\' functionality is enabled for this key vault. If it\'s not set to any value(true or false) when creating new key vault, it will be set to true by default. Once set to true, it cannot be reverted to false.')
param enableSoftDelete bool = true

@description('Specifies the softDelete data retention days. It accepts >=7 and <=90.')
param softDeleteRetentionInDays int = 90

@allowed([
  true
  false
])
@description('Controls how data actions are authorized. When true, the key vault will use Role Based Access Control (RBAC) for authorization of data actions, and the access policies specified in vault properties will be ignored (warning: this is a preview feature). When false, the key vault will use the access policies specified in vault properties, and any policy stored on Azure Resource Manager will be ignored. If null or not specified, the vault is created with the default value of false. Note that management actions are always authorized with RBAC.')
param enableRbacAuthorization bool = false

// @description('Specifies the name of the private link to key vault.')
// param keyVaultPrivateEndpointName string = '${keyVaultName}KeyVaultPrivateEndpoint'

@description('Specifies all secrets {"secretName":"","secretValue":""} wrapped in a secure object. This is for testing purpose only')
param secretsArray array = [
  {
    secretName: 'secret1'
    secretValue: 'value1'
  }
  {
    secretName: 'secret2'
    secretValue: 'value2'
  }
  {
    secretName: 'secret3'
    secretValue: 'value3'
  }
]

@description('SSL certificate to be uploaded to keyvault')
param certsArray array

@description('name of log analytics workspace')
param lawsName string

// var keyVaultPublicDNSZoneForwarder = ((toLower(environment().name) == 'azureusgovernment') ? '.vaultcore.usgovcloudapi.net' : '.vaultcore.azure.net')
// var keyVaultPrivateDnsZoneName_var = 'privatelink${keyVaultPublicDNSZoneForwarder}'
// var keyVaultPrivateEndpointGroupName = 'vault'
// var keyVaultPrivateDnsZoneGroupName_var = '${keyVaultPrivateEndpointName}/${keyVaultPrivateEndpointGroupName}PrivateDnsZoneGroup'

resource keyVault_resource 'Microsoft.KeyVault/vaults@2019-09-01' = {
  name: keyVaultName
  location: location

  properties: {
    tenantId: tenantId
    sku: {
      name: skuName
      family: 'A'
    }
    enabledForDeployment: enabledForDeployment
    enabledForTemplateDeployment: enabledForTemplateDeployment
    enabledForDiskEncryption: enabledForDiskEncryption
    enableSoftDelete: enableSoftDelete
    softDeleteRetentionInDays: softDeleteRetentionInDays
    enableRbacAuthorization: enableRbacAuthorization
    networkAcls: {
      bypass: 'AzureServices'
      defaultAction: 'Deny'
      ipRules: []
      virtualNetworkRules: []
    }
    accessPolicies: [
      // {
      //   tenantId: tenantId
      //   objectId: reference(vmId, '2019-12-01', 'Full').identity.principalId
      //   permissions: {
      //     keys: keysPermissions
      //     secrets: secretsPermissions
      //     certificates: certificatesPermissions
      //   }
      // }
    ]
  }
}

resource keyVaultName_secretsArray_secretName 'Microsoft.KeyVault/vaults/secrets@2019-09-01' = [for item in secretsArray: {
  name: '${keyVaultName}/${item.secretName}'
  properties: {
    value: item.secretValue
  }
  dependsOn: [
    keyVault_resource
  ]
}]

resource keyvault_cetificate_sslcert 'Microsoft.KeyVault/vaults/secrets@2019-09-01' = [for item in certsArray: {
  name: '${keyVaultName}/${item.name}'
  properties: {
    value: item.value
  }
  dependsOn: [
    keyVault_resource
  ]
}]


resource virtualNetwork_resource 'Microsoft.Network/virtualNetworks@2021-03-01' existing = {
  name: virtualNetworkName
}

resource endpointSubnet_resource 'Microsoft.Network/virtualNetworks/subnets@2021-03-01' existing = {
  name: endpointSubnetName
  parent: virtualNetwork_resource
}

// resource keyVaultPrivateDnsZone_resource 'Microsoft.Network/privateDnsZones@2020-06-01' = {
//   name: keyVaultPrivateDnsZoneName_var
//   location: 'global'
//   properties: {
//   }
// }

// resource keyVaultPrivateDnsZoneName_link_to_virtualNetworkName 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2018-09-01' = {
//   name: '${keyVaultPrivateDnsZone_resource.name}/link_to_${toLower(virtualNetworkName)}'
//   location: 'global'
//   properties: {
//     registrationEnabled: false
//     virtualNetwork: {
//       id: virtualNetwork_resource.id
//     }
//   }
//   dependsOn: [
//     virtualNetwork_resource
//   ]
// }

// resource keyVaultPrivateEndpoint_resource 'Microsoft.Network/privateEndpoints@2020-04-01' = {
//   name: keyVaultPrivateEndpointName
//   location: location
//   properties: {
//     privateLinkServiceConnections: [
//       {
//         name: keyVaultPrivateEndpointName
//         properties: {
//           privateLinkServiceId: keyVault_resource.id
//           groupIds: [
//             keyVaultPrivateEndpointGroupName
//           ]
//         }
//       }
//     ]
//     subnet: {
//       id: endpointSubnet_resource.id
//     }
//     customDnsConfigs: [
//       {
//         fqdn: '${keyVaultName}${keyVaultPublicDNSZoneForwarder}'
//       }
//     ]
//   }
//   dependsOn: [
//     endpointSubnet_resource
//   ]
// }

// resource keyVaultPrivateDnsZoneGroupName 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2020-03-01' = {
//   name: keyVaultPrivateDnsZoneGroupName_var
//   properties: {
//     privateDnsZoneConfigs: [
//       {
//         name: 'dnsConfig'
//         properties: {
//           privateDnsZoneId: keyVaultPrivateDnsZone_resource.id
//         }
//       }
//     ]
//   }
//   dependsOn: [
//     keyVault_resource
//     keyVaultPrivateEndpoint_resource
//   ]
// }

// setup diagnostic setting
resource laws_resource 'Microsoft.OperationalInsights/workspaces@2021-06-01' existing = {
  name: lawsName
}

resource keyvaultDiagnostics_resource 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: '${keyVaultName}AllDiagnostic'
  scope: keyVault_resource
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

output keyVaultName_output string = keyVaultName
output keyVaultId_output string = keyVault_resource.id

