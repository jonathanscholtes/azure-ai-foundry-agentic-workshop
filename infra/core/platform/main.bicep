param containerRegistryName string
param location string

@description('The name of the user-assigned managed identity used by the container app.')
param managedIdentityName string


module containerregistry 'registry/container-registry.bicep' = {
  name: 'containerregistry'
  params: {
    containerRegistryName: containerRegistryName
    location: location
    managedIdentityName:managedIdentityName
  }

}


module buildImage 'registry/build-image.bicep' = {
  name: 'buildImage'
  params:{ 
     containerRegistryName:containerregistry.outputs.containerRegistryName
      location:location 
      managedIdentityName:managedIdentityName
  }
  dependsOn:[containerregistry]
}

output containerRegistryID string = containerregistry.outputs.containerRegistryID
output containerRegistryName string = containerregistry.outputs.containerRegistryName
