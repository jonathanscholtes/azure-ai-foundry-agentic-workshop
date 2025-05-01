#!/bin/bash

# Params
apiAppName=$1
resourceGroupName=$2
pythonAppPath=$3

#pythonAppPath="../src/api"
tempDir="artifacts/api/temp"
zipFilePath="artifacts/api/app.zip"

# Construct the argument list
args="$pythonAppPath $zipFilePath $tempDir --exclude_dirs venv --exclude_files .env *.md"

# Execute the Python script
python directory_zipper.py $args

echo "Deploy the Azure Web App..."

maxRetries=3
delaySeconds=30

for ((i=1; i<=maxRetries; i++)); do
    echo "Attempt ${i}: Deploying Azure Web App..."
    
    az webapp deploy \
        --resource-group "$resourceGroupName" \
        --name "$apiAppName" \
        --src-path "$zipFilePath" \
        --type zip \
        --timeout 600 \
        --track-status false \
        --async true

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