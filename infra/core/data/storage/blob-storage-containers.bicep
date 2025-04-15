param storageAccountName string


resource storageAcct 'Microsoft.Storage/storageAccounts@2023-05-01' existing = {
  name: storageAccountName
}

resource blobServices 'Microsoft.Storage/storageAccounts/blobServices@2023-01-01' = {
  parent: storageAcct
  name: 'default'
}

resource loadContainer 'Microsoft.Storage/storageAccounts/blobServices/containers@2023-04-01' = {
  parent: blobServices
  name: 'load'
}

resource dataContainer 'Microsoft.Storage/storageAccounts/blobServices/containers@2023-04-01' = {
  parent: blobServices
  name: 'data'
}

resource completedContainer 'Microsoft.Storage/storageAccounts/blobServices/containers@2023-04-01' = {
  parent: blobServices
  name: 'completed'
}


