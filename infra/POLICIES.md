# Azure Policy Governance for AI Resources

This document describes the Azure Policy controls implemented to govern Azure Machine Learning and AI Foundry (Cognitive Services) resources.

## Overview

The AI governance policies enforce security and compliance standards across your AI infrastructure. Policies are organized into five control categories:

| Category | Description | Policies |
|----------|-------------|----------|
| **Network Security** | Ensure private connectivity and network isolation | 4 |
| **Identity Management** | Enforce Azure AD authentication, disable local auth | 2 |
| **Data Protection** | Require customer-managed key encryption | 2 |
| **Model Governance** | Control which AI models can be deployed | 2 |
| **Logging & Monitoring** | Ensure diagnostic logging is enabled | 1 |

---

## Policy Controls

### Network Security

| Policy | Description | Effect | Built-in ID |
|--------|-------------|--------|-------------|
| **Azure ML Workspaces should disable public network access** | Ensures ML workspaces are not exposed on the public internet | Audit/Deny | `438c38d2-3772-465a-a9cc-7a6666a275ce` |
| **Azure ML Workspaces should use private link** | Requires private endpoint connections for ML workspaces | Audit/Deny | `45e05259-1eb5-4f70-9574-baf73e9d219b` |
| **Azure ML Computes should be in a virtual network** | Ensures compute resources are deployed within a VNet | Audit/Deny | `7804b5c7-01dc-4723-969b-ae300cc07ff1` |
| **Azure AI Services should restrict network access** | Requires network rules to limit access to AI Services | Audit/Deny | `037eea7a-bd0a-46c5-9a66-03aea78705d3` |

**Why it matters:** Network isolation prevents unauthorized access and data exfiltration. Private endpoints ensure traffic stays within your virtual network.

---

### Identity Management

| Policy | Description | Effect | Built-in ID |
|--------|-------------|--------|-------------|
| **Azure ML Computes should have local authentication disabled** | Requires Azure AD for ML compute authentication | Audit/Deny | `e96a9a5f-07ca-471b-9bc5-6a0f33cbd68f` |
| **Azure AI Services should have key access disabled** | Disables API key authentication, requiring Entra ID | Audit/Deny | `71ef260a-8f18-47b7-abcb-62d0673d94dc` |

**Why it matters:** Azure AD/Entra ID provides centralized identity management, conditional access, MFA, and audit trails. API keys are shared secrets that are harder to manage and rotate.

> ⚠️ **Note:** Disabling local auth on AI Services will prevent Azure OpenAI Studio from working in development mode. Consider using `Audit` in dev/test environments.

---

### Data Protection

| Policy | Description | Effect | Built-in ID |
|--------|-------------|--------|-------------|
| **Azure ML Workspaces should be encrypted with CMK** | Requires customer-managed keys for workspace encryption | Audit/Deny | `ba769a63-b8cc-4b2d-abf6-ac33c7204be8` |
| **Azure AI Services should encrypt data at rest with CMK** | Requires customer-managed keys for AI Services encryption | Audit/Deny | `67121cc7-ff39-4ab8-b7e3-95b84dab487d` |

**Why it matters:** Customer-managed keys (CMK) provide full control over encryption key lifecycle, including rotation and revocation. Required for many regulatory compliance standards.

> ℹ️ **Note:** CMK encryption requires Azure Key Vault setup and is typically only required for production workloads with specific compliance requirements. Disabled by default.

---

### Model Governance

| Policy | Description | Effect | Built-in ID |
|--------|-------------|--------|-------------|
| **Azure ML Deployments should only use approved Registry Models** | Restricts ML model deployments to an approved list | Audit/Deny | `12e5dd16-d201-47ff-849b-8454061c293d` |
| **Cognitive Services Deployments should only use approved Registry Models** | Restricts AI Services model deployments to an approved list | Audit/Deny | `aafe3651-cb78-4f68-9f81-e7e41509110f` |

**Why it matters:** Model governance ensures only vetted and approved AI models are deployed, preventing use of untested or potentially harmful models.

