
from azure.search.documents import SearchClient
from langchain_community.vectorstores.azuresearch import AzureSearch
from langchain_openai import AzureOpenAIEmbeddings
from dotenv import load_dotenv
from os import environ

load_dotenv(override=True)

def vector_search(query: str):
    """Searches knowledge base using vector similarity."""

    # Create embedding 
    embeddings: AzureOpenAIEmbeddings = AzureOpenAIEmbeddings(
        azure_deployment=environ.get("AZURE_OPENAI_EMBEDDING"),
        openai_api_version=environ.get("AZURE_OPENAI_API_VERSION"),
        azure_endpoint=environ.get("AZURE_OPENAI_ENDPOINT"),
        api_key=environ.get("AZURE_OPENAI_API_KEY"),)


    # Vector search in Azure Cognitive Search
    vector_store = AzureSearch(
        azure_search_endpoint=environ.get("AZURE_AI_SEARCH_ENDPOINT"),
        azure_search_key=environ.get("AZURE_AI_SEARCH_KEY"),
        index_name=environ.get("AZURE_AI_SEARCH_INDEX"),
        embedding_function=embeddings.embed_query,
        semantic_configuration_name= 'default'
    )


    docs = vector_store.semantic_hybrid_search(
    query=query,
    k=3
    )

    formatted_docs = []
    for doc in docs:
        content = doc.page_content.strip()
        title = doc.metadata.get("title", "Untitled")
        page = doc.metadata.get("pageNumber", "N/A")
        formatted_docs.append(f"[{title} - Page {page}]: {content}")

    return "\n\n".join(formatted_docs)
    
