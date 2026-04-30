/*
  Azure Databricks workspace with VNet injection and private connectivity
  
  Description: 
  - Creates an Azure Databricks workspace with VNet injection (secure cluster connectivity)
  - Public network access disabled
  - No public IPs on cluster nodes
  - Private endpoint for UI and API access
  - Private DNS zone for name resolution
*/

@description('Name of the Azure Databricks workspace')
param databricksName string = 'dbw-sail-dev'

@description('Location for all resources.')
param location string = 'canadacentral'

@description('The pricing tier of the Databricks workspace.')
@allowed([
  'standard'
  'premium'
])
param pricingTier string = 'premium'

@description('Name of the virtual network')
param vnetName string = 'private-vnet'

@description('Name of the private endpoint subnet')
param peSubnetName string = 'pe-subnet'

@description('Name of the Databricks host (public) subnet')
param databricksHostSubnetName string = 'databricks-host-subnet'

@description('Name of the Databricks container (private) subnet')
param databricksContainerSubnetName string = 'databricks-container-subnet'

@description('Name of virtual network resource group')
param vnetRgName string

@description('Create private DNS zones for private endpoints. Set to false if DNS zones already exist or are managed centrally.')
param createPrivateDnsZones bool = true

// Build resource IDs across RGs
var vnetId = resourceId(vnetRgName, 'Microsoft.Network/virtualNetworks', vnetName)
var peSubnetId = resourceId(vnetRgName, 'Microsoft.Network/virtualNetworks/subnets', vnetName, peSubnetName)
var managedRgName = 'databricks-rg-${databricksName}-${uniqueString(databricksName, resourceGroup().id)}'
var managedRgId = '${subscription().id}/resourceGroups/${managedRgName}'

/*
  Step 1: Create the Databricks workspace with VNet injection
*/
resource databricksWorkspace 'Microsoft.Databricks/workspaces@2024-05-01' = {
  name: databricksName
  location: location
  sku: {
    name: pricingTier
  }
  properties: {
    managedResourceGroupId: managedRgId

    // Networking
    publicNetworkAccess: 'Disabled'
    requiredNsgRules: 'NoAzureDatabricksRules'

    parameters: {
      customVirtualNetworkId: {
        value: vnetId
      }
      customPublicSubnetName: {
        value: databricksHostSubnetName
      }
      customPrivateSubnetName: {
        value: databricksContainerSubnetName
      }
      enableNoPublicIp: {
        value: true
      }
    }
  }
}

/*
  Step 2: Create a private endpoint for Databricks UI and API
*/
resource databricksPrivateEndpoint 'Microsoft.Network/privateEndpoints@2024-05-01' = {
  name: '${databricksName}-private-endpoint'
  location: location
  properties: {
    subnet: {
      id: peSubnetId
    }
    privateLinkServiceConnections: [
      {
        name: '${databricksName}-private-link-service-connection'
        properties: {
          privateLinkServiceId: databricksWorkspace.id
          groupIds: [
            'databricks_ui_api'
          ]
        }
      }
    ]
  }
}

/*
  Step 3: Create a private DNS zone for the private endpoint
*/
resource databricksPrivateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = if (createPrivateDnsZones) {
  name: 'privatelink.azuredatabricks.net'
  location: 'global'
}

// Link DNS zone to VNet
resource databricksDnsVnetLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2024-06-01' = if (createPrivateDnsZones) {
  parent: databricksPrivateDnsZone
  location: 'global'
  name: 'databricks-link'
  properties: {
    virtualNetwork: {
      id: vnetId
    }
    registrationEnabled: false
  }
}

// DNS zone group for the private endpoint
resource databricksDnsGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2024-05-01' = if (createPrivateDnsZones) {
  parent: databricksPrivateEndpoint
  name: '${databricksName}-dns-group'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: '${databricksName}-dns-config'
        properties: {
          privateDnsZoneId: databricksPrivateDnsZone.id
        }
      }
    ]
  }
  dependsOn: [
    databricksDnsVnetLink
  ]
}
