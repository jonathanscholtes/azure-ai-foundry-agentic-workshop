param projectName string
param resourceToken string
param location string
param identityName string



var storageAccountName ='sa${projectName}${resourceToken}'


module storage 'storage/main.bicep' = {
name: 'storage'
params:{
  identityName:identityName
   location:location
   storageAccountName:storageAccountName

}
}


output storageAccountName string = storageAccountName
output storageAccountId string = storage.outputs.storageAccountId

