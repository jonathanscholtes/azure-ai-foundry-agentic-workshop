targetScope = 'subscription'

@minLength(1)
@maxLength(64)
@description('Name which is used to generate a short unique hash for each resource')
param environmentName string

@minLength(1)
@maxLength(64)
@description('Name which is used to generate a short unique hash for each resource')
param projectName string

@minLength(1)
@description('Primary location for all resources')
param location string

param resourceGroupName string

param resourceToken string


@description('Name of the User Assigned Managed Identity')
param managedIdentityName string

@description('Name of the Log Analytics Workspace')
param logAnalyticsWorkspaceName string

param appInsightsName string

@description('Name of the Azure Container Registry')
param containerRegistryName string

param appServicePlanName string

param storageAccountName string

param keyVaultUri string

param OpenAIEndPoint string

param searchServiceEndpoint string

param azureAISearchKey string


resource resourceGroup 'Microsoft.Resources/resourceGroups@2024-03-01' existing =  {
  name: resourceGroupName
}



module loaderFunctionWebApp 'loader-function-web-app.bicep' = {
  name: 'loaderFunctionWebApp'
  scope: resourceGroup
  params: { 
    location: location
    identityName: managedIdentityName
    functionAppName: 'func-loader-${resourceToken}'
    functionAppPlanName: appServicePlanName
    StorageAccountName: storageAccountName
    logAnalyticsWorkspaceName: logAnalyticsWorkspaceName
    appInsightsName: appInsightsName
    keyVaultUri:keyVaultUri
    OpenAIEndPoint: OpenAIEndPoint
    searchServiceEndpoint: searchServiceEndpoint
    azureAISearchKey:azureAISearchKey
    azureAiSearchBatchSize: 100
    documentChunkOverlap: 500
    documentChunkSize: 2000
  
  }
}


module apiWebApp 'api-web-app.bicep' = {
  name: 'apiWebApp'
  scope: resourceGroup
  params: { 
    location: location
    identityName: managedIdentityName
    webAppName: 'api-${projectName}-${environmentName}-${resourceToken}'
    appServicePlanName: appServicePlanName
    StorageAccountName: storageAccountName
    logAnalyticsWorkspaceName: logAnalyticsWorkspaceName
    appInsightsName: appInsightsName
    keyVaultUri:keyVaultUri
  }
}


module mcpContainerApps 'mcp-container-app.bicep' = {
  name: 'mcpContainerApps'
  scope: resourceGroup
  params: {
    location: location
    managedIdentityName: managedIdentityName
    containerAppBaseName: '${projectName}-${environmentName}-${resourceToken}'
    containerRegistryName: containerRegistryName
    logAnalyticsWorkspaceName: logAnalyticsWorkspaceName
    searchServiceEndpoint: searchServiceEndpoint
    OpenAIEndPoint: OpenAIEndPoint
    openAPIEndpoint:apiWebApp.outputs.webAppNameURL
  }
}

output functionAppName string =  loaderFunctionWebApp.outputs.functionAppName
output apiAppName string =  apiWebApp.outputs.webAppName
