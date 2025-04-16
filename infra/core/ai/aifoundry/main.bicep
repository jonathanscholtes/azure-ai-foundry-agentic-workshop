
param projectName string
param environmentName string
param resourceToken string
param location string
param identityName string
param applicationInsightsId string
param aiSearchTarget string
param searchServiceId string
param searchServicename string
param storageAccountId string
param numberComputeInstances int =1


@description('Resource ID of the key vault resource for storing connection strings')
param keyVaultId string

param containerRegistryID string

var aiServicesName  = 'ais-${projectName}-${environmentName}-${resourceToken}'
var aiProjectName  = 'prj-${projectName}-${environmentName}-${resourceToken}'

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
}



module aiProject 'ai-project.bicep' = {
  name: 'aiProject'
  params:{
    aiHubResourceId:aiHub.outputs.aiHubResourceId
    location: location
    aiProjectName: aiProjectName
    aiProjectFriendlyName: 'AI Workshop Project'
    aiProjectDescription: 'Project for Workshop'    
  }
}

module aiModels 'ai-models.bicep' = {
  name:'aiModels'
  params:{
    aiServicesName:aiServicesName
  }
  dependsOn:[aiServices,aiProject]
}


module aiCompute 'compute/main.bicep' = if (numberComputeInstances > 0){
name: 'aiCompute'
params: { 
  aiHubName:aiHub.outputs.aiHubName
  numberComputeInstances:numberComputeInstances
  projectName: projectName
  environmentName: environmentName
  resourceToken:resourceToken
  location:location
  managedIdentityName:identityName
}
}


module addCapabilityHost 'add-capability-host.bicep' = {
  name: 'addCapabilityHost'
  params: {
    capabilityHostName: '${environmentName}-${resourceToken}'
    aiHubName: aiHub.outputs.aiHubName
    aiProjectName: aiProjectName
    aiSearchConnectionName: aiHub.outputs.aiServicesConnectionName
    aoaiConnectionName: aiHub.outputs.aiServicesConnectionName
  }
  dependsOn:[aiProject]
}

output aiservicesTarget string = aiServices.outputs.aiservicesTarget
output OpenAIEndPoint string = aiServices.outputs.OpenAIEndPoint
