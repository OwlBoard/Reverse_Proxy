# Use the official nginx image as the base
FROM nginx:alpine

# Copy the nginx configuration file
COPY nginx.conf /etc/nginx/nginx.conf

# Copy any additional configuration files if needed
# COPY ssl/ /etc/nginx/ssl/

# Expose port 80 for HTTP traffic
EXPOSE 80

# Add health check (using curl instead of wget for better compatibility)
HEALTHCHECK --interval=30s --timeout=3s --start-period=10s --retries=3 \
  CMD curl -f http://localhost/health || exit 1

# Install curl for health checks
RUN apk add --no-cache curl

# Start nginx
CMD ["nginx", "-g", "daemon off;"]