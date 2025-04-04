
param location string
param aiHubName string
param managedIdentityName string
param numberComputeInstances int
param projectName string
param environmentName string

module devCompute 'ai-dev-compute.bicep' = [for x in range(1, numberComputeInstances): {
  name:'devCompute-${x}'
  params: {
    aiHubName:aiHubName
    location:location
    managedIdentityName:managedIdentityName
    computeName: '${projectName}-${x}-${environmentName}'
    generatedAppName: 'generative-ai-app-${guid(projectName)}'
  }
}]
