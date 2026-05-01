
Deploying Azure Databricks AI for Canadian Data Residency

This document provides deployment guidance, configuration requirements, and a reference implementation for operating the Azure Databricks Data Intelligence Platform within only Canadian Azure regions. It is an Azure Databricks-focused companion to the Azure [Sovereign AI Landing Zone (SAIL)](https://github.com/Azure/SAIL) repository.

  

# 1. Platform Foundation - Shared Residency Controls

## 1.1 Core Concepts

Azure Databricks is the Microsoft Azure-native deployment of the Databricks Data Intelligence Platform, jointly engineered with Microsoft and offered as a first-party service that shows up directly in the Azure portal with consolidated billing. It integrates natively with the Azure stack: ADLS Gen2 for storage, Microsoft Entra ID for identity, Power BI and Microsoft Fabric for BI and downstream analytics, Azure Private Link and VNet injection for networking, Azure Key Vault for secrets, and Azure Monitor for observability. The platform runs Apache Spark, Delta Lake, Unity Catalog, MLflow, and Mosaic AI on serverless or classic compute, letting teams unify data engineering, SQL analytics, machine learning, and generative AI on one governed copy of their data.

  
  

Azure Databricks architecture consists of the control plane and the compute plane, each witha distinct residency posture. 

- Control plane: This is in the Microsoft-managed subscription and manages your deployment. It includes a web app, jobs, cluster management, and notebooks. It is fixed to a regional Azure Databricks instance at workspace creation. 
    
- Compute plane: The compute plane processes your data, and includes Azure Databricks runtime clusters and networking. The classic compute plane runs in your Azure subscription.. The serverless compute plane runs in the Microsoft-managed subscription and is scoped to the workspace region; no data leaves the Azure region.
    

  
  
  

Unity Catalog (UC) is the residency enforcement mechanism that sits across both planes. Every table, Volume, model, and function is addressed through Unity Catalog, and Unity Catalog privileges are the authoritative permission boundary. This is what allows a single set of residency controls to apply uniformly across data engineering, warehousing, and AI workloads.

  

## 1.2 Region Selection

Azure Databricks is offered in both Azure Canada regions: Canada Central and Canada East. Most features are available in each region, as noted in the [supported regions matrix](https://learn.microsoft.com/en-us/azure/databricks/resources/supported-regions).   A workspace's region is fixed at creation and cannot be migrated. Plan the region selection before provisioning.

  

CLI - create a workspace in Canada Central

```
az databricks workspace create \
  --name <workspace> --resource-group <rg> \
  --location canadacentral --sku premium
```
  

CLI - create a workspace in Canada East

```
az databricks workspace create \

  --name <workspace> --resource-group <rg> \

  --location canadaeast --sku premium
```
  

CLI - verify region

```
az databricks workspace show -n <workspace> -g <rg> --query location
```
  

## 1.3 Data Residency Controls

This section consolidates the residency controls that apply to every workload on the platform, covering data at rest and data in transit across both the classic and serverless compute planes.

Data at rest. Every storage surface that a Databricks workspace touches must be provisioned in a Canadian region. The surfaces are: the workspace root (DBFS root), created at workspace provisioning automatically; the Unity Catalog metastore, of which exactly one exists per region; Unity Catalog managed storage, which can be assigned at the metastore, catalog, or schema level; external locations backing external tables and Volumes; MLflow artifacts, which inherit residency from their Unity Catalog registered model; and Azure Key Vault for customer-managed keys applied to the DBFS root, managed services, and managed disks.

  

CLI - create UC metastore, storage credential, external location, and catalog

```
databricks storage-credentials create --json '{
  "name": "canada-managed-id",
  "azure_managed_identity": {"access_connector_id": "<access-connector-resource-id>"}
}'
```
  

```
databricks metastores create --json '{

  "name": "canada-central-metastore",

  "region": "canadacentral",

  "storage_root": "abfss://uc-root@<storage>.dfs.core.windows.net/"

}'
```
  

```
databricks catalogs create --json '{

  "name": "sovereign_ca",

  "storage_root": "abfss://catalog-root@<storage>.dfs.core.windows.net/"

}'
```

  

CLI - create an IP access list and inspect classic network posture

  

```
databricks ip-access-lists create --json '{

  "label": "corp-egress",

  "list_type": "ALLOW",

  "ip_addresses": ["203.0.113.0/24"]

}'
```
  

```
az databricks workspace show -n <workspace> -g <rg> \

  --query '{vnet:parameters.customVirtualNetworkId.value, noPublicIP:parameters.enableNoPublicIp.value}'

```
  

## 1.4 Identity and Access

Identity provisioning into the Databricks account has two supported paths and the choice affects operational overhead rather than residency posture. SCIM provisioning from Entra ID is configured in Entra, groups are mapped, and users and groups are synchronized to the Databricks account on a schedule. Automatic Identity Management (AIM) is the newer alternative: users and groups are resolved on demand from the Entra tenant without requiring a pre-configured SCIM job, reducing standing identity configuration and simplifying large or dynamic user populations. Both paths respect the tenant boundary.

For service-to-service authentication from Databricks compute into Azure storage, the recommended credential is an Azure Managed Identity attached to the Access Connector for Azure Databricks. Unity Catalog privileges are the residency-aligned permission boundary across all workloads.

  

CLI - create a service principal and grant catalog access

```
databricks service-principals create --json '{

  "display_name": "etl-sp",

  "application_id": "<entra-app-id>"

}'

```
```
databricks grants update CATALOG sovereign_ca --json '{

  "changes": [{

    "principal": "<entra-app-id>",

    "add": ["USE_CATALOG", "USE_SCHEMA", "SELECT"]

  }]

}'

```
  

CLI - enable Automatic Identity Management (account-level; verify command name against installed CLI version)

  

```
databricks account settings update-automatic-identity-management --json '{

  "setting": {"enabled": true}

}'
```

  

## 1.5 Audit and Evidence

Unity Catalog system tables provide the authoritative audit record for Databricks activity and are themselves subject to the residency controls of the parent catalog - they land in Canadian Unity Catalog storage when the metastore is provisioned in a Canadian region. The tables of primary interest are likely  system.access.audit (workspace- and account-level activity), system.access.table_lineage (read and write lineage across catalogs), and system.billing.usage (compute usage tied to workloads).

  

CLI - create a warehouse and query the audit tables for the last seven days

  

```
databricks warehouses create --json '{

  "name": "audit-wh",

  "cluster_size": "Small",

  "warehouse_type": "PRO",

  "enable_serverless_compute": true

}'
```

  

```
databricks api post /api/2.0/sql/statements --json '{

  "warehouse_id": "<id>",

  "statement": "SELECT * FROM system.access.audit WHERE event_date >= current_date() - 7"

}'

```
  

# 2. Workload Residency - Applying the Foundation

Each subsection below identifies what is specific on top of the foundation noted above.

## 2.1 Data Engineering

Lakeflow Declarative Pipelines, classic jobs, and Auto Loader inherit region residency from the workspace.

  

CLI - create a serverless Lakeflow pipeline and a scheduled job

  

```
databricks pipelines create --json '{

  "name": "bronze_ingest",

  "serverless": true,

  "catalog": "sovereign_ca",

  "target": "bronze",

  "libraries": [{"notebook": {"path": "/Workspace/Pipelines/bronze_ingest"}}]

}'
```

  

`databricks jobs create --json @resources/training_job.yml`
  

`databricks jobs get <job-id>`

  
  

## 2.2 Data Warehousing

SQL warehouses come in three variants - Classic, Pro, and Serverless. Serverless warehouses execute in the same Canadian region as the serverless compute plane, Classic and Pro execute in the classic compute plane, also in the same Canadian region. AI/BI Dashboards and Genie spaces store their query results and serialized definitions in the workspace. 

  

CLI - create a serverless SQL warehouse and a dashboard

  

```
databricks warehouses create --json '{

  "name": "analytics-wh",

  "cluster_size": "Medium",

  "warehouse_type": "PRO",

  "enable_serverless_compute": true,

  "auto_stop_mins": 10

}'

```
  

```
databricks lakeview create --json '{

  "display_name": "Consumption Dashboard",

  "warehouse_id": "<id>",

  "serialized_dashboard": "<json>"

}'

```
  
  

## 3. AI and Machine Learning - Deep Dive

3.1 ML Lifecycle on Sovereign Infrastructure

Notebooks, MLflow experiments, Unity Catalog registered models, the Databricks Feature Store, and Online Tables all land in Canadian Unity Catalog storage when the workspace and metastore are provisioned in a Canadian region. MLflow model artifacts are written to the storage backing the registered model's catalog. Model training and validation can run on either compute plane, thus still staying on Canadian servers.

CLI - create a registered model and an online table

```
databricks registered-models create --json '{

  "name": "iris_clf",

  "catalog_name": "sovereign_ca",

  "schema_name": "ml",

  "storage_location": "abfss://models@<storage>.dfs.core.windows.net/iris_clf"

}'

```
```
databricks online-tables create --json '{

  "name": "sovereign_ca.ml.features_online",

  "spec": {"source_table_full_name": "sovereign_ca.ml.features", "primary_key_columns": ["id"], "run_triggered": {}}

}'

```
  
  

## 3.1 Model Serving Deployment in Canada

For workloads that must keep inference compute and data in Canadian Azure regions only (Canada Central / Canada East, no cross-geo processing), choose one of the following options and record it in the workload’s design.

---

#### Option A – Serve custom ML models on Azure Databricks in Canada

Use this when you train and serve custom machine learning models, whether built within Databricks or from an outside source (e.g. HuggingFace). You can register and deploy them as Unity Catalog–registered models, thus enabling all the governance and compliance features therein.

Model inference runs in the same Canadian region as the workspace.  Optionally, you can enable AI Gateway on the endpoint to add guardrails, rate limits, and inference tables in a Canadian Unity Catalog

CPU only models are supported. Models that required GPUs are supported but GPU availability is limited to T4 and A100 models.

CLI – create a custom model endpoint from Unity Catalog

```
databricks registered-models create --json '{

  "name": "credit_risk_model",

  "catalog_name": "sovereign_ca",

  "schema_name": "ml"

}'

```
  

```
databricks serving-endpoints create --json '{

  "name": "credit-risk-endpoint",

  "config": {

    "served_entities": [{

      "entity_name": "sovereign_ca.ml.credit_risk_model",

      "entity_version": "1",

      "workload_size": "Small",

      "scale_to_zero_enabled": true

    }]

  }

}'
```

  

#### Option B – Serving LLM Models Running on Canadian Servers

Use this when you need a state-of-the-art LLM (for example, GPT-4o or similar) but must keep LLM inference and data residency in Canada.  You can use Microsoft Foundry to host an LLM and integrate it with Databricks via the AI Gateway.

The foundational LLM model is deployed in Microsoft Foundry using a regional deployment in a Canadian region (typically Canada East). 

- Unity Catalog manages permissions, governance, audit, and monitoring
    
- AI Gateway manages guardrails, rate limits, inference tables, and more
    
- Prompts and inference are processed by the model in Canadian Foundry infrastructure and remain in Canada
    

In Foundry, deploy an LLM foundational model as a regional or regional provisioned-throughput deployment (not “Global Deployment”). Additional costs may apply.  Then, in Databricks, create a secret scope that stores the Foundry API key.  Register the Foundry deployment as an external model and expose it as a serving endpoint.  Finally, consider enabling AI Gateway on that endpoint to capture all inference requests/responses into Canadian UC inference tables and apply guardrails.

CLI – create a secret scope and external-model endpoint for Foundry

# Secret scope for Foundry credentials

```
databricks secrets create-scope foundry

```
```
databricks secrets put-secret foundry api-key --string-value "<foundry-api-key>"

```
  

# External model endpoint pointing at a Foundry-hosted LLM in Canada East

```
databricks serving-endpoints create --json '{

  "name": "foundry-gpt4o-ca",

  "config": {

    "served_entities": [{

      "name": "gpt-4o",

      "external_model": {

        "provider": "openai",

        "name": "gpt-4o",

        "task": "llm/v1/chat",

        "openai_config": {

          "openai_api_type": "azure",

          "openai_api_base": "https://<foundry-resource>.openai.azure.com/",

          "openai_deployment_name": "gpt-4o",

          "openai_api_version": "2024-08-01-preview",

          "openai_api_key": "{{secrets/foundry/api-key}}"

        }

      }

    }]

  }

}'

```
  
  
  
  

## 3.2 Vector Search Index

Vector Search runs on serverless compute in the workspace region, and Delta Sync indexes are backed by Delta tables in Canadian Unity Catalog storage. 

CLI - create a Vector Search endpoint and a Delta Sync index

```
databricks vector-search-endpoints create-endpoint --json '{

  "name": "vs-ca-central",

  "endpoint_type": "STANDARD"

}'
```

```
databricks vector-search-indexes create-index --json '{

  "name": "sovereign_ca.ai.docs_index",

  "endpoint_name": "vs-ca-central",

  "primary_key": "id",

  "index_type": "DELTA_SYNC",

  "delta_sync_index_spec": {

    "source_table": "sovereign_ca.ai.docs",

    "pipeline_type": "TRIGGERED",

    "embedding_source_columns": [{

      "name": "content",

      "embedding_model_endpoint_name": "databricks-bge-large-en"

    }]

  }

}'

  
```

## 3.3 Governance for AI

AI Gateway is the control plane for Model Serving endpoints. It provides request and response guardrails, per-endpoint rate limits, usage tracking, and, critically for regulated workloads, inference tables. Inference tables log every request and response to Delta tables in Unity Catalog.

  

CLI - enable AI Gateway, inference tables, and a quality monitor

```
databricks serving-endpoints put-ai-gateway <endpoint-name> --json '{

  "inference_table_config": {

    "enabled": true,

    "catalog_name": "sovereign_ca",

    "schema_name": "ai_audit",

    "table_name_prefix": "inf"

  },

  "rate_limits": [{"calls": 100, "renewal_period": "minute"}],

  "guardrails": {"input": {"safety": {"enabled": true}}}

}'

```
```
databricks quality-monitors create --json '{

  "table_name": "sovereign_ca.ai_audit.inf_payload",

  "assets_dir": "/Workspace/Monitors/inf_payload",

  "output_schema_name": "sovereign_ca.ai_audit",

  "inference_log": {"problem_type": "PROBLEM_TYPE_CLASSIFICATION", "timestamp_col": "timestamp"}

}'

```
  

## 3.4 Microsoft Foundry and Azure OpenAI Integration

Connecting Databricks with Foundry is easy. Start by registering the upstream endpoint as an external model in Databricks Model Serving. Databricks provides the governance, audit, and routing layer on top: every request and response routed through the Databricks endpoint is captured in Canadian Unity Catalog inference tables, is subject to Databricks guardrails and rate limits, and is governed by the same Unity Catalog permission model that applies to all other workloads on your platform.

Most importantly, note that Foundry allows Global Standard options for LLMs, which means that your request may be routed to any GPU in any region.  To keep your data and request in Canada, only certain regions and certain models may be used.  Additional charges may apply.

  

CLI - create a secret scope and an external-model endpoint pointing at a Foundry deployment

  

`databricks secrets create-scope foundry`

  

`databricks secrets put-secret foundry api-key --string-value "<foundry-key>"`

  

```
databricks serving-endpoints create --json '{

  "name": "foundry-gpt-4o-ca",

  "config": {

    "served_entities": [{

      "name": "<for example: gpt-4o>”,

      "external_model": {

        "provider": "openai",

        "name": "<for example: gpt-4o>”,

        "task": "llm/v1/chat",

        "openai_config": {

          "openai_api_type": "azure",

          "openai_api_base": "https://<foundry-resource>.openai.azure.com/",

          "openai_deployment_name": “<for example: gpt-4o>”,

          "openai_api_version": “<for example: 2024-08-01-preview>”,

          "openai_api_key": "{{secrets/foundry/api-key}}"

        }

      }

    }]

  }

}'

```
  
  

## 3.5 Genie (AI/BI Dashboards)

  

The underlying model powering Genie (AI/BI) dashboards is available in Canadian Azure regions, specifically Canada Central and Canada East, ensuring that compute and inference adhere to local data residency requirements. However, it is important to note that the companion research agent model is not currently available in these Canadian regions. For residency, AI/BI Dashboards and Genie spaces are designed to store their generated query results and serialized definitions directly within the workspace. This means their data is subject to the platform's foundation of residency controls, which require all storage surfaces, including the workspace itself, to be provisioned in a Canadian region.

  

To ensure that Genie runs in Canada, you must enable “Enforce data processing within workspace Geography for Designated Services” in the account console.

  
  
  
  

3.6 ai_forecast

  

ai_forecast() is a built-in Databricks SQL table-valued function that performs time-series forecasting directly inside a query, with no model training, no MLflow, and no notebook required. It takes a historical series, a time column, a value column, an optional grouping column for multi-series forecasts, a frequency, and a horizon, then returns forecasted values with prediction intervals. Under the hood it picks an appropriate statistical or ML model automatically and runs on serverless SQL warehouses, which makes it useful for ad-hoc capacity planning, demand forecasting, and consumption projections without leaving the SQL editor. It is part of the AI Functions family alongside ai_query, ai_classify, and ai_extract. 

  

```
  -- Forecast next 90 days of daily DBU consumption per workspace

  WITH historical AS (

    SELECT

      usage_date,

      workspace_id,

      SUM(usage_quantity) AS daily_dbus

    FROM system.billing.usage

    WHERE usage_date >= DATEADD(DAY, -365, CURRENT_DATE())

      AND usage_unit = 'DBU'

    GROUP BY usage_date, workspace_id

  )

  SELECT *

  FROM AI_FORECAST(

    TABLE(historical),

    horizon       => DATEADD(DAY, 90, CURRENT_DATE()),

    time_col      => 'usage_date',

    value_col     => 'daily_dbus',

    group_col     => 'workspace_id',

    frequency     => '1 day',

    prediction_interval_width => 0.95

  )

  ORDER BY workspace_id, usage_date;

```
  

 The result set includes the forecast point estimate plus lower/upper bounds at the requested confidence interval, which you can plot directly in a AI/BI dashboard.

  
  

3.7 AI-generated comments in Unity Catalog

Unity Catalog AI-generated comments use a built-in foundation model to automatically draft descriptions for tables and columns based on schema, sample data, and surrounding metadata, which removes most of the manual cost of documenting a large catalogue. For Canadian workspaces, inference runs on Foundation Model API endpoints hosted in Canadian regions, so both the model and the data stay in Canada. 

# 4. Declarative Automation Bundles

Declarative Automation Bundles enable the repeatable and code-driven ability to spin up Databricks resources (e.g. clusters) with specific code (e.g. models, notebooks).  This allows consistent and provably repeatable creation (and/or tear-down) of projects and assets.

  

CLI - authenticate, deploy, run, tear down

```
databricks auth login https://<workspace-host>.azuredatabricks.net --profile=<profile>

databricks bundle deploy -p <profile>

databricks bundle run train_iris -p <profile>

databricks api put \

  "/api/2.1/unity-catalog/models/<catalog>.<schema>.<model>/aliases/champion" \

  --profile=<profile> \

  --json '{"version_num": 1}'

```
`databricks api get /api/2.0/serving-endpoints/<endpoint-name> -p <profile>`

# 5. Contributing

Contributions are welcome. See the repository README.md for contact and the contribution process.

# 6. Trademarks

Databricks, Unity Catalog, Delta Lake, MLflow, and Mosaic AI are trademarks of Databricks, Inc. Microsoft, Azure, and Azure Databricks are trademarks of Microsoft Corporation. Third-party marks referenced in this document belong to their respective owners.

  
**