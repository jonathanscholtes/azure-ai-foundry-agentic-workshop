metadata description = 'Creates an Azure AI Search instance.'
param name string
param location string = resourceGroup().location

param sku object = {
  name: 'standard'
}

param disableLocalAuth bool = false
param disabledDataExfiltrationOptions array = []
param encryptionWithCmk object = {
  enforcement: 'Unspecified'
}
@allowed([
  'default'
  'highDensity'
])
param hostingMode string = 'default'
param networkRuleSet object = {
  bypass: 'None'
  ipRules: []
}
param partitionCount int = 1
@allowed([
  'enabled'
  'disabled'
])
param publicNetworkAccess string = 'enabled'
param replicaCount int = 1
@allowed([
  'disabled'
  'free'
  'standard'
])
param semanticSearch string = 'disabled'

param managedIdentityName string

resource managedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' existing= {
  name: managedIdentityName
}

resource search 'Microsoft.Search/searchServices@2021-04-01-preview' = {
  name: name
  location: location
  // The free tier does not support managed identity
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${managedIdentity.id}': {}
    }
  }
  properties: {
    authOptions: {
      aadOrApiKey: {
        aadAuthFailureMode: 'http401WithBearerChallenge'
      }
    }
    disableLocalAuth: disableLocalAuth
    disabledDataExfiltrationOptions: disabledDataExfiltrationOptions
    encryptionWithCmk: encryptionWithCmk
    hostingMode: hostingMode
    partitionCount: partitionCount
    publicNetworkAccess: publicNetworkAccess
    replicaCount: replicaCount
    semanticSearch: semanticSearch
    networkRuleSet:networkRuleSet
  }
  sku: sku
}

output searchServiceId string = search.id
output searchServiceEndpoint string = 'https://${name}.search.windows.net/'
