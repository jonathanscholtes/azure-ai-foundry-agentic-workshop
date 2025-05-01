# Params
param (
    [string]$functionAppName,
    [string]$resourceGroupName
)

$pythonAppPath = "..\src\DocumentProcessingFunction"
$tempDir = "artifacts\loader\temp"
$zipFilePath = "artifacts\loader\app.zip"

# Construct the argument list
$args = "$pythonAppPath $zipFilePath $tempDir --exclude_dirs venv  --exclude_files local.settings.json .env *.md"

# Execute the Python script
Start-Process "python" -ArgumentList "directory_zipper.py $args" -NoNewWindow -Wait

Write-Host "Deploy the Function App via zip deploy (with remote build)..."

$maxRetries = 3
$delaySeconds = 30

for ($i = 1; $i -le $maxRetries; $i++) {
    Write-Host "Attempt ${i}: Deploying Function App..."
    az functionapp deployment source config-zip `
        --resource-group $resourceGroupName `
        --name $functionAppName `
        --src $zipFilePath `
        --build-remote true

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