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

@description('Name of the Azure Cognitive Search service instance')
param searchServicename string

@description('Resource ID of the Application Insights instance used for monitoring and telemetry')
param applicationInsightsId string

@description('Resource ID of the Azure Storage Account used by the solution')
param storageAccountId string

@description('Resource ID of the Azure Container Registry used to store and manage container images')
param containerRegistryID string

@description('Configuration settings for the project; expected to be an array of objects defining project-specific values')
param projectConfig array

@description('Resource ID of the Key Vault used for storing secrets and connection strings')
param keyVaultId string



module search 'aisearch/main.bicep' = { 
  name: 'aisearch'
  params: {
  location:location
  managedIdentityName: identityName
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
    projectConfig:projectConfig
    
  }

}



output aiservicesTarget string = aifoundry.outputs.aiservicesTarget
output OpenAIEndPoint string = aifoundry.outputs.OpenAIEndPoint
output searchServicename string = searchServicename

