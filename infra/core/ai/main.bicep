param projectName string
param environmentName string
param resourceToken string
param location string
param identityName string
param searchServicename string
param applicationInsightsId string
param storageAccountId string
param containerRegistryID string

param projectConfig array


@description('Resource ID of the key vault resource for storing connection strings')
param keyVaultId string



module aiServices 'azure-ai-services.bicep' = {
  name: 'aiServices'
  params: {
    aiServicesName: 'ais-${projectName}-${environmentName}-${resourceToken}'
    location: location
    identityName: identityName
    customSubdomain: 'openai-app-${resourceToken}'
    
  }
}


module search 'aisearch/main.bicep' = { 
  name: 'aisearch'
  params: {
  location:location
  managedIdentityName: identityName
  searchServicename: searchServicename

  }

  dependsOn:[aiServices]
}


module aifoundry 'aifoundry/main.bicep' = {
  name: 'aifoundry'
  params: { 
    location:location
    environmentName: environmentName
    identityName: identityName
    keyVaultId: keyVaultId
    projectName: projectName
    resourceToken: resourceToken
    applicationInsightsId:applicationInsightsId
    searchServiceId:search.outputs.searchServiceId
    aiSearchTarget:search.outputs.searchServiceEndpoint
    storageAccountId:storageAccountId
    containerRegistryID: containerRegistryID
    projectConfig:projectConfig
    aiServicesResourceId:aiServices.outputs.aiservicesID
    aiServicesEndpoint: '${aiServices.outputs.OpenAIEndPoint}/'
    aiServicesName:aiServices.outputs.aiServicesName

  }
  dependsOn:[aiServices]
}



output aiservicesTarget string = aiServices.outputs.aiservicesTarget
output OpenAIEndPoint string = aiServices.outputs.OpenAIEndPoint
output searchServiceEndpoint string = search.outputs.searchServiceEndpoint
output azureAISearchKey string = search.outputs.azureAISearchKey

