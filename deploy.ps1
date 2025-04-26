param (
    [string]$Subscription,
    [string]$Location = "eastus2",
    [string]$ResourceGroupName
)


# Variables
$projectName = "foundry"
$environmentName = "lab"
$timestamp = Get-Date -Format "yyyyMMddHHmmss"

function Get-RandomAlphaNumeric {
    param (
        [int]$Length = 12,
        [string]$Seed
    )

    $base62Chars = "abcdefghijklmnopqrstuvwxyz123456789"

    # Convert the seed string to a hash (e.g., MD5)
    $md5 = [System.Security.Cryptography.MD5]::Create()
    $seedBytes = [System.Text.Encoding]::UTF8.GetBytes($Seed)
    $hashBytes = $md5.ComputeHash($seedBytes)

    # Use bytes from hash to generate characters
    $randomString = ""
    for ($i = 0; $i -lt $Length; $i++) {
        $index = $hashBytes[$i % $hashBytes.Length] % $base62Chars.Length
        $randomString += $base62Chars[$index]
    }

    return $randomString
}

# Example usage: Generate a resource token based on a seed
$resourceToken = Get-RandomAlphaNumeric -Length 12 -Seed $timestamp


# Clear account context and configure Azure CLI settings
az account clear
az config set core.enable_broker_on_windows=false
az config set core.login_experience_v2=off

# Login to Azure
az login 
az account set --subscription $Subscription

# If no resource group name is passed, generate one
if (-not $ResourceGroupName) {
    $rgName = "rg-$projectName-$environmentName-$Location-$resourceToken"
} else {
    $rgName = $ResourceGroupName
}

# Check if the resource group exists
$resourceGroup = az group show --name $rgName --query "name" --output tsv

if (-not $resourceGroup) {
    Write-Host "Resource group '$rgName' does not exist. Creating it..."
    az group create --name $rgName --location $Location
} else {
    Write-Host "Resource group '$rgName' already exists."
}



# Step 1: Deploy Infrastructure
$deploymentNameInfra = "deployment-infra-$resourceToken"
$templateFile = "infra/main.bicep"
$deploymentOutput = az deployment sub create `
    --name $deploymentNameInfra `
    --location $Location `
    --template-file $templateFile `
    --parameters `
        environmentName=$environmentName `
        projectName=$projectName `
        location=$Location `
        resourceGroupName=$rgName `
        resourceToken=$resourceToken `
        projectConfig=@./project_resource_config.json `
    --query "properties.outputs"


# Parse the deployment output to get app names and resource group
$deploymentOutputJsonInfra = $deploymentOutput | ConvertFrom-Json
$managedIdentityName = $deploymentOutputJsonInfra.managedIdentityName.value
$appServicePlanName = $deploymentOutputJsonInfra.appServicePlanName.value
$storageAccountName = $deploymentOutputJsonInfra.storageAccountName.value
$logAnalyticsWorkspaceName = $deploymentOutputJsonInfra.logAnalyticsWorkspaceName.value
$applicationInsightsName = $deploymentOutputJsonInfra.applicationInsightsName.value
$keyVaultUri = $deploymentOutputJsonInfra.keyVaultUri.value
$OpenAIEndPoint = $deploymentOutputJsonInfra.OpenAIEndPoint.value
$searchServiceEndpoint = $deploymentOutputJsonInfra.searchServiceEndpoint.value 
$containerRegistryName = $deploymentOutputJsonInfra.containerRegistryName.value


Write-Host "=== Building Images for MCP Server ==="
Write-Host "Using ACR: $containerRegistryName"
Write-Host "Resource Group: $rgName`n"

# Define image names and paths
$images = @(
    @{ name = "weather-mcp"; path = ".\src\MCP\weather" },
    @{ name = "search-mcp"; path = ".\src\MCP\search" },
    @{ name = "energy-mcp"; path = ".\src\MCP\energy" },
    @{ name = "nginx-mcp-gateway"; path = ".\src\MCP\nginx" }
)

# Build images
foreach ($image in $images) {
    Write-Host "Building image '$($image.name):latest' from '$($image.path)'..."
    Write-Host "az acr build --resource-group $rgName --registry $containerRegistryName --image $($image.name):latest $image.path"

    az acr build `
        --resource-group $rgName `
        --registry $containerRegistryName `
        --image "$($image.name):latest" `
        $image.path
}


# Step 2: Deploy Apps
$deploymentNameApps = "deployment-apps-$resourceToken"
$appsTemplateFile = "infra/app/main.bicep"
$deploymentOutputApps = az deployment sub create  `
    --name $deploymentNameApps `
    --location $Location `
    --template-file $appsTemplateFile `
    --parameters `
        environmentName=$environmentName `
        projectName=$projectName `
        location=$Location `
        resourceGroupName=$rgName `
        resourceToken=$resourceToken `
        managedIdentityName=$managedIdentityName `
        logAnalyticsWorkspaceName=$logAnalyticsWorkspaceName `
        appInsightsName=$applicationInsightsName `
        containerRegistryName=$containerRegistryName `
        appServicePlanName=$appServicePlanName `
        storageAccountName=$storageAccountName `
        keyVaultUri=$keyVaultUri `
        OpenAIEndPoint=$OpenAIEndPoint `
        searchServiceEndpoint=$searchServiceEndpoint `
    --query "properties.outputs"


$deploymentOutputJson = $deploymentOutputApps | ConvertFrom-Json
$functionAppName = $deploymentOutputJson.functionAppName.value
$apiAppName = $deploymentOutputJson.apiAppName.value


Write-Host "Waiting for App Services before pushing code"

$waitTime = 180  # Total wait time in seconds 180

# Display counter
for ($i = $waitTime; $i -gt 0; $i--) {
    Write-Host "`rWaiting: $i seconds remaining..." -NoNewline
    Start-Sleep -Seconds 1
}

Write-Host "`rWait time completed!" 

Set-Location -Path .\scripts


# Deploy Azure Function for Loading AI Search Indexes from PDFs 
Write-Output "*****************************************"
Write-Output "Deploying Function Application from scripts"
Write-Output "If timeout occurs, rerun the following command from scripts:"
Write-Output ".\deploy_functionapp.ps1 -functionAppName $functionAppName -resourceGroupName $rgName"
& .\deploy_functionapp.ps1 -functionAppName $functionAppName -resourceGroupName $rgName


# Deploy Python FastAPI for OpenAPI and GraphQL
Write-Output "*****************************************"
Write-Output "Deploying Python FastAPI from scripts"
Write-Output "If timeout occurs, rerun the following command from scripts:"
Write-Output ".\deploy_api.ps1 -apiAppName $apiAppName -resourceGroupName $rgName -pythonAppPath ..\src\api"
& .\deploy_api.ps1 -apiAppName $apiAppName -resourceGroupName $rgName -pythonAppPath "..\src\api"


Set-Location -Path ..

Write-Output "Deployment Complete"