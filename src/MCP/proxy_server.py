from fastapi import FastAPI, Request
from fastapi.responses import StreamingResponse
import httpx

app = FastAPI()

BACKENDS = {
    "weather": "http://localhost:8001",
    "search": "http://localhost:8002",
    "datacenters": "http://localhost:8003",
}

@app.api_route("/{group}/{path:path}", methods=["GET", "POST"])
async def proxy(group: str, path: str, request: Request):
    if group not in BACKENDS:
        return {"error": f"Unknown tool group: {group}"}

    backend_url = f"{BACKENDS[group]}/{path}"
    headers = dict(request.headers)

    async with httpx.AsyncClient(timeout=None) as client:
        req = client.build_request(
            method=request.method,
            url=backend_url,
            headers=headers,
            content=await request.body()
        )
        resp = await client.send(req, stream=True)

        return StreamingResponse(
            resp.aiter_raw(),
            status_code=resp.status_code,
            headers=resp.headers
        )