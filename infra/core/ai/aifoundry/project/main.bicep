param location string
param aiHubName string
param numberComputeInstances int
param aiProjectName string
param resourceToken string
param identityName string
param environmentName string

@description('Name for Ai Search connection.')
param aiSearchConnectionName string

@description('Name for ACS connection.')
param aoaiConnectionName string

param aiHubResourceId string

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
