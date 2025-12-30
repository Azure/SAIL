## Infrastructure as code to deploy Microsoft Foundry and Azure Machine Learning with proper private networking controls

### Steps

1. Create new (or use existing) resource group(s)

```bash
az group create --name <new-rg-name> --location <your-selected-region>
```


2. Create virtual network and the subnet in an independent resource group:

```bash
az deployment group create --resource-group <new-rg-name-vnet> --template-file vnet.bicep
```

3. Deploy the foundry.bicep infrastructure as code:

```bash
az deployment group create --resource-group <new-rg-name> --template-file foundry-basic.bicep --parameters vnetRgName="<new-rg-name-vnet>"
```
