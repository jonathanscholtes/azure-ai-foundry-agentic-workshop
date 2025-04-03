param storageAccountName string
param location string


resource storageAcct 'Microsoft.Storage/storageAccounts@2023-05-01' = {
  name: storageAccountName
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {
    allowSharedKeyAccess: true
    publicNetworkAccess: 'Enabled'
    allowBlobPublicAccess: false
  }
}

output storageAccountId string = storageAcct.id
