from mcp.server.fastmcp import FastMCP
import uvicorn
import logging
from azure.search.documents import SearchClient
from azure.search.documents.models import VectorizableTextQuery
from azure.identity import DefaultAzureCredential
from os import environ
from dotenv import load_dotenv

# Load environment variables
load_dotenv(override=True)

# Initialize logger
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


# FastMCP setup
mcp = FastMCP("Server for Azure AI Search", port=int(environ.get("MCP_PORT", 8082)), on_duplicate_tools="error", message_path="/search/messages/")

class AzureSearchClient:
    """Client for Azure AI Search service."""

    def __init__(self):
        """Initialize Azure Search client with credentials from environment variables."""
        logger.info("Initializing Azure Search client...")

        self.endpoint = environ.get("AZURE_AI_SEARCH_ENDPOINT")
        self.index_name = environ.get("AZURE_AI_SEARCH_INDEX")

        if not self.endpoint or not self.index_name:
            missing = []
            if not self.endpoint:
                missing.append("AZURE_AI_SEARCH_ENDPOINT")
            if not self.index_name:
                missing.append("AZURE_AI_SEARCH_INDEX")
            raise ValueError(f"Missing environment variables: {', '.join(missing)}")

        self.credential = DefaultAzureCredential()
        self.search_client = SearchClient(
            endpoint=self.endpoint,
            index_name=self.index_name,
            credential=self.credential
        )

        logger.info(f"Azure Search client initialized for index: {self.index_name}")

    def hybrid_search(self, query, top=5, vector_field="content_vector"):
        """Perform hybrid search (keyword + vector) on the index."""
        logger.info(f"Performing hybrid search for: {query}")
        results = self.search_client.search(
            search_text=query,
            vector_queries=[
                VectorizableTextQuery(
                    text=query,
                    k_nearest_neighbors=50,
                    fields=vector_field
                )
            ],
            top=top,
            select=["title", "content","pageNumber"]
        )
        return self._format_results(results)

    def vector_search(self, query, top=5, vector_field="content_vector"):
        """Perform vector-only search on the index."""
        logger.info(f"Performing vector search for: {query}")
        results = self.search_client.search(
            vector_queries=[
                VectorizableTextQuery(
                    text=query,
                    k_nearest_neighbors=50,
                    fields=vector_field
                )
            ],
            top=top,
            select=["title", "content","pageNumber"]
        )
        return self._format_results(results)

    def _format_results(self, results):
        """Format search results into a list of dictionaries."""
        formatted = []
        for result in results:
            formatted.append({
                "title": result.get("title", "Unknown"),
                "content": result.get("content"),
                "pageNumber": result.get("pageNumber")
            })
        logger.info(f"Formatted {len(formatted)} search results")
        return formatted

# Initialize the Azure Search client
try:
    search_client = AzureSearchClient()
except Exception as e:
    logger.error(f"Failed to initialize AzureSearchClient: {e}")
    search_client = None

def _format_results_as_markdown(results, title):
    """Helper function to format search results into markdown."""
    if not results:
        return f"### {title} Results\n\n_No results found._"

    output = [f"### {title} Results"]
    for idx, r in enumerate(results, 1):
        r_title = r.get('title', 'Untitled')
        r_content = r.get('content', 'No content available.')
        r_page = r.get('pageNumber')

        page_info = f" (Page {r_page})" if r_page is not None else ""

        output.append(
            f"**{idx}. {r_title}**{page_info}\n\n{r_content}\n---"
        )
    
    return "\n".join(output)




@mcp.tool()
def hybrid_search(query: str, top: int = 5) -> str:
    """Use Azure AI Search to find information about data center facilities, energy usage, and resource intensity. Ideal for technical document lookups."""
    logger.info(f"Tool called: hybrid_search(query='{query}', top={top})")
    if not ai_search:
        logger.error(f"Azure Search client is not initialized.")
        return "Error: Azure Search client is not initialized."
    try:
        results = ai_search.hybrid_search(query, top)
        return _format_results_as_markdown(results, "Hybrid Search")
    except Exception as e:
        logger.error(f"Error during hybrid_search: {e}")
        return f"Error: {str(e)}"




ai_search: AzureSearchClient | None= None



if __name__ == "__main__":
    logger.info("Starting the FastMCP Azure AI Search service...")   
    logger.info(f"Service name: {environ.get('SERVICE_NAME', 'unknown')}")
    ai_search = AzureSearchClient()
    logger.info("Azure AI Search Client Init...")   

    mcp.run(transport="sse")
 
