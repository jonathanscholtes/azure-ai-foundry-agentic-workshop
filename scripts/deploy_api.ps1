# Params
param (
    [string]$apiAppName,
    [string]$resourceGroupName,
    [string]$pythonAppPath
)

#$pythonAppPath = "..\src\api"
$tempDir = "artifacts\api\temp"
$zipFilePath = "artifacts\api\app.zip"

# Construct the argument list
$args = "$pythonAppPath $zipFilePath $tempDir --exclude_dirs venv --exclude_files .env *.md"

# Execute the Python script
Start-Process "python" -ArgumentList "directory_zipper.py $args" -NoNewWindow -Wait

# Deploy the zip file to the Azure Web App

Write-Host "Deploy the Azure Web App..."

$maxRetries = 3
$delaySeconds = 30

for ($i = 1; $i -le $maxRetries; $i++) {
    Write-Host "Attempt ${i}: Deploying Azure Web App..."
    az webapp deploy --resource-group $resourceGroupName --name $apiAppName --src-path $zipFilePath --type 'zip' --timeout 600 --track-status false --async true


    if ($LASTEXITCODE -eq 0) {
        Write-Host "Deployment succeeded on attempt ${i}."
        break
    } else {
        Write-Host "Deployment failed with exit code $LASTEXITCODE. Retrying in $delaySeconds seconds..."
        Start-Sleep -Seconds $delaySeconds
    }

    if ($i -eq $maxRetries) {
        throw "Deployment failed after $maxRetries attempts."
    }
}