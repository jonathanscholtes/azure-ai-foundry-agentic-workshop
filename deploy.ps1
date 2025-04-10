param (
    [string]$Subscription,
    [string]$Location = "eastus2",
    [int]$DevComputeInstances,
    [string]$ResourceGroupName
)


# Variables
$projectName = "foundry"
$environmentName = "lab"
$templateFile = "infra/main.bicep"
$deploymentName = "foundrylab-$Location"


function Get-RandomAlphaNumeric {
    param (
        [int]$Length = 12,    
        [string]$Seed        
    )
    
    # Base62 characters (lowercase + digits)
    $base62Chars = "abcdefghijklmnopqrstuvwxyz123456789"
    
    # Set the seed for random number generation
    $rng = New-Object System.Random -ArgumentList ( [System.BitConverter]::ToInt32([System.Text.Encoding]::UTF8.GetBytes($Seed), 0) )
    
    # Generate the random string based on the seed
    $randomString = -join ((1..$Length) | ForEach-Object { $base62Chars[$rng.Next(0, $base62Chars.Length)] })
    
    return $randomString
}

# Example usage: Generate a resource token based on a seed
$resourceToken = Get-RandomAlphaNumeric -Length 12 -Seed "$environmentName$projectName$Location$Subscription"


# Clear account context and configure Azure CLI settings
az account clear
az config set core.enable_broker_on_windows=false
az config set core.login_experience_v2=off

# Login to Azure
az login 
az account set --subscription $Subscription



# If no resource group name is passed, generate one
if (-not $ResourceGroupName) {
    $rgName = "rg-$projectName-$environmentName-$Location-$resourceToken"
} else {
    $rgName = $ResourceGroupName
}

# Check if the resource group exists
$resourceGroup = az group show --name $rgName --query "name" --output tsv

if (-not $resourceGroup) {
    Write-Host "Resource group '$rgName' does not exist. Creating it..."
    az group create --name $rgName --location $Location
} else {
    Write-Host "Resource group '$rgName' already exists."
}

# Start the deployment
$deploymentOutput = az deployment sub create `
    --name $deploymentName `
    --location $Location `
    --template-file $templateFile `
    --parameters `
        environmentName=$environmentName `
        projectName=$projectName `
        location=$Location `
        numberComputeInstances=$DevComputeInstances `
        resourceGroupName=$rgName `
        resourceToken=$resourceToken `
    --query "properties.outputs"


# Parse the deployment output to get app names and resource group
$deploymentOutputJson = $deploymentOutput | ConvertFrom-Json
$resourceGroupName = $deploymentOutputJson.resourceGroupName.value


Write-Host "Deployment Complete"