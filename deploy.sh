#!/bin/bash

# Usage: ./deploy.sh <subscription> [location] [resource_group_name]

location="${1:-eastus2}"
resource_group_name="${2:-}"
skip_models=false

# Check for optional --skip-models flag
for arg in "$@"; do
  if [[ "$arg" == "--skip-models" ]]; then
    skip_models=true
  fi
done

# Variables
project_name="fndry"
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
    rg_name="rg-${project_name}-${environment_name}-${location}-${resource_token}"
else
    rg_name="$resource_group_name"
fi

# Check if resource group exists
existing_rg=$(az group show --name "$rg_name" --query "name" --output tsv 2>/dev/null)

if [ -z "$existing_rg" ]; then
    echo "Resource group '$rg_name' does not exist. Creating it..."
    az group create --name "$rg_name" --location "$location"
else
    echo "Resource group '$rg_name' already exists."
fi

# Variables
deploymentNameInfra="deployment-infra-${resource_token}"
templateFile="infra/main.bicep"

# Step 1: Deploy Infrastructure
deploymentOutput=$(az deployment sub create \
    --name "$deploymentNameInfra" \
    --location "$location" \
    --template-file "$templateFile" \
    --parameters \
        environmentName="$environment_name" \
        projectName="$project_name" \
        location="$location" \
        skipModels="$skip_models" \
        resourceGroupName="$rg_name" \
        resourceToken="$resource_token" \
        projectConfig="@./project_resource_config.json" \
    --query "properties.outputs" \
    --output json)

# Parse deployment output
managedIdentityName=$(echo "$deploymentOutput" | jq -r '.managedIdentityName.value')
appServicePlanName=$(echo "$deploymentOutput" | jq -r '.appServicePlanName.value')
storageAccountName=$(echo "$deploymentOutput" | jq -r '.storageAccountName.value')
logAnalyticsWorkspaceName=$(echo "$deploymentOutput" | jq -r '.logAnalyticsWorkspaceName.value')
applicationInsightsName=$(echo "$deploymentOutput" | jq -r '.applicationInsightsName.value')
keyVaultName=$(echo "$deploymentOutput" | jq -r '.keyVaultName.value')
OpenAIEndPoint=$(echo "$deploymentOutput" | jq -r '.OpenAIEndPoint.value')
containerRegistryName=$(echo "$deploymentOutput" | jq -r '.containerRegistryName.value')
searchServicename=$(echo "$deploymentOutput" | jq -r '.searchServicename.value')

echo "=== Building Images for MCP Server ==="
echo "Using ACR: $containerRegistryName"
echo "Resource Group: $rg_name"
echo

images=(
    "weather-mcp ./src/MCP/weather"
    "search-mcp ./src/MCP/search"
    "energy-mcp ./src/MCP/energy"
    "nginx-mcp-gateway ./src/MCP/nginx"
)

for image_info in "${images[@]}"; do
    image_name=$(echo "$image_info" | awk '{print $1}')
    image_path=$(echo "$image_info" | awk '{print $2}')
    
    echo "Building image '${image_name}:latest' from '${image_path}'..."
    az acr build \
        --resource-group "$rg_name" \
        --registry "$containerRegistryName" \
        --image "${image_name}:latest" \
        "$image_path"
done

echo "=== Step 2: Deploy Apps ==="

deploymentNameApps="deployment-apps-${resource_token}"
appsTemplateFile="infra/app/main.bicep"

deploymentOutputApps=$(az deployment sub create \
    --name "$deploymentNameApps" \
    --location "$location" \
    --template-file "$appsTemplateFile" \
    --parameters \
        environmentName="$environment_name" \
        projectName="$project_name" \
        location="$location" \
        resourceGroupName="$rg_name" \
        resourceToken="$resource_token" \
        managedIdentityName="$managedIdentityName" \
        logAnalyticsWorkspaceName="$logAnalyticsWorkspaceName" \
        appInsightsName="$applicationInsightsName" \
        containerRegistryName="$containerRegistryName" \
        appServicePlanName="$appServicePlanName" \
        storageAccountName="$storageAccountName" \
        keyVaultName="$keyVaultName" \
        OpenAIEndPoint="$OpenAIEndPoint" \
        searchServicename="$searchServicename" \
    --query "properties.outputs" \
    --output json)

functionAppName=$(echo "$deploymentOutputApps" | jq -r '.functionAppName.value')
apiAppName=$(echo "$deploymentOutputApps" | jq -r '.apiAppName.value')

echo "Function App Name: $functionAppName"
echo "API App Name: $apiAppName"

echo "Waiting for App Services before pushing code..."

waitTime=60
for ((i=waitTime; i>0; i--)); do
    echo -ne "\rWaiting: $i seconds remaining..."
    sleep 1
done
echo -e "\rWait time completed!"

cd ./scripts

echo "*****************************************"
echo "Deploying Function Application"
chmod +x deploy_functionapp.sh
./deploy_functionapp.sh "$functionAppName" "$rg_name"

echo "*****************************************"
echo "Deploying Python FastAPI"
chmod +x deploy_api.sh
./deploy_api.sh "$apiAppName" "$rg_name" "../src/api"

cd ..

echo "Deployment Complete"
