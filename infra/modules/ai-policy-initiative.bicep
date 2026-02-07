/*
  Azure Policy Initiative (Policy Set) for AI Governance
  
  This module creates a custom policy initiative that groups all AI governance
  policies together for easier assignment and management.
  
  Deploy at subscription or management group scope.
*/

targetScope = 'subscription'

// Parameters
@description('Display name for the policy initiative')
param initiativeName string = 'AI-Governance-Initiative'

@description('Display name shown in Azure Portal')
param initiativeDisplayName string = 'AI Resources Governance Initiative'

@description('Description of the policy initiative')
param initiativeDescription string = 'This initiative enforces security and compliance policies for Azure Machine Learning and AI Foundry resources.'

@description('Category for organizing in Azure Portal')
param category string = 'AI Governance'

// Built-in Policy Definition IDs
var policyDefinitionIds = {
  // Network Security
  amlDisablePublicAccess: '/providers/Microsoft.Authorization/policyDefinitions/438c38d2-3772-465a-a9cc-7a6666a275ce'
  amlRequirePrivateLink: '/providers/Microsoft.Authorization/policyDefinitions/45e05259-1eb5-4f70-9574-baf73e9d219b'
  amlRequireVnet: '/providers/Microsoft.Authorization/policyDefinitions/7804b5c7-01dc-4723-969b-ae300cc07ff1'
  aiServicesRestrictNetwork: '/providers/Microsoft.Authorization/policyDefinitions/037eea7a-bd0a-46c5-9a66-03aea78705d3'
  
  // Authentication
  amlDisableLocalAuth: '/providers/Microsoft.Authorization/policyDefinitions/e96a9a5f-07ca-471b-9bc5-6a0f33cbd68f'
  aiServicesDisableLocalAuth: '/providers/Microsoft.Authorization/policyDefinitions/71ef260a-8f18-47b7-abcb-62d0673d94dc'
  
  // Data Protection
  amlRequireCMK: '/providers/Microsoft.Authorization/policyDefinitions/ba769a63-b8cc-4b2d-abf6-ac33c7204be8'
  aiServicesRequireCMK: '/providers/Microsoft.Authorization/policyDefinitions/67121cc7-ff39-4ab8-b7e3-95b84dab487d'
  
  // Model Governance
  amlAllowedModels: '/providers/Microsoft.Authorization/policyDefinitions/12e5dd16-d201-47ff-849b-8454061c293d'
  cognitiveServicesAllowedModels: '/providers/Microsoft.Authorization/policyDefinitions/aafe3651-cb78-4f68-9f81-e7e41509110f'
  
  // Diagnostics
  aiServicesEnableDiagnostics: '/providers/Microsoft.Authorization/policyDefinitions/1b4d1c4e-934c-4703-944c-27c82c06bebb'
}

