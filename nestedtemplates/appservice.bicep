@description('The location in which all resources should be deployed.')
param location string = resourceGroup().location

@description('The name of the app to create.')
param appName string = 'app${uniqueString(resourceGroup().id)}'

@description('Name of veritual network where the private endpoint will be created')
param virtualNetworkName string

@description('Name of veritual network where the private endpoint will be created')
param keyvaultName string

@description('App Service SKU')
param appServicePlanSku string = enableZoneRedundant ? 'P1v3' : 'S1'

@description('Name of the default scaling rule')
param autoscaleSettingName string = '${appName}DefaultScalingSetting'

@description('Admistrators email to receive autoscale notification')
param autoscaleNotificationEmail string = 'administrator@abc.com'


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

@description('Specifies the Azure Active Directory tenant ID that should be used for authenticating requests to the key vault. Get it by using Get-AzSubscription cmdlet.')
param tenantId string = subscription().tenantId

@description('Secete 1 name, for testing purpose')
param secret1Name string = 'secret1'

@description('Application subnet name')
param appServiceSubnetName string

@description('Application GW serviceendpoint subnet name')
param appGWServiceEnpointSubnetName string

@description('name of log analytics workspace')
param lawsName string

@description('Application Insights name')
param applicationInsightsName string = '${appName}ApplicationInsight${uniqueString(resourceGroup().id)}'

@description('App Service health check path')
param appHealthCheckPath string = '/'

@description('Enable remote debug. Only turn on this in dev / stagging env')
param remoteDebugEnable bool = false

@description('Enable snapshot debugger')
param snapshotDebuggerEnale string = 'disabled'

@description('Enable zone redudant')
param enableZoneRedundant bool

var appServicePlanName = '${appName}${uniqueString(subscription().subscriptionId)}'
var keyVaultPublicDNSZoneForwarder = ((toLower(environment().name) == 'azureusgovernment') ? '.vaultcore.usgovcloudapi.net' : '.vaultcore.azure.net')
var testSecret1Uri_var = 'https://${keyvaultName}${keyVaultPublicDNSZoneForwarder}/secrets/${secret1Name}/'

resource virtualNetwork_resource 'Microsoft.Network/virtualNetworks@2021-03-01' existing = {
  name: virtualNetworkName
}

resource keyvault_resource 'Microsoft.KeyVault/vaults@2019-09-01' existing = {
  name: keyvaultName
}

resource endpointSubnet_resource 'Microsoft.Network/virtualNetworks/subnets@2021-03-01' existing = {
  name: appServiceSubnetName
  parent: virtualNetwork_resource
}

resource appGWServiceEnpointSubnet_resource 'Microsoft.Network/virtualNetworks/subnets@2021-03-01' existing = {
  name: appGWServiceEnpointSubnetName
  parent: virtualNetwork_resource
}

resource appServicePlan 'Microsoft.Web/serverfarms@2021-02-01' = {
  name: appServicePlanName
  location: location
  sku: {
    name: appServicePlanSku
    capacity: enableZoneRedundant? 3 : 1
  }
  kind: 'app'
  properties: {
    zoneRedundant: enableZoneRedundant
  }
}

// create the app service to host the application
resource webApp_resource 'Microsoft.Web/sites@2021-01-01' = {
  name: appName
  location: location
  kind: 'app'
  properties: {
    serverFarmId: appServicePlan.id
    virtualNetworkSubnetId: endpointSubnet_resource.id
    httpsOnly: false
    siteConfig: {
      http20Enabled: true
      minTlsVersion: '1.2'
      ipSecurityRestrictions: [
        {
          vnetSubnetResourceId: appGWServiceEnpointSubnet_resource.id
          action: 'Allow'
          tag: 'Default'
          priority: 200
          name: 'appGatewaySubnet'
          description: 'Isolate traffic to subnet containing Azure Application Gateway'
        }
      ]
      appSettings: [
        {
          name: 'APPINSIGHTS_INSTRUMENTATIONKEY'
          value: applicationInsights_resource.properties.InstrumentationKey
        }
        {
          name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
          value: applicationInsights_resource.properties.ConnectionString
        }
        {
          name: 'ApplicationInsightsAgent_EXTENSION_VERSION'
          value: '~2'
        }
        {
          name: 'secret1'
          value: '@Microsoft.KeyVault(SecretUri=${testSecret1Uri_var})'
        }
        {
          name: 'XDT_MicrosoftApplicationInsights_Mode'
          value: 'recommended'
        }
        {
          name: 'APPINSIGHTS_PROFILERFEATURE_VERSION'
          value: '1.0.0'
        }
        {
          name: 'APPINSIGHTS_SNAPSHOTFEATURE_VERSION'
          value: '1.0.0'
        }
        {
          name: 'DiagnosticServices_EXTENSION_VERSION'
          value: '~3'
        }
        {
          name: 'SnapshotDebugger_EXTENSION_VERSION'
          value: snapshotDebuggerEnale // only enable this in dev env / stag env
        }
      ]
      healthCheckPath: appHealthCheckPath
      loadBalancing: 'LeastRequests'
      remoteDebuggingEnabled: remoteDebugEnable
      requestTracingEnabled: true
      vnetRouteAllEnabled: false
    }

  }
  identity: {
    type: 'SystemAssigned'
  }
  dependsOn: [
    endpointSubnet_resource
  ]
}

