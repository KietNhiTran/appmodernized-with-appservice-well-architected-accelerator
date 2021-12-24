@description('The location in which all resources should be deployed.')
param location string = resourceGroup().location

@description('Virtual network name')
param virtualNetworkName string 

@description('application gateway name')
param applicationGWName string = 'appGW${uniqueString(resourceGroup().id)}'

@description('DNS name for the applicationtion frontend')
param applicationDNSName string

@description('Application GW serviceendpoint subnet name')
param appGWServiceEnpointSubnetName string

@description('app service name')
param appServiceName string

@description('Keyvault name')
param keyvaultName string

@description('SSL certificate')
param certName string

@description('application gateway autoscale min capacity')
param applicationGatewayAutoScaleMinCapacity int = 2

@description('application gateway autoscale max capacity')
param applicationGatewayAutoScaleMaxCapacity int = 5

@description('Specifies the Azure Active Directory tenant ID that should be used for authenticating requests to the key vault. Get it by using Get-AzSubscription cmdlet.')
param tenantId string = subscription().tenantId


@description('Specifies the permissions to keys in the vault. Valid values are: all, encrypt, decrypt, wrapKey, unwrapKey, sign, verify, get, list, create, update, import, delete, backup, restore, recover, and purge.')
param keysPermissions array = [
  'get'
  'create'
  'delete'
  'list'
  'update'
  'import'
  'backup'
  'restore'
  'recover'
]

@description('Specifies the permissions to secrets in the vault. Valid values are: all, get, list, set, delete, backup, restore, recover, and purge.')
param secretsPermissions array = [
  'get'
  'list'
  'set'
  'delete'
  'backup'
  'restore'
  'recover'
]

@description('Specifies the permissions to certificates in the vault. Valid values are: all, get, list, set, delete, managecontacts, getissuers, listissuers, setissuers, deleteissuers, manageissuers, backup, and recover.')
param certificatesPermissions array = [
  'get'
  'list'
  'delete'
  'create'
  'import'
  'update'
  'managecontacts'
  'getissuers'
  'listissuers'
  'setissuers'
  'deleteissuers'
  'manageissuers'
  'backup'
  'recover'
]

@description('Application gateway user assigned identity')
param identityName string = 'appGWId${uniqueString(resourceGroup().id)}'

@description('name of log analytics workspace')
param lawsName string

var applicationGWSkuName_var = 'WAF_v2'
var applicationGWTierName_var = 'WAF_v2'
var appGwIpConfigName_var = 'appGatewayIpConfigName'
var appGwFrontendIpConfigName_var = 'appGatewayPublicFrontendIpConfig'
var publicIpAddressName_var = 'myAppGatewayPublicIp-${uniqueString(resourceGroup().id)}'
var publicIpAddressSku_var = 'Standard'
var publicIpAddressAllocationType = 'Static'
var webAppName_var = '${applicationDNSName}-${uniqueString(resourceGroup().id)}'
var appGwFrontendPortName_var = 'appGatewayFrontendPort_80'
var appGwFrontendPort_var = 443
var appGwBackendAddressPoolName_var = 'appGateway${webAppName_var}BackendPool'
var appGwHttpSettingName_var = 'appGatewayHttpSetting_443'
var appGwListenerName_var = 'appGatewayListener'
var appGwFrontendIpConfigId_var = resourceId('Microsoft.Network/applicationGateways/frontendIPConfigurations/', applicationGWName, appGwFrontendIpConfigName_var)
var appGwFrontendPortId_var = resourceId('Microsoft.Network/applicationGateways/frontendPorts/', applicationGWName, appGwFrontendPortName_var)
var appGwListenerId_var = resourceId('Microsoft.Network/applicationGateways/httpListeners/', applicationGWName, appGwListenerName_var)
var appGwBackendAddressPoolId_var = resourceId('Microsoft.Network/applicationGateways/backendAddressPools/', applicationGWName, appGwBackendAddressPoolName_var)
var appGwHttpSettingId_var = resourceId('Microsoft.Network/applicationGateways/backendHttpSettingsCollection/', applicationGWName, appGwHttpSettingName_var)
var appGwRoutingRuleName_var = 'appGatewayRoutingRule'
var appGwHttpSettingProbeName_var = 'appGatewayHttpSettingProbe_443'
var applicationGWCert_var = '${webAppName_var}Cert'
var appGWCertID_var = resourceId('Microsoft.Network/applicationGateways/sslCertificates', applicationGWName, applicationGWCert_var)

resource virtualNetwork_resource 'Microsoft.Network/virtualNetworks@2021-03-01' existing = {
  name: virtualNetworkName
}

resource appGWServiceEnpointSubnet_resource 'Microsoft.Network/virtualNetworks/subnets@2021-03-01' existing = {
  name: appGWServiceEnpointSubnetName
  parent: virtualNetwork_resource
}

