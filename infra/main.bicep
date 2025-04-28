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

resource resourceGroup 'Microsoft.Resources/resourceGroups@2024-03-01' existing =  {
  name: resourceGroupName
}

param projectConfig array


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
   logAnalyticsName: 'log-${projectName}-${environmentName}-${resourceToken}'
   applicationInsightsName: 'appi-${projectName}-${environmentName}-${resourceToken}'
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
    projectConfig:projectConfig
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


/*
module mcpWeatherServer 'app/mcp--weather-web-app.bicep' = {
  name: 'mcpWeatherServer'
  scope: resourceGroup
  params: { 
    location: location
    identityName: security.outputs.managedIdentityName
    webAppName: 'mcp-weather-${environmentName}-${resourceToken}'
    appServicePlanName: apps.outputs.appServicePlanName
    logAnalyticsWorkspaceName: monitor.outputs.logAnalyticsWorkspaceName
    appInsightsName: monitor.outputs.applicationInsightsName
  }
}*/


output managedIdentityName string = security.outputs.managedIdentityName
output appServicePlanName string = apps.outputs.appServicePlanName 
output storageAccountName string = data.outputs.storageAccountName 
output logAnalyticsWorkspaceName string = monitor.outputs.logAnalyticsWorkspaceName
output applicationInsightsName string = monitor.outputs.applicationInsightsName
output keyVaultUri string = security.outputs.keyVaultUri
output OpenAIEndPoint string = ai.outputs.OpenAIEndPoint 
output searchServiceEndpoint string = ai.outputs.searchServiceEndpoint 
output containerRegistryName string = platform.outputs.containerRegistryName
output azureAISearchName string = ai.outputs.azureAISearchName
