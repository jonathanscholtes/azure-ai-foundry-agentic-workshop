@description('Azure region of the deployment')
param location string

@description('Name of the AI hub')
param aiHubName string

@description('Friendly display name for the AI hub')
param aiHubFriendlyName string

@description('Description of the AI hub')
param aiHubDescription string

@description('Resource ID of the Key Vault for storing connection strings')
param keyVaultResourceId string

param containerRegistryID string

@description('Resource ID of the Azure AI Services instance')
param aiServicesResourceId string

@description('Target endpoint of the Azure AI Services instance')
param aiServicesEndpoint string

@description('Target endpoint of the Azure AI Search service')
param aiSearchEndpoint string


@description('Resource ID of the Azure Storage Account')
param storageAccountResourceId string

@description('Resource ID of the Application Insights instance')
param appInsightsResourceId string

@description('Name of the user-assigned managed identity')
param managedIdentityName string

@description('Resource ID of the Azure AI Search service')
param aiSearchResourceId string


var aiServicesConnectionName = '${aiHubName}-connection-AI-Services'
var aiSearchConnectionName = '${aiHubName}-connection-AzureAISearch'

resource managedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' existing = {
  name: managedIdentityName
}

resource aiHub 'Microsoft.MachineLearningServices/workspaces@2024-10-01-preview' = {
  name: aiHubName
  location: location
  identity: {
    type: 'SystemAssigned, UserAssigned'
    userAssignedIdentities: {
      '${managedIdentity.id}': {}
    }
  }
  properties: {
    friendlyName: aiHubFriendlyName
    description: aiHubDescription
    keyVault: keyVaultResourceId
    containerRegistry: containerRegistryID
    applicationInsights: appInsightsResourceId
    storageAccount: storageAccountResourceId
    systemDatastoresAuthMode: 'accesskey'
    provisionNetworkNow: false
    publicNetworkAccess: 'Enabled'
  }
  kind: 'hub'
 
}

resource aiServicesConnection 'Microsoft.MachineLearningServices/workspaces/connections@2024-01-01-preview' = {
  parent: aiHub
  name: aiServicesConnectionName
  properties: {
    category: 'AzureOpenAI'
    target: aiServicesEndpoint
    authType: 'ApiKey'
    isSharedToAll: true
    credentials: {
      key: '${listKeys(aiServicesResourceId, '2021-10-01').key1}'
    }
    metadata: {
      ApiType: 'Azure'
      ResourceId: aiServicesResourceId
    }
  }
}

resource aiSearchConnection 'Microsoft.MachineLearningServices/workspaces/connections@2024-01-01-preview' = {
  parent: aiHub
  name: aiSearchConnectionName
  properties: {
    category: 'CognitiveSearch'
    target: aiSearchEndpoint
    authType: 'ApiKey'
    isSharedToAll: true
    credentials: {
      key: '${listAdminKeys(aiSearchResourceId, '2021-04-01-preview').primaryKey}'
    }
    metadata: {
      ApiType: 'Azure'
      ResourceId: aiSearchResourceId
    }
  }
}

#disable-next-line BCP081
resource hubCapabilityHost 'Microsoft.MachineLearningServices/workspaces/capabilityHosts@2024-10-01-preview' = {
  name: '${aiHubName}-capabilityHost'
  parent: aiHub
  properties: {
     capabilityHostKind: 'Agents'
  }
}

output aiHubResourceId string = aiHub.id
output aiHubName string = aiHubName
output aiSearchConnectionName string = aiSearchConnectionName
output aiServicesConnectionName string = aiServicesConnectionName
