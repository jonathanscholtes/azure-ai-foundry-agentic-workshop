
@description('Name used to identify the project; also used to generate a short, unique hash for each resource')
param projectName string

@description('Name representing the deployment environment (e.g., "dev", "test", "prod", "lab"); used to generate a short, unique hash for each resource')
param environmentName string

@description('Token or string used to uniquely identify this resource deployment (e.g., build ID, commit hash)')
param resourceToken string

@description('Azure region where all resources will be deployed (e.g., "eastus")')
param location string

@description('Name of the User Assigned Managed Identity to assign to deployed services')
param identityName string

@description('Resource ID of the Application Insights instance used for monitoring')
param applicationInsightsId string

@description('Target name or identifier for the Azure AI Search service instance')
param aiSearchTarget string

@description('Resource ID of the Azure AI Search service')
param searchServiceId string

@description('Resource ID of the Azure Storage Account used by the solution')
param storageAccountId string

@description('Configuration settings for the project; expected to be an array of objects defining project-specific parameters')
param projectConfig array


@description('Resource ID of the Key Vault used for storing secrets and connection strings')
param keyVaultId string

@description('Resource ID of the Azure Container Registry used to store container images')
param containerRegistryID string


param skipModels bool = false


module aiServices 'azure-ai-services.bicep' = {
  name: 'aiServices'
  params: {
    aiServicesName: 'ais-${projectName}-${environmentName}-${resourceToken}'
    location: location
    identityName: identityName
    customSubdomain: 'openai-app-${resourceToken}'
    
  }
}



module aiHub 'ai-hub.bicep' = {
  name: 'aihub'
  params:{
    aiHubName: 'hub-${projectName}-${environmentName}-${resourceToken}'
    aiHubDescription: 'Hub for AI Workshop'
    aiServicesResourceId:aiServices.outputs.aiservicesID
    aiServicesEndpoint: '${aiServices.outputs.OpenAIEndPoint}/'
    keyVaultResourceId: keyVaultId
    location: location
    aiHubFriendlyName: 'AI Workshop Hub'
    appInsightsResourceId:applicationInsightsId
    managedIdentityName:identityName
    aiSearchEndpoint:aiSearchTarget
    aiSearchResourceId:searchServiceId
    storageAccountResourceId:storageAccountId
    containerRegistryID:containerRegistryID
  }
}



module aiProjects 'project/main.bicep' = [for i in range(0, length(projectConfig)): {
  name: 'aiProjects-${projectConfig[i].projectName}'
  params: {
    aiHubResourceId: aiHub.outputs.aiHubResourceId
    location: location
    aiProjectName: '${projectConfig[i].projectName}'
    aiSearchConnectionName: aiHub.outputs.aiServicesConnectionName
    aoaiConnectionName: aiHub.outputs.aiServicesConnectionName
    aiHubName:aiHub.outputs.aiHubName
    identityName:identityName
    numberComputeInstances: projectConfig[i].devComputeInstances
    resourceToken:resourceToken
    environmentName:environmentName
    users: projectConfig[i].?users ?? []
  }
  dependsOn: i == 0 ? [] : [
    resourceId('Microsoft.Resources/deployments', 'aiProjects-${projectConfig[i - 1].projectName}')
  ]
}]

module aiModels 'ai-models.bicep' = if (skipModels == false) {
  name:'aiModels'
  params:{
    aiServicesName:aiServices.outputs.aiServicesName
  }
  
}


output aiservicesTarget string = aiServices.outputs.aiservicesTarget
output OpenAIEndPoint string = aiServices.outputs.OpenAIEndPoint
