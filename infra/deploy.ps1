#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Deploys SAIL infrastructure to Azure

.DESCRIPTION
    This script deploys the SAIL infrastructure including:
    - Virtual Network (optional, if it doesn't exist)
    - Azure Machine Learning workspace with dependencies
    - Microsoft Foundry (Azure AI Services) with GPT-4o deployment

.PARAMETER ConfigFile
    Path to the configuration JSON file. Default: config.json

.PARAMETER SkipVNetDeployment
    Skip VNet deployment if it already exists

.PARAMETER DeploymentType
    Type of deployment: 'all', 'vnet', 'aml', 'foundry'

.PARAMETER SubscriptionId
    Azure subscription ID (optional, will use current subscription if not specified)

.EXAMPLE
    .\deploy.ps1 -ConfigFile .\config.json -DeploymentType all

.EXAMPLE
    .\deploy.ps1 -ConfigFile .\config.prod.json -SkipVNetDeployment -DeploymentType aml
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$false)]
    [string]$ConfigFile = "config.json",
    
    [Parameter(Mandatory=$false)]
    [switch]$SkipVNetDeployment,
    
    [Parameter(Mandatory=$false)]
    [ValidateSet('all', 'vnet', 'aml', 'foundry')]
    [string]$DeploymentType = 'all',
    
    [Parameter(Mandatory=$false)]
    [string]$SubscriptionId
)

# Set error action preference
$ErrorActionPreference = "Stop"

# Function to write colored output
function Write-Status {
    param(
        [string]$Message,
        [string]$Type = "Info"
    )
    
    switch ($Type) {
        "Info"    { Write-Host "[INFO] $Message" -ForegroundColor Cyan }
        "Success" { Write-Host "[SUCCESS] $Message" -ForegroundColor Green }
        "Warning" { Write-Host "[WARNING] $Message" -ForegroundColor Yellow }
        "Error"   { Write-Host "[ERROR] $Message" -ForegroundColor Red }
    }
}

# Function to check if Azure CLI is installed
function Test-AzureCLI {
    try {
        $null = az version
        return $true
    }
    catch {
        return $false
    }
}

# Main deployment function
function Start-Deployment {
    Write-Status "Starting SAIL infrastructure deployment..." "Info"
    
    # Check if Azure CLI is installed
    if (-not (Test-AzureCLI)) {
        Write-Status "Azure CLI is not installed. Please install it from https://docs.microsoft.com/cli/azure/install-azure-cli" "Error"
        exit 1
    }
    
    # Check if config file exists
    if (-not (Test-Path $ConfigFile)) {
        Write-Status "Configuration file '$ConfigFile' not found." "Error"
        exit 1
    }
    
    # Load configuration
    Write-Status "Loading configuration from $ConfigFile..." "Info"
    $config = Get-Content $ConfigFile | ConvertFrom-Json
    
    # Set subscription if specified
    if ($SubscriptionId) {
        Write-Status "Setting Azure subscription to $SubscriptionId..." "Info"
        az account set --subscription $SubscriptionId
    }
    
    # Get current subscription
    $currentSub = az account show | ConvertFrom-Json
    Write-Status "Using subscription: $($currentSub.name) ($($currentSub.id))" "Info"
    
    # Create resource groups
    Write-Status "Creating resource groups..." "Info"
    
    Write-Status "Creating VNet resource group: $($config.vnetResourceGroup)" "Info"
    az group create --name $config.vnetResourceGroup --location $config.location --output none
    
    Write-Status "Creating main resource group: $($config.resourceGroup)" "Info"
    az group create --name $config.resourceGroup --location $config.location --output none
    
    Write-Status "Resource groups created successfully" "Success"
    
    # Deploy VNet
    if (-not $SkipVNetDeployment -and ($DeploymentType -eq 'all' -or $DeploymentType -eq 'vnet')) {
        Write-Status "Deploying Virtual Network..." "Info"
        
        $vnetDeploymentName = "vnet-deployment-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
        
        az deployment group create `
            --name $vnetDeploymentName `
            --resource-group $config.vnetResourceGroup `
            --template-file vnet.bicep `
            --parameters vnet.parameters.json `
            --output none
        
        if ($LASTEXITCODE -eq 0) {
            Write-Status "Virtual Network deployed successfully" "Success"
        } else {
            Write-Status "Virtual Network deployment failed" "Error"
            exit 1
        }
    }
    
    # Deploy Azure Machine Learning
    if ($DeploymentType -eq 'all' -or $DeploymentType -eq 'aml') {
        Write-Status "Deploying Azure Machine Learning workspace..." "Info"
        
        $amlDeploymentName = "aml-deployment-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
        
        az deployment group create `
            --name $amlDeploymentName `
            --resource-group $config.resourceGroup `
            --template-file aml.bicep `
            --parameters vnetName=$($config.vnetName) `
            --parameters vnetRgName=$($config.vnetResourceGroup) `
            --parameters subnetName=$($config.subnetName) `
            --parameters location=$($config.location) `
            --parameters amlName=$($config.amlName) `
            --parameters amlFriendlyName="$($config.amlFriendlyName)" `
            --parameters amlDescription="$($config.amlDescription)" `
            --parameters prefix=$($config.prefix) `
            --parameters createPrivateDnsZones=$($config.createPrivateDnsZones) `
            --output none
        
        if ($LASTEXITCODE -eq 0) {
            Write-Status "Azure Machine Learning workspace deployed successfully" "Success"
        } else {
            Write-Status "Azure Machine Learning deployment failed" "Error"
            exit 1
        }
    }
    
    # Deploy Microsoft Foundry
    if ($DeploymentType -eq 'all' -or $DeploymentType -eq 'foundry') {
        Write-Status "Deploying Microsoft Foundry (Azure AI Services)..." "Info"
        
        $foundryDeploymentName = "foundry-deployment-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
        
        az deployment group create `
            --name $foundryDeploymentName `
            --resource-group $config.resourceGroup `
            --template-file foundry-basic.bicep `
            --parameters aiFoundryName=$($config.foundryName) `
            --parameters location=$($config.foundryLocation) `
            --parameters defaultProjectName=$($config.foundryProjectName) `
            --parameters vnetName=$($config.vnetName) `
            --parameters peSubnetName=$($config.subnetName) `
            --parameters vnetRgName=$($config.vnetResourceGroup) `
            --parameters createPrivateDnsZones=$($config.createPrivateDnsZones) `
            --output none
        
        if ($LASTEXITCODE -eq 0) {
            Write-Status "Microsoft Foundry deployed successfully" "Success"
        } else {
            Write-Status "Microsoft Foundry deployment failed" "Error"
            exit 1
        }
    }
    
    Write-Status "Deployment completed successfully!" "Success"
    Write-Status "Resource Group: $($config.resourceGroup)" "Info"
    Write-Status "VNet Resource Group: $($config.vnetResourceGroup)" "Info"
}

# Execute deployment
try {
    Start-Deployment
}
catch {
    Write-Status "Deployment failed with error: $_" "Error"
    exit 1
}
