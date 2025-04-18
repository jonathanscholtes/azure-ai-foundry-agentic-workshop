
@description('AI project name')
param aiProjectName string

@description('Name for Ai Search connection.')
param aiSearchConnectionName string

@description('Name for ACS connection.')
param aoaiConnectionName string

@description('Name for capabilityHost.')
param capabilityHostName string 

var storageConnections = ['${aiProjectName}/workspaceblobstore']
var aiSearchConnection = ['${aiSearchConnectionName}']
var aiServiceConnections = ['${aoaiConnectionName}']


resource aiProject 'Microsoft.MachineLearningServices/workspaces@2024-10-01-preview' existing = {
  name: aiProjectName
}



#disable-next-line BCP081
resource projectCapabilityHost 'Microsoft.MachineLearningServices/workspaces/capabilityHosts@2024-10-01-preview' = {
  name: '${aiProjectName}-${capabilityHostName}'
  parent: aiProject
  properties: {
    capabilityHostKind: 'Agents'
    aiServicesConnections: aiServiceConnections
    vectorStoreConnections: aiSearchConnection
    storageConnections: storageConnections
  }
}
