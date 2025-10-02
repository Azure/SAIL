## Objective

The following is guidance to facilitate deployment of generic AI models including large language models (LLMs) on Azure Machine Learning's (AML) Managed Online Endpoints for efficient, scalable, and secure real-time inference.​ Two patterns of deployment types are described: models through vLLM and generic AI models. By leveraging AML's [Managed Online Endpoints](https://learn.microsoft.com/en-us/azure/machine-learning/how-to-deploy-online-endpoints?view=azureml-api-2&tabs=cli), the model would be deployed within the AML region and secured through inbound and outbound private connections thus ensuring a secured and sovereign solution.

In particular, this pattern gives you the ability to utilize OOTB Hugging Face models onto Managed Online Endpoints in AML.

 ### Pre-requisites : 

1. vLLM: A high-throughput, memory-efficient inference engine designed for LLMs.​ We will be create a custom Dockerized environment for vLLM on AML as a foundational step.
2. (Optional) You can also bring in any generic AI models by leveraging the custom Dockerfile and providing a generic score.py file that loads the model in memory and defines inferencing.
3. Managed Online Endpoints: A feature in Azure Machine Learning that simplifies deploying machine learning models for real-time inference by handling serving, scaling, securing, and monitoring complexities.​ At the time of writing, an additional context to using this feature is to ensure data and regional residency abilities that could be achieved through the setup here.
4. Model of your choice from HuggingFace (or any generic AI model). Knowledge around usage of HuggingFace models and the workflow and AUthN aspects are assumed.

## Key Deployment Steps:

1. Create a Custom Environment on AzureML: Define a Dockerfile specifying the environment for the model, utilizing vLLM's base container with necessary dependencies.​

2. Deploy the AzureML Managed Online Endpoint: Configure the endpoint and deployment settings using YAML files, specifying the model to deploy, environment variables, and instance configurations.​

3. Test the Deployment: Retrieve the endpoint's scoring URI and API keys, then send test requests to ensure the model is serving correctly.​ Using MS Entra for authentication and authorization is supported as well: https://learn.microsoft.com/en-us/azure/machine-learning/concept-endpoints-online-auth?view=azureml-api-2

4  (Optional) - Autoscale the AML Endpoint: Set up autoscaling rules to dynamically adjust the number of instances based on real-time metrics, ensuring efficient handling of varying loads.​


### Essence of the steps via code/CLI commands: 

1. Authentication
```
az account set --subscription <subscription ID>
az configure --defaults workspace=<Azure Machine Learning workspace name> group=<resource group>
```
3. Build Environment
```
az ml environment create -f environment.yml
```
4. Deploy to Managed Online Endpoint
```
az ml online-endpoint create -f endpoint.yml
az ml online-deployment create -f deployment.yml --all-traffic
```
5. Get API endpoint and API keys
```
az ml online-endpoint show -n <name>
az ml online-endpoint get-credentials -n <name>
```
7. Test the model using the test_model.py file

## Contributing

This project welcomes contributions and suggestions.  Most contributions require you to agree to a
Contributor License Agreement (CLA) declaring that you have the right to, and actually do, grant us
the rights to use your contribution. For details, visit [Contributor License Agreements](https://cla.opensource.microsoft.com).

When you submit a pull request, a CLA bot will automatically determine whether you need to provide
a CLA and decorate the PR appropriately (e.g., status check, comment). Simply follow the instructions
provided by the bot. You will only need to do this once across all repos using our CLA.

This project has adopted the [Microsoft Open Source Code of Conduct](https://opensource.microsoft.com/codeofconduct/).
For more information see the [Code of Conduct FAQ](https://opensource.microsoft.com/codeofconduct/faq/) or
contact [opencode@microsoft.com](mailto:opencode@microsoft.com) with any additional questions or comments.

## Trademarks

This project may contain trademarks or logos for projects, products, or services. Authorized use of Microsoft
trademarks or logos is subject to and must follow
[Microsoft's Trademark & Brand Guidelines](https://www.microsoft.com/legal/intellectualproperty/trademarks/usage/general).
Use of Microsoft trademarks or logos in modified versions of this project must not cause confusion or imply Microsoft sponsorship.
Any use of third-party trademarks or logos are subject to those third-party's policies.
