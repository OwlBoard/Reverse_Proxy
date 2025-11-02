# Mobile Reverse Proxy Implementation

## Overview

This document describes the implementation of a dedicated reverse proxy service for the Mobile Frontend that acts as a secure intermediary between mobile clients and the OwlBoard API Gateway. This architecture pattern provides enhanced security, improved performance, and better separation of concerns.

## Architecture Diagram

```
Mobile App (Flutter) → Mobile Reverse Proxy (Nginx) → API Gateway (Nginx) → Backend Services
     :3001                    :3003                        :8000              :5000/:8001/:8002/:8080
```

## Implementation Details

### 1. Service Structure

The reverse proxy is implemented as a separate Docker service with the following structure:

```
Reverse_Proxy/
├── Dockerfile              # Container definition
├── nginx.conf             # Nginx configuration with security features
├── docker-compose.yml     # Standalone service configuration
└── README.md              # This documentation
```

### 2. Key Components

#### 2.1 Dockerfile
```dockerfile
FROM nginx:alpine
COPY nginx.conf /etc/nginx/nginx.conf
EXPOSE 80
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD wget --quiet --tries=1 --spider http://localhost/health || exit 1
CMD ["nginx", "-g", "daemon off;"]
```

#### 2.2 Nginx Configuration Features
- **Rate Limiting**: 30 requests/second with burst capacity
- **Security Headers**: X-Frame-Options, X-Content-Type-Options, CSP
- **CORS Configuration**: Mobile-specific CORS headers
- **WebSocket Support**: Full upgrade header support
- **Error Handling**: Custom error pages and graceful fallbacks
- **Performance Optimization**: Gzip compression, connection keepalive

#### 2.3 Docker Compose Integration
```yaml
mobile_reverse_proxy:
  build:
    context: ./Reverse_Proxy
  container_name: mobile_reverse_proxy
  ports:
    - "3003:80"
  depends_on:
    - api_gateway
  networks:
    - owlboard-network
```

## Implementation Steps

### Step 1: Create Reverse Proxy Service

1. **Created Reverse_Proxy Directory Structure**
   ```bash
   mkdir Reverse_Proxy
   cd Reverse_Proxy
   ```

2. **Implemented Nginx Configuration**
   - Configured upstream for API Gateway
   - Added security headers and rate limiting
   - Implemented CORS for mobile clients
   - Added health check and metrics endpoints

3. **Created Dockerfile**
   - Used nginx:alpine as base image
   - Added health check configuration
   - Optimized for container environment

### Step 2: Update Docker Compose Configuration

1. **Added Service to Main docker-compose.yml**
   ```yaml
   mobile_reverse_proxy:
     build:
       context: ./Reverse_Proxy
     ports:
       - "3003:80"
     depends_on:
       - api_gateway
   ```

2. **Updated Network Configuration**
   - Ensured service is on owlboard-network
   - Configured proper service dependencies

### Step 3: Update Mobile Frontend Configuration

1. **Modified Flutter API Configuration**
   ```dart
   static const String baseUrl = 
       String.fromEnvironment('REVERSE_PROXY_URL', 
                              defaultValue: 'http://localhost:3003');
   ```

2. **Updated Environment Variables**
   - Changed from direct API Gateway access
   - Now routes through reverse proxy on port 3003

## Security Improvements

### 1. **Enhanced Access Control**
```nginx
# Rate limiting to prevent abuse
limit_req_zone $binary_remote_addr zone=api:10m rate=30r/s;
limit_req zone=api burst=50 nodelay;

# Security headers
add_header X-Frame-Options "SAMEORIGIN" always;
add_header X-Content-Type-Options "nosniff" always;
add_header X-XSS-Protection "1; mode=block" always;
```

**Benefits:**
- Prevents DDoS attacks through rate limiting
- Protects against common web vulnerabilities
- Provides consistent security policy enforcement

### 2. **Request Filtering and Validation**
```nginx
# Block common attack vectors
location ~* \.(php|asp|aspx|jsp)$ {
    deny all;
    return 444;
}

# Block hidden files
location ~ /\. {
    deny all;
    return 444;
}
```

**Benefits:**
- Filters malicious requests before reaching API Gateway
- Prevents directory traversal attacks
- Blocks access to sensitive file types

### 3. **Header Management**
```nginx
# Remove sensitive headers from client
proxy_hide_header X-Powered-By;
server_tokens off;

# Add security headers
proxy_set_header X-Forwarded-Host $server_name;
proxy_set_header X-Real-IP $remote_addr;
```

**Benefits:**
- Hides server information from attackers
- Properly forwards client information to backend
- Maintains audit trail for security analysis

### 4. **Network Isolation**
- Mobile clients only communicate with reverse proxy
- Reverse proxy communicates with API Gateway on internal network
- Backend services remain isolated from direct external access

## Performance Benefits

### 1. **Connection Pooling**
```nginx
upstream api_gateway {
    server api_gateway:80;
    keepalive 32;
}
```
**Result:** Reduced connection overhead and improved response times

### 2. **Request Buffering**
```nginx
proxy_buffering on;
proxy_buffer_size 4k;
proxy_buffers 8 4k;
proxy_busy_buffers_size 8k;
```
**Result:** Better handling of large requests and improved throughput

### 3. **Compression**
```nginx
gzip on;
gzip_vary on;
gzip_min_length 1024;
gzip_types text/plain text/css application/json;
```
**Result:** Reduced bandwidth usage and faster response times

## Monitoring and Observability

### 1. **Health Check Endpoint**
```bash
curl http://localhost:3003/health
# Response: Mobile Reverse Proxy - Healthy
```

### 2. **Metrics Endpoint**
```bash
curl http://localhost:3003/metrics
# Response: Status info and upstream health
```

### 3. **Logging Configuration**
```yaml
logging:
  driver: "json-file"
  options:
    max-size: "10m"
    max-file: "3"
```

## Testing the Implementation

### 1. **Start the Services**
```bash
# From project root
docker-compose up --build mobile_reverse_proxy api_gateway

# Or start all services
docker-compose up --build
```

### 2. **Test Reverse Proxy Functionality**
```bash
# Test health check
curl http://localhost:3003/health

# Test API proxy (should return user service response)
curl http://localhost:3003/api/users/

# Test with mobile app configuration
curl -H "Origin: http://localhost:3001" \
     -H "Content-Type: application/json" \
     http://localhost:3003/api/users/
```

### 3. **Verify Security Headers**
```bash
curl -I http://localhost:3003/api/users/
# Should show security headers:
# X-Frame-Options: SAMEORIGIN
# X-Content-Type-Options: nosniff
# X-XSS-Protection: 1; mode=block
```

### 4. **Test Rate Limiting**
```bash
# Send multiple rapid requests to test rate limiting
for i in {1..60}; do
  curl -s -o /dev/null -w "%{http_code}\n" http://localhost:3003/api/users/
done
# Should show 429 (Too Many Requests) after hitting rate limit
```

## Deployment and Operations

### 1. **Environment Variables**
```yaml
environment:
  - NGINX_WORKER_PROCESSES=auto
  - NGINX_WORKER_CONNECTIONS=1024
  - REVERSE_PROXY_URL=http://localhost:3003  # For mobile app
```

### 2. **Service Dependencies**
```yaml
depends_on:
  - api_gateway
```

### 3. **Network Configuration**
```yaml
networks:
  - owlboard-network
```

## Recommendations for Replication

### 1. **Security Best Practices**

#### Rate Limiting Configuration
```nginx
# Adjust based on your traffic patterns
limit_req_zone $binary_remote_addr zone=api:10m rate=30r/s;
limit_req zone=api burst=50 nodelay;
```

#### SSL/TLS Implementation (Production)
```nginx
server {
    listen 443 ssl http2;
    ssl_certificate /path/to/certificate.crt;
    ssl_certificate_key /path/to/private.key;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE+AESGCM:ECDHE+AES256:ECDHE+AES128:!aNULL:!MD5:!DSS;
}
```

### 2. **Performance Optimization**

#### Worker Process Configuration
```nginx
# In nginx.conf
worker_processes auto;
worker_connections 1024;
worker_rlimit_nofile 2048;
```

#### Caching Strategy (Optional)
```nginx
# Add caching for static API responses
location /api/static/ {
    proxy_cache api_cache;
    proxy_cache_valid 200 5m;
    proxy_cache_key "$request_uri";
    proxy_pass http://api_gateway/api/static/;
}
```

### 3. **Monitoring Setup**

#### Nginx Status Module
```nginx
location /nginx_status {
    stub_status on;
    access_log off;
    allow 127.0.0.1;
    deny all;
}
```

#### Custom Metrics Collection
```bash
# Add to monitoring script
curl -s http://localhost:3003/nginx_status | \
  awk '/Active connections/ {print "nginx_connections " $3}'
```

### 4. **Error Handling**

#### Custom Error Pages
```nginx
error_page 502 503 504 /50x.html;
location = /50x.html {
    root /usr/share/nginx/html;
    internal;
}
```

#### Graceful Degradation
```nginx
# Fallback for API Gateway unavailability
location @fallback {
    return 503 '{"error":"Service temporarily unavailable"}';
    add_header Content-Type application/json;
}
```

### 5. **Development Workflow**

#### Local Development
```bash
# For local development, update mobile app config:
export REVERSE_PROXY_URL=http://localhost:3003

# Start only reverse proxy for testing
cd Reverse_Proxy
docker-compose up
```

#### Debugging
```bash
# Check reverse proxy logs
docker logs mobile_reverse_proxy

# Test connectivity
docker exec -it mobile_reverse_proxy ping api_gateway

# Verify nginx configuration
docker exec -it mobile_reverse_proxy nginx -t
```

## Troubleshooting

### Common Issues and Solutions

1. **"Registration failed: 404 page not found" Error**
   
   This error typically occurs when the mobile frontend can't reach the reverse proxy. Follow these steps:
   
   ```bash
   # Step 1: Verify reverse proxy is running and healthy
   docker ps | grep mobile_reverse_proxy
   curl http://localhost:3003/health
   
   # Step 2: Test the registration endpoint directly
   curl -X POST "http://localhost:3003/api/users/register" \
     -H "Content-Type: application/x-www-form-urlencoded" \
     -d "email=test@example.com&password=testpass&full_name=Test User"
   
   # Step 3: Clear browser cache and hard refresh (Ctrl+Shift+R)
   # The mobile frontend might be using a cached version
   
   # Step 4: Check if mobile frontend was rebuilt with correct configuration
   docker exec mobile_frontend grep -r "localhost:3003" /usr/share/nginx/html/
   ```
   
   **If the grep command returns no results, rebuild the mobile frontend:**
   ```bash
   docker-compose build --no-cache mobile_frontend
   docker-compose up -d mobile_frontend
   ```

2. **502 Bad Gateway**
   ```bash
   # Check API Gateway status
   docker ps | grep api_gateway
   
   # Test connectivity from reverse proxy to API Gateway
   docker exec -it mobile_reverse_proxy curl http://api_gateway/api/users/
   ```

3. **CORS Errors**
   ```bash
   # Verify CORS headers in response
   curl -H "Origin: http://localhost:3001" -I http://localhost:3003/api/users/
   ```

4. **Rate Limiting Issues**
   ```nginx
   # Adjust rate limiting for development in nginx.conf
   limit_req_zone $binary_remote_addr zone=api:10m rate=100r/s;
   ```

5. **Container Health Check Failures**
   ```bash
   # Check health endpoint manually
   docker exec -it mobile_reverse_proxy curl http://localhost/health
   
   # If health check fails, rebuild with updated Dockerfile
   docker-compose build --no-cache mobile_reverse_proxy
   ```

### Mobile Frontend Debugging Steps

1. **Check Browser Developer Console**
   - Open browser DevTools (F12)
   - Go to Network tab
   - Try registering a user
   - Look for failed requests to localhost:3003

2. **Verify API Configuration**
   ```bash
   # Check if the mobile app was built with correct API URL
   docker exec mobile_frontend grep -A5 -B5 "localhost:3003" /usr/share/nginx/html/main.dart.js
   ```

3. **Test Direct API Access**
   ```javascript
   // In browser console on localhost:3001, test:
   fetch('http://localhost:3003/api/users/')
     .then(response => response.json())
     .then(data => console.log(data))
     .catch(error => console.error('Error:', error));
   ```

4. **Hard Refresh the Mobile App**
   - Press Ctrl+Shift+R (or Cmd+Shift+R on Mac)
   - Or clear browser cache completely

### Service Dependency Issues

1. **Ensure Services Start in Correct Order**
   ```bash
   # Start services step by step to isolate issues
   docker-compose up -d mysql_db postgres_db mongo_db redis_db rabbitmq
   docker-compose up -d user_service canvas_service comments_service chat_service
   docker-compose up -d api_gateway
   docker-compose up -d mobile_reverse_proxy
   docker-compose up -d mobile_frontend
   ```

2. **Check Service Dependencies**
   ```bash
   # Verify all required services are running
   docker-compose ps
   
   # Check logs for dependency errors
   docker-compose logs mobile_reverse_proxy
   docker-compose logs mobile_frontend
   ```

## Future Enhancements

### 1. **Advanced Security Features**
- JWT token validation at proxy level
- IP whitelisting for administrative endpoints
- Request signing verification

### 2. **Performance Improvements**
- Redis-based rate limiting for cluster deployment
- Advanced caching strategies
- Load balancing across multiple API Gateway instances

### 3. **Monitoring and Analytics**
- Integration with Prometheus/Grafana
- Real-time traffic analytics
- Automated alerting for service health

### 4. **High Availability**
- Multiple reverse proxy instances
- Automatic failover configuration
- Health-based routing

This implementation provides a robust, secure, and scalable solution for mobile API access while maintaining clean separation of concerns and following industry best practices for reverse proxy architecture.