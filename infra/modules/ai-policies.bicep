/*
  Azure Policy Assignments for AI Resource Governance
  
  This module creates policy assignments to enforce security and compliance
  for Azure Machine Learning and AI Foundry resources.
  
  Policies included:
  - Network security (private endpoints, public access)
  - Authentication (disable local auth, require Entra ID)
  - Data protection (encryption with CMK)
  - Model governance (allowed models)
  - Diagnostic logging
*/

// Parameters
@description('The effect for audit policies. Use Audit for visibility, Deny for enforcement.')
@allowed(['Audit', 'Deny', 'Disabled'])
param auditOrDenyEffect string = 'Audit'

@description('Whether to enforce CMK encryption on AI resources.')
param enforceCMKEncryption bool = false

@description('Whether to enforce private endpoints (strict network isolation).')
param enforcePrivateEndpoints bool = true

@description('Whether to restrict AI model deployments to approved models.')
param restrictModelDeployments bool = false

@description('List of allowed model asset IDs for AI deployments.')
param allowedModelAssetIds array = []

@description('Location for policy assignment resources.')
param location string = resourceGroup().location

// Built-in Policy Definition IDs
var policyDefinitions = {
  // Azure Machine Learning policies
  amlDisablePublicAccess: '/providers/Microsoft.Authorization/policyDefinitions/438c38d2-3772-465a-a9cc-7a6666a275ce'
  amlRequirePrivateLink: '/providers/Microsoft.Authorization/policyDefinitions/45e05259-1eb5-4f70-9574-baf73e9d219b'
  amlDisableLocalAuth: '/providers/Microsoft.Authorization/policyDefinitions/e96a9a5f-07ca-471b-9bc5-6a0f33cbd68f'
  amlRequireCMK: '/providers/Microsoft.Authorization/policyDefinitions/ba769a63-b8cc-4b2d-abf6-ac33c7204be8'
  amlRequireVnet: '/providers/Microsoft.Authorization/policyDefinitions/7804b5c7-01dc-4723-969b-ae300cc07ff1'
  
  // Azure AI Services / Cognitive Services / AI Foundry policies
  aiServicesDisableLocalAuth: '/providers/Microsoft.Authorization/policyDefinitions/71ef260a-8f18-47b7-abcb-62d0673d94dc'
  aiServicesRestrictNetwork: '/providers/Microsoft.Authorization/policyDefinitions/037eea7a-bd0a-46c5-9a66-03aea78705d3'
  aiServicesRequireCMK: '/providers/Microsoft.Authorization/policyDefinitions/67121cc7-ff39-4ab8-b7e3-95b84dab487d'
  aiServicesEnableDiagnostics: '/providers/Microsoft.Authorization/policyDefinitions/1b4d1c4e-934c-4703-944c-27c82c06bebb'
  
  // Configure policies (DINE)
  configureAiServicesDisableLocalAuth: '/providers/Microsoft.Authorization/policyDefinitions/55eff01b-f2bd-4c32-9203-db285f709d30'
  configureCognitiveServicesDisablePublicAccess: '/providers/Microsoft.Authorization/policyDefinitions/47ba1dd7-28d9-4b07-a8d5-9813bed64e0c'
  
  // Model governance
  amlAllowedModels: '/providers/Microsoft.Authorization/policyDefinitions/12e5dd16-d201-47ff-849b-8454061c293d'
  cognitiveServicesAllowedModels: '/providers/Microsoft.Authorization/policyDefinitions/aafe3651-cb78-4f68-9f81-e7e41509110f'
}

// ============================================================================
// NETWORK SECURITY POLICIES
// ============================================================================

// Policy: Azure ML Workspaces should disable public network access
resource amlDisablePublicAccessAssignment 'Microsoft.Authorization/policyAssignments@2024-04-01' = if (enforcePrivateEndpoints) {
  name: 'aml-disable-public-access'
  location: location
  properties: {
    displayName: 'Azure ML Workspaces should disable public network access'
    description: 'Disabling public network access improves security by ensuring workspaces are not exposed on the public internet.'
    policyDefinitionId: policyDefinitions.amlDisablePublicAccess
    parameters: {
      effect: {
        value: auditOrDenyEffect
      }
    }
    nonComplianceMessages: [
      {
        message: 'Azure Machine Learning workspaces must have public network access disabled. Use private endpoints for connectivity.'
      }
    ]
  }
}

