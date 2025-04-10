param projectName string
param environmentName string
param resourceToken string
param location string


var appServicePlanName = 'asp-lnx-${projectName}-${environmentName}-${resourceToken}'

module appServicePlanLinux 'app-service.bicep' = {
  name: 'appServicePlanLinux'
  params: {
    location:location
    name:  appServicePlanName
    linuxMachine: true
  }
}


output appServicePlanName string = appServicePlanName
