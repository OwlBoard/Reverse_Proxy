# Mobile Frontend Configuration Guide

## Quick Setup - Connect Mobile Frontend to Reverse Proxy

### Option 1: Docker Network (Recommended for Container-based Mobile Frontend)

If your mobile frontend is running in a Docker container on the same network:

```yaml
# In your mobile frontend docker-compose.yml or environment config
environment:
  - API_BASE_URL=http://reverse_proxy/api
  - USER_SERVICE_URL=http://reverse_proxy/api/users
  - COMMENTS_SERVICE_URL=http://reverse_proxy/api/comments
  - CHAT_SERVICE_URL=http://reverse_proxy/api/chat
  - CANVAS_SERVICE_URL=http://reverse_proxy/api/canvas
```

### Option 2: External Access (For Development on Local Machine/Emulator)

For Flutter/Dart mobile app running on local machine or emulator:

```dart
// lib/config/api_config.dart
class ApiConfig {
  // For Android Emulator
  static const String baseUrl = 'http://10.0.2.2:9000/api';
  
  // For iOS Simulator
  // static const String baseUrl = 'http://localhost:9000/api';
  
  // For Physical Device (use your computer's IP)
  // static const String baseUrl = 'http://192.168.1.XXX:9000/api';
  
  // Service endpoints
  static const String userService = '$baseUrl/users';
  static const String commentsService = '$baseUrl/comments';
  static const String chatService = '$baseUrl/chat';
  static const String canvasService = '$baseUrl/canvas';
}
```

### Option 3: Production Configuration

For production deployment with a domain:

```dart
class ApiConfig {
  static const String baseUrl = 'https://api.yourdomain.com/api';
  
  static const String userService = '$baseUrl/users';
  static const String commentsService = '$baseUrl/comments';
  static const String chatService = '$baseUrl/chat';
  static const String canvasService = '$baseUrl/canvas';
}
```

## Testing Your Configuration

### From Flutter/Dart Application

```dart
import 'package:http/http.dart' as http;
import 'dart:convert';

Future<void> testApiConnection() async {
  try {
    // Test health endpoint
    final healthResponse = await http.get(
      Uri.parse('http://10.0.2.2:9000/health'),
    );
    print('Health Check: ${healthResponse.body}');
    
    // Test user service
    final usersResponse = await http.get(
      Uri.parse('http://10.0.2.2:9000/api/users/'),
      headers: {'Content-Type': 'application/json'},
    );
    
    if (usersResponse.statusCode == 200) {
      final users = json.decode(usersResponse.body);
      print('✅ Connected! Found ${users.length} users');
    }
  } catch (e) {
    print('❌ Connection failed: $e');
  }
}
```

### From PowerShell (Testing)

```powershell
# Test from your development machine
Invoke-RestMethod -Uri "http://localhost:9000/api/users/" -Method GET

# Test health endpoint
Invoke-RestMethod -Uri "http://localhost:9000/health" -Method GET
```

## Android Emulator Network Configuration

When using Android Emulator, the special IP address `10.0.2.2` refers to the host machine's localhost.

**Add network permissions to AndroidManifest.xml:**

```xml
<manifest>
    <uses-permission android:name="android.permission.INTERNET" />
    <uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
    
    <application
        android:usesCleartextTraffic="true">
        <!-- Your app configuration -->
    </application>
</manifest>
```

## iOS Simulator Configuration

For iOS Simulator, use `localhost`:

```dart
static const String baseUrl = 'http://localhost:9000/api';
```

**Add network configuration to Info.plist:**

```xml
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSAllowsLocalNetworking</key>
    <true/>
    <key>NSAllowsArbitraryLoads</key>
    <true/>
</dict>
```

## Physical Device Configuration

To test on a physical device:

1. **Find your computer's IP address:**
   ```powershell
   # Windows
   ipconfig | Select-String "IPv4"
   
   # Output example: 192.168.1.105
   ```

2. **Ensure your device and computer are on the same WiFi network**

3. **Update your app configuration:**
   ```dart
   static const String baseUrl = 'http://192.168.1.105:9000/api';
   ```

4. **Ensure Windows Firewall allows port 9000:**
   ```powershell
   # Allow port 9000 in Windows Firewall
   New-NetFirewallRule -DisplayName "Reverse Proxy" -Direction Inbound -LocalPort 9000 -Protocol TCP -Action Allow
   ```

## WebSocket Configuration (Chat & Comments)

For real-time features using WebSockets:

```dart
import 'package:web_socket_channel/web_socket_channel.dart';

class ChatService {
  late WebSocketChannel channel;
  
  void connectToChat(String dashboardId) {
    // For Android Emulator
    final wsUrl = 'ws://10.0.2.2:9000/api/chat/ws/dashboards/$dashboardId/comments';
    
    // For iOS Simulator
    // final wsUrl = 'ws://localhost:9000/api/chat/ws/dashboards/$dashboardId/comments';
    
    channel = WebSocketChannel.connect(Uri.parse(wsUrl));
    
    channel.stream.listen(
      (message) {
        print('Received: $message');
      },
      onError: (error) {
        print('WebSocket error: $error');
      },
      onDone: () {
        print('WebSocket closed');
      },
    );
  }
  
  void sendMessage(Map<String, dynamic> message) {
    channel.sink.add(json.encode(message));
  }
  
  void dispose() {
    channel.sink.close();
  }
}
```