// Policy: Azure ML Workspaces should use private link
resource amlRequirePrivateLinkAssignment 'Microsoft.Authorization/policyAssignments@2024-04-01' = if (enforcePrivateEndpoints) {
  name: 'aml-require-private-link'
  location: location
  properties: {
    displayName: 'Azure ML Workspaces should use private link'
    description: 'Ensure Azure Machine Learning workspaces are connected via private endpoints.'
    policyDefinitionId: policyDefinitions.amlRequirePrivateLink
    parameters: {
      effect: {
        value: auditOrDenyEffect
      }
    }
    nonComplianceMessages: [
      {
        message: 'Azure Machine Learning workspaces must be configured with private link connections.'
      }
    ]
  }
}

// Policy: Azure AI Services resources should restrict network access
resource aiServicesRestrictNetworkAssignment 'Microsoft.Authorization/policyAssignments@2024-04-01' = if (enforcePrivateEndpoints) {
  name: 'ai-services-restrict-network'
  location: location
  properties: {
    displayName: 'Azure AI Services resources should restrict network access'
    description: 'Restrict network access to AI Services by configuring network rules.'
    policyDefinitionId: policyDefinitions.aiServicesRestrictNetwork
    parameters: {
      effect: {
        value: auditOrDenyEffect
      }
    }
    nonComplianceMessages: [
      {
        message: 'Azure AI Services resources must have network access restricted to allowed networks only.'
      }
    ]
  }
}

// Policy: Azure ML Computes should be in a virtual network
resource amlRequireVnetAssignment 'Microsoft.Authorization/policyAssignments@2024-04-01' = if (enforcePrivateEndpoints) {
  name: 'aml-require-vnet'
  location: location
  properties: {
    displayName: 'Azure ML Computes should be in a virtual network'
    description: 'Ensure Azure Machine Learning compute resources are deployed within a virtual network.'
    policyDefinitionId: policyDefinitions.amlRequireVnet
    parameters: {
      effect: {
        value: auditOrDenyEffect
      }
    }
    nonComplianceMessages: [
      {
        message: 'Azure Machine Learning compute resources must be deployed within a virtual network.'
      }
    ]
  }
}

// ============================================================================
// AUTHENTICATION POLICIES
// ============================================================================

// Policy: Azure ML Computes should have local authentication disabled
resource amlDisableLocalAuthAssignment 'Microsoft.Authorization/policyAssignments@2024-04-01' = {
  name: 'aml-disable-local-auth'
  location: location
  properties: {
    displayName: 'Azure ML Computes should have local authentication disabled'
    description: 'Disabling local authentication improves security by ensuring ML Computes require Azure AD identities exclusively.'
    policyDefinitionId: policyDefinitions.amlDisableLocalAuth
    parameters: {
      effect: {
        value: auditOrDenyEffect
      }
    }
    nonComplianceMessages: [
      {
        message: 'Azure Machine Learning compute resources must use Azure AD authentication. Local authentication is not allowed.'
      }
    ]
  }
}

// Policy: Azure AI Services should have key access disabled (disable local auth)
resource aiServicesDisableLocalAuthAssignment 'Microsoft.Authorization/policyAssignments@2024-04-01' = {
  name: 'ai-services-disable-local-auth'
  location: location
  properties: {
    displayName: 'Azure AI Services should have key access disabled'
    description: 'Key access (local authentication) should be disabled. Microsoft Entra ID becomes the only access method.'
    policyDefinitionId: policyDefinitions.aiServicesDisableLocalAuth
    parameters: {
      effect: {
        value: auditOrDenyEffect
      }
    }
    nonComplianceMessages: [
      {
        message: 'Azure AI Services resources must disable key-based authentication. Use Microsoft Entra ID for authentication.'
      }
    ]
  }
}

// ============================================================================
// DATA PROTECTION POLICIES (CMK Encryption)
// ============================================================================

// Policy: Azure ML Workspaces should be encrypted with CMK
resource amlRequireCMKAssignment 'Microsoft.Authorization/policyAssignments@2024-04-01' = if (enforceCMKEncryption) {
  name: 'aml-require-cmk'
  location: location
  properties: {
    displayName: 'Azure ML Workspaces should be encrypted with customer-managed key'
    description: 'Manage encryption at rest of Azure Machine Learning workspace data with customer-managed keys.'
    policyDefinitionId: policyDefinitions.amlRequireCMK
    parameters: {
      effect: {
        value: auditOrDenyEffect
      }
    }
    nonComplianceMessages: [
      {
        message: 'Azure Machine Learning workspaces must be encrypted with a customer-managed key (CMK).'
      }
    ]
  }
}

