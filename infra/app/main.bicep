targetScope = 'subscription'

@minLength(1)
@maxLength(64)
@description('Name representing the deployment environment (e.g., "dev", "test", "prod", "lab"); used to generate a short, unique hash for each resource')
param environmentName string

@minLength(1)
@maxLength(64)
@description('Name used to identify the project; also used to generate a short, unique hash for each resource')
param projectName string

@minLength(1)
@description('Azure region where all resources will be deployed (e.g., "eastus")')
param location string

@description('Name of the resource group where resources will be deployed')
param resourceGroupName string

@description('Token or string used to uniquely identify this resource deployment (e.g., build ID, commit hash)')
param resourceToken string

@description('Name of the User Assigned Managed Identity to assign to deployed services')
param managedIdentityName string

@description('Name of the Log Analytics Workspace for centralized monitoring')
param logAnalyticsWorkspaceName string

@description('Name of the Application Insights instance for telemetry')
param appInsightsName string

@description('Name of the Azure Container Registry for storing container images')
param containerRegistryName string

@description('Name of the App Service Plan for hosting web apps or APIs')
param appServicePlanName string

@description('Name of the Azure Storage Account used for blob or file storage')
param storageAccountName string

@description('Name of the Azure Key Vault used to store secrets and keys securely')
param keyVaultName string

@description('Endpoint URL of the Azure OpenAI resource (e.g., https://your-resource.openai.azure.com/)')
param OpenAIEndPoint string

@description('Name of the Azure AI Search service instance')
param searchServicename string



resource resourceGroup 'Microsoft.Resources/resourceGroups@2024-03-01' existing =  {
  name: resourceGroupName
}


module appSecurity 'app-secrets.bicep' = {
  name: 'appSecurity'
  scope: resourceGroup
  params: {
   keyVaultName:keyVaultName
   searchServicename: searchServicename

  }
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
    keyVaultUri:appSecurity.outputs.keyVaultUri
    OpenAIEndPoint: OpenAIEndPoint
    searchServiceEndpoint: appSecurity.outputs.searchServiceEndpoint
    azureAISearchKey: appSecurity.outputs.AzureAISearchKey
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
    keyVaultUri:appSecurity.outputs.keyVaultUri
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
    searchServiceEndpoint: appSecurity.outputs.searchServiceEndpoint
    OpenAIEndPoint: OpenAIEndPoint
    openAPIEndpoint:apiWebApp.outputs.webAppNameURL
  }
}

output functionAppName string =  loaderFunctionWebApp.outputs.functionAppName
output apiAppName string =  apiWebApp.outputs.webAppName