// Policy Initiative Definition
resource aiGovernanceInitiative 'Microsoft.Authorization/policySetDefinitions@2025-01-01' = {
  name: initiativeName
  properties: {
    displayName: initiativeDisplayName
    description: initiativeDescription
    policyType: 'Custom'
    metadata: {
      category: category
      version: '1.0.0'
    }
    parameters: {
      // Effect parameters
      networkPolicyEffect: {
        type: 'String'
        metadata: {
          displayName: 'Effect for network policies'
          description: 'The effect for network security policies'
        }
        allowedValues: [
          'Audit'
          'Deny'
          'Disabled'
        ]
        defaultValue: 'Audit'
      }
      authPolicyEffect: {
        type: 'String'
        metadata: {
          displayName: 'Effect for authentication policies'
          description: 'The effect for authentication policies'
        }
        allowedValues: [
          'Audit'
          'Deny'
          'Disabled'
        ]
        defaultValue: 'Audit'
      }
      cmkPolicyEffect: {
        type: 'String'
        metadata: {
          displayName: 'Effect for CMK encryption policies'
          description: 'The effect for customer-managed key encryption policies'
        }
        allowedValues: [
          'Audit'
          'Deny'
          'Disabled'
        ]
        defaultValue: 'Disabled'
      }
      modelGovernanceEffect: {
        type: 'String'
        metadata: {
          displayName: 'Effect for model governance policies'
          description: 'The effect for AI model deployment governance policies'
        }
        allowedValues: [
          'Audit'
          'Deny'
          'Disabled'
        ]
        defaultValue: 'Disabled'
      }
      // Model governance parameters
      allowedAssetIds: {
        type: 'Array'
        metadata: {
          displayName: 'Allowed model asset IDs'
          description: 'List of allowed model asset IDs for deployments'
        }
        defaultValue: []
      }
    }
    policyDefinitions: [
      // ========== NETWORK SECURITY POLICIES ==========
      {
        policyDefinitionId: policyDefinitionIds.amlDisablePublicAccess
        policyDefinitionReferenceId: 'amlDisablePublicAccess'
        parameters: {
          effect: {
            value: '[parameters(\'networkPolicyEffect\')]'
          }
        }
        groupNames: [
          'NetworkSecurity'
        ]
      }
      {
        policyDefinitionId: policyDefinitionIds.amlRequirePrivateLink
        policyDefinitionReferenceId: 'amlRequirePrivateLink'
        parameters: {
          effect: {
            value: '[parameters(\'networkPolicyEffect\')]'
          }
        }
        groupNames: [
          'NetworkSecurity'
        ]
      }
      {
        policyDefinitionId: policyDefinitionIds.amlRequireVnet
        policyDefinitionReferenceId: 'amlRequireVnet'
        parameters: {
          effect: {
            value: '[parameters(\'networkPolicyEffect\')]'
          }
        }
        groupNames: [
          'NetworkSecurity'
        ]
      }
      {
        policyDefinitionId: policyDefinitionIds.aiServicesRestrictNetwork
        policyDefinitionReferenceId: 'aiServicesRestrictNetwork'
        parameters: {
          effect: {
            value: '[parameters(\'networkPolicyEffect\')]'
          }
        }
        groupNames: [
          'NetworkSecurity'
        ]
      }
      // ========== AUTHENTICATION POLICIES ==========
      {
        policyDefinitionId: policyDefinitionIds.amlDisableLocalAuth
        policyDefinitionReferenceId: 'amlDisableLocalAuth'
        parameters: {
          effect: {
            value: '[parameters(\'authPolicyEffect\')]'
          }
        }
        groupNames: [
          'IdentityManagement'
        ]
      }
      {
        policyDefinitionId: policyDefinitionIds.aiServicesDisableLocalAuth
        policyDefinitionReferenceId: 'aiServicesDisableLocalAuth'
        parameters: {
          effect: {
            value: '[parameters(\'authPolicyEffect\')]'
          }
        }
        groupNames: [
          'IdentityManagement'
        ]
      }
      // ========== DATA PROTECTION POLICIES ==========
      {
        policyDefinitionId: policyDefinitionIds.amlRequireCMK
        policyDefinitionReferenceId: 'amlRequireCMK'
        parameters: {
          effect: {
            value: '[parameters(\'cmkPolicyEffect\')]'
          }
        }
        groupNames: [
          'DataProtection'
        ]
      }
      {
        policyDefinitionId: policyDefinitionIds.aiServicesRequireCMK
        policyDefinitionReferenceId: 'aiServicesRequireCMK'
        parameters: {
          effect: {
            value: '[parameters(\'cmkPolicyEffect\')]'
          }
        }
        groupNames: [
          'DataProtection'
        ]
      }
      // ========== MODEL GOVERNANCE POLICIES ==========
      {
        policyDefinitionId: policyDefinitionIds.amlAllowedModels
        policyDefinitionReferenceId: 'amlAllowedModels'
        parameters: {
          effect: {
            value: '[parameters(\'modelGovernanceEffect\')]'
          }
          allowedAssetIds: {
            value: '[parameters(\'allowedAssetIds\')]'
          }
        }
        groupNames: [
          'ModelGovernance'
        ]
      }
      {
        policyDefinitionId: policyDefinitionIds.cognitiveServicesAllowedModels
        policyDefinitionReferenceId: 'cognitiveServicesAllowedModels'
        parameters: {
          effect: {
            value: '[parameters(\'modelGovernanceEffect\')]'
          }
          allowedAssetIds: {
            value: '[parameters(\'allowedAssetIds\')]'
          }
        }
        groupNames: [
          'ModelGovernance'
        ]
      }
      // ========== DIAGNOSTIC POLICIES ==========
      {
        policyDefinitionId: policyDefinitionIds.aiServicesEnableDiagnostics
        policyDefinitionReferenceId: 'aiServicesEnableDiagnostics'
        parameters: {
          effect: {
            value: 'AuditIfNotExists'
          }
        }
        groupNames: [
          'Logging'
        ]
      }
    ]
    policyDefinitionGroups: [
      {
        name: 'NetworkSecurity'
        displayName: 'Network Security'
        description: 'Policies to ensure AI resources are properly network isolated'
      }
      {
        name: 'IdentityManagement'
        displayName: 'Identity Management'
        description: 'Policies to enforce Azure AD authentication and disable local auth'
      }
      {
        name: 'DataProtection'
        displayName: 'Data Protection'
        description: 'Policies to ensure data encryption with customer-managed keys'
      }
      {
        name: 'ModelGovernance'
        displayName: 'Model Governance'
        description: 'Policies to control which AI models can be deployed'
      }
      {
        name: 'Logging'
        displayName: 'Logging & Monitoring'
        description: 'Policies to ensure proper diagnostic logging is enabled'
      }
    ]
  }
}

// Outputs
@description('The resource ID of the policy initiative')
output initiativeId string = aiGovernanceInitiative.id

@description('The name of the policy initiative')
output initiativeName string = aiGovernanceInitiative.name
