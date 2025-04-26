from mcp.server.fastmcp import FastMCP
import uvicorn
import logging
from os import environ
from dotenv import load_dotenv

# Load environment variables
load_dotenv(override=True)

# Initialize logger
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# FastMCP setup
mcp = FastMCP("Weather", port=int(environ.get("MCP_PORT", 8082)), on_duplicate_tools="error",message_path="/weather/messages/")


@mcp.tool()
def get_weather_tool(location: str):
    """Call to get the current weather."""
    logger.info(f"Fetching weather for {location}")
    if location.lower() in ["sf", "san francisco"]:
        return "It's 60 degrees and foggy."
    else:
        return "It's 90 degrees and sunny."

@mcp.tool()
def convert_fahrenheit_to_celsius(fahrenheit: float) -> str:
    """
    Converts a temperature from Fahrenheit (F) to Celsius (C) and returns a string formatted as 'X°C'.
    
    Use this tool when you are given a temperature in Fahrenheit and need to return the value in Celsius.
    """
    logger.info(f"Converting {fahrenheit}°F to Celsius")
    celsius = (fahrenheit - 32) * 5 / 9
    return f"{celsius:.1f}°C"

if __name__ == "__main__":
    logger.info("Starting the FastMCP Weather service...")
    mcp.run(transport="sse")
    logger.info("FastMCP Weather service is running.")

