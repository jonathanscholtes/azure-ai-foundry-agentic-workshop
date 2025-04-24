param containerRegistryName string
param location string



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


output containerRegistryID string = containerRegistry.id
output containerRegistryName string = containerRegistry.name
