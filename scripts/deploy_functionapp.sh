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

# Ping the function app to wake it up
echo "Ping the Function App to wake it up..."
if curl -s -m 10 "https://$functionAppName.azurewebsites.net" > /dev/null; then
  echo "Function App responded. Sleeping briefly..."
  sleep 10
else
  echo "Warm-up ping failed, continuing anyway..."
fi

echo "Deploying Function App via zip deploy..."

max_retries=3
delay_seconds=30
success=false

for ((i=1; i<=max_retries; i++)); do
  if az functionapp deployment source config-zip \
    --resource-group "$resourceGroupName" \
    --name "$functionAppName" \
    --src "$zipFilePath" \
    --build-remote true; then
    echo "Deployment succeeded on attempt $i."
    success=true
    break
  else
    echo "Attempt $i failed. Waiting $delay_seconds seconds before retrying..."
    sleep $delay_seconds
  fi
done

if [ "$success" = false ]; then
  echo "Deployment failed after $max_retries attempts."
  exit 1
fi
