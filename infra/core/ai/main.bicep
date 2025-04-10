param projectName string
param environmentName string
param resourceToken string
param location string
param identityName string
param searchServicename string
param applicationInsightsId string
param storageAccountId string
param containerRegistryID string
param numberComputeInstances int

@description('Resource ID of the key vault resource for storing connection strings')
param keyVaultId string



module search 'aisearch/main.bicep' = { 
  name: 'aisearch'
  params: {
  location:location
  identityName: identityName
  searchServicename: searchServicename

  }
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
    numberComputeInstances: numberComputeInstances
  }

}



output aiservicesTarget string = aifoundry.outputs.aiservicesTarget
output OpenAIEndPoint string = aifoundry.outputs.OpenAIEndPoint
output searchServiceEndpoint string = search.outputs.searchServiceEndpoint
