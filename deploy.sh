#!/bin/bash

# Usage: ./deploy.sh <subscription> [location] <dev_compute_instances> [resource_group_name]

location=${1:-eastus2}
resource_group_name=$2

# Variables
project_name="foundry"
environment_name="lab"




# Function to generate random alphanumeric string (base62)
generate_random_alphanumeric() {
    length=$1
    base62chars="abcdefghijklmnopqrstuvwxyz123456789"
    result=""
    
    for ((i = 0; i < length; i++)); do
        index=$(( RANDOM % ${#base62chars} ))
        result+=${base62chars:$index:1}
    done

    echo "$result"
}

# Generate resource token
resource_token=$(generate_random_alphanumeric 12)


# If no resource group name is passed, generate one
if [ -z "$resource_group_name" ]; then
    rg_name="rg-$project_name-$environment_name-$location-$resource_token"
else
    rg_name=$resource_group_name
fi

# Check if resource group exists
existing_rg=$(az group show --name "$rg_name" --query "name" --output tsv 2>/dev/null)

if [ -z "$existing_rg" ]; then
    echo "Resource group '$rg_name' does not exist. Creating it..."
    az group create --name "$rg_name" --location "$location"
else
    echo "Resource group '$rg_name' already exists."
fi

# Variables (make sure these are already set in your environment or passed in)
deploymentNameInfra="deployment-infra-$resourceToken"
templateFile="infra/main.bicep"

# Step 1: Deploy Infrastructure
deploymentOutput=$(az deployment sub create \
    --name "$deploymentNameInfra" \
    --location "$Location" \
    --template-file "$templateFile" \
    --parameters \
        environmentName="$environmentName" \
        projectName="$projectName" \
        location="$Location" \
        resourceGroupName="$rgName" \
        resourceToken="$resourceToken" \
        projectConfig="@./project_resource_config.json" \
    --query "properties.outputs" \
    --output json)

# Parse the deployment output to get app names and resource group
managedIdentityName=$(echo "$deploymentOutput" | jq -r '.managedIdentityName.value')
appServicePlanName=$(echo "$deploymentOutput" | jq -r '.appServicePlanName.value')
storageAccountName=$(echo "$deploymentOutput" | jq -r '.storageAccountName.value')
logAnalyticsWorkspaceName=$(echo "$deploymentOutput" | jq -r '.logAnalyticsWorkspaceName.value')
applicationInsightsName=$(echo "$deploymentOutput" | jq -r '.applicationInsightsName.value')
keyVaultUri=$(echo "$deploymentOutput" | jq -r '.keyVaultUri.value')
OpenAIEndPoint=$(echo "$deploymentOutput" | jq -r '.OpenAIEndPoint.value')
searchServiceEndpoint=$(echo "$deploymentOutput" | jq -r '.searchServiceEndpoint.value')
containerRegistryName=$(echo "$deploymentOutput" | jq -r '.containerRegistryName.value')
azureAISearchKey=$(echo "$deploymentOutput" | jq -r '.azureAISearchKey.value')

echo "=== Building Images for MCP Server ==="
echo "Using ACR: $containerRegistryName"
echo "Resource Group: $rgName"
echo

# Define image names and paths as an associative array of arrays
images=(
    "weather-mcp ./src/MCP/weather"
    "search-mcp ./src/MCP/search"
    "energy-mcp ./src/MCP/energy"
    "nginx-mcp-gateway ./src/MCP/nginx"
)

# Build images
for image_info in "${images[@]}"; do
    image_name=$(echo "$image_info" | awk '{print $1}')
    image_path=$(echo "$image_info" | awk '{print $2}')
    
    echo "Building image '${image_name}:latest' from '${image_path}'..."
    echo "az acr build --resource-group $rgName --registry $containerRegistryName --image ${image_name}:latest ${image_path}"

    az acr build \
        --resource-group "$rgName" \
        --registry "$containerRegistryName" \
        --image "${image_name}:latest" \
        "$image_path"
done

echo "=== Step 2: Deploy Apps ==="

deploymentNameApps="deployment-apps-$resourceToken"
appsTemplateFile="infra/app/main.bicep"

# Run the deployment
deploymentOutputApps=$(az deployment sub create \
    --name "$deploymentNameApps" \
    --location "$Location" \
    --template-file "$appsTemplateFile" \
    --parameters \
        environmentName="$environmentName" \
        projectName="$projectName" \
        location="$Location" \
        resourceGroupName="$rgName" \
        resourceToken="$resourceToken" \
        managedIdentityName="$managedIdentityName" \
        logAnalyticsWorkspaceName="$logAnalyticsWorkspaceName" \
        appInsightsName="$applicationInsightsName" \
        containerRegistryName="$containerRegistryName" \
        appServicePlanName="$appServicePlanName" \
        storageAccountName="$storageAccountName" \
        keyVaultUri="$keyVaultUri" \
        OpenAIEndPoint="$OpenAIEndPoint" \
        searchServiceEndpoint="$searchServiceEndpoint" \
        azureAISearchKey="$azureAISearchKey" \
    --query "properties.outputs")

# Parse output using jq
functionAppName=$(echo "$deploymentOutputApps" | jq -r '.functionAppName.value')
apiAppName=$(echo "$deploymentOutputApps" | jq -r '.apiAppName.value')

echo "Function App Name: $functionAppName"
echo "API App Name: $apiAppName"

echo "Waiting for App Services before pushing code"

waitTime=60  # Total wait time in seconds

# Display counter
for ((i=$waitTime; i>0; i--)); do
    echo -ne "\rWaiting: $i seconds remaining..."
    sleep 1
done

echo -e "\rWait time completed!"

# Change directory to scripts
cd ./scripts

# Deploy Azure Function for Loading AI Search Indexes from PDFs 
echo "*****************************************"
echo "Deploying Function Application from scripts"
echo "If timeout occurs, rerun the following command from scripts:"
echo "./deploy_functionapp.sh $function_app_name $rgName"


chmod +x deploy_functionapp.sh

# Run the deploy script
./deploy_functionapp.sh "$function_app_name" "$rgName"


# Deploy Python FastAPI for OpenAPI and GraphQL
echo "*****************************************"
echo "Deploying Python FastAPI from scripts"
echo "If timeout occurs, rerun the following command from scripts:"
echo "./deploy_api.sh $api_app_name $rgName ../src/api"

chmod +x deploy_api.sh

# Run the deploy script
./deploy_api.sh "$api_app_name" "$rgName" "../src/api"


# Change directory back
cd ..

echo "Deployment Complete"
