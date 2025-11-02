#!/bin/bash

# Mobile Frontend Registration Diagnostics
# Run this script to diagnose registration issues

echo "🔍 Mobile Frontend Registration Diagnostics"
echo "==========================================="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print status
print_status() {
    if [ $1 -eq 0 ]; then
        echo -e "${GREEN}✅ $2${NC}"
    else
        echo -e "${RED}❌ $2${NC}"
    fi
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

echo "1. Checking Docker Services..."
echo "==============================="

# Check if containers are running
services=("mobile_frontend" "mobile_reverse_proxy" "api_gateway" "user_service")
for service in "${services[@]}"; do
    if docker ps | grep -q "$service"; then
        print_status 0 "$service is running"
    else
        print_status 1 "$service is not running"
        echo "   Run: docker-compose up -d $service"
    fi
done

echo ""
echo "2. Testing Network Connectivity..."
echo "=================================="

# Test reverse proxy health
if curl -s -f http://localhost:3003/health > /dev/null; then
    print_status 0 "Reverse proxy health check"
else
    print_status 1 "Reverse proxy health check"
    echo "   The reverse proxy is not responding on port 3003"
fi

# Test API Gateway
if curl -s -f http://localhost:8000/api/users/ > /dev/null; then
    print_status 0 "API Gateway connectivity"
else
    print_status 1 "API Gateway connectivity"
    echo "   The API Gateway is not responding on port 8000"
fi

# Test reverse proxy to API Gateway
if curl -s -f http://localhost:3003/api/users/ > /dev/null; then
    print_status 0 "Reverse proxy → API Gateway routing"
else
    print_status 1 "Reverse proxy → API Gateway routing"
    echo "   The reverse proxy cannot route to the API Gateway"
fi

echo ""
echo "3. Testing Registration Endpoint..."
echo "==================================="

# Test registration endpoint
response=$(curl -s -w "%{http_code}" -o /tmp/reg_test.json \
    -X POST "http://localhost:3003/api/users/register" \
    -H "Content-Type: application/x-www-form-urlencoded" \
    -H "Origin: http://localhost:3001" \
    -d "email=diagnostic-test@example.com&password=testpass123&full_name=Diagnostic Test")

if [ "$response" = "200" ]; then
    print_status 0 "Registration endpoint test"
    echo "   Response: $(cat /tmp/reg_test.json)"
elif [ "$response" = "409" ]; then
    print_status 0 "Registration endpoint test (user already exists)"
else
    print_status 1 "Registration endpoint test (HTTP $response)"
    echo "   Response: $(cat /tmp/reg_test.json 2>/dev/null || echo 'No response')"
fi

echo ""
echo "4. Checking Mobile Frontend Configuration..."
echo "============================================"

# Check if mobile frontend has correct API URL (relative URLs)
if docker exec mobile_frontend grep -q '/api/users/register' /usr/share/nginx/html/main.dart.js 2>/dev/null; then
    print_status 0 "Mobile frontend built with correct API URL (relative)"
else
    print_status 1 "Mobile frontend not built with correct API URL"
    echo "   The mobile frontend may be using absolute URLs"
    echo "   Run: docker-compose build --no-cache mobile_frontend"
fi

# Check mobile frontend accessibility
if curl -s -f http://localhost:3001/ > /dev/null; then
    print_status 0 "Mobile frontend accessibility"
else
    print_status 1 "Mobile frontend accessibility"
    echo "   The mobile frontend is not accessible on port 3001"
fi

# NEW: Test API proxy through mobile frontend
if curl -s -f http://localhost:3001/api/users/ > /dev/null; then
    print_status 0 "Mobile frontend API proxy"
else
    print_status 1 "Mobile frontend API proxy"
    echo "   The mobile frontend cannot proxy API requests"
fi

echo ""
echo "5. CORS and Security Headers..."
echo "==============================="

# Test CORS headers
cors_test=$(curl -s -I -H "Origin: http://localhost:3001" http://localhost:3003/api/users/ | grep -i "access-control-allow-origin" || echo "")
if [ -n "$cors_test" ]; then
    print_status 0 "CORS headers present"
    echo "   $cors_test"
else
    print_status 1 "CORS headers missing"
    echo "   This may cause browser-side errors"
fi

echo ""
echo "📋 Summary and Recommendations:"
echo "==============================="

# Check overall health
unhealthy_count=0

# Count unhealthy services
for service in "${services[@]}"; do
    if ! docker ps | grep -q "$service"; then
        ((unhealthy_count++))
    fi
done

if [ $unhealthy_count -eq 0 ] && [ "$response" = "200" ] || [ "$response" = "409" ]; then
    echo -e "${GREEN}🎉 System appears to be working correctly!${NC}"
    echo ""
    echo "If you're still experiencing registration issues:"
    echo "1. Clear your browser cache (Ctrl+Shift+R)"
    echo "2. Check browser developer console for errors"
    echo "3. Ensure you're accessing http://localhost:3001"
else
    echo -e "${RED}⚠️  Issues detected that may prevent registration${NC}"
    echo ""
    echo "Quick fixes to try:"
    echo "1. Restart all services: docker-compose down && docker-compose up -d"
    echo "2. Rebuild mobile frontend: docker-compose build --no-cache mobile_frontend"
    echo "3. Check service logs: docker-compose logs mobile_reverse_proxy"
fi

echo ""
echo "🔗 Service URLs:"
echo "  • Mobile Frontend: http://localhost:3001"
echo "  • Reverse Proxy: http://localhost:3003"
echo "  • API Gateway: http://localhost:8000"

# Cleanup
rm -f /tmp/reg_test.json

echo ""
echo "For more help, see: Reverse_Proxy/README.md"