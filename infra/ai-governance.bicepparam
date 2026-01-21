/*
  AI Governance Policies Parameters
  
  Configure these parameters based on your environment and compliance requirements.
*/

using 'ai-governance.bicep'

// Deployment location
param location = 'canadaeast'

// Environment configuration
param environment = 'dev'

// =============================================================================
// POLICY EFFECTS
// =============================================================================
// Options: 'Audit' (report only), 'Deny' (block), 'Disabled' (off)
//
// Recommendation:
// - dev/test: Use 'Audit' to understand compliance without blocking deployments
// - prod: Use 'Deny' for critical security policies

// Network Security: Ensure private endpoints and VNet integration
param networkPolicyEffect = 'Audit'

// Authentication: Require Azure AD, disable local/key auth
param authPolicyEffect = 'Audit'

// Data Protection: Require customer-managed keys (CMK)
// Note: CMK requires additional Key Vault setup
param cmkPolicyEffect = 'Disabled'

// Model Governance: Restrict which AI models can be deployed
param modelGovernanceEffect = 'Disabled'

// =============================================================================
// MODEL GOVERNANCE CONFIGURATION
// =============================================================================
// Only used when modelGovernanceEffect is 'Audit' or 'Deny'

// Allowed model asset IDs - specific models that can be deployed
// Example: 'azureml://registries/azure-openai/models/gpt-4o/versions/1'
param allowedAssetIds = [
  // Uncomment and modify as needed:
  // 'azureml://registries/azure-openai/models/gpt-4o/versions/1'
  // 'azureml://registries/azure-openai/models/gpt-35-turbo/versions/3'
  // 'azureml://registries/azure-openai/models/text-embedding-ada-002/versions/2'
]
