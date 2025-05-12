param keyVaultName string 
param searchServicename string


var kv_AzureAISearchKey = 'AzureAISearchKey'

resource keyVault 'Microsoft.KeyVault/vaults@2022-07-01' existing = {
  name: keyVaultName
}


resource search 'Microsoft.Search/searchServices@2021-04-01-preview' existing = {
  name: searchServicename
}

resource keyVaultSecret 'Microsoft.KeyVault/vaults/secrets@2021-10-01' = {
  name: '${keyVault.name}/${kv_AzureAISearchKey}'
  properties: {
    value: listAdminKeys(search.id, search.apiVersion).primaryKey
  }
}


output keyVaultUri string = keyVault.properties.vaultUri
output searchServiceEndpoint string = 'https://${search.name}.search.windows.net/'
output AzureAISearchKey string = '@Microsoft.KeyVault(VaultName=${keyVaultName};SecretName=${kv_AzureAISearchKey})'