resource appService_resource 'Microsoft.Web/sites@2021-02-01' existing = {
  name: appServiceName
}

resource keyvault_resource 'Microsoft.KeyVault/vaults@2019-09-01' existing = {
  name: keyvaultName
}

resource publicIpAddress_resource 'Microsoft.Network/publicIPAddresses@2020-05-01' = {
  name: publicIpAddressName_var
  location: location
  sku: {
    name: publicIpAddressSku_var
  }
  properties: {
    publicIPAllocationMethod: publicIpAddressAllocationType
    dnsSettings: {
      domainNameLabel: toLower(webAppName_var)
    }
  }
}

var sslCertId = '${keyvault_resource.properties.vaultUri}secrets/${certName}'
resource applicationGateway_resource 'Microsoft.Network/applicationGateways@2021-03-01' = {
  name: applicationGWName
  location: location
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${appGWUserIdentity.id}' : {}
    }
  }
  properties: {
    sku: {
      name: applicationGWSkuName_var
      tier: applicationGWTierName_var
    }
    sslCertificates: [
      {
        name: applicationGWCert_var
        properties: {
          keyVaultSecretId: sslCertId
        }
      }
    ]
    gatewayIPConfigurations: [
      {
        name: appGwIpConfigName_var
        properties: {
          subnet: {
            id: appGWServiceEnpointSubnet_resource.id
          }
        }
      }
    ]
    frontendIPConfigurations: [
      {
        name: appGwFrontendIpConfigName_var
        properties: {
          publicIPAddress: {
            id: publicIpAddress_resource.id
          }
        }
      }
    ]
    frontendPorts: [
      {
        name: appGwFrontendPortName_var
        properties: {
          port: appGwFrontendPort_var
        }
      }
    ]
    backendAddressPools: [
      {
        name: appGwBackendAddressPoolName_var
        properties: {
          backendAddresses: [
            {
              fqdn: appService_resource.properties.hostNames[0]
            }
          ]
        }
      }
    ]
    backendHttpSettingsCollection: [
      {
        name: appGwHttpSettingName_var
        properties: {
          port: 443
          protocol: 'Https'
          cookieBasedAffinity: 'Disabled'
          requestTimeout: 20
          pickHostNameFromBackendAddress: true
        }
      }
    ]
    httpListeners: [
      {
        name: appGwListenerName_var
        properties: {
          frontendIPConfiguration: {
            id: appGwFrontendIpConfigId_var
          }
          frontendPort: {
            id: appGwFrontendPortId_var
          }
          protocol: 'Https'
          sslCertificate: {
            id: appGWCertID_var
          }
        }
      }
    ]
    requestRoutingRules: [
      {
        name: appGwRoutingRuleName_var
        properties: {
          ruleType: 'Basic'
          httpListener: {
            id: appGwListenerId_var
          }
          backendAddressPool: {
            id: appGwBackendAddressPoolId_var
          }
          backendHttpSettings: {
            id: appGwHttpSettingId_var
          }
        }
      }
    ]
    enableHttp2: true
    probes: [
      {
        name: appGwHttpSettingProbeName_var
        properties: {
          interval: 30
          minServers: 0
          path: '/'
          protocol: 'Https'
          timeout: 30
          unhealthyThreshold: 3
          pickHostNameFromBackendHttpSettings: true
        }
      }
    ]
    autoscaleConfiguration: {
      minCapacity: applicationGatewayAutoScaleMinCapacity
      maxCapacity: applicationGatewayAutoScaleMaxCapacity
    }
    webApplicationFirewallConfiguration: {
      enabled: true
      firewallMode: 'Prevention'
      ruleSetType: 'OWASP'
      ruleSetVersion: '3.2'
    }
  }
  dependsOn: [
    appService_resource
    keyvaultAccessPolicies
  ]
}

resource appGWUserIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2018-11-30' = {
  name: identityName
  location: location
}

resource keyvaultAccessPolicies 'Microsoft.KeyVault/vaults/accessPolicies@2019-09-01' = {
  name: 'add'
  parent: keyvault_resource
  properties: {
    accessPolicies: [
      {
        tenantId: tenantId
        objectId: reference(appGWUserIdentity.id).principalId
        permissions: {
          keys: keysPermissions
          certificates:certificatesPermissions
          secrets: secretsPermissions
        }
      }
    ]
  }
}

// setting up diagnostics logging
resource laws_resource 'Microsoft.OperationalInsights/workspaces@2021-06-01' existing = {
  name: lawsName
}

resource appGWDiagnostics_resource 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: '${applicationGWName}AllDiagnostic'
  scope: applicationGateway_resource
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

output appGWName_output string = applicationGateway_resource.name
