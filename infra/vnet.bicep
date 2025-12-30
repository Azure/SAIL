/*
  Generic virtual network and subnet
  
  Description: 
  - Virtual network
  - Subnet
*/

@description('Name of the virtual network')
param vnetName string = 'private-vnet'

@description('Name of the private endpoint subnet')
param peSubnetName string = 'pe-subnet'

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2024-05-01' = {
  name: vnetName
  location: resourceGroup().location
  properties: {
    addressSpace: {
      addressPrefixes: [
        '192.168.0.0/16'
      ]
    }
    subnets: [
      {
        name: peSubnetName
        properties: {
          addressPrefix: '192.168.0.0/24'
        }
      }
    ]
  }
}

resource subnet 'Microsoft.Network/virtualNetworks/subnets@2024-05-01' = {
  parent: virtualNetwork
  name: peSubnetName
  properties: {
    addressPrefix: '192.168.0.0/24'
  }
}
