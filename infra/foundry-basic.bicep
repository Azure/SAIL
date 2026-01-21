/*
  AI Foundry account and project - with public network access disabled. References existing virtual network
  
  Description: 
  - Creates an AI Foundry (previously known as Azure AI Services) account and public network access disabled.
  - Creates a gpt-4o model deployment
*/
@description('That name is the name of our application. It has to be unique. Type a name followed by your resource group name. (<name>-<resourceGroupName>)')
param aiFoundryName string = 'foundry-canadaeast-sail-dev-3'

@description('Location for all resources.')
param location string = 'canadaeast'

@description('Name of the first project')
param defaultProjectName string = '${aiFoundryName}-proj'

@description('Name of the virtual network')
param vnetName string = 'private-vnet'

@description('Name of the private endpoint subnet')
param peSubnetName string = 'pe-subnet'

@description('Name of virtual network resource group')
param vnetRgName string

@description('Create private DNS zones for private endpoints. Set to false if DNS zones already exist or are managed centrally.')
param createPrivateDnsZones bool = true

@description('Build resource IDs across RGs')
var vnetId   = resourceId(vnetRgName, 'Microsoft.Network/virtualNetworks', vnetName)
var subnetId = resourceId(vnetRgName, 'Microsoft.Network/virtualNetworks/subnets', vnetName, peSubnetName)

resource account 'Microsoft.CognitiveServices/accounts@2025-10-01-preview' = {
  name: aiFoundryName
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  kind: 'AIServices'
  sku: {
    name: 'S0'
  }
  properties: {
    // Networking
    publicNetworkAccess: 'Disabled'

    // Specifies whether this resource support project management as child resources, used as containers for access management, data isolation, and cost in AI Foundry.
    allowProjectManagement: true

    // Defines developer API endpoint subdomain
    customSubDomainName: aiFoundryName

    // Auth
    disableLocalAuth: false
  }
}

resource aiAccountPrivateEndpoint 'Microsoft.Network/privateEndpoints@2024-05-01' = {
  name: '${aiFoundryName}-private-endpoint'
  location: resourceGroup().location
  dependsOn: [
    modelDeployment
  ]
  properties: {
    subnet: {
      id: subnetId                  // Deploy in customer subnet
    }
    privateLinkServiceConnections: [
      {
        name: '${aiFoundryName}-private-link-service-connection'
        properties: {
          privateLinkServiceId: account.id
          groupIds: [
            'account'                     // Target AI Services account
          ]
        }
      }
    ]
  }
}

/* 
  Step 5: Create a private DNS zone for the private endpoint
*/
resource aiServicesPrivateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = if (createPrivateDnsZones) {
  name: 'privatelink.services.ai.azure.com'
  location: 'global'
}

resource openAiPrivateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = if (createPrivateDnsZones) {
  name: 'privatelink.openai.azure.com'
  location: 'global'
}

resource cognitiveServicesPrivateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = if (createPrivateDnsZones) {
  name: 'privatelink.cognitiveservices.azure.com'
  location: 'global'
}

// 2) Link AI Services and Azure OpenAI and Cognitive Services DNS Zone to VNet
resource aiServicesLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2024-06-01' = if (createPrivateDnsZones) {
  parent: aiServicesPrivateDnsZone
  location: 'global'
  name: 'aiServices-link'
  properties: {
    virtualNetwork: {
      id: vnetId                       // Link to specified VNet
    }
    registrationEnabled: false           // Don't auto-register VNet resources
  }
}

resource aiOpenAILink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2024-06-01' = if (createPrivateDnsZones) {
  parent: openAiPrivateDnsZone
  location: 'global'
  name: 'aiServicesOpenAI-link'
  properties: {
    virtualNetwork: {
      id: vnetId                       // Link to specified VNet
    }
    registrationEnabled: false           // Don't auto-register VNet resources
  }
}

resource cognitiveServicesLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2024-06-01' = if (createPrivateDnsZones) {
  parent: cognitiveServicesPrivateDnsZone
  location: 'global'
  name: 'aiServicesCognitiveServices-link'
  properties: {
    virtualNetwork: {
      id: vnetId                     // Link to specified VNet
    }
    registrationEnabled: false           // Don't auto-register VNet resources
  }
}

// 3) DNS Zone Group for AI Services
resource aiServicesDnsGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2024-05-01' = if (createPrivateDnsZones) {
  parent: aiAccountPrivateEndpoint
  name: '${aiFoundryName}-dns-group'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: '${aiFoundryName}-dns-aiserv-config'
        properties: {
          privateDnsZoneId: aiServicesPrivateDnsZone.id
        }
      }
      {
        name: '${aiFoundryName}-dns-openai-config'
        properties: {
          privateDnsZoneId: openAiPrivateDnsZone.id
        }
      }
      {
        name: '${aiFoundryName}-dns-cogserv-config'
        properties: {
          privateDnsZoneId: cognitiveServicesPrivateDnsZone.id
        }
      }
    ]
  }
  dependsOn: [
    aiServicesLink 
    cognitiveServicesLink
    aiOpenAILink
  ]
}


/*
  Step 6: Deploy gpt-4o model
*/
resource modelDeployment 'Microsoft.CognitiveServices/accounts/deployments@2025-10-01-preview'= {
  parent: account
  name: 'gpt-4o'
  sku : {
    capacity: 25
    name: 'Standard'
  }
  properties: {
    model:{
      name: 'gpt-4o'
      format: 'OpenAI'
      version: '2024-11-20'
    }
  }
}

/*
  Step 4: Create a Project
*/
resource project 'Microsoft.CognitiveServices/accounts/projects@2025-10-01-preview' = {
  name: defaultProjectName
  parent: account
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {}
}

output accountId string = account.id
output accountName string = account.name
output project string = project.name
