@description('Azure region of the deployment')
param location string

@description('AI project name')
param aiProjectName string

param aiProjectFriendlyName string

@description('AI project description')
param aiProjectDescription string

param aiHubResourceId string

param users array = []


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


resource roleAssignments 'Microsoft.Authorization/roleAssignments@2022-04-01' = [for user in users: {
  name: guid(aiProject.id, user.user)  
  properties: {
    principalId: user.objectId  
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '64702f94-c441-49e6-a78b-ef80e0188fee')  
    
  }
  scope:aiProject
}
]

output aiProjectName string = aiProject.name
