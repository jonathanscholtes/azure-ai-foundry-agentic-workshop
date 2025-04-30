# Use NGINX as base image
FROM nginx:latest

# Copy the NGINX configuration file into the container
COPY nginx.conf /etc/nginx/nginx.conf
COPY index.html /etc/nginx/html/index.html

# Expose the HTTP port for NGINX
EXPOSE 80
