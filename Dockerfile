# Reverse Proxy Dockerfile
# Based on Nginx Alpine for lightweight and secure proxy

FROM nginx:1.27-alpine

# Remove default nginx configuration
RUN rm /etc/nginx/conf.d/default.conf

# Copy custom nginx configuration
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Create cache directories for improved performance
RUN mkdir -p /var/cache/nginx/proxy_temp && \
    mkdir -p /var/cache/nginx/client_temp && \
    chown -R nginx:nginx /var/cache/nginx

# Expose port 80 for HTTP traffic
EXPOSE 80

# Health check to ensure nginx is running properly
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD wget --no-verbose --tries=1 --spider http://127.0.0.1/health || exit 1

# Run nginx in foreground
CMD ["nginx", "-g", "daemon off;"]
