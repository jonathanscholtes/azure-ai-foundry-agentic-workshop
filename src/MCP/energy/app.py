from fastmcp import FastMCP
from fastmcp.server.openapi import RouteMap, RouteType
import httpx
import uvicorn
import requests
import json
import logging

from os import environ
from dotenv import load_dotenv

# Load environment variables
load_dotenv(override=True)

# Setup logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


# Load OpenAPI spec from environment
try:
    openapi_url = environ["OPENAPI_URL"]
    logger.info(f"Fetching OpenAPI spec from {openapi_url}...")
    
    # Synchronous fetch of OpenAPI spec
    spec_url = f"{openapi_url}/openapi.json"
    response = requests.get(spec_url)
    response.raise_for_status()
    spec = response.json()

    # Create an async client for the API
    api_client = httpx.AsyncClient(base_url=openapi_url)

    custom_maps = [
    # Force all usage endpoints to be Tools
    RouteMap(methods=["GET"], 
            pattern=r"^/usage/.*", 
            route_type=RouteType.TOOL)]

    # Create an MCP server from the OpenAPI spec
    mcp = FastMCP.from_openapi(openapi_spec=spec,
    client=api_client, port=int(environ.get("MCP_PORT", 8083)),
    message_path="/energy/messages/",
    name="Data Center Energy Usage Service",
    route_maps=custom_maps) 
    
except KeyError as e:
    logger.error(f"Missing required environment variable: {e}")
    raise
except Exception as e:
    logger.error(f"Failed to initialize FastMCP from OpenAPI spec: {e}")
    raise

if __name__ == "__main__":
    logger.info("Starting the FastMCP Energy service...")
    mcp.run(transport="sse")