




![setup container](../media/template-setup.png)

![container ready](../media/template-ready.png)

Launch VS Code Web
![container launch](../media/container-vs-code-web.png)



```bash

git clone --no-checkout https://github.com/jonathanscholtes/azure-ai-foundry-agentic-workshop.git

cd azure-ai-foundry-agentic-workshop

git sparse-checkout init --cone

git sparse-checkout set src/Notebooks

git checkout
```


### Evinroment Variables for Notebooks

create a new file called `.env` in the Notebook directory. Copy the variables from `sample.env` into the `.env.` Then update 

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