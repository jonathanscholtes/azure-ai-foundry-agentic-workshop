############# Plugins User by Semantic Kernel ###########


from semantic_kernel.functions import kernel_function
from user_functions import vector_search
from typing import Annotated

class WeatherPlugin:

    @kernel_function
    async def get_weather(location: Annotated[str, "The location to get the current weather"]):
        """Call to get the current weather."""
        if location.lower() in ["sf", "san francisco"]:
            return "It's 60 degrees and foggy."
        else:
            return "It's 90 degrees and sunny."

    @kernel_function
    async def get_sunrise_sunset(location: Annotated[str, "The location to get the sunrise and sunset"]):
        """Call to get the sunrise and sunset for a given location."""
        
        return "Sunrise: 6:05 A.M, Sunset: 8:15 P.M"


class DataCenterPlugin:
    """Class for managing data center operations."""

    @kernel_function
    def get_datacenter_documents(query:  Annotated[str, "The search query to perform similarity search"]):
        """Searches the knowledge base using vector similarity."""
        return vector_search(query)