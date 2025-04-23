from fastapi import FastAPI, Request
from fastapi.responses import StreamingResponse
import httpx
from httpx import HTTPStatusError, ConnectError
import logging

# Set up logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = FastAPI()

BACKENDS = {
    "weather": "https://ca-foundry-lab-51biegbjlxd3.ashysky-c599812a.eastus2.azurecontainerapps.io:8001",
    "search": "http://localhost:8002",
    "datacenters": "http://localhost:8003",
}

@app.api_route("/{group}/{path:path}", methods=["GET", "POST"])
async def proxy(group: str, path: str, request: Request):
    if group not in BACKENDS:
        logger.error(f"Unknown tool group: {group}")
        return {"error": f"Unknown tool group: {group}"}

    backend_url = f"{BACKENDS[group]}/{path}"
    headers = dict(request.headers)

    try:
        logger.info(f"Sending request to {backend_url} with method {request.method}")
        async with httpx.AsyncClient(timeout=10.0) as client:  # 10 seconds timeout
            req = client.build_request(
                method=request.method,
                url=backend_url,
                headers=headers,
                content=await request.body()
            )
            resp = await client.send(req, stream=True)

            logger.info(f"Received response with status code {resp.status_code}")
            return StreamingResponse(
                resp.aiter_raw(),
                status_code=resp.status_code,
                headers=resp.headers
            )
    
    except ConnectError:
        logger.error("Failed to connect to the backend service.")
        return {"error": "Failed to connect to the backend service."}
    except HTTPStatusError as e:
        logger.error(f"Backend returned an error: {e.response.status_code}")
        return {"error": f"Backend returned an error: {e.response.status_code}"}
    except httpx.RequestError as e:
        logger.error(f"An error occurred while requesting: {str(e)}")
        return {"error": f"An error occurred while requesting: {str(e)}"}
    except Exception as e:
        logger.error(f"An unexpected error occurred: {str(e)}")
        return {"error": f"An unexpected error occurred: {str(e)}"}
