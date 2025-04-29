
param projectName string
param environmentName string
param resourceToken string
param location string
param identityName string
param applicationInsightsId string
param aiSearchTarget string
param searchServiceId string
param storageAccountId string
param projectConfig array


@description('Resource ID of the key vault resource for storing connection strings')
param keyVaultId string

param containerRegistryID string

var aiServicesName  = 'ais-${projectName}-${environmentName}-${resourceToken}'



module aiServices 'azure-ai-services.bicep' = {
  name: 'aiServices'
  params: {
    aiServicesName: aiServicesName
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
  dependsOn:[aiServices]
}



module aiProjects 'project/main.bicep' = [for proj in projectConfig: {
  name: 'aiProjects-${proj.projectName}'
  params: {
    aiHubResourceId: aiHub.outputs.aiHubResourceId
    location: location
    aiProjectName: '${proj.projectName}'
    aiSearchConnectionName: aiHub.outputs.aiServicesConnectionName
    aoaiConnectionName: aiHub.outputs.aiServicesConnectionName
    aiHubName:aiHub.outputs.aiHubName
    identityName:identityName
    numberComputeInstances: proj.devComputeInstances
    resourceToken:resourceToken
    environmentName:environmentName
    users: proj.?users ?? []
  }
  dependsOn:[aiHub]
}]

module aiModels 'ai-models.bicep' = {
  name:'aiModels'
  params:{
    aiServicesName:aiServicesName
  }
  dependsOn:[aiServices]
}

output aiservicesTarget string = aiServices.outputs.aiservicesTarget
output OpenAIEndPoint string = aiServices.outputs.OpenAIEndPoint
