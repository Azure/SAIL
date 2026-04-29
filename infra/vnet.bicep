/*
  Generic virtual network and subnet
  
  Description: 
  - Virtual network
  - Subnet for private endpoints
  - Subnets for Databricks VNet injection (host and container) with delegation and NSG
*/

@description('Name of the virtual network')
param vnetName string = 'private-vnet'

@description('Name of the private endpoint subnet')
param peSubnetName string = 'pe-subnet'

@description('Name of the Databricks host subnet')
param databricksHostSubnetName string = 'databricks-host-subnet'

@description('Name of the Databricks container subnet')
param databricksContainerSubnetName string = 'databricks-container-subnet'

// NSG for Databricks subnets (required for VNet injection)
resource databricksNsg 'Microsoft.Network/networkSecurityGroups@2024-05-01' = {
  name: '${vnetName}-databricks-nsg'
  location: resourceGroup().location
}

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
      {
        name: databricksHostSubnetName
        properties: {
          addressPrefix: '192.168.1.0/24'
          networkSecurityGroup: {
            id: databricksNsg.id
          }
          delegations: [
            {
              name: 'databricks-delegation'
              properties: {
                serviceName: 'Microsoft.Databricks/workspaces'
              }
            }
          ]
        }
      }
      {
        name: databricksContainerSubnetName
        properties: {
          addressPrefix: '192.168.2.0/24'
          networkSecurityGroup: {
            id: databricksNsg.id
          }
          delegations: [
            {
              name: 'databricks-delegation'
              properties: {
                serviceName: 'Microsoft.Databricks/workspaces'
              }
            }
          ]
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
