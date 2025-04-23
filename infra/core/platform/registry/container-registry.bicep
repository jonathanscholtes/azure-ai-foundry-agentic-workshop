param containerRegistryName string
param location string

@description('The name of the user-assigned managed identity used by the container app.')
param managedIdentityName string


resource managedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' existing = {
  name: managedIdentityName
}

resource containerRegistry 'Microsoft.ContainerRegistry/registries@2024-11-01-preview' = {
  name: containerRegistryName
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    adminUserEnabled: true
    policies: {
      quarantinePolicy: { status: 'disabled' }
      trustPolicy: { type: 'Notary', status: 'disabled' }
      retentionPolicy: { days: 7, status: 'disabled' }
      exportPolicy: { status: 'enabled' }
      azureADAuthenticationAsArmPolicy: { status: 'enabled' }
      softDeletePolicy: { retentionDays: 7, status: 'disabled' }
    }
    encryption: { status: 'disabled' }
    dataEndpointEnabled: false
    publicNetworkAccess: 'Enabled'  
    networkRuleBypassOptions: 'AzureServices'
    zoneRedundancy: 'Disabled'
    anonymousPullEnabled: false
    metadataSearch: 'Disabled'
  }
}


resource acrBuildCustomRole 'Microsoft.Authorization/roleDefinitions@2022-04-01' = {
  name: guid(containerRegistryName, 'ACRBuildCustomRole')
  properties: {
    roleName: 'ACR Build Custom Role'
    description: 'Custom role for building and pushing images to ACR'
    assignableScopes: [
      containerRegistry.id
    ]
    permissions: [
      {
        actions: [
          'Microsoft.ContainerRegistry/registries/push/write'
          'Microsoft.ContainerRegistry/registries/pull/read'
          'Microsoft.ContainerRegistry/registries/read'
          'Microsoft.ContainerRegistry/registries/write'
          'Microsoft.ContainerRegistry/registries/listBuildSourceUploadUrl/action'
          'Microsoft.ContainerRegistry/registries/scheduleRun/action'
          'Microsoft.ContainerRegistry/registries/runs/listLogSasUrl/action'
        ]
        notActions: []
        dataActions: []
        notDataActions: []
      }
    ]
  }
}


// Assign the custom role to the managed identity
resource roleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(containerRegistryName, managedIdentity.id, acrBuildCustomRole.id)
  scope: containerRegistry
  properties: {
    roleDefinitionId: acrBuildCustomRole.id
    principalId: managedIdentity.properties.principalId
    principalType: 'ServicePrincipal'
  }
}

output containerRegistryID string = containerRegistry.id
output containerRegistryName string = containerRegistry.name
