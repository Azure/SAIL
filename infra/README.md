## Infrastructure as code to deploy Microsoft Foundry and Azure Machine Learning with proper private networking controls

### Initial set-up for resource-group(s) and virtual network

Create new (or use existing) resource group(s)

```bash
az group create --name <new-rg-name> --location <your-selected-region>
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
