## Deployment: Azure AI Foundry and Dependencies

### **Prerequisites**
Ensure you have the following before deploying the solution:
- ✅ **Azure Subscription:** Active subscription with sufficient privileges to create and manage resources.  
- ✅ **Azure CLI:** Install the [Azure CLI](https://learn.microsoft.com/en-us/cli/azure/get-started-with-azure-cli) for managing Azure resources.  
- ✅ **IDE with Bicep & PowerShell Support:** Use [VS Code](https://code.visualstudio.com/download) with the **Bicep extension** for development and validation.  

---

### **1. Clone the Repository**
Clone the project repository to your local machine:

```bash
git clone https://github.com/jonathanscholtes/azure-ai-foundry-agentic-workshop.git
cd azure-ai-foundry-agentic-workshop
```


### 2. Deploy the Solution  
Navigate to the infrastructure directory:

```bash
cd infra
```

Run the following PowerShell command to deploy the solution. Replace the placeholders with your actual subscription name and Azure region. The `-ResourceGroupName` flag is optional for deploying to an exising Azure Resource Group:

```powershell
.\deploy.ps1 -Subscription '[Subscription Name]' -Location 'eastus2' -ResourceGroupName '[Name of existing resource group (optional)]'
```

✅ This script provisions all required Azure resources based on the specified parameters. The deployment may take up to **20 minutes** to complete.






  