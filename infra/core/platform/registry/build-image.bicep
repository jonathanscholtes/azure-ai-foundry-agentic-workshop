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

resource buildImage 'Microsoft.Resources/deploymentScripts@2020-10-01' = {
  name: 'buildAcrImageScript'
  location: location
  kind: 'AzureCLI'
  properties: {
    azCliVersion: '2.53.0'
    scriptContent: '''
      az acr build \
        --registry $containerRegistryName \
        --image $imageName:latest \
        --file Dockerfile \
        --context https://github.com/${org}/${repo}.git#${branch}:src/MCP
    '''
    environmentVariables: [
      { name: 'containerRegistryName'
       value: containerRegistryName }
      { name: 'imageName'
       value: imageName }
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
