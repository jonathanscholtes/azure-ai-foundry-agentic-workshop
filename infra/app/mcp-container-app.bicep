@description('Base name of the Azure Container App to be deployed')
param containerAppBaseName string

@description('Azure region where the resources will be deployed (e.g., "eastus")')
param location string

@description('Name of the User Assigned Managed Identity to be used by the Container App')
param managedIdentityName string

@description('Name of the Log Analytics Workspace for monitoring and diagnostics')
param logAnalyticsWorkspaceName string

@description('Name of the Azure Container Registry for storing and managing container images')
param containerRegistryName string

@description('Endpoint URL of the Azure Cognitive Search service (e.g., https://<service>.search.windows.net)')
param searchServiceEndpoint string

@description('Endpoint URL of the Azure OpenAI resource (e.g., https://<resource>.openai.azure.com/)')
param OpenAIEndPoint string

@description('URL of the OpenAPI (Swagger) endpoint used by the application or agents')
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
