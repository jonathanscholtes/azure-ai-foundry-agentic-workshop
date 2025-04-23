@description('The name of the container app being deployed.')
param containerAppName string

@description('The Azure region where the container app will be deployed.')
param location string

@description('The endpoint for the Azure AI Search service.')
param searchServiceEndpoint string

@description('The name of the user-assigned managed identity used by the container app.')
param managedIdentityName string

@description('The name of the Azure Container Registry where the app image is stored.')
param containerRegistryName string

@description('The name of the Log Analytics Workspace used for diagnostics.')
param logAnalyticsWorkspaceName string

resource managedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' existing = {
  name: managedIdentityName
}

resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2021-06-01' existing = {
  name: logAnalyticsWorkspaceName
}

resource containerAppEnvironment 'Microsoft.App/managedEnvironments@2025-01-01' = {
  name: 'cae-${containerAppName}'
  location: location
  sku: {
    name: 'Consumption'
  }
  properties: {
    appLogsConfiguration: {
      destination: 'log-analytics'
      logAnalyticsConfiguration: {
        customerId: logAnalyticsWorkspace.properties.customerId
        sharedKey: logAnalyticsWorkspace.listKeys().primarySharedKey
      }
    }
  }
}

resource containerApp 'Microsoft.App/containerApps@2025-01-01' = {
  name: 'ca-${containerAppName}'
  location: location
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${managedIdentity.id}': {}
    }
  }
  properties: {
    environmentId: containerAppEnvironment.id
    configuration: {
      ingress: {
        external: true
        targetPort: 8000
      }
      registries: [
        {
          server: '${containerRegistryName}.azurecr.io'
          identity: managedIdentity.id
        }
      ]
    }
    template: {
      containers: [
        {
          name: 'main-container'
          image: '${containerRegistryName}.azurecr.io/mcpservers:latest'
          resources: {
            cpu: 1
            memory: '2Gi'
          } 
          env: [
            {
              name: 'AZURE_AI_SEARCH_ENDPOINT'
              value: searchServiceEndpoint
            }
          ]
        }
      ]
      revisionSuffix: 'v1'
      scale: {
        minReplicas: 1
        maxReplicas: 2
      }
    }
  }
}