## Environment-Based Configuration

Create separate configurations for different environments:

```dart
enum Environment { development, staging, production }

class ApiConfig {
  static Environment currentEnv = Environment.development;
  
  static String get baseUrl {
    switch (currentEnv) {
      case Environment.development:
        return 'http://10.0.2.2:9000/api';  // Android Emulator
      case Environment.staging:
        return 'https://staging-api.yourdomain.com/api';
      case Environment.production:
        return 'https://api.yourdomain.com/api';
    }
  }
  
  static String get wsBaseUrl {
    switch (currentEnv) {
      case Environment.development:
        return 'ws://10.0.2.2:9000/api';
      case Environment.staging:
        return 'wss://staging-api.yourdomain.com/api';
      case Environment.production:
        return 'wss://api.yourdomain.com/api';
    }
  }
}
```

## HTTP Client Configuration with Error Handling

```dart
import 'package:http/http.dart' as http;
import 'dart:convert';

class ApiClient {
  static const String baseUrl = 'http://10.0.2.2:9000/api';
  static const Duration timeout = Duration(seconds: 30);
  
  static Future<dynamic> get(String endpoint) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl$endpoint'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(timeout);
      
      return _handleResponse(response);
    } catch (e) {
      throw Exception('Failed to load data: $e');
    }
  }
  
  static Future<dynamic> post(String endpoint, Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl$endpoint'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(data),
      ).timeout(timeout);
      
      return _handleResponse(response);
    } catch (e) {
      throw Exception('Failed to post data: $e');
    }
  }
  
  static dynamic _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return json.decode(response.body);
    } else if (response.statusCode == 429) {
      throw Exception('Rate limit exceeded. Please try again later.');
    } else if (response.statusCode == 503) {
      throw Exception('Service temporarily unavailable. Please try again later.');
    } else {
      throw Exception('HTTP ${response.statusCode}: ${response.body}');
    }
  }
}
```

## Rate Limiting Handling

The reverse proxy implements rate limiting. Handle rate limit errors gracefully:

```dart
class ApiService {
  Future<List<User>> getUsers() async {
    try {
      final data = await ApiClient.get('/users/');
      return (data as List).map((json) => User.fromJson(json)).toList();
    } on Exception catch (e) {
      if (e.toString().contains('Rate limit')) {
        // Show user-friendly message
        showSnackBar('Too many requests. Please wait a moment.');
        // Wait and retry
        await Future.delayed(Duration(seconds: 2));
        return getUsers(); // Retry
      }
      rethrow;
    }
  }
}
```

## Cache-Aware Requests

The reverse proxy caches GET requests. For data that must be fresh:

```dart
Future<dynamic> getFreshData(String endpoint) async {
  final uri = Uri.parse('$baseUrl$endpoint');
  final response = await http.get(
    uri,
    headers: {
      'Content-Type': 'application/json',
      'Cache-Control': 'no-cache',  // Force fresh data
    },
  );
  return json.decode(response.body);
}
```

## Security Best Practices

1. **Never store sensitive data in API URLs**
2. **Use HTTPS in production**
3. **Implement authentication tokens:**

```dart
class AuthenticatedApiClient extends ApiClient {
  static String? _authToken;
  
  static void setAuthToken(String token) {
    _authToken = token;
  }
  
  static Future<dynamic> authenticatedGet(String endpoint) async {
    final response = await http.get(
      Uri.parse('$baseUrl$endpoint'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_authToken',
      },
    );
    return _handleResponse(response);
  }
}
```

## Troubleshooting

### Connection Refused

**Problem:** `SocketException: Connection refused`

**Solutions:**
- Verify reverse proxy is running: `docker ps | grep reverse_proxy`
- Check if port 9000 is exposed: `docker port reverse_proxy`
- For Android Emulator, use `10.0.2.2` instead of `localhost`
- For physical device, use your computer's IP address

### Certificate Errors (HTTPS)

**Problem:** `HandshakeException: Handshake error`

**Solution for development only:**
```dart
class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback = (X509Certificate cert, String host, int port) => true;
  }
}

void main() {
  HttpOverrides.global = MyHttpOverrides();
  runApp(MyApp());
}
```

### Timeout Errors

**Problem:** Requests timing out

**Solutions:**
- Increase timeout duration
- Check network connectivity
- Verify services are running: `docker ps`
- Check reverse proxy logs: `docker logs reverse_proxy`

## Monitoring and Debugging

### Enable Debug Logging

```dart
void main() {
  // Enable HTTP logging in development
  if (kDebugMode) {
    HttpClient.enableHttpLogging = true;
  }
  runApp(MyApp());
}
```

### View Reverse Proxy Logs

```powershell
# Real-time logs
docker logs -f reverse_proxy

# Last 50 lines
docker logs reverse_proxy --tail 50

# Filter by error
docker logs reverse_proxy 2>&1 | Select-String "error"
```

## Summary

- **Development URL:** `http://10.0.2.2:9000/api` (Android) or `http://localhost:9000/api` (iOS)
- **Health Check:** `http://10.0.2.2:9000/health`
- **WebSocket:** `ws://10.0.2.2:9000/api/chat/ws/...`
- **Rate Limit:** 30 requests/second (burst of 10)
- **Cache TTL:** 1 minute for GET requests

For complete API endpoint documentation, see `API_ENDPOINTS_GUIDE.md` in the root directory.
