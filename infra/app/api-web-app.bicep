param appServicePlanName string
param webAppName string
param location string
param StorageAccountName string
param identityName string
param logAnalyticsWorkspaceName string
param appInsightsName string
param keyVaultUri string


resource appServicePlan 'Microsoft.Web/serverfarms@2022-03-01' existing = {
  name: appServicePlanName
}

resource appInsights 'Microsoft.Insights/components@2020-02-02' existing = {
  name: appInsightsName
}

resource managedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' existing= {
  name: identityName
}


resource webApp 'Microsoft.Web/sites@2022-03-01' = {
  name: webAppName
  location: location
    identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${managedIdentity.id}': {}
    }
  }
  properties: {
    serverFarmId: appServicePlan.id
    siteConfig: {
      
      linuxFxVersion: 'PYTHON|3.11'
      appCommandLine: 'gunicorn -w 2 -k uvicorn.workers.UvicornWorker -b 0.0.0.0:8000 main:app'      
      appSettings: [
        {
          name: 'SCM_DO_BUILD_DURING_DEPLOYMENT'
          value: '1'
        }   
        {
          name: 'SERVER_URL'
          value: 'https://${webAppName}.azurewebsites.net'
        }
        {
          name: 'AZURE_STORAGE_CONTAINER'
          value: 'data'
        }
        {
          name: 'AZURE_STORAGE_ACCOUNT'
          value: StorageAccountName
        } 
        {
          name: 'AZURE_CLIENT_ID'
          value: managedIdentity.properties.clientId
        } 
        {
          name: 'APPINSIGHTS_INSTRUMENTATIONKEY'
          value: appInsights.properties.InstrumentationKey
        }
        {
          name: 'ApplicationInsightsAgent_EXTENSION_VERSION'
          value: '~3'
        }
        {
          name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
          value: appInsights.properties.ConnectionString
        }    
        {
          name:'KeyVaultUri'
          value:keyVaultUri
        }
        {
          // Temp to fix: ImportError: cannot import name 'AccessTokenInfo' from 'azure.core.credentials'
          name:'WEBSITE_PIN_SYSTEM_IMAGES'
          value:'application_insights_python|applicationinsights/auto-instrumentation/python:1.0.0b18'
        }
        
      
      ]
      alwaysOn: true
    }
    publicNetworkAccess: 'Enabled'
    
  }
 
}


resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2021-06-01'  existing =  {
  name: logAnalyticsWorkspaceName
}

resource diagnosticSettingsAPI 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: '${webAppName}-diagnostic'
  scope: webApp
  properties: {
    workspaceId: logAnalyticsWorkspace.id
    logs: [
      {
        category: 'AppServiceHTTPLogs'
        enabled: true
        retentionPolicy: {
          enabled: false
          days: 0
        }
      }
      {
        category: 'AppServiceConsoleLogs'
        enabled: true
        retentionPolicy: {
          enabled: false
          days: 0
        }
      }
      {
        category: 'AppServiceAppLogs'
        enabled: true
        retentionPolicy: {
          enabled: false
          days: 0
        }
      }
    ]
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
        retentionPolicy: {
          enabled: false
          days: 0
        }
      }
    ]
  }
}


output webAppNameURL string = 'https://${webAppName}.azurewebsites.net'
output webAppId string = webApp.id
output webAppName string = webAppName
