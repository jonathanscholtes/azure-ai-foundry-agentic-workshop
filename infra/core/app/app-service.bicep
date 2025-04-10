param name string
param location string
param linuxMachine bool

resource appServicePlan 'Microsoft.Web/serverfarms@2022-03-01' = {
  name: name
  location: location
  sku: {
    name: 'B2'
    tier: 'Basic'
    size: 'B2'
   family: 'B'
    capacity: 2
  }
  properties: {
    reserved: linuxMachine
    isXenon: false
    hyperV: false
  }
}

output appServicePlanName string = appServicePlan.name

