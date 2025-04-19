########## Wrapper Tools Used By LangChain/LangGraph #########

from langchain_core.tools import tool
from typing import Union
from user_functions import vector_search



@tool
def get_weather_tool(location: str):
    """Call to get the current weather."""
    if location.lower() in ["sf", "san francisco"]:
        return "It's 60 degrees and foggy."
    else:
        return "It's 90 degrees and sunny."

@tool
def convert_fahrenheit_to_celsius(fahrenheit: float) -> str:
    """
    Converts a temperature from Fahrenheit (F) to Celsius (C) and returns a string formatted as 'X°C'.
    
    Use this tool when you are given a temperature in Fahrenheit and need to return the value in Celsius.
    """
    celsius = (fahrenheit - 32) * 5 / 9
    return f"{celsius:.1f}°C"

@tool
def vector_search_tool(query: str):
    """Searches knowledge base using vector similarity."""
    return vector_search(query)