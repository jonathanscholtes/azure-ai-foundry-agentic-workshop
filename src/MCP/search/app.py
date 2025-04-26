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
mcp = FastMCP("Server for Azure AI Search", port=int(environ.get("MCP_PORT", 8082)), on_duplicate_tools="error")

class AzureSearchClient:
    """Client for Azure AI Search service."""

    def __init__(self):
        """Initialize Azure Search client with credentials from environment variables."""
        logger.info("Initializing Azure Search client...")

        self.endpoint = environ.get("AZURE_SEARCH_SERVICE_ENDPOINT")
        self.index_name = environ.get("AZURE_SEARCH_INDEX_NAME")

        if not self.endpoint or not self.index_name:
            missing = []
            if not self.endpoint:
                missing.append("AZURE_SEARCH_SERVICE_ENDPOINT")
            if not self.index_name:
                missing.append("AZURE_SEARCH_INDEX_NAME")
            raise ValueError(f"Missing environment variables: {', '.join(missing)}")

        self.credential = DefaultAzureCredential()
        self.search_client = SearchClient(
            endpoint=self.endpoint,
            index_name=self.index_name,
            credential=self.credential
        )

        logger.info(f"Azure Search client initialized for index: {self.index_name}")

    def hybrid_search(self, query, top=5, vector_field="text_vector"):
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
            select=["title", "chunk"]
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
            select=["title", "chunk"]
        )
        return self._format_results(results)

    def _format_results(self, results):
        """Format search results into a list of dictionaries."""
        formatted = []
        for result in results:
            formatted.append({
                "title": result.get("title", "Unknown"),
                "content": result.get("chunk", "")[:1000],
                "score": result.get("@search.score", 0)
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
    output = [f"### {title} Results"]
    for r in results:
        output.append(f"- **{r['title']}** (Score: {r['score']:.2f})\n\n{r['content']}\n")
    return "\n".join(output)

@mcp.tool()
def hybrid_search(query: str, top: int = 5) -> str:
    """Tool for performing hybrid Azure Search."""
    logger.info(f"Tool called: hybrid_search(query='{query}', top={top})")
    if not search_client:
        return "Error: Azure Search client is not initialized."
    try:
        results = search_client.hybrid_search(query, top)
        return _format_results_as_markdown(results, "Hybrid Search")
    except Exception as e:
        logger.error(f"Error during hybrid_search: {e}")
        return f"Error: {str(e)}"

if __name__ == "__main__":
    logger.info("Starting the FastMCP Azure AI Search service...")
    logger.info(f"Service name: {environ.get('SERVICE_NAME', 'unknown')}")
    mcp.run(transport="sse")
    logger.info("FastMCP Azure AI Search is running.")
