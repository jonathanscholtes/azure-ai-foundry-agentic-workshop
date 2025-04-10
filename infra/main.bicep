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

param numberComputeInstances int

resource resourceGroup 'Microsoft.Resources/resourceGroups@2024-03-01' existing =  {
  name: resourceGroupName
}


module security 'core/security/main.bicep' = {
  name: 'security'
  scope: resourceGroup
  params:{
    keyVaultName: 'kv${projectName}${resourceToken}'
    managedIdentityName: 'id-${projectName}-${environmentName}'
    location: location
  }
  
}

module monitor 'core/monitor/main.bicep' = { 
  name:'monitor'
  scope: resourceGroup
  params:{ 
   location:location 
   logAnalyticsName: 'log-${projectName}-${environmentName}'
   applicationInsightsName: 'appi-${projectName}-${environmentName}'
  }
}


module data 'core/data/main.bicep' = {
  name: 'data'
  scope: resourceGroup
  params:{
    projectName:projectName
    resourceToken:resourceToken
    location: location
    identityName:security.outputs.managedIdentityName
  
  }
}


module platform 'core/platform/main.bicep' = { 
  name: 'platform'
  scope: resourceGroup
  params: { 
    containerRegistryName: 'cr${projectName}${environmentName}${resourceToken}'
    location:location
  }
}

module ai 'core/ai/main.bicep' = {
  name: 'ai'
  scope: resourceGroup
  params: { 
    projectName:projectName
    environmentName:environmentName
    resourceToken:resourceToken
    location: location
    keyVaultId: security.outputs.keyVaultID
    applicationInsightsId: monitor.outputs.applicationInsightsId
    identityName:security.outputs.managedIdentityName
    searchServicename: 'srch-${projectName}-${environmentName}-${resourceToken}'
    storageAccountId:data.outputs.storageAccountId
    containerRegistryID: platform.outputs.containerRegistryID
    numberComputeInstances:numberComputeInstances
  }
}

module apps 'core/app/main.bicep' ={ 
  name: 'apps'
  scope: resourceGroup
  params:{
    projectName:projectName
    environmentName:environmentName
    resourceToken:resourceToken
    location: location
  }
}

module loaderFunctionWebApp 'app/loader-function-web-app.bicep' = {
  name: 'loaderFunctionWebApp'
  scope: resourceGroup
  params: { 
    location: location
    identityName: security.outputs.managedIdentityName
    functionAppName: 'func-loader-${resourceToken}'
    functionAppPlanName: apps.outputs.appServicePlanName
    StorageAccountName: data.outputs.storageAccountName
    logAnalyticsWorkspaceName: monitor.outputs.logAnalyticsWorkspaceName
    appInsightsName: monitor.outputs.applicationInsightsName
    keyVaultUri:security.outputs.keyVaultUri
    OpenAIEndPoint: ai.outputs.OpenAIEndPoint
    searchServiceEndpoint: ai.outputs.searchServiceEndpoint
    azureAiSearchBatchSize: 100
    documentChunkOverlap: 500
    documentChunkSize: 2000
  
  }
}

output resourceGroupName string = resourceGroup.name
output functionAppName string = loaderFunctionWebApp.outputs.functionAppName