**Example allowed models:**
```
azureml://registries/azure-openai/models/gpt-4o/versions/1
azureml://registries/azure-openai/models/gpt-35-turbo/versions/3
azureml://registries/azure-openai/models/text-embedding-ada-002/versions/2
```

> ℹ️ **Note:** Model governance is disabled by default. Enable when you need to restrict which models can be deployed in your organization.

---

### Logging & Monitoring

| Policy | Description | Effect | Built-in ID |
|--------|-------------|--------|-------------|
| **Diagnostic logs in Azure AI services should be enabled** | Audits AI Services for diagnostic logging configuration | AuditIfNotExists | `1b4d1c4e-934c-4703-944c-27c82c06bebb` |

**Why it matters:** Diagnostic logs are essential for security investigations, troubleshooting, and compliance auditing.

---

## Deployment

### Deploy to Subscription

```bash
# Deploy with default settings (Audit mode)
az deployment sub create \
  --location canadaeast \
  --template-file ai-governance.bicep \
  --parameters ai-governance.bicepparam

# Deploy with specific environment
az deployment sub create \
  --location canadaeast \
  --template-file ai-governance.bicep \
  --parameters ai-governance.bicepparam \
  --parameters environment=prod
```

### View Compliance Status

```bash
# Summary of policy compliance
az policy state summarize --policy-set-definition ai-governance-dev

# List non-compliant resources
az policy state list \
  --policy-set-definition ai-governance-dev \
  --filter "complianceState eq 'NonCompliant'"
```

---

## Configuration

### Policy Effects

Configure policy effects in `ai-governance.bicepparam`:

| Effect | Behavior | Recommended For |
|--------|----------|-----------------|
| `Audit` | Report non-compliance without blocking | Dev/Test environments |
| `Deny` | Block non-compliant deployments | Production environments |
| `Disabled` | Turn off the policy | Policies not applicable |

### Environment-Specific Settings

| Parameter | Dev/Test | Production |
|-----------|----------|------------|
| `networkPolicyEffect` | Audit | Deny |
| `authPolicyEffect` | Audit | Deny |
| `cmkPolicyEffect` | Disabled | Audit or Deny |
| `modelGovernanceEffect` | Disabled | Audit or Deny |
| `enforcementMode` | DoNotEnforce | Default (Enforce) |

### Enforcement Mode

The deployment automatically sets enforcement mode based on environment:
- **dev/test**: `DoNotEnforce` - Policies are evaluated but not enforced
- **prod**: `Default` - Policies are fully enforced

---

## Files

| File | Description |
|------|-------------|
| `ai-governance.bicep` | Main deployment file (subscription scope) |
| `ai-governance.bicepparam` | Parameters file for customization |
| `modules/ai-policy-initiative.bicep` | Policy initiative (policy set) definition |
| `modules/ai-policies.bicep` | Individual policy assignments (resource group scope) |

---

## Compliance Mapping

These policies align with common compliance frameworks:

| Framework | Controls Addressed |
|-----------|-------------------|
| **Microsoft Cloud Security Benchmark** | NS-2 (Network Security), IM-1 (Identity Management), DP-5 (Data Protection) |
| **NIST 800-53** | AC-3 (Access Enforcement), SC-7 (Boundary Protection), SC-28 (Data at Rest) |
| **ISO 27001** | A.9 (Access Control), A.13 (Communications Security), A.10 (Cryptography) |
| **SOC 2** | CC6.1 (Logical Access), CC6.6 (System Boundaries), CC6.7 (Data Transmission) |

---

## References

- [Azure Policy built-in definitions for Azure Machine Learning](https://learn.microsoft.com/azure/machine-learning/policy-reference)
- [Azure Policy built-in definitions for Azure AI Services](https://learn.microsoft.com/azure/ai-services/policy-reference)
- [Azure Policy regulatory compliance](https://learn.microsoft.com/azure/governance/policy/concepts/regulatory-compliance)
- [Microsoft cloud security benchmark](https://learn.microsoft.com/security/benchmark/azure/introduction)
