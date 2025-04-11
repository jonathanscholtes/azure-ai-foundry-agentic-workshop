from langchain_core.tools import tool

from user_functions import vector_search



@tool
def get_weather_tool(location: str):
    """Call to get the current weather."""
    if location.lower() in ["sf", "san francisco"]:
        return "It's 60 degrees and foggy."
    else:
        return "It's 90 degrees and sunny."


@tool
def vector_search_tool(query: str):
    """Searches knowledge base using vector similarity."""
    return vector_search(query)