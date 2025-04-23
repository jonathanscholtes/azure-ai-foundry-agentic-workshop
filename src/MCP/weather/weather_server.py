from mcp.server.fastmcp import FastMCP
import uvicorn

mcp = FastMCP("Weather")

@mcp.tool()
def get_weather_tool(location: str):
    """Call to get the current weather."""
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
    celsius = (fahrenheit - 32) * 5 / 9
    return f"{celsius:.1f}°C"

if __name__ == "__main__":
    mcp.run(transport="sse")

