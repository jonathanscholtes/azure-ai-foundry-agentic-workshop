@description('Name of the Azure Cognitive Search service instance')
param searchServicename string

@description('Name of the User Assigned Managed Identity to assign to deployed services')
param managedIdentityName string

@description('Azure region where all resources will be deployed (e.g., "eastus")')
param location string

module search_service 'search-service.bicep' = { 
 name: 'search_service'
 params: { 
   name: searchServicename
   location:location
    semanticSearch: 'standard'
    disableLocalAuth: false
    publicNetworkAccess: 'enabled'
    managedIdentityName:managedIdentityName
 }
}

module search_roles 'search-roles.bicep' = { 
  name: 'search_roles'
  params: { 
    identityName: managedIdentityName
     searchServicename: searchServicename
  }
  dependsOn:[search_service]
}


output searchServiceId string = search_service.outputs.searchServiceId
output searchServiceEndpoint string = search_service.outputs.searchServiceEndpoint