// enable logging
resource appServiceLogging 'Microsoft.Web/sites/config@2020-06-01' = {
  parent: webApp_resource
  name: 'logs'
  properties: {
    applicationLogs: {
      fileSystem: {
        level: 'Warning'
      }
    }
    httpLogs: {
      fileSystem: {
        retentionInMb: 40
        enabled: true
      }
    }
    failedRequestsTracing: {
      enabled: true
    }
    detailedErrorMessages: {
      enabled: true
    }
  }
}

/// enable app service to access keyvault via policy
resource keyvaultAccessPolicies 'Microsoft.KeyVault/vaults/accessPolicies@2019-09-01' = {
  name: 'add'
  parent: keyvault_resource
  properties: {
    accessPolicies: [
      {
        tenantId: tenantId
        objectId: webApp_resource.identity.principalId
        permissions: {
          keys: keysPermissions
          certificates:certificatesPermissions
          secrets: secretsPermissions
        }
      }
    ]
  }
}

// auto scaling
resource appDefaultAutoScale_resource 'Microsoft.Insights/autoscalesettings@2021-05-01-preview' = {
  location: location
  name: autoscaleSettingName
  properties: {
    enabled: true
    name: autoscaleSettingName
    notifications: [
      {
        operation: 'Scale'
        email: {
          customEmails: [
            autoscaleNotificationEmail
          ]
          sendToSubscriptionAdministrator: true
          sendToSubscriptionCoAdministrators: false
        }
        webhooks: []
      }
    ]
    predictiveAutoscalePolicy: {
      scaleMode: 'Disabled'
    }
    targetResourceLocation: location
    targetResourceUri: appServicePlan.id
    profiles: [
      {
        name: '${autoscaleSettingName}Profile'
        capacity: {
          default: enableZoneRedundant ? '3' : '1'
          maximum: '6'
          minimum: enableZoneRedundant ? '3' : '1'
        }
        rules: [
          {
            scaleAction: {
                direction: 'Increase'
                type: 'ChangeCount'
                value: '1'
                cooldown: 'PT10M'
            }
            metricTrigger: {
                metricName: 'CpuPercentage'
                metricNamespace: 'microsoft.web/serverfarms'
                metricResourceUri: appServicePlan.id
                operator: 'GreaterThan'
                statistic: 'Average'
                threshold: 80
                timeAggregation: 'Average'
                timeGrain: 'PT1M'
                timeWindow: 'PT10M'
                dimensions:[]
                dividePerInstance: false
            }
         }
         {
            scaleAction: {
                direction: 'Decrease'
                type: 'ChangeCount'
                value: '1'
                cooldown: 'PT10M'
            }
            metricTrigger: {
                metricName: 'CpuPercentage'
                metricNamespace: 'microsoft.web/serverfarms'
                metricResourceUri: appServicePlan.id
                operator: 'LessThan'
                statistic: 'Average'
                threshold: 50
                timeAggregation: 'Average'
                timeGrain: 'PT1M'
                timeWindow: 'PT10M'
                dimensions:[]
                dividePerInstance: false
            }
          }
        ]
      }
    ]
  }
  dependsOn: [
    webApp_resource
  ]
}

// enable scale diagnostic logging setting
resource scaleDiagnosticSetting 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: '${appName}AutoScaleAllDiagnostic'
  scope: appDefaultAutoScale_resource
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

// Create application insights component
resource laws_resource 'Microsoft.OperationalInsights/workspaces@2021-06-01' existing = {
  name: lawsName
}


resource applicationInsights_resource 'Microsoft.Insights/components@2020-02-02-preview' = {
  name: applicationInsightsName
  location: location
  kind: 'web'
  properties: {
    Application_Type: 'web'
    WorkspaceResourceId: laws_resource.id
  }
}


output appServiceName_output string = appName

// appendix for reference only
// resource appServiceSiteExtension 'Microsoft.Web/sites/config@2021-02-01' = {
//   parent: webApp_resource
//   name: 'appsettings'
//   properties: {
//     secret1: '@Microsoft.KeyVault(SecretUri=${testSecret1Uri_var})'
//   } 
// }


// resource appServiceSiteExtension 'Microsoft.Web/sites/config@2021-02-01' = {
//   parent: webApp_resource
//   name: 'appsettings'
//   properties: {
//     APPINSIGHTS_INSTRUMENTATIONKEY: applicationInsights_resource.properties.InstrumentationKey
//     APPINSIGHTS_PROFILERFEATURE_VERSION: '1.0.0'
//     APPINSIGHTS_SNAPSHOTFEATURE_VERSION: '1.0.0'
//     APPLICATIONINSIGHTS_CONNECTION_STRING: applicationInsights_resource.properties.ConnectionString
//     ApplicationInsightsAgent_EXTENSION_VERSION: '~2'
//     DiagnosticServices_EXTENSION_VERSION: '~3'
//     InstrumentationEngine_EXTENSION_VERSION: 'disabled'
//     SnapshotDebugger_EXTENSION_VERSION: 'disabled'
//     XDT_MicrosoftApplicationInsights_Mode: 'recommended'
//     XDT_MicrosoftApplicationInsights_BaseExtensions: 'disabled'
//     XDT_MicrosoftApplicationInsights_Java: '1'
//     XDT_MicrosoftApplicationInsights_NodeJS: '1'
//     XDT_MicrosoftApplicationInsights_PreemptSdk: 'disabled'
//     secret1: '@Microsoft.KeyVault(SecretUri=${testSecret1Uri_var})'
//   } 
// }
