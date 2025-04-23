@description('Name of the Azure Container Registry')
param containerRegistryName string

@description('Deployment location')
param location string

@description('Name of the image to build and push')
param imageName string = 'mcpservers'

@description('GitHub organization or user name')
param org string = 'jonathanscholtes'

@description('GitHub repository name')
param repo string = 'azure-ai-foundry-agentic-workshop'

@description('Git branch containing the Docker context')
param branch string = 'main'

@description('The name of the user-assigned managed identity used by the container app.')
param managedIdentityName string


resource managedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' existing = {
  name: managedIdentityName
}


resource buildImage 'Microsoft.Resources/deploymentScripts@2020-10-01' = {
  name: 'buildAcrImageScript'
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${managedIdentity.id}': {}
    }
  }
  location: location
  kind: 'AzureCLI'
  properties: {
    azCliVersion: '2.53.0'
    scriptContent: '''
      echo "Building image:"
      git clone --branch ${branch} https://github.com/${org}/${repo}.git
      cd ${repo}/src/MCP
      az acr build \
        --registry ${containerRegistryName} \
        --image ${containerRegistryName}.azurecr.io/${imageName}:${imageTag} \
        --file Dockerfile \
        .
    '''
    environmentVariables: [
      { name: 'containerRegistryName'
       value: containerRegistryName }
      { name: 'imageName'
       value: imageName }
       { name: 'imageTag'
       value: 'latest' }
      { name: 'org'
       value: org }
      { name: 'repo'
       value: repo }
      { name: 'branch'
       value: branch }
    ]
    cleanupPreference: 'OnSuccess'
    retentionInterval: 'P1D'
    timeout: 'PT30M'
  }
}
