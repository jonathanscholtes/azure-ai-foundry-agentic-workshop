#!/bin/bash

# Params
functionAppName=$1
resourceGroupName=$2

pythonAppPath="../src/DocumentProcessingFunction"
tempDir="artifacts/loader/temp"
zipFilePath="artifacts/loader/app.zip"

# Construct the argument list
args="$pythonAppPath $zipFilePath $tempDir --exclude_dirs venv --exclude_files local.settings.json .env *.md"

# Execute the Python script
python directory_zipper.py $args

# Deploy the function app
az functionapp deployment source config-zip --resource-group "$resourceGroupName" --name "$functionAppName" --src "$zipFilePath" --build-remote true

echo "Waiting for the function app to finish deployment..."
sleep 30

# Ping the function app to wake it up
curl -I "https://$functionAppName.azurewebsites.net"
