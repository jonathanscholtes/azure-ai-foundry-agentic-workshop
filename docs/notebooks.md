## Explore Sample Notebooks

The sample notebooks demonstrate **vector search**, **semantic retrieval**, and **Agentic AI patterns** using **Azure AI Foundry** and **Azure AI Search**.

These examples showcase how to build intelligent applications grounded in enterprise data using retrieval-augmented generation (RAG) and agent-based workflows.

---

### Optional: Set Up VS Code Container on Azure AI Foundry

To run the notebooks on your Azure AI Foundry compute instance, you can optionally set up a VS Code container for a more integrated development experience.

#### Steps:

1. In your **Azure AI Project**, navigate to **Templates** and select **VS Code Compute**.
2. Ensure your compute instance is running, then click **Set up Container**.

   > ⚠️ This setup may take a few minutes to complete.

![setup container](../media/template-setup.png)

3. Once the container is ready, you’ll see a **Ready** status indicator.

![container ready](../media/template-ready.png)

4. To launch VS Code in the browser, use the dropdown menu and select the **Web** option.

![container launch](../media/container-vs-code-web.png)

---

## 📥 Download Workshop Notebooks

Once your environment is up and running, you can download the sample notebooks directly from the GitHub repository using the following commands:

```bash
# Clone the repository without checking out all files
git clone --no-checkout https://github.com/jonathanscholtes/azure-ai-foundry-agentic-workshop.git

# Navigate into the repo folder
cd azure-ai-foundry-agentic-workshop

# Enable sparse checkout to download only the notebooks folder
git sparse-checkout init --cone
git sparse-checkout set src/Notebooks

# Checkout the selected content
git checkout
```

This approach downloads only the relevant [src/Notebooks](../src/Notebooks) directory, keeping your workspace clean and lightweight.

---

### ⚙️ Environment Variables for Notebooks

After downloading the notebook files, create a `.env` file in the same directory to connect your code to the deployed Azure AI resources.

#### Steps:

1. Copy the contents of `sample.env` to a new file named `.env`.
2. Update the values in `.env` with your specific Azure resource details:

```
AZURE_AI_SEARCH_ENDPOINT='Your Azure AI Search Endpoint'
AZURE_AI_SEARCH_KEY='Your Azure AI Search Key'
AZURE_AI_SEARCH_INDEX='Azure AI Search Index'
AZURE_OPENAI_EMBEDDING='text-embedding'
AZURE_OPENAI_API_VERSION='2024-06-01'
AZURE_OPENAI_ENDPOINT='Endpoint from deployed Azure AI Service or Azure OpenAI Service'
AZURE_OPENAI_API_KEY='Key from deployed Azure AI Service or Azure OpenAI Service'
AZURE_OPENAI_MODEL='gpt-4o'
```

