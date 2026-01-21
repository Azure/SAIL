/*
  AI Governance Policies Deployment
  
  This file deploys the AI governance policy initiative to a subscription
  and assigns it to the specified scope (subscription or resource group).
  
  Usage:
    # Deploy initiative at subscription level
    az deployment sub create --location <location> --template-file ai-governance.bicep --parameters ai-governance.bicepparam
    
    # Or with PowerShell
    New-AzSubscriptionDeployment -Location <location> -TemplateFile ai-governance.bicep -TemplateParameterFile ai-governance.bicepparam
*/

targetScope = 'subscription'

// ============================================================================
// PARAMETERS
// ============================================================================

@description('Location for policy assignment resources')
param location string

@description('Environment name for naming resources')
@allowed(['dev', 'test', 'prod'])
param environment string = 'dev'

// Policy Effect Parameters
@description('Effect for network security policies')
@allowed(['Audit', 'Deny', 'Disabled'])
param networkPolicyEffect string = 'Audit'

@description('Effect for authentication policies')
@allowed(['Audit', 'Deny', 'Disabled'])
param authPolicyEffect string = 'Audit'

@description('Effect for CMK encryption policies')
@allowed(['Audit', 'Deny', 'Disabled'])
param cmkPolicyEffect string = 'Disabled'

@description('Effect for model governance policies')
@allowed(['Audit', 'Deny', 'Disabled'])
param modelGovernanceEffect string = 'Disabled'

// Model Governance Parameters
@description('List of allowed AI model asset IDs')
param allowedAssetIds array = []

// ============================================================================
// VARIABLES
// ============================================================================

var initiativeName = 'ai-governance-${environment}'
var assignmentName = 'ai-governance-assignment-${environment}'

// ============================================================================
// POLICY INITIATIVE
// ============================================================================

module policyInitiative 'modules/ai-policy-initiative.bicep' = {
  name: 'deploy-ai-policy-initiative'
  params: {
    initiativeName: initiativeName
    initiativeDisplayName: 'AI Resources Governance - ${toUpper(environment)}'
    initiativeDescription: 'Enforces security and compliance policies for Azure ML and AI Foundry resources in ${environment} environment.'
    category: 'AI Governance'
  }
}

// ============================================================================
// POLICY ASSIGNMENT
// ============================================================================

resource policyAssignment 'Microsoft.Authorization/policyAssignments@2025-01-01' = {
  name: assignmentName
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    displayName: 'AI Governance Policies - ${toUpper(environment)}'
    description: 'Assignment of AI governance initiative for ${environment} environment'
    policyDefinitionId: policyInitiative.outputs.initiativeId
    enforcementMode: environment == 'prod' ? 'Default' : 'DoNotEnforce'
    parameters: {
      networkPolicyEffect: {
        value: networkPolicyEffect
      }
      authPolicyEffect: {
        value: authPolicyEffect
      }
      cmkPolicyEffect: {
        value: cmkPolicyEffect
      }
      modelGovernanceEffect: {
        value: modelGovernanceEffect
      }
      allowedAssetIds: {
        value: allowedAssetIds
      }
    }
    nonComplianceMessages: [
      {
        message: 'This resource violates AI governance policies. Please review the policy requirements and update your configuration.'
      }
      {
        policyDefinitionReferenceId: 'amlDisablePublicAccess'
        message: 'Azure Machine Learning workspaces must have public network access disabled.'
      }
      {
        policyDefinitionReferenceId: 'aiServicesRestrictNetwork'
        message: 'Azure AI Services must have network access restricted.'
      }
      {
        policyDefinitionReferenceId: 'amlDisableLocalAuth'
        message: 'Azure Machine Learning resources must use Azure AD authentication only.'
      }
      {
        policyDefinitionReferenceId: 'aiServicesDisableLocalAuth'
        message: 'Azure AI Services must use Azure AD authentication only. Key-based auth is not allowed.'
      }
    ]
  }
}

// ============================================================================
// OUTPUTS
// ============================================================================

@description('The ID of the policy initiative')
output initiativeId string = policyInitiative.outputs.initiativeId

@description('The ID of the policy assignment')
output assignmentId string = policyAssignment.id

@description('The principal ID of the policy assignment managed identity')
output assignmentPrincipalId string = policyAssignment.identity.principalId

@description('Summary of policy configuration')
output policyConfiguration object = {
  environment: environment
  enforcementMode: environment == 'prod' ? 'Enforcing' : 'AuditOnly'
  networkPolicies: networkPolicyEffect
  authPolicies: authPolicyEffect
  cmkPolicies: cmkPolicyEffect
  modelGovernance: modelGovernanceEffect
  scope: 'Subscription'
}
