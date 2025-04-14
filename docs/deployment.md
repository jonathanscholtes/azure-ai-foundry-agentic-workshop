## Deployment: Azure AI Foundry and Dependencies

### **Prerequisites**
Ensure you have the following before deploying the solution:
- ✅ **Azure Subscription:** Active subscription with sufficient privileges to create and manage resources.  
- ✅ **Azure CLI:** Install the [Azure CLI](https://learn.microsoft.com/en-us/cli/azure/get-started-with-azure-cli) for managing Azure resources.  
- ✅ **IDE with Bicep & PowerShell Support:** Use [VS Code](https://code.visualstudio.com/download) with the **Bicep extension** for development and validation.  

---

### **1. Clone the Repository**
Clone the repository to your local machine and navigate into the project directory:

```bash
git clone https://github.com/jonathanscholtes/azure-ai-foundry-agentic-workshop.git

cd azure-ai-foundry-agentic-workshop
```


### 2. Deploy the Solution  

#### 🔹 PowerShell (Windows)

Run the following PowerShell command to deploy the solution. Replace the placeholders with your actual subscription name and Azure region. The `-ResourceGroupName` flag is optional for deploying to an exising Azure Resource Group:

```powershell
.\deploy.ps1 -Subscription '[Subscription Name]' -Location 'eastus2' -DevComputeInstances 1 -ResourceGroupName '[Name of existing resource group (optional)]'
```

#### 🔹 Bash (Linux)

Run the following commands in your terminal to deploy the solution.
Make sure the deployment script is executable and that you're authenticated with Azure.
The third argument (resource group name) is optional.

```bash

# Make the script executable
chmod +x deploy.sh

chmod +x scripts/deploy_functionapp.sh

# Authenticate with Azure
az login
# or use
az login --identity

# Set the active subscription
az account set --subscription '[Subscription Name]'

# Deploy the solution to the secified Location, with DevComputeInstances
./deploy.sh 'eastus2' 1 '[Existing Resource Group Name (optional)]'
```

✅ This script provisions all required Azure resources based on the specified parameters. The deployment may take up to **20 minutes** to complete.






  