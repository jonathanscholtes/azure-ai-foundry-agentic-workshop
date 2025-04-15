# Params
param (
    [string]$apiAppName,
    [string]$resourceGroupName
)

$pythonAppPath = "..\src\api"
$tempDir = "artifacts\api\temp"
$zipFilePath = "artifacts\api\app.zip"

# Construct the argument list
$args = "$pythonAppPath $zipFilePath $tempDir --exclude_dirs venv --exclude_files .env *.md"

# Execute the Python script
Start-Process "python" -ArgumentList "directory_zipper.py $args" -NoNewWindow -Wait

# Deploy the zip file to the Azure Web App
az webapp deploy --resource-group $resourceGroupName --name $apiAppName --src-path $zipFilePath --type 'zip' --timeout 60000 --track-status true

