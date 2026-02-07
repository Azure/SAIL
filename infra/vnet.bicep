/*
  Generic virtual network and subnet
  
  Description: 
  - Virtual network with optional DDoS protection
  - Subnet with Network Security Group (required for landing zone compliance)
*/

@description('Name of the virtual network')
param vnetName string = 'private-vnet'

@description('Name of the private endpoint subnet')
param peSubnetName string = 'pe-subnet'

@description('Address space for the virtual network')
param addressPrefix string = '192.168.0.0/16'

@description('Address prefix for the private endpoint subnet')
param subnetPrefix string = '192.168.0.0/24'

@description('Enable DDoS protection (required in some landing zones)')
param enableDdosProtection bool = false

@description('Resource ID of existing DDoS protection plan (required if enableDdosProtection is true and createDdosPlan is false)')
param ddosProtectionPlanId string = ''

@description('Create a new DDoS protection plan')
param createDdosPlan bool = false

// DDoS Protection Plan (optional - only create if specified)
resource ddosPlan 'Microsoft.Network/ddosProtectionPlans@2024-05-01' = if (createDdosPlan) {
  name: '${vnetName}-ddos-plan'
  location: resourceGroup().location
  properties: {}
}

// Network Security Group for the subnet (required by Azure Landing Zone policies)
resource nsg 'Microsoft.Network/networkSecurityGroups@2024-05-01' = {
  name: '${peSubnetName}-nsg'
  location: resourceGroup().location
  properties: {
    securityRules: [
      // Allow inbound HTTPS for private endpoint traffic
      {
        name: 'AllowHttpsInbound'
        properties: {
          priority: 100
          direction: 'Inbound'
          access: 'Allow'
          protocol: 'Tcp'
          sourceAddressPrefix: 'VirtualNetwork'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '443'
        }
      }
      // Deny all other inbound traffic from internet
      {
        name: 'DenyInternetInbound'
        properties: {
          priority: 4096
          direction: 'Inbound'
          access: 'Deny'
          protocol: '*'
          sourceAddressPrefix: 'Internet'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '*'
        }
      }
    ]
  }
}

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2024-05-01' = {
  name: vnetName
  location: resourceGroup().location
  properties: {
    addressSpace: {
      addressPrefixes: [
        addressPrefix
      ]
    }
    ddosProtectionPlan: enableDdosProtection ? {
      id: createDdosPlan ? ddosPlan.id : ddosProtectionPlanId
    } : null
    enableDdosProtection: enableDdosProtection
    subnets: [
      {
        name: peSubnetName
        properties: {
          addressPrefix: subnetPrefix
          networkSecurityGroup: {
            id: nsg.id
          }
        }
      }
    ]
  }
}

output vnetId string = virtualNetwork.id
output subnetId string = virtualNetwork.properties.subnets[0].id
output nsgId string = nsg.id
