#!/bin/bash

# Usage: ./deploy.sh <subscription> [location] <dev_compute_instances> [resource_group_name]

subscription=$1
location=${2:-eastus2}
dev_compute_instances=$3
resource_group_name=$4

# Variables
project_name="foundry"
environment_name="lab"
template_file="infra/main.bicep"
deployment_name="foundrylab-$location"

# Function to generate random alphanumeric string (base62)
generate_random_alphanumeric() {
    length=$1
    seed=$2
    base62chars="abcdefghijklmnopqrstuvwxyz123456789"
    result=""
    seed_bytes=$(echo -n "$seed" | md5sum | cut -d ' ' -f1)

    for ((i = 0; i < length; i++)); do
        index=$(( 0x${seed_bytes:$((i*2)):2} % ${#base62chars} ))
        result+=${base62chars:$index:1}
    done
    echo "$result"
}

# Generate resource token
resource_token=$(generate_random_alphanumeric 12 "${environment_name}${project_name}${location}${subscription}")

# Clear previous account context and set Azure CLI config
az account clear
az config set core.enable_broker_on_windows=false
az config set core.login_experience_v2=off

# Login to Azure and set subscription
az login
az account set --subscription "$subscription"

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

echo "Deployment Complete"
