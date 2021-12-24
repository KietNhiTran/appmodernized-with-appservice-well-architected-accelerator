@description('Specifies the location for all the resources.')
param location string

@description('Private endpoint Name')
param privateEndpointName string

@description('private endpoint connection name')
param privateEndpointConnectionName string = '${privateEndpointName}-pep-${uniqueString(resourceGroup().id)}'

@description('ID of Service resource which privdes endpoint service')
param privateEndpointServiceId string 

@description('Private endpoint group type ID')
param groupType string

@description('Subnet which hosts the private endpoint')
param privateEndpointSubnetName string

@description('Private DNS zone name')
param privateDNSZoneName string

@description('Virtual Network name')
param virtualNetworkName string

@description('Private DNS zone name')
param privateDNSZoneLinkName string = '${privateDNSZoneName}/${privateDNSZoneName}-${virtualNetworkName}-link'

@description('FQDN of the service which provides endpoint sevice.')
param privateEndpointFQDN string

var privateDnsZoneGroupName_var = '${privateEndpointName}/${groupType}PrivateDnsZoneGroup'

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2021-05-01' existing = {
  name: virtualNetworkName
}

resource subnet 'Microsoft.Network/virtualNetworks/subnets@2021-05-01' existing = {
  name: privateEndpointSubnetName
  parent: virtualNetwork
}

resource privateEndpoint_resource 'Microsoft.Network/privateEndpoints@2020-04-01' = {
  name: privateEndpointName
  location: location
  properties: {
    privateLinkServiceConnections: [
      {
        name: privateEndpointConnectionName
        properties: {
          privateLinkServiceId: privateEndpointServiceId
          groupIds: [
            groupType
          ]
        }
      }
    ]
    subnet: {
      id: subnet.id
    }
    customDnsConfigs: [
      {
        fqdn: privateEndpointFQDN
      }
    ]
  }
  dependsOn: [
    subnet
  ]
}

resource privateDNSZone_resource 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: privateDNSZoneName
  location: 'global'
  properties: {
  }
}

resource privateDNSLink_resource 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  name: privateDNSZoneLinkName
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: virtualNetwork.id
    }
  }
  dependsOn: [
    privateDNSZone_resource
    virtualNetwork
  ]
}

resource privateDnsZoneGroup_resource 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2020-03-01' = {
  name: privateDnsZoneGroupName_var
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'dnsConfig'
        properties: {
          privateDnsZoneId: privateDNSZone_resource.id
        }
      }
    ]
  }
  dependsOn: [
    privateEndpoint_resource
  ]
}

output privateEndpointFQDN_output string = privateEndpointFQDN
