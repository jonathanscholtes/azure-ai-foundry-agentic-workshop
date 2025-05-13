# Use Python 3.10 as base image
FROM python:3.10-slim

# Set working directory
WORKDIR /app

# Install dependencies
COPY requirements.txt /app/
RUN pip install -r requirements.txt

# Copy the application files
COPY . /app/

# Set environment variable for the port (this can be changed if needed)
ENV MCP_PORT 8082

# Expose the required port
EXPOSE 8082

# Command to run the application (you can replace with your FastMCP start command)
CMD ["python", "app.py"]
