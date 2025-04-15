#!/bin/bash

# Params
apiAppName=$1
resourceGroupName=$2

pythonAppPath="../src/api"
tempDir="artifacts/api/temp"
zipFilePath="artifacts/api/app.zip"

# Construct the argument list
args="$pythonAppPath $zipFilePath $tempDir --exclude_dirs venv --exclude_files .env *.md"

# Execute the Python script
python directory_zipper.py $args

# Deploy the zip file to the Azure Web App
az webapp deploy --resource-group "$resourceGroupName" --name "$apiAppName" --src-path "$zipFilePath" --type 'zip' --timeout 60000 --track-status true