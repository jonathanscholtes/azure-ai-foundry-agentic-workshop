from fastmcp.server.openapi import FastMCPOpenAPI
from mcp.types import TextContent
from typing import Any
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
    RouteMap(methods=["GET"], 
            pattern=r"^/usage/.*", 
            route_type=RouteType.TOOL)]

    # Create an MCP server from the OpenAPI spec
    mcp = FastMCPOpenAPI.from_openapi(openapi_spec=spec,
    client=api_client, port=int(environ.get("MCP_PORT", 8083)),
    message_path="/energy/messages/",
    name="Data Center Energy Usage Service",
    route_maps=custom_maps) 

    ## Override the tool calling to work with pydantic models from API
    original_call_tool = mcp._tool_manager.call_tool

    async def custom_call_tool(name: str, arguments: dict, context: Any = None) -> Any:
        
        logger.info(f"Tool Call: {name} with args: {arguments}")
        result = await original_call_tool(name, arguments, context=context)
        
        if isinstance(result, dict):
            result_text = json.dumps(result)
        else:
            result_text = str(result)

        return [TextContent(text=result_text, type="text")]

    mcp._tool_manager.call_tool = custom_call_tool
    
except KeyError as e:
    logger.error(f"Missing required environment variable: {e}")
    raise
except Exception as e:
    logger.error(f"Failed to initialize FastMCP from OpenAPI spec: {e}")
    raise

if __name__ == "__main__":
    logger.info("Starting the FastMCP Energy service...")
    mcp.run(transport="sse")