#!/bin/bash

# Mobile Reverse Proxy Management Script
# Usage: ./manage.sh [build|start|stop|test|logs|health]

set -e

PROXY_NAME="mobile_reverse_proxy"
PROXY_PORT="3003"

case "$1" in
  build)
    echo "Building Mobile Reverse Proxy..."
    docker-compose build mobile_reverse_proxy
    echo "✅ Build completed"
    ;;
    
  start)
    echo "Starting Mobile Reverse Proxy..."
    docker-compose up -d mobile_reverse_proxy
    echo "✅ Mobile Reverse Proxy started on port $PROXY_PORT"
    ;;
    
  stop)
    echo "Stopping Mobile Reverse Proxy..."
    docker-compose stop mobile_reverse_proxy
    echo "✅ Mobile Reverse Proxy stopped"
    ;;
    
  restart)
    echo "Restarting Mobile Reverse Proxy..."
    docker-compose restart mobile_reverse_proxy
    echo "✅ Mobile Reverse Proxy restarted"
    ;;
    
  test)
    echo "Testing Mobile Reverse Proxy..."
    
    # Test health endpoint
    echo "🔍 Testing health endpoint..."
    if curl -f -s "http://localhost:$PROXY_PORT/health" > /dev/null; then
      echo "✅ Health check passed"
    else
      echo "❌ Health check failed"
      exit 1
    fi
    
    # Test API proxy
    echo "🔍 Testing API proxy..."
    if curl -f -s "http://localhost:$PROXY_PORT/api/users/" > /dev/null; then
      echo "✅ API proxy test passed"
    else
      echo "❌ API proxy test failed"
      exit 1
    fi
    
    # Test CORS headers
    echo "🔍 Testing CORS headers..."
    CORS_HEADERS=$(curl -s -I -H "Origin: http://localhost:3001" "http://localhost:$PROXY_PORT/api/users/" | grep -i "access-control-allow-origin" || true)
    if [ -n "$CORS_HEADERS" ]; then
      echo "✅ CORS headers present"
    else
      echo "❌ CORS headers missing"
      exit 1
    fi
    
    echo "✅ All tests passed!"
    ;;
    
  logs)
    echo "Showing Mobile Reverse Proxy logs..."
    docker-compose logs -f mobile_reverse_proxy
    ;;
    
  health)
    echo "Checking Mobile Reverse Proxy health..."
    
    # Container status
    if docker ps | grep -q $PROXY_NAME; then
      echo "✅ Container is running"
    else
      echo "❌ Container is not running"
      exit 1
    fi
    
    # Health endpoint
    HEALTH_RESPONSE=$(curl -s "http://localhost:$PROXY_PORT/health" || echo "ERROR")
    if [[ $HEALTH_RESPONSE == *"Healthy"* ]]; then
      echo "✅ Health endpoint responding"
    else
      echo "❌ Health endpoint not responding"
      exit 1
    fi
    
    # Metrics endpoint
    METRICS_RESPONSE=$(curl -s "http://localhost:$PROXY_PORT/metrics" || echo "ERROR")
    if [[ $METRICS_RESPONSE == *"Active"* ]]; then
      echo "✅ Metrics endpoint responding"
    else
      echo "❌ Metrics endpoint not responding"
    fi
    
    echo "✅ Health check completed"
    ;;
    
  config-test)
    echo "Testing Nginx configuration..."
    docker exec $PROXY_NAME nginx -t
    echo "✅ Nginx configuration is valid"
    ;;
    
  *)
    echo "Usage: $0 {build|start|stop|restart|test|logs|health|config-test}"
    echo ""
    echo "Commands:"
    echo "  build        - Build the reverse proxy container"
    echo "  start        - Start the reverse proxy service"
    echo "  stop         - Stop the reverse proxy service"
    echo "  restart      - Restart the reverse proxy service"
    echo "  test         - Run comprehensive tests"
    echo "  logs         - Show container logs"
    echo "  health       - Check service health"
    echo "  config-test  - Test Nginx configuration"
    exit 1
    ;;
esac