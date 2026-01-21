# SAIL Infrastructure Deployment Guide

This guide provides instructions for deploying the SAIL infrastructure to Azure using the PowerShell deployment script.

## Prerequisites

1. **Azure CLI**: Install from [https://docs.microsoft.com/cli/azure/install-azure-cli](https://docs.microsoft.com/cli/azure/install-azure-cli)
2. **PowerShell**: Version 7.0 or later recommended
3. **Azure Subscription**: Active Azure subscription with appropriate permissions
4. **Login to Azure**: Run `az login` before deployment

## Quick Start

### 1. Login to Azure

```powershell
az login
```

### 2. Configure Your Deployment

Edit the `config.json` file with your specific values:

```json
{
  "location": "canadaeast",
  "resourceGroup": "rg-sail-dev",
  "vnetResourceGroup": "rg-sail-network-dev",
  "vnetName": "private-vnet",
  "subnetName": "pe-subnet",
  "amlName": "sail",
  "amlFriendlyName": "SAIL Azure ML deployment demo",
  "amlDescription": "This is an example SAIL deployment using Azure ML.",
  "prefix": "saildeploy",
  "foundryName": "foundry-canadaeast-sail-dev",
  "foundryLocation": "canadaeast",
  "foundryProjectName": "foundry-canadaeast-sail-dev-proj"
}
```

### 3. Deploy Everything

```powershell
.\deploy.ps1
```

This will deploy:
- Virtual Network with private endpoint subnet
- Azure Machine Learning workspace with all dependencies
- Microsoft Foundry (Azure AI Services) with GPT-4o deployment

## Advanced Usage

### Deploy Only Specific Components

**Deploy only VNet:**
```powershell
.\deploy.ps1 -DeploymentType vnet
```

**Deploy only Azure ML:**
```powershell
.\deploy.ps1 -DeploymentType aml -SkipVNetDeployment
```

**Deploy only Foundry:**
```powershell
.\deploy.ps1 -DeploymentType foundry -SkipVNetDeployment
```

### Use Different Configuration Files

**Development environment:**
```powershell
.\deploy.ps1 -ConfigFile .\config.json
```

**Production environment:**
```powershell
.\deploy.ps1 -ConfigFile .\config.prod.json
```

### Specify Subscription

```powershell
.\deploy.ps1 -SubscriptionId "your-subscription-id"
```

### Skip VNet Deployment (if VNet already exists)

```powershell
.\deploy.ps1 -SkipVNetDeployment
```

## Configuration Files

### config.json (Development)
Default configuration for development environments.

### config.prod.json (Production)
Configuration template for production environments with production-appropriate naming.

### vnet.parameters.json
Static parameters for VNet deployment. Modify if you need different VNet/subnet names.

## Deployment Architecture

The script deploys resources in the following order:

1. **Resource Groups**
   - VNet resource group (e.g., `rg-sail-network-dev`)
   - Main resource group (e.g., `rg-sail-dev`)

2. **Virtual Network** (unless skipped)
   - Private virtual network (192.168.0.0/16)
   - Private endpoint subnet (192.168.0.0/24)

3. **Azure Machine Learning** (if selected)
   - AML Workspace
   - Key Vault
   - Storage Account
   - Container Registry
   - Application Insights
   - Private endpoints for secure networking

4. **Microsoft Foundry** (if selected)
   - Azure AI Services account
   - GPT-4o model deployment
   - Private endpoint
   - Private DNS zones

## Troubleshooting

### Azure CLI Not Found
Ensure Azure CLI is installed and available in your PATH:
```powershell
az version
```

### Authentication Errors
Login to Azure and ensure you have access to the subscription:
```powershell
az login
az account show
az account list --output table
```

### Resource Group Already Exists
The script will use existing resource groups if they already exist. This is by design.

### VNet Already Exists
Use the `-SkipVNetDeployment` flag to skip VNet creation:
```powershell
.\deploy.ps1 -SkipVNetDeployment
```

### Permission Errors
Ensure your Azure account has:
- Contributor role on the subscription or resource group
- Permissions to create resource groups
- Permissions to create network resources and private endpoints

### Deployment Failures
Check the Azure Portal > Resource Groups > Deployments for detailed error messages.

## Cleanup

To remove all deployed resources:

```powershell
# Delete main resource group
az group delete --name rg-sail-dev --yes --no-wait

# Delete VNet resource group
az group delete --name rg-sail-network-dev --yes --no-wait
```

## Security Considerations

- All resources are deployed with private endpoints
- Public network access is disabled for AI Services
- Resources are isolated within the virtual network
- Key Vault is used for secrets management
- Managed identities are used where possible

## Next Steps

After deployment:

1. **Azure Machine Learning**: Access the workspace through Azure Portal or Azure ML Studio
2. **Microsoft Foundry**: Access through Azure AI Studio at [https://ai.azure.com](https://ai.azure.com)
3. **Model Deployment**: Follow the instructions in `/aml/deployment/` to deploy models
4. **Testing**: Use the test scripts in `/aml/test/` to verify deployments

## Support

For issues or questions:
- Check the [README.md](README.md) for architecture details
- Review Azure deployment logs in the Azure Portal
- Check resource-specific logs in Azure Monitor
