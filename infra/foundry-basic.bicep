/*
  AI Foundry account and project - with public network access disabled
  
  Description: 
  - Creates an AI Foundry (previously known as Azure AI Services) account and public network access disabled.
  - Creates a gpt-4o model deployment
*/
@description('That name is the name of our application. It has to be unique. Type a name followed by your resource group name. (<name>-<resourceGroupName>)')
param aiFoundryName string = 'foundrypnadisabled'

@description('Location for all resources.')
param location string = 'eastus'

@description('Name of the first project')
param defaultProjectName string = '${aiFoundryName}-proj'
