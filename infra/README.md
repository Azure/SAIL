## Infrastructure as code to deploy Microsoft Foundry and Azure Machine Learning with proper private networking controls

## What's New

### Automated Deployment Script (PowerShell)
We've added comprehensive PowerShell-based deployment automation to simplify infrastructure deployment:

- **`deploy.ps1`**: Main deployment script with support for selective deployments (all, vnet, aml, foundry)
- **Configuration Files**: Environment-specific JSON configuration files (`config.json`, `config.prod.json`)
- **Automated Resource Management**: Automatic resource group creation and subscription handling
- **Multi-Environment Support**: Easy switching between development and production configurations
- **Error Handling**: Comprehensive validation and error reporting

See [DEPLOYMENT.md](DEPLOYMENT.md) for detailed usage instructions and examples.

### Private DNS Zone Control
New parameter to control private DNS zone creation for enterprise scenarios:

- **`createPrivateDnsZones`** parameter (default: `true`) - Set to `false` to suppress DNS zone creation
- Applies to all resources: Key Vault, Storage, Container Registry, Azure ML, and Foundry
- Useful for:
  - Centralized DNS management in hub-spoke architectures
  - Environments where DNS zones already exist
  - Custom DNS configurations
  - Azure Private DNS Resolver scenarios

**Example usage:**
```json
{
  "createPrivateDnsZones": false
}
```

Or via command line:
```bash
az deployment group create --template-file aml.bicep --parameters createPrivateDnsZones=false ...
```

---

## Manual Deployment

### Initial set-up for resource-group(s) and virtual network

Create new (or use existing) resource group(s)

```bash
az group create --name <new-rg-name> --location <your-selected-region>
az group create --name <new-rg-name-vnet> --location <your-selected-region>
```
Create virtual network and the subnet in an independent resource group:

```bash
az deployment group create --resource-group <new-rg-name-vnet> --template-file vnet.bicep
```

### Steps for Azure Machine Learning

Deploy the ```aml.bicep``` infrastructure as code:

```bash
az deployment group create --resource-group <new-rg-name> --template-file aml.bicep --parameters vnetName="private-vnet" vnetRgName="<new-rg-name-vnet>" subnetName="pe-subnet"

```


### Steps for Microsoft Foundry

Deploy the ```foundry.bicep``` infrastructure as code:

```bash
az deployment group create --resource-group <new-rg-name> --template-file foundry-basic.bicep --parameters vnetRgName="<new-rg-name-vnet>"
```
