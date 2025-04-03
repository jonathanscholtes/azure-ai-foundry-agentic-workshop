param storageAccountName string
param location string
param identityName string


module storageAccount 'blob-storage-account.bicep' ={
  name: 'storageAccount'
  params:{
     location: location
     storageAccountName:storageAccountName
  }
}

module storageContainers 'blob-storage-containers.bicep' = {
  name: 'storageContainers'
  params: {
    storageAccountName: storageAccountName
  }
  dependsOn:[storageAccount]
}

module storageRoles 'blob-storage-roles.bicep' = {
  name: 'storageRoles'
  params:{
    identityName:identityName
     storageAccountName:storageAccountName
  }
  dependsOn:[storageAccount]
}


output storageAccountId string = storageAccount.outputs.storageAccountId
