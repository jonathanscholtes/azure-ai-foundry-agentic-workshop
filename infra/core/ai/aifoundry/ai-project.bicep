@description('Azure region of the deployment')
param location string

@description('AI project name')
param aiProjectName string

param aiProjectFriendlyName string

@description('AI project description')
param aiProjectDescription string

param aiHubResourceId string

resource aiProject 'Microsoft.MachineLearningServices/workspaces@2023-08-01-preview' = {
  name: aiProjectName
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    friendlyName: aiProjectFriendlyName
    description: aiProjectDescription
    hbiWorkspace: false  
    hubResourceId: aiHubResourceId
  }
  kind: 'Project'

}



