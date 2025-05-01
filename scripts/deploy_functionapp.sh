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

echo "Deploy the Function App via zip deploy (with remote build)..."

maxRetries=3
delaySeconds=30

for ((i=1; i<=maxRetries; i++)); do
    echo "Attempt ${i}: Deploying Function App..."
    
    az functionapp deployment source config-zip \
        --resource-group "$resourceGroupName" \
        --name "$functionAppName" \
        --src "$zipFilePath" \
        --build-remote true

    if [ $? -eq 0 ]; then
        echo "Deployment succeeded on attempt ${i}."
        break
    else
        echo "Deployment failed with exit code $? Retrying in ${delaySeconds} seconds..."
        sleep $delaySeconds
    fi

    if [ $i -eq $maxRetries ]; then
        echo "Deployment failed after ${maxRetries} attempts."
        exit 1
    fi
done
