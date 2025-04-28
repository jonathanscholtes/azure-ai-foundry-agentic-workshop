@description('Name of the Container App')
param containerAppBaseName string

@description('Azure region for deployment')
param location string

@description('Name of the User Assigned Managed Identity')
param managedIdentityName string

@description('Name of the Log Analytics Workspace')
param logAnalyticsWorkspaceName string


@description('Name of the Azure Container Registry')
param containerRegistryName string

param searchServiceEndpoint string


param OpenAIEndPoint string

param openAPIEndpoint string



resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2021-06-01' existing = {
  name: logAnalyticsWorkspaceName
}


resource managedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' existing = {
  name: managedIdentityName
}

resource containerRegistry 'Microsoft.ContainerRegistry/registries@2024-11-01-preview' existing = {
  name: containerRegistryName
}

// Container App Environment
resource containerAppEnv 'Microsoft.App/managedEnvironments@2023-05-01' = {
  name: 'cae-${containerAppBaseName}'
  location: location
  properties: {
    appLogsConfiguration: {
      destination: 'log-analytics'
      logAnalyticsConfiguration: {
        customerId: logAnalyticsWorkspace.properties.customerId
        sharedKey: listKeys(logAnalyticsWorkspace.id, logAnalyticsWorkspace.apiVersion).primarySharedKey
      }
    }
  }
}

// Weather Container App
resource mcpApp 'Microsoft.App/containerApps@2023-05-01' = {
  name: 'ca-mcp-${containerAppBaseName}'
  location: location
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${managedIdentity.id}': {}
    }
  }
  properties: {
    managedEnvironmentId: containerAppEnv.id
    configuration: {
      activeRevisionsMode: 'Single'
      ingress: {
        external: true
        targetPort: 80
        transport: 'auto'
      }
      registries: [
        {
          server: containerRegistry.properties.loginServer
          identity: managedIdentity.id
           
        }
      ]
    }
    template: {
     containers: [
        {
          name: 'nginx-gateway'
          image: '${containerRegistry.properties.loginServer}/nginx-mcp-gateway:latest'
        }
        {
          name: 'weather'
          image: '${containerRegistry.properties.loginServer}/weather-mcp:latest'
          env: [
            { name: 'SERVICE_NAME', value: 'weather' }
            { name: 'MCP_PORT', value: '8081' }
          ]
        }
        {
          name: 'search'
          image: '${containerRegistry.properties.loginServer}/search-mcp:latest'
          env: [
            { name: 'SERVICE_NAME', value: 'search' }
            { name: 'MCP_PORT', value: '8082' }
            {
              name: 'AZURE_AI_SEARCH_ENDPOINT'
              value: searchServiceEndpoint
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
            {name:'AZURE_AI_SEARCH_INDEX'
          value:'workshop-index'}
          {
            name: 'AZURE_CLIENT_ID'
            value: managedIdentity.properties.clientId
          } 
          ]
        }
        {
          name: 'energy'
          image: '${containerRegistry.properties.loginServer}/energy-mcp:latest'
          env: [
            { name: 'SERVICE_NAME', value: 'weather' }
            { name: 'MCP_PORT', value: '8083' }
            { name: 'OPENAPI_URL', value: openAPIEndpoint }
          ]
        }
      ]
    }
  }
}
