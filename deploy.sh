#!/bin/bash

# Usage: ./deploy.sh <subscription> [location] <dev_compute_instances> [resource_group_name]

location=${1:-eastus2}
dev_compute_instances=$2
resource_group_name=$3

# Variables
project_name="foundry"
environment_name="lab"
template_file="infra/main.bicep"
deployment_name="foundrylab-$location"



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

# Deploy the Bicep template
deployment_output=$(az deployment sub create \
    --name "$deployment_name" \
    --location "$location" \
    --template-file "$template_file" \
    --parameters \
        environmentName="$environment_name" \
        projectName="$project_name" \
        location="$location" \
        numberComputeInstances="$dev_compute_instances" \
        resourceGroupName="$rg_name" \
        resourceToken="$resource_token" \
    --query "properties.outputs" -o json)

# Extract resource group name from output if needed
resource_group_name=$(echo "$deployment_output" | jq -r '.resourceGroupName.value')
function_app_name=$(echo "$deployment_output" | jq -r '.functionAppName.value')

echo "Waiting for App Services before pushing code"

waitTime=200  # Total wait time in seconds

# Display counter
for ((i=$waitTime; i>0; i--)); do
    echo -ne "\rWaiting: $i seconds remaining..."
    sleep 1
done

echo -e "\rWait time completed!"

# Change directory to scripts
cd ./scripts

# Deploy Function Application
echo "*****************************************"
echo "Deploying Function Application from scripts"
echo "If timeout occurs, rerun the following command from scripts:"
echo "./deploy_functionapp.sh $function_app_name $resource_group_name"


chmod +x deploy_functionapp.sh

# Run the deploy script
./deploy_functionapp.sh "$function_app_name" "$resource_group_name"

# Change directory back
cd ..

echo "Deployment Complete"
