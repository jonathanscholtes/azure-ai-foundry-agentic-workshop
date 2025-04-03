param containerRegistryName string
param location string




module containerregistry 'registry/container-registry.bicep' = {
  name: 'containerregistry'
  params: {
    containerRegistryName: containerRegistryName
    location: location
  }

}


output containerRegistryID string = containerregistry.outputs.containerRegistryID
output containerRegistryName string = containerRegistryName
