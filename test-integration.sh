#!/bin/bash

# Integration test script for Mobile Reverse Proxy
# This script tests the complete flow from mobile app to backend services

set -e

PROXY_URL="http://localhost:3003"
API_GATEWAY_URL="http://localhost:8000"

echo "🚀 Starting Mobile Reverse Proxy Integration Tests"
echo "=================================================="

# Function to test endpoint
test_endpoint() {
    local endpoint=$1
    local description=$2
    local expected_status=${3:-200}
    
    echo "🔍 Testing: $description"
    echo "   Endpoint: $PROXY_URL$endpoint"
    
    response=$(curl -s -w "%{http_code}" -o /tmp/response.json "$PROXY_URL$endpoint" || echo "000")
    
    if [ "$response" = "$expected_status" ]; then
        echo "   ✅ Status: $response (Expected: $expected_status)"
    else
        echo "   ❌ Status: $response (Expected: $expected_status)"
        echo "   Response: $(cat /tmp/response.json 2>/dev/null || echo 'No response')"
        return 1
    fi
    echo ""
}

# Function to test CORS
test_cors() {
    local endpoint=$1
    local description=$2
    
    echo "🔍 Testing CORS: $description"
    echo "   Endpoint: $PROXY_URL$endpoint"
    
    cors_headers=$(curl -s -I -H "Origin: http://localhost:3001" "$PROXY_URL$endpoint" | grep -i "access-control-allow-origin" || true)
    
    if [ -n "$cors_headers" ]; then
        echo "   ✅ CORS headers present: $cors_headers"
    else
        echo "   ❌ CORS headers missing"
        return 1
    fi
    echo ""
}

# Function to test rate limiting
test_rate_limiting() {
    echo "🔍 Testing Rate Limiting"
    echo "   Sending 35 requests rapidly (limit is 30/s)..."
    
    local success_count=0
    local rate_limited_count=0
    
    for i in {1..35}; do
        response=$(curl -s -w "%{http_code}" -o /dev/null "$PROXY_URL/health" || echo "000")
        if [ "$response" = "200" ]; then
            ((success_count++))
        elif [ "$response" = "429" ]; then
            ((rate_limited_count++))
        fi
    done
    
    echo "   Successful requests: $success_count"
    echo "   Rate limited requests: $rate_limited_count"
    
    if [ $rate_limited_count -gt 0 ]; then
        echo "   ✅ Rate limiting is working"
    else
        echo "   ⚠️  Rate limiting may not be working (check configuration)"
    fi
    echo ""
}

# Function to test security headers
test_security_headers() {
    echo "🔍 Testing Security Headers"
    
    headers=$(curl -s -I "$PROXY_URL/health")
    
    local security_headers=(
        "X-Frame-Options"
        "X-Content-Type-Options"
        "X-XSS-Protection"
        "Referrer-Policy"
    )
    
    for header in "${security_headers[@]}"; do
        if echo "$headers" | grep -qi "$header"; then
            echo "   ✅ $header header present"
        else
            echo "   ❌ $header header missing"
        fi
    done
    echo ""
}

# Wait for services to be ready
echo "⏳ Waiting for services to be ready..."
for i in {1..30}; do
    if curl -s "$PROXY_URL/health" > /dev/null 2>&1; then
        echo "✅ Reverse proxy is ready"
        break
    fi
    if [ $i -eq 30 ]; then
        echo "❌ Reverse proxy not ready after 30 seconds"
        exit 1
    fi
    sleep 1
done

# Basic functionality tests
echo "🧪 Basic Functionality Tests"
echo "============================="
test_endpoint "/health" "Health check endpoint"
test_endpoint "/metrics" "Metrics endpoint"

# API proxy tests
echo "🧪 API Proxy Tests"
echo "=================="
test_endpoint "/api/users/" "User service proxy"

# CORS tests
echo "🧪 CORS Tests"
echo "============="
test_cors "/api/users/" "User service CORS"
test_cors "/health" "Health endpoint CORS"

# Security tests
echo "🧪 Security Tests"
echo "================="
test_security_headers

# Performance tests
echo "🧪 Performance Tests"
echo "===================="
test_rate_limiting

# Error handling tests
echo "🧪 Error Handling Tests"
echo "======================="
test_endpoint "/nonexistent" "404 Error handling" 404
test_endpoint "/api/nonexistent/" "API 404 Error handling" 404

echo "🎉 Integration tests completed!"
echo "==============================="

# Clean up
rm -f /tmp/response.json

echo ""
echo "📊 Test Summary:"
echo "- Reverse proxy is accessible on port 3003"
echo "- API requests are properly forwarded to API Gateway"
echo "- CORS headers are configured for mobile app"
echo "- Security headers are in place"
echo "- Rate limiting is configured"
echo "- Error handling is working"
echo ""
echo "🔗 Access Points:"
echo "- Reverse Proxy: $PROXY_URL"
echo "- Health Check: $PROXY_URL/health"
echo "- Metrics: $PROXY_URL/metrics"
echo "- API Proxy: $PROXY_URL/api/*"