## Infrastructure as code to deploy Microsoft Foundry and Azure Machine Learning with proper private networking controls

### Steps

1. Create new (or use existing) resource group:

```bash
az group create --name <new-rg-name> --location <your-selected-region>
```


1. Create virtual network and the subnet in an independent resource group:



3. Deploy the foundry.bicep infrastructure as code:
