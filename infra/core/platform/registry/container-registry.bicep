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


var acrPullRole = resourceId('Microsoft.Authorization/roleDefinitions', '7f951dda-4ed3-4680-a7ca-43fe172d538d')
var acrPushRole = resourceId('Microsoft.Authorization/roleDefinitions', '8311e382-0749-4cb8-b61a-304f252e45ec')
var contributorRole = resourceId('Microsoft.Authorization/roleDefinitions', 'b24988ac-6180-42a0-ab88-20f7382dd24c') 



resource rolePullAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(containerRegistry.id, managedIdentity.id, acrPullRole)
  scope: containerRegistry
  properties: {
    roleDefinitionId: acrPullRole
    principalId: managedIdentity.properties.principalId
    principalType: 'ServicePrincipal'
  }
}


resource rolePushAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(containerRegistry.id, managedIdentity.id, acrPushRole)
  scope: containerRegistry
  properties: {
    roleDefinitionId: acrPushRole
    principalId: managedIdentity.properties.principalId
    principalType: 'ServicePrincipal'
  }
}

resource roleContributorAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(containerRegistry.id, managedIdentity.id, contributorRole)
  scope: containerRegistry
  properties: {
    roleDefinitionId: contributorRole
    principalId: managedIdentity.properties.principalId
    principalType: 'ServicePrincipal'
  }
}

output containerRegistryID string = containerRegistry.id
output containerRegistryName string = containerRegistry.name
