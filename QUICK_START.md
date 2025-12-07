# Reverse Proxy - Quick Start Guide

## 🚀 Getting Started in 5 Minutes

### Step 1: Verify Installation

All files are already created in the `Reverse_Proxy` directory:

```
Reverse_Proxy/
├── Dockerfile                      ✅ Container configuration
├── nginx.conf                      ✅ Nginx configuration  
├── .dockerignore                   ✅ Docker ignore file
├── README.md                       ✅ Full documentation
├── IMPLEMENTATION_SUMMARY.md       ✅ Implementation report
├── MOBILE_FRONTEND_SETUP.md        ✅ Mobile integration guide
├── test_reverse_proxy.ps1          ✅ Test script
└── QUICK_START.md                  ✅ This guide
```

### Step 2: Start the Reverse Proxy

The reverse proxy is **already running** on port 9000!

To verify:
```powershell
docker ps --filter "name=reverse_proxy"
```

Expected output:
```
NAMES           STATUS                   PORTS
reverse_proxy   Up X minutes             0.0.0.0:9000->80/tcp
```

### Step 3: Test the Reverse Proxy

Run the automated test:
```powershell
& ".\Reverse_Proxy\test_reverse_proxy.ps1"
```

Or test manually:
```powershell
# Health check
Invoke-RestMethod -Uri "http://localhost:9000/health"

# User service
Invoke-RestMethod -Uri "http://localhost:9000/api/users/"

# Chat service
Invoke-RestMethod -Uri "http://localhost:9000/api/chat/health"

# Canvas service
Invoke-RestMethod -Uri "http://localhost:9000/api/canvas?id=test"
```

### Step 4: Update Mobile Frontend

Update your mobile app to use the reverse proxy:

**For Android Emulator:**
```dart
static const String baseUrl = 'http://10.0.2.2:9000/api';
```

**For iOS Simulator:**
```dart
static const String baseUrl = 'http://localhost:9000/api';
```

**For Physical Device:**
```dart
static const String baseUrl = 'http://YOUR_COMPUTER_IP:9000/api';
```

See `MOBILE_FRONTEND_SETUP.md` for complete instructions.

## 📊 What You Get

### Security Features ✅
- ✅ Rate limiting (30 requests/second)
- ✅ Security headers (XSS, Clickjacking protection)
- ✅ Request size limits (10MB max)
- ✅ Path filtering (blocks .env, .git, etc.)
- ✅ Connection limits (10 concurrent per IP)

### Performance Features ✅
- ✅ Response caching (1-minute TTL)
- ✅ Connection pooling (32 connections)
- ✅ Buffer optimization
- ✅ WebSocket support

### Monitoring Features ✅
- ✅ Health endpoint: `/health`
- ✅ Cache status header: `X-Cache-Status`
- ✅ Access logs
- ✅ Error logs

## 🔧 Common Commands

### View Logs
```powershell
# Real-time logs
docker logs -f reverse_proxy

# Last 20 lines
docker logs reverse_proxy --tail 20
```

### Restart Service
```powershell
docker-compose restart reverse_proxy
```

### Rebuild After Config Changes
```powershell
docker-compose build reverse_proxy
docker-compose up -d reverse_proxy
```

### Stop Service
```powershell
docker-compose stop reverse_proxy
```

### Start Service
```powershell
docker-compose start reverse_proxy
```

## 📈 Architecture Flow

```
Mobile App (Port 9000)
    ↓
Reverse Proxy
    ↓
API Gateway (Port 8000)
    ↓
Backend Services
    ├─ User Service
    ├─ Chat Service
    ├─ Canvas Service
    └─ Comments Service
```

## 🎯 Quick Tests

### Test 1: Is it running?
```powershell
Invoke-RestMethod -Uri "http://localhost:9000/health"
# Expected: "healthy"
```

### Test 2: Can I access APIs?
```powershell
Invoke-RestMethod -Uri "http://localhost:9000/api/users/"
# Expected: Array of users
```

### Test 3: Is caching working?
```powershell
$response = Invoke-WebRequest -Uri "http://localhost:9000/api/users/"
$response.Headers.'X-Cache-Status'
# Expected: "HIT" or "MISS"
```

### Test 4: Are security headers present?
```powershell
$response = Invoke-WebRequest -Uri "http://localhost:9000/api/users/"
$response.Headers.'X-Frame-Options'
# Expected: "SAMEORIGIN"
```

## 🐛 Troubleshooting

### Problem: Connection refused
**Solution:** Verify container is running:
```powershell
docker ps | Select-String "reverse_proxy"
```

### Problem: 503 Error (Rate limited)
**Solution:** Wait a few seconds or increase rate limit in `nginx.conf`

### Problem: 403 Forbidden
**Solution:** This is normal for root path `/`. Use `/api/*` endpoints instead.

### Problem: Changes not applying
**Solution:** Rebuild the container:
```powershell
docker-compose build --no-cache reverse_proxy
docker-compose up -d reverse_proxy
```

## 📚 Full Documentation

- **README.md** - Complete implementation guide (12,000 words)
- **IMPLEMENTATION_SUMMARY.md** - Detailed implementation report
- **MOBILE_FRONTEND_SETUP.md** - Mobile app integration
- **API_ENDPOINTS_GUIDE.md** - (Root dir) All API endpoints

## ✅ Success Criteria

Your reverse proxy is working if:

1. ✅ Container is running: `docker ps | grep reverse_proxy`
2. ✅ Health check responds: `http://localhost:9000/health`
3. ✅ APIs are accessible: `http://localhost:9000/api/users/`
4. ✅ Security headers present: `X-Frame-Options`, `X-XSS-Protection`
5. ✅ Cache is working: `X-Cache-Status: HIT`

## 🎉 You're Done!

The reverse proxy is fully operational and ready for use!

**Next step:** Update your mobile frontend to use `http://10.0.2.2:9000/api` (Android) or `http://localhost:9000/api` (iOS).

---

**Need help?** Check the full documentation in `README.md` or run the test script to verify everything is working correctly.
