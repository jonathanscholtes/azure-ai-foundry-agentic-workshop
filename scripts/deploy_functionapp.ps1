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

Write-Host "Ping the Function App to wake it up..."
try {
    Invoke-WebRequest -Uri "https://$functionAppName.azurewebsites.net" -Method Get -UseBasicParsing -TimeoutSec 10
    Start-Sleep -Seconds 10
} catch {
    Write-Host "Initial warm-up ping failed, continuing anyway..."
}

Write-Host "Deploy the Function App via zip deploy (with remote build)..."

$maxRetries = 3
$delaySeconds = 30
$success = $false

for ($i = 1; $i -le $maxRetries; $i++) {
    try {
        az functionapp deployment source config-zip `
            --resource-group $resourceGroupName `
            --name $functionAppName `
            --src $zipFilePath `
            --build-remote true

        Write-Host "Deployment succeeded on attempt $i."
        $success = $true
        break
    } catch {
        Write-Host "Attempt $i failed. Waiting $delaySeconds seconds before retrying..."
        Start-Sleep -Seconds $delaySeconds
    }
}

if (-not $success) {
    throw "Deployment failed after $maxRetries attempts."
}