@description('Azure region where all resources will be deployed (e.g., "eastus")')
param location string

@description('Name of the Azure AI Hub to be created or referenced')
param aiHubName string

@description('Number of compute instances to allocate for the project')
param numberComputeInstances int

@description('Name of the AI project to be created within the AI Hub')
param aiProjectName string

@description('Token or string used to uniquely identify this resource deployment (e.g., build ID, commit hash)')
param resourceToken string

@description('Name of the User Assigned Managed Identity to assign to deployed services')
param identityName string

@description('Name representing the deployment environment (e.g., "dev", "test", "prod", "lab")')
param environmentName string

@description('Name for AI Search connection')
param aiSearchConnectionName string

@description('Name for Azure OpenAI connection')
param aoaiConnectionName string

@description('Resource ID of the Azure AI Hub instance')
param aiHubResourceId string

@description('Array of user configuration objects to be assigned roles or permissions in the deployment')
param users array = []


module aiProject 'ai-project.bicep' =  {
  name: 'aiProject-${aiProjectName}'
  params: {
    aiHubResourceId: aiHubResourceId
    location: location
    aiProjectName: 'proj-${aiProjectName}-${environmentName}-${resourceToken}'
    aiProjectFriendlyName: 'AI Workshop Project - ${aiProjectName}'
    aiProjectDescription: 'Project for Workshop'
    users: users
  }
}

module aiCompute 'compute/main.bicep' = if (numberComputeInstances > 0){
  name: 'aiCompute-${aiProjectName}'
  params: { 
    aiHubName:aiHubName
    numberComputeInstances:numberComputeInstances
    projectName: aiProjectName
    resourceToken:resourceToken
    environmentName:environmentName
    location:location
    managedIdentityName:identityName
  }
  dependsOn:[aiProject]
  }



  module addCapabilityHost 'add-capability-host.bicep' = {
    name: 'addCapabilityHost-${aiProjectName}'
    params: {
      capabilityHostName: 'agent-${aiProjectName}-${resourceToken}'
      aiProjectName: aiProject.outputs.aiProjectName
      aiSearchConnectionName: aiSearchConnectionName
      aoaiConnectionName: aoaiConnectionName
    }
  }
