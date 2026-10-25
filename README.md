# 🌊 DioFlow

[![pub package](https://img.shields.io/pub/v/dio_flow.svg?style=for-the-badge&logo=dart&logoColor=white)](https://pub.dev/packages/dio_flow)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg?style=for-the-badge)](https://opensource.org/licenses/MIT)
[![Dart](https://img.shields.io/badge/Dart-3.7%2B-0175C2?style=for-the-badge&logo=dart&logoColor=white)](https://dart.dev)
[![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20iOS%20%7C%20Web%20%7C%20macOS%20%7C%20Windows%20%7C%20Linux-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev/multi-platform)

A robust, developer-friendly Flutter HTTP client built on Dio that handles the heavy lifting out of the box: **predictable typed responses**, **single-flight token refresh**, **stream-safe retries**, **isolated local caching**, **built-in request mocking**, and **real-time upload progress tracking**.

---

## ⚡ 30-Second Quick Start

### 1. Add Dependencies

```yaml
dependencies:
  dio_flow: ^3.1.0
  dio: ^5.11.0
```

### 2. Initialize in `main()`

```dart
import 'package:flutter/material.dart';
import 'package:dio_flow/dio_flow.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  DioFlowConfig.initialize(
    baseUrl: 'https://api.example.com',
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 15),
  );
  await ApiClient.initialize();

  runApp(const MyApp());
}
```

### 3. Make Your First Request

```dart
final response = await DioRequestHandler.get('/users/1');

if (response.isSuccess) {
  print('User: ${response.data}');
} else {
  print('Error ${response.statusCode}: ${response.message}');
}
```

---

## 🧭 Why DioFlow?

| Feature | Standard Dio | DioFlow |
| --- | :---: | :---: |
| **Response Format** | Raw `dynamic` / uncaught errors | Predictable `SuccessResponseModel` or `FailedResponseModel` |
| **Crash Protection** | Unhandled exceptions crash UI | Internal guards ensure every call returns a structured model |
| **Token Refresh** | Complex custom interceptors | Automatic single-flight refresh with queueing for concurrent 401s |
| **Request Retries** | Retrying FormData burns stream | Automatically clones `FormData` on retry attempts |
| **Local Cache** | Third-party cache store needed | Built-in isolated cache with query-key stabilization & `isFromCache` |
| **Offline Mocking** | Mock adapters & build runners | Global `MockDioFlow` active with zero backend dependencies |
| **Sensitive Logs** | Exposes bearer tokens in console | Automatically masks passwords, tokens, cookies, and keys in cURL |
| **Web & WASM** | `dart:io` crashes on browser | 100% Web and WASM compatible with conditional adapters |

---

## 📚 Table of Contents

- [🚀 Everyday Usage (Cheat Sheet)](#-everyday-usage-cheat-sheet)
- [📡 Request Methods & Parameters](#-request-methods--parameters)
- [🧪 Offline Request Mocking](#-offline-request-mocking)
- [💾 Smart Local Caching](#-smart-local-caching)
- [🔐 Authentication & Automatic Token Refresh](#-authentication--automatic-token-refresh)
- [📤 File Upload with Live Progress](#-file-upload-with-live-progress)
- [📥 File Download](#-file-download)
- [🔁 Automatic Retries & Crash Prevention](#-automatic-retries--crash-prevention)
- [🚦 Rate Limiting & Concurrency](#-rate-limiting--concurrency)
- [🎨 Console Logging & Copyable cURL](#-console-logging--copyable-curl)
- [🔗 GraphQL Helpers](#-graphql-helpers)
- [⚙️ Full Configuration Reference](#️-full-configuration-reference)

---

## 🚀 Everyday Usage (Cheat Sheet)

### Basic GET with Path Parameters & Query

```dart
final response = await DioRequestHandler.get(
  '/posts/{id}/comments',
  pathParameters: {'id': 10},
  parameters: {'page': 1, 'limit': 20},
);

if (response.isSuccess) {
  final List comments = response.data;
  print('Fetched ${comments.length} comments');
}
```

### Basic POST / PUT / PATCH / DELETE

```dart
// POST JSON
final postRes = await DioRequestHandler.post(
  '/users',
  data: {'name': 'Sarah Connor', 'role': 'Admin'},
);

// PUT Update
final putRes = await DioRequestHandler.put(
  '/users/42',
  data: {'name': 'John Connor'},
);

// DELETE
final deleteRes = await DioRequestHandler.delete('/users/42');
```

---

## 📡 Request Methods & Parameters

All HTTP methods in `DioRequestHandler` (`get`, `post`, `put`, `patch`, `delete`) share the same unified signature:

```dart
Future<ResponseModel> get(
  dynamic endpoint, {
  Map<String, dynamic>? parameters,      // Query parameters (?page=1&sort=desc)
  Map<String, dynamic>? pathParameters,  // Path placeholders (/users/{id})
  RequestOptionsModel requestOptions,    // Per-request cache, retry, headers
  CancelToken? cancelToken,              // Request cancellation token
});
```

### Inspecting Responses

Every call returns a `ResponseModel` that never throws uncaught network crashes:

```dart
final response = await DioRequestHandler.get('/dashboard');

if (response.isSuccess) {
  // Convenient getters
  final data = response.data;
  final statusCode = response.statusCode; // e.g. 200
  final isCached = response.isFromCache;  // true if served from local cache
  final curl = response.logCurl;          // copyable cURL command
} else {
  // Structured error handling
  final errorMsg = response.message;      // Clean user-friendly message
  final statusCode = response.statusCode; // e.g. 404, 500, 499 (cancelled)
  final errorType = response.errorType;   // e.g. ErrorType.notFound, ErrorType.timeout
}
```

### Named Endpoints (Optional)

You can register endpoints centrally to avoid hardcoding paths throughout your app:

```dart
EndpointProvider.instance.registerAll({
  'profile': '/api/v1/user/profile',
  'updateUser': '/api/v1/user/{id}',
});

// Use the registered key directly:
final res = await DioRequestHandler.get('profile');
```

---

## 🧪 Offline Request Mocking

Test your UI and workflows instantly without waiting for backend APIs or an internet connection:

```dart
// 1. Enable mock mode anywhere in tests or demo apps:
MockDioFlow.enableMockMode();

// 2. Register mock endpoints:
MockDioFlow.mockResponse(
  '/users/1',
  MockResponse.success({
    'id': 1,
    'name': 'Sarah Connor',
    'email': 'sarah@example.com',
  }),
);

// 3. Mock POST or Error responses with custom delay:
MockDioFlow.mockResponse(
  '/orders',
  MockResponse.success({'orderId': 'ord_123'}, statusCode: 201),
  method: 'POST',
);

MockDioFlow.mockResponse(
  '/error-endpoint',
  MockResponse.failure('Account suspended', statusCode: 403),
);

// When done:
MockDioFlow.disableMockMode();
```

---

## 💾 Smart Local Caching

Enable instant response caching on GET requests. Subsequent calls with the same parameters return from local cache in **0 ms**:

```dart
final response = await DioRequestHandler.get(
  '/catalog',
  parameters: {'category': 'books'},
  requestOptions: const RequestOptionsModel(
    cacheOptions: CacheOptions(
      shouldCache: true,
      cacheDuration: Duration(minutes: 10), // Cache valid for 10 minutes
    ),
  ),
);

if (response.isFromCache) {
  print('Served instantly from local cache!');
}
```

### Safe Cache Clearing

`ApiClient.clearCache()` safely wipes **only** cache keys created by `dio_flow`, preserving your app's user tokens, theme, and other SharedPreferences data:

```dart
await ApiClient.clearCache();
```

---

## 🔐 Authentication & Automatic Token Refresh

DioFlow provides a bulletproof token management lifecycle:
1. Automatically attaches `Authorization: Bearer <token>` to requests marked with `hasBearerToken: true`.
2. Proactively checks token expiration before sending.
3. Automatically catches `401 Unauthorized` responses, refreshes the token, and replays the original request once.
4. **Single-Flight Coordination:** If 10 parallel requests receive a `401`, only **one** refresh request is sent to your backend; the other 9 wait and resume seamlessly with the new token.

### Setup Token Management

```dart
await TokenManager.initialize();

// Save initial tokens upon user login:
// (expiry is completely OPTIONAL - pass null if your server doesn't provide one)
await TokenManager.setTokens(
  accessToken: 'initial_access_token',
  refreshToken: 'initial_refresh_token',
  expiry: DateTime.now().add(const Duration(hours: 2)), // optional
);

// Register your refresh API logic:
TokenManager.setRefreshHandler((currentRefreshToken) async {
  // Use refreshDio or DioRefreshTokenRequestHandle to avoid recursive interceptors:
  final response = await DioRefreshTokenRequestHandle.post(
    '/auth/refresh',
    data: {'refresh_token': currentRefreshToken},
  );

  if (response.isSuccess) {
    return RefreshTokenResponse(
      accessToken: response.data['access_token'],
      refreshToken: response.data['refresh_token'], // optional
      expiry: null, // optional
    );
  }

  throw ApiException('Session expired');
});
```

### Sending Authenticated Requests

Simply set `hasBearerToken: true`:

```dart
final response = await DioRequestHandler.get(
  '/user/me',
  requestOptions: const RequestOptionsModel(hasBearerToken: true),
);
```

---

## 📤 File Upload with Live Progress

Upload files, images, or raw byte buffers with a real-time progress callback:

```dart
// Native (Mobile / Desktop) or Web (Uint8List)
final bytes = Uint8List.fromList(imageBytes);

final response = await FileHandler.uploadFile(
  '/media/upload',
  {'avatar': bytes}, // fieldName -> file or bytes
  UploadMethodsEnum.post,
  additionalData: {'userId': '42', 'description': 'Profile image'},
  onProgress: (sent, total) {
    final progress = (sent / total) * 100;
    print('Upload Progress: ${progress.toStringAsFixed(1)}%');
  },
);
```

---

## 📥 File Download

Download binary data (PDFs, images, documents) directly as bytes or plain text:

```dart
// 1. Download as raw bytes:
final response = await FileHandler.downloadBytes(
  '/reports/2026.pdf',
  UploadMethodsEnum.get, // supports get, post, put, patch
);

if (response.isSuccess) {
  final Uint8List fileBytes = response.data;
  // Save to disk using path_provider or open with open_file
}

// 2. Download plain text (CSV, Logs, TXT):
final textResponse = await FileHandler.downloadText(
  '/logs/daily.csv',
  UploadMethodsEnum.get,
);
```

---

## 🔁 Automatic Retries & Crash Prevention

Configure exponential backoff or retry status codes per request:

```dart
final response = await DioRequestHandler.get(
  '/live-feed',
  requestOptions: const RequestOptionsModel(
    retryOptions: RetryOptions(
      maxAttempts: 3,                                // Total attempts (1 = no retry)
      retryInterval: Duration(milliseconds: 500),    // Wait between attempts
      retryStatusCodes: [408, 500, 502, 503, 504],   // Status codes to retry
      retryOnConnectionTimeout: true,
      retryOnReceiveTimeout: true,
    ),
  ),
);
```

> **🛡️ Stream-Safe:** DioFlow automatically calls `FormData.clone()` before replaying multipart requests, preventing "Cannot finalize stream multiple times" crashes.

---

## 🚦 Rate Limiting & Concurrency

### Fast & Unblocked by Default

In DioFlow, **requests flow freely without artificial client-side barriers**. Rapid user interactions, tab switching, and parallel dashboard widgets execute smoothly without hitting rate-limit errors.

### Optional Client-Side Rate Limiter

If your specific backend requires strict client-side throttling to prevent abuse, you can opt-in during initialization:

```dart
DioFlowConfig.initialize(
  baseUrl: 'https://api.example.com',
  enableRateLimit: true,                            // Defaults to false
  rateLimitMaxRequests: 60,                         // Allowed requests
  rateLimitInterval: const Duration(minutes: 1),    // Time window
);
```

---

## 🎨 Console Logging & Copyable cURL

DioFlow's internal logger is **silent by default** so it never spams your development console. Enable it per request when debugging:

```dart
final response = await DioRequestHandler.post(
  '/login',
  data: {'email': 'user@example.com', 'password': 'mySecretPassword'},
  requestOptions: const RequestOptionsModel(
    logModel: LogModel(defaultLog: true),
  ),
);
```

### 🔒 Built-In Security Masking

DioFlow automatically masks sensitive fields case-insensitively across headers, query parameters, request bodies, and cURL commands:
- `Authorization`, `token`, `accessToken`, `refreshToken`
- `password`, `secret`, `apiKey`, `cookie`, `credential`

The generated cURL commands are clean, safe to copy into bug reports, and guaranteed not to expose user credentials.

---

## 🔗 GraphQL Helpers

Execute GraphQL queries, mutations, and batch operations with built-in typed response models:

```dart
final response = await GraphQLHandler.query(
  r'''
    query GetUser($id: ID!) {
      user(id: $id) {
        id
        name
        email
      }
    }
  ''',
  variables: {'id': '42'},
);

if (response.isSuccess) {
  print('User: ${response.data['user']}');
}
```

---

## ⚙️ Full Configuration Reference

### `DioFlowConfig.initialize` Options

| Parameter | Type | Default | Description |
| --- | --- | --- | --- |
| `baseUrl` | `String` | **required** | The root endpoint for all HTTP requests |
| `connectTimeout` | `Duration` | `30s` | Connection timeout |
| `receiveTimeout` | `Duration` | `30s` | Receive timeout |
| `sendTimeout` | `Duration` | `30s` | Send timeout |
| `enableRateLimit` | `bool` | `false` | Enable client-side request rate limiter |
| `rateLimitMaxRequests`| `int` | `60` | Max requests within interval |
| `rateLimitInterval` | `Duration` | `1m` | Time window for rate limiter |
| `customInterceptors` | `List<Interceptor>?` | `null` | Additional custom Dio interceptors |

### `RequestOptionsModel` Options

| Parameter | Type | Default | Description |
| --- | --- | --- | --- |
| `hasBearerToken` | `bool` | `false` | Automatically inject active Bearer token |
| `customHeaders` | `Map<String, dynamic>?` | `null` | Per-request custom headers |
| `cacheOptions` | `CacheOptions` | `noApiCache` | Cache TTL and policies |
| `retryOptions` | `RetryOptions` | `defaultOptions` | Retry attempts and status codes |
| `logModel` | `LogModel` | `disabledAllLog` | Log console output and cURL |
| `responseType` | `ResponseType` | `json` | Response parsing (`json`, `bytes`, `plain`) |

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
