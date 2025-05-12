param functionAppName string
param functionAppPlanName string

@description('Azure region where all resources will be deployed (e.g., "eastus")')
param location string
param StorageAccountName string
param identityName string
param logAnalyticsWorkspaceName string
param appInsightsName string
param keyVaultUri string
param OpenAIEndPoint string
param searchServiceEndpoint string
param documentChunkSize int = 2000
param documentChunkOverlap int = 500
param azureAiSearchBatchSize int = 100
param azureAISearchKey string



var blob_uri = 'https://${StorageAccountName}.blob.core.windows.net'
var queue_uri = 'https://${StorageAccountName}.queue.core.windows.net'


resource appServicePlan 'Microsoft.Web/serverfarms@2022-03-01' existing = {
  name: functionAppPlanName
}

resource appInsights 'Microsoft.Insights/components@2020-02-02' existing = {
  name: appInsightsName
}

resource managedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' existing= {
  name: identityName
}

// resourceGroups breaks SearchIndexerDataUserAssignedIdentity
var resource_id = managedIdentity.id
var adj_resource_id = replace(resource_id, 'resourceGroups', 'resourcegroups')

resource functionApp 'Microsoft.Web/sites@2022-03-01' = {
  name: functionAppName
  location: location
  kind: 'functionapp,linux'
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${managedIdentity.id}': {}
    }
  }
  properties: {
    serverFarmId: appServicePlan.id
    keyVaultReferenceIdentity: managedIdentity.id
    siteConfig: {
      appSettings: [
        {
          name: 'AzureWebJobsStorage__credential'
          value: 'managedidentity'
        }
        {
          name: 'AzureWebJobsStorage__clientId'
          value: managedIdentity.properties.clientId
        }
        {
          name: 'AzureWebJobsStorage__accountName'
          value: StorageAccountName
        }
        {
          name: 'AZURE_STORAGE_URL'
          value: blob_uri
        }        
        {
          name: 'FUNCTIONS_EXTENSION_VERSION'
          value: '~4'
        }
        {
          name: 'WEBSITE_RUN_FROM_PACKAGE'
          value: 'true'
        }
        {
          name: 'FUNCTIONS_WORKER_RUNTIME'
          value: 'python'
        }
        {
          name: 'AzureWebJobsFeatureFlags'
          value: 'EnableWorkerIndexing'
        }
        {
          name: 'APPINSIGHTS_INSTRUMENTATIONKEY'
          value: appInsights.properties.InstrumentationKey
        }
        {
          name: 'AZURE_CLIENT_ID'
          value: managedIdentity.properties.clientId
        } 
        {
          name:'AZURE_CLIENT_RESOURCE_ID'
          value:adj_resource_id
        }
        {
          name:'KeyVaultUri'
          value:keyVaultUri
        }    
        {
          name: 'AZURE_OPENAI_EMBEDDING'
          value: 'text-embedding'
        }
        {
          name: 'OPENAI_API_VERSION'
          value: '2024-06-01'
        }
        {
          name: 'AZURE_OPENAI_ENDPOINT'
          value: OpenAIEndPoint
        }
        {
          name: 'AZURE_AI_SEARCH_ENDPOINT'
          value: searchServiceEndpoint
        } 
        {
          name:'AZURE_AI_SEARCH_API_KEY'
          value:azureAISearchKey
        }
        {
          name: 'AZURE_AI_SEARCH_BATCH_SIZE'
          value: string(azureAiSearchBatchSize)
        }       
        {
          name: 'AZURE_AI_SEARCH_INDEX'
          value: 'workshop-index'
        } 
        {
          name: 'DOCUMENT_CHUNK_SIZE'
          value: string(documentChunkSize)
        } 
        {
          name: 'DOCUMENT_CHUNK_OVERLAP'
          value: string(documentChunkOverlap)
        } 
        {
          name:'BlobTriggerConnection__blobServiceUri'
          value:blob_uri
        }
        {
          name:'BlobTriggerConnection__queueServiceUri'
          value:queue_uri
        }
        {
          name:'BlobTriggerConnection__serviceUri'
          value:blob_uri
        }
        {
          name:'BlobTriggerConnection__credential'
          value:'managedidentity'
        }
        {
          name:'BlobTriggerConnection__clientId'
          value: managedIdentity.properties.clientId
        }
      ]
       linuxFxVersion: 'PYTHON|3.11'
       alwaysOn: true
       
    }
  }
}

resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2021-06-01'  existing =  {
  name: logAnalyticsWorkspaceName
}

resource diagnosticSettingsAPI 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: '${functionAppName}-diagnostic'
  scope: functionApp
  properties: {
    workspaceId: logAnalyticsWorkspace.id
    logs: [
      {
        category: 'FunctionAppLogs'
        enabled: true
        retentionPolicy: {
          enabled: false
          days: 0
        }
      }
      
    ]
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
        retentionPolicy: {
          enabled: false
          days: 0
        }
      }
    ]
  }
}

output functionAppId string = functionApp.id
output functionAppName string = functionAppName
