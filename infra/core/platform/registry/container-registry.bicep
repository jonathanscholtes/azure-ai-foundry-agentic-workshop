param containerRegistryName string
param location string

@description('The name of the user-assigned managed identity used by the container app.')
param managedIdentityName string


resource managedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' existing = {
  name: managedIdentityName
}

var acrPullRole = resourceId('Microsoft.Authorization/roleDefinitions', '7f951dda-4ed3-4680-a7ca-43fe172d538d')


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


@description('This allows the managed identity of the container app to access the registry, note scope is applied to the wider ResourceGroup not the ACR')
resource roleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(resourceGroup().id, managedIdentity.id, acrPullRole)
  properties: {
    roleDefinitionId: acrPullRole
    principalId: managedIdentity.properties.principalId
    principalType: 'ServicePrincipal'
  }
}

output containerRegistryID string = containerRegistry.id
