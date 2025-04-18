param location string
param aiHubName string
param computeName string
param managedIdentityName string
param generatedAppName string

resource aiHub 'Microsoft.MachineLearningServices/workspaces@2024-10-01-preview' existing = {
  name: aiHubName

}

resource managedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' existing = {
  name: managedIdentityName
}


resource compute 'Microsoft.MachineLearningServices/workspaces/computes@2025-01-01-preview' = {
  parent:aiHub
  name: computeName
  location: location
  identity: {
    type: ' UserAssigned'
    userAssignedIdentities: {
      '${managedIdentity.id}': {}
    }
  }
  properties: {
    disableLocalAuth: true
    computeType: 'ComputeInstance'
    computeLocation: location
    properties: {
      vmSize: 'Standard_E4ds_v4'
      applicationSharingPolicy: 'Shared'
      enableOSPatching: false
      releaseQuotaOnStop: false
      enableRootAccess: true
      enableSSO: true
      idleTimeBeforeShutdown: 'PT60M'
      customServices: [
        {
          type: 'docker'
          name: generatedAppName
          image: {
            type: 'azureml'
            reference: 'azureml://registries/azureml/environments/ai-studio-dev/versions/4'
          }
          environmentVariables: {
            AZUREAI_CI_CUSTOM_APP: {
              type: 'local'
              value: 'True'
            }
          }
          docker: {
            privileged: true
          }
          endpoints: [
            {
              protocol: 'http'
              name: 'connect'
              target: 9000
              published: 9000
            }
          ]
          volumes: []
          kernel: {
            argv: [
              'python'
              '-m'
              'ipykernel_launcher'
              '-f'
              '{connection_file}'
            ]
            displayName: generatedAppName
            language: 'python'
          }
        }
      ]
    }
  }
}