// Policy: Azure AI Services should encrypt data at rest with CMK
resource aiServicesRequireCMKAssignment 'Microsoft.Authorization/policyAssignments@2024-04-01' = if (enforceCMKEncryption) {
  name: 'ai-services-require-cmk'
  location: location
  properties: {
    displayName: 'Azure AI Services should encrypt data at rest with CMK'
    description: 'Using customer-managed keys to encrypt data at rest provides more control over the key lifecycle.'
    policyDefinitionId: policyDefinitions.aiServicesRequireCMK
    parameters: {
      effect: {
        value: auditOrDenyEffect
      }
    }
    nonComplianceMessages: [
      {
        message: 'Azure AI Services resources must be encrypted with a customer-managed key (CMK).'
      }
    ]
  }
}

// ============================================================================
// MODEL GOVERNANCE POLICIES
// ============================================================================

// Policy: Azure ML Deployments should only use approved Registry Models
resource amlAllowedModelsAssignment 'Microsoft.Authorization/policyAssignments@2024-04-01' = if (restrictModelDeployments && length(allowedModelAssetIds) > 0) {
  name: 'aml-allowed-models'
  location: location
  properties: {
    displayName: 'Azure ML Deployments should only use approved Registry Models'
    description: 'Restrict the deployment of Registry models to control externally created models used within your organization.'
    policyDefinitionId: policyDefinitions.amlAllowedModels
    parameters: {
      effect: {
        value: auditOrDenyEffect
      }
      allowedAssetIds: {
        value: allowedModelAssetIds
      }
    }
    nonComplianceMessages: [
      {
        message: 'Only approved AI models from the allowed list can be deployed. Contact your administrator for model approval.'
      }
    ]
  }
}

// Policy: Cognitive Services Deployments should only use approved Registry Models
resource cognitiveServicesAllowedModelsAssignment 'Microsoft.Authorization/policyAssignments@2024-04-01' = if (restrictModelDeployments && length(allowedModelAssetIds) > 0) {
  name: 'cognitive-allowed-models'
  location: location
  properties: {
    displayName: 'Cognitive Services Deployments should only use approved Registry Models'
    description: 'Restrict the deployment of Registry models to control externally created models used within your organization.'
    policyDefinitionId: policyDefinitions.cognitiveServicesAllowedModels
    parameters: {
      effect: {
        value: auditOrDenyEffect
      }
      allowedAssetIds: {
        value: allowedModelAssetIds
      }
    }
    nonComplianceMessages: [
      {
        message: 'Only approved AI models from the allowed list can be deployed. Contact your administrator for model approval.'
      }
    ]
  }
}

// ============================================================================
// DIAGNOSTIC LOGGING POLICIES
// ============================================================================

// Policy: Diagnostic logs in Azure AI services should be enabled
resource aiServicesEnableDiagnosticsAssignment 'Microsoft.Authorization/policyAssignments@2024-04-01' = {
  name: 'ai-services-enable-diagnostics'
  location: location
  properties: {
    displayName: 'Diagnostic logs in Azure AI services should be enabled'
    description: 'Enable logs for Azure AI services resources for investigation purposes when a security incident occurs.'
    policyDefinitionId: policyDefinitions.aiServicesEnableDiagnostics
    parameters: {
      effect: {
        value: 'AuditIfNotExists'
      }
    }
    nonComplianceMessages: [
      {
        message: 'Azure AI Services resources must have diagnostic logging enabled.'
      }
    ]
  }
}

// ============================================================================
// OUTPUTS
// ============================================================================

@description('Array of policy assignment IDs created')
output policyAssignmentIds array = [
  amlDisableLocalAuthAssignment.id
  aiServicesDisableLocalAuthAssignment.id
  aiServicesEnableDiagnosticsAssignment.id
]

@description('Summary of policies applied')
output policySummary object = {
  networkSecurityPolicies: enforcePrivateEndpoints ? 4 : 0
  authenticationPolicies: 2
  dataProtectionPolicies: enforceCMKEncryption ? 2 : 0
  modelGovernancePolicies: restrictModelDeployments && length(allowedModelAssetIds) > 0 ? 2 : 0
  diagnosticPolicies: 1
}
