from routes import energy_usage
from graphql_api.schema import schema
from strawberry.fastapi import GraphQLRouter
import uvicorn
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
import logging
from fastapi.logger import logger

# Configure Logging to use Gunicorn log settings, if available
gunicorn_logger = logging.getLogger('gunicorn.error')
logger.handlers = gunicorn_logger.handlers
logger.setLevel(gunicorn_logger.level)


# FastAPI Application Setup
app = FastAPI()

# Configure CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include REST router
app.include_router(energy_usage.router)

# Include GraphQL
graphql_app = GraphQLRouter(schema)
app.include_router(graphql_app, prefix="/graphql")


@app.get("/")
def get_status() -> str:
    """Root endpoint to check if the application is running."""
    logger.info("**Logging - RUNNING**")
    return "running"

# Run the application using Uvicorn when executed directly
if __name__ == "__main__":
    uvicorn.run("main:app", host="0.0.0.0", port=8000)