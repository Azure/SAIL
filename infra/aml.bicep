// Execute this main file to deploy Azure AI studio resources in the basic security configuration

// Parameters
@minLength(2)
@maxLength(12)
@description('Name for the AI resource and used to derive name of dependent resources.')
param amlName string = 'sail'

@description('Friendly name for your Azure AI resource')
param amlFriendlyName string = 'SAIL Azure ML deployment demo'

@description('Description of your Azure AI resource displayed in AI studio')
param amlDescription string = 'This is an example SAIL deployment using Azure ML.'

@description('Set of tags to apply to all resources.')
param tags object = {}

@description('Resource name of the virtual network to deploy the resource into.')
param vnetName string

@description('Resource group name of the virtual network to deploy the resource into.')
param vnetRgName string

@description('Name of the subnet to deploy into.')
param subnetName string

@description('The location into which the resources should be deployed.')
param location string = resourceGroup().location

@minLength(2)
@maxLength(10)
@description('Prefix for all resource names.')
param prefix string = 'saildeploy'

@description('Create private DNS zones for private endpoints. Set to false if DNS zones already exist or are managed centrally.')
param createPrivateDnsZones bool = true

// Variables
var name = toLower('${amlName}')

// Create a short, unique suffix, that will be unique to each resource group
var uniqueSuffix = substring(uniqueString(resourceGroup().id), 0, 7)

var vnetResourceId = '/subscriptions/${subscription().subscriptionId}/resourceGroups/${vnetRgName}/providers/Microsoft.Network/virtualNetworks/${vnetName}'
var subnetResourceId = '${vnetResourceId}/subnets/${subnetName}'

// Dependent resources for the Azure Machine Learning workspace
module aiDependencies 'modules/dependent-resources.bicep' = {
  name: 'dependencies-${name}-${uniqueSuffix}-deployment'
  params: {
    location: location
    tags: tags
    subnetResourceId: subnetResourceId
    vnetResourceId: vnetResourceId
    prefix: prefix
    createPrivateDnsZones: createPrivateDnsZones
  }
}

module amlWorkspace 'modules/aml-workspace.bicep' = {
  name: 'aml-${name}-${uniqueSuffix}-deployment'
  params: {
    // workspace organization
    amlWorkspaceName: 'aml-${name}-${uniqueSuffix}'
    amlWorkspaceFriendlyName: amlFriendlyName
    amlWorkspaceDescription: amlDescription
    location: location
    tags: tags

    //metadata
    uniqueSuffix: uniqueSuffix

    //network related
    vnetResourceId: vnetResourceId
    subnetResourceId: subnetResourceId
    createPrivateDnsZones: createPrivateDnsZones

    // dependent resources
    applicationInsightsId: aiDependencies.outputs.applicationInsightsId
    containerRegistryId: aiDependencies.outputs.containerRegistryId
    keyVaultId: aiDependencies.outputs.keyvaultId
    storageAccountId: aiDependencies.outputs.storageId

  }
}
