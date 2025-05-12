@description('Name of the Azure Key Vault used to store secrets and configuration values')
param keyVaultName string

@description('Name of the User Assigned Managed Identity to assign to deployed services')
param managedIdentityName string

@description('Azure region where all resources will be deployed (e.g., "eastus")')
param location string


module managedIdentity 'managed-identity.bicep' = {
  name: 'managed-identity'
  params: {
    name: managedIdentityName
    location: location
  }
}

module keyVault 'keyvault.bicep' = {
  name: 'keyVault'
  params: {
    location: location
    keyVaultName: keyVaultName
  }
}


module securiyRoles 'security-roles.bicep' = { 
  name:'securiyRoles'
  params: {
    keyVaultName: keyVaultName
    managedIdentityName: managedIdentityName
  }
  dependsOn: [keyVault,managedIdentity]
}


output managedIdentityName string = managedIdentity.outputs.managedIdentityName
output managedIdentityId string = managedIdentity.outputs.managedIdentityId
output keyVaultID string = keyVault.outputs.keyVaultId
output keyVaultName string = keyVaultName
output keyVaultUri string = keyVault.outputs.keyVaultUri
