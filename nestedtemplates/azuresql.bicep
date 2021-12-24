@description('Specifies the location for all the resources.')
param location string

@description('Azure SQL DB server name')
param sqlServerName string = 'sqlServer${uniqueString(resourceGroup().id)}'

@description('Azure SQL DB server name')
param sqlDatabaseName string = 'db001'

@description('SQL server admin user name')
param sqlServerAdmin string

@description('Sql Server admin password')
param sqlServerPassword string

@description('database collation')
param databaseCollation string = 'SQL_Latin1_General_CP1_CI_AS'

@description('Enable zone redudant')
param enableZoneRedundant bool

@description('name of log analytics workspace')
param lawsName string

@description('Sku of the Database')
param dbSKU string = 'GP_Gen5_2'


resource azureSQL 'Microsoft.Sql/servers@2021-05-01-preview' = {
  location: location
  name: sqlServerName
  properties: {
    administratorLogin: sqlServerAdmin
    administratorLoginPassword: sqlServerPassword
    publicNetworkAccess: 'Disabled'
  }

}

resource azureSQLDB 'Microsoft.Sql/servers/databases@2021-05-01-preview' = {
  location: location
  name: sqlDatabaseName
  parent: azureSQL
  properties: {
    collation: databaseCollation
    sampleName: 'AdventureWorksLT'
    zoneRedundant: enableZoneRedundant
  }
  sku: {
    name: dbSKU
  }
}

// setup diagnostic setting
resource laws_resource 'Microsoft.OperationalInsights/workspaces@2021-06-01' existing = {
  name: lawsName
}

resource keyvaultDiagnostics_resource 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: '${sqlServerName}-${sqlDatabaseName}-AllDiagnostic'
  scope: azureSQLDB
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
        category: 'InstanceAndAppAdvanced'
        enabled: true
      }
    ]
  }
}

output sqlName_output string = azureSQL.name
output sqlServerId_output string = azureSQL.id
