# 🌊 Dio Flow

[![pub package](https://img.shields.io/pub/v/dio_flow.svg?style=for-the-badge&logo=dart&logoColor=white)](https://pub.dev/packages/dio_flow)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg?style=for-the-badge)](https://opensource.org/licenses/MIT)
[![Flutter](https://img.shields.io/badge/Flutter-3.7.0+-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev)
[![Platform](https://img.shields.io/badge/Platform-iOS%20%7C%20Android%20%7C%20Web%20%7C%20Windows%20%7C%20macOS%20%7C%20Linux-lightgrey?style=for-the-badge)](https://flutter.dev/multi-platform)

A powerful, production-ready Flutter package that supercharges Dio HTTP client

Built for modern Flutter applications that demand robust, scalable API integration

[📖 Documentation](#-table-of-contents) • [🚀 Quick Start](#-getting-started) • [💡 Examples](example/) • [🐛 Issues](https://github.com/Moein-dev/dio_flow/issues)

---

## 🎯 Why Dio Flow?

Dio Flow transforms your API integration experience by providing enterprise-grade features out of the box:

- **🔥 Zero Configuration**: Get started in minutes with sensible defaults
- **🛡️ Production Ready**: Battle-tested with comprehensive error handling
- **🚀 Performance First**: Built-in caching, retry logic, and request optimization
- **🌐 Universal**: Works seamlessly across all Flutter platforms
- **🧪 Developer Friendly**: Extensive mocking support for testing
- **📊 Observable**: Built-in metrics and detailed logging

## 📋 Table of Contents

- [🎯 Why Dio Flow?](#-why-dio-flow)
- [✨ Features](#-features)
- [🎯 Platform Support](#-platform-support)
- [📦 Installation](#-installation)
- [🚀 Getting Started](#-getting-started)
- [🎯 Core Components](#-core-components)
- [� Authentication](#-authentication)
- [🌐 Endpoint Configuration](#-endpoint-configuration)
- [🔄 Advanced Features](#-advanced-features)
- [�️ uBest Practices](#️-best-practices)
- [🧪 Mock Support](#-mock-support)
- [� GraphQL Support](#-graphql-support)
- [� FBile Operations](#-file-operations)
- [🔍 Troubleshooting](#-troubleshooting)
- [🤝 Contributing](#-contributing)
- [� LicenseOse](#-license)

## ✨ Features

| 🚀 **Core**             | 🔒 **Security**        | 🛠️ **Developer Experience** |
| ----------------------- | ---------------------- | --------------------------- |
| Modern HTTP Client      | Token Management       | Type-Safe Responses         |
| Smart Response Handling | Auto Token Refresh     | Comprehensive Testing       |
| Intelligent Caching     | Request Authentication | Built-in Mocking            |
| Auto-Retry Logic        | Secure Token Storage   | Detailed Logging            |

| 🌐 **Platform**   | 📊 **Performance** | 🔧 **Advanced**  |
| ----------------- | ------------------ | ---------------- |
| Universal Support | Request Metrics    | GraphQL Support  |
| Web Compatible    | Rate Limiting      | File Operations  |
| Cross-Platform    | Network Awareness  | Pagination Utils |
| WASM Ready        | Connection Pooling | JSON Utilities   |

### 🎯 Key Capabilities

- **🚀 Modern HTTP Client**: Enhanced Dio with production-grade features
- **🔄 Smart Response Handling**: Automatic conversion to strongly-typed models
- **💾 Intelligent Caching**: Configurable TTL with automatic invalidation
- **🔑 Token Management**: Robust authentication with automatic refresh
- **🔁 Auto-Retry**: Configurable retry logic with exponential backoff
- **⚡ Rate Limiting**: Built-in throttling to prevent API abuse
- **📶 Network Awareness**: Automatic connectivity change handling
- **📊 Request Metrics**: Built-in performance tracking and analytics
- **🔍 Detailed Logging**: Complete request/response logging with cURL commands
- **📄 Pagination Support**: Utilities for handling paginated API responses
- **🛡️ Type Safety**: Strong typing throughout the entire library
- **🎯 Error Handling**: Comprehensive error handling with typed responses
- **🧪 Mock Support**: Built-in mocking system for testing without real HTTP calls
- **🔗 GraphQL Support**: Native GraphQL queries, mutations, and subscriptions
- **📁 File Operations**: Easy file upload/download with progress tracking
- **🔧 Extensible Architecture**: Plugin-based design for custom functionality

## 🎯 Platform Support

### 🌐 Universal Flutter Support - Write Once, Run Everywhere

| Platform       | Support | File Operations | Network Checking | WASM Compatible |
| -------------- | ------- | --------------- | ---------------- | --------------- |
| 📱 **iOS**     | ✅ Full | ✅ Complete     | ✅ Native        | ✅ Ready        |
| 🤖 **Android** | ✅ Full | ✅ Complete     | ✅ Native        | ✅ Ready        |
| 🌐 **Web**     | ✅ Full | 🔄 Bytes Only\* | ✅ HTTP-based    | ✅ Compatible   |
| 🪟 **Windows** | ✅ Full | ✅ Complete     | ✅ Native        | ✅ Ready        |
| 🍎 **macOS**   | ✅ Full | ✅ Complete     | ✅ Native        | ✅ Ready        |
| 🐧 **Linux**   | ✅ Full | ✅ Complete     | ✅ Native        | ✅ Ready        |

> **💡 Web Platform Note**: File operations use `Uint8List` instead of `File` objects due to browser security restrictions. This ensures maximum compatibility while maintaining functionality.

## 📦 Installation

### Get started in seconds with a single dependency

### 📋 Add Dependency

```yaml
dependencies:
  dio_flow: ^1.3.1
```

### 🔄 Install

```bash
flutter pub get
```

### 📱 Import

```dart
import 'package:dio_flow/dio_flow.dart';
```

#### 📦 Development Dependencies (Optional)

For enhanced development experience:

```yaml
dev_dependencies:
  dio_flow: ^1.3.1
  # For testing with mocks
  mockito: ^5.4.0
  # For integration testing
  integration_test:
    sdk: flutter
```

## 🚀 Getting Started

### ⚡ From zero to API calls in under 2 minutes

### 🎯 Quick Setup

```dart
import 'package:dio_flow/dio_flow.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 🔧 Configure Dio Flow
  DioFlowConfig.initialize(
    baseUrl: 'https://api.example.com',
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 30),
    sendTimeout: const Duration(seconds: 30),
  );

  // 🚀 Initialize the client
  await ApiClient.initialize();

  // 🔑 Initialize token management
  await TokenManager.initialize();

  runApp(MyApp());
}
```

### 🎯 Your First API Call

```dart
// 📡 Make your first request
final response = await DioRequestHandler.get('users');

if (response is SuccessResponseModel) {
  print('✅ Success: ${response.data}');
} else {
  print('❌ Error: ${response.error?.message}');
}
```

## 🎯 Core Components

### DioRequestHandler

The main class for making HTTP requests:

```dart
// GET request
final response = await DioRequestHandler.get(
  'users',
  parameters: {'role': 'admin'},
  requestOptions: RequestOptionsModel(
    hasBearerToken: true,
    cacheOptions: CacheOptions(
      shouldCache: true,
      cacheDuration: const Duration(minutes: 5),
    ),
    retryOptions: RetryOptions(
      maxAttempts: 3,
      retryInterval: const Duration(seconds: 1),
    ),
  ),
);

// POST request with typed response
final loginResponse = await DioRequestHandler.post<LoginResponse>(
  'auth/login',
  data: {
    'email': 'user@example.com',
    'password': '********',
  },
  requestOptions: RequestOptionsModel(
    hasBearerToken: false,
  ),
);
```

### Response Models

All responses are wrapped in typed models:

```dart
if (response is SuccessResponseModel) {
  final data = response.data;
  // Handle success
} else {
  final error = response.error;
  switch (error.errorType) {
    case ErrorType.network:
      // Handle network error
      break;
    case ErrorType.validation:
      // Handle validation error
      break;
    case ErrorType.unauthorized:
      // Handle auth error
      break;
    // ... handle other error types
  }
}
```

### Interceptors

The package includes several built-in interceptors that are automatically configured:

1. **MetricsInterceptor**: Tracks request performance and timing
2. **CacheInterceptor**: Manages response caching with SharedPreferences
3. **RateLimitInterceptor**: Prevents API throttling (30 requests per minute by default)

These interceptors are automatically added to the Dio instance when `ApiClient.initialize()` is called. No additional configuration is required.

## 🔑 Authentication

### 🛡️ Enterprise-grade authentication with automatic token management

Dio Flow provides a comprehensive authentication system with persistent storage, automatic token refresh, and seamless integration:

```dart
// Initialize token manager (call this in your main.dart)
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await TokenManager.initialize();

  // Register refresh logic (consumer-side). Optional — if you don't set it,
  // automatic refresh will be disabled and TokenManager will return null on expired token.
  TokenManager.setRefreshHandler((refreshToken) async {
    final refreshResp = await DioRefreshTokenRequestHandle.post(
      ApiEndpointsKey.refreshToken,
      data: {'refreshToken': refreshToken},
    );

    if (refreshResp is! SuccessResponseModel) {
      // go to login page
    }

    final data = refreshResp.data!;

    return RefreshTokenResponse(
      accessToken: data['accessToken'] as String,
      refreshToken: data['refreshToken'] as String?,
      expiry: DateTime.now().add(Duration(days: 29)),
      );
  });

  runApp(MyApp());
}

// Setting tokens with persistence
await TokenManager.setTokens(
  accessToken: 'your_access_token',
  refreshToken: 'your_refresh_token',
  expiry: DateTime.now().add(Duration(hours: 1)),
);

// Check presence/validity (auto-refresh performed if expired and handler is set)
final hasToken = await TokenManager.hasAccessToken(); // returns true/false

// Getting access token (will automatically refresh if expired and a handler is configured)
final token = await TokenManager.getAccessToken(); // can be null if no handler and expired

// Clearing tokens
await TokenManager.clearTokens();
```

Key features:

- Persistent token storage using SharedPreferences (tokens survive app restarts).

- RefreshTokenHandler typedef — consumer provides a small callback that receives the refresh token and returns a RefreshTokenResponse (access, refresh, expiry). This keeps the package network-agnostic.

- TokenManager.setRefreshHandler(...) — register refresh logic at startup or runtime (optional).

- Automatic refresh behavior — hasAccessToken() and getAccessToken() will automatically attempt to refresh when the access token is expired only if a refresh handler has been set. If no handler is provided, expired tokens are treated as absent (methods return false/null).

-Single-flight refresh protection — internal \_refreshCompleter ensures only one refresh request runs at a time; concurrent callers wait for that single result.

- Tokens returned by the refresh handler are persisted via setTokens() (keeps state consistent across restarts).

- All token operations are asynchronous for non-blocking startup and safer IO.

- getAccessToken() behavior is unified: it either returns a valid token, triggers refresh (if handler exists), or returns null (if expired and no handler).

### Protected Requests

```dart
// Make authenticated request
final response = await DioRequestHandler.get(
  'user/profile',
  requestOptions: RequestOptionsModel(
    hasBearerToken: true, // This will automatically include the token
  ),
);

// Handle token expiration
if (response.error?.errorType == ErrorType.unauthorized) {
  // Token expired, handle refresh or logout
}
```

## 🌐 Endpoint Configuration

### Basic Endpoints

```dart
// Register endpoints
EndpointProvider.instance.register('login', '/auth/login');
EndpointProvider.instance.register('users', '/api/users');

// Use registered endpoints
final response = await DioRequestHandler.post(
  'login',
  data: {'email': email, 'password': password},
);
```

### Dynamic Endpoints

```dart
// Register endpoint with parameters
EndpointProvider.instance.register('user_details', '/api/users/{id}');

// Use with path parameters
final response = await DioRequestHandler.get(
  'user_details',
  pathParameters: {'id': '123'},
);
```

## 🔄 Advanced Features

### Caching

```dart
// Enable caching for a request
final response = await DioRequestHandler.get(
  'users',
  requestOptions: RequestOptionsModel(
    cacheOptions: CacheOptions(
      shouldCache: true,
      cacheDuration: const Duration(minutes: 5),
    ),
  ),
);

// Use predefined cache options
final shortCacheResponse = await DioRequestHandler.get(
  'frequent-data',
  requestOptions: RequestOptionsModel(
    cacheOptions: CacheOptions.shortApiCache, // 1 minute cache
  ),
);

final longCacheResponse = await DioRequestHandler.get(
  'static-data',
  requestOptions: RequestOptionsModel(
    cacheOptions: CacheOptions.longApiCache, // 1 hour cache
  ),
);

// Clear cache
await ApiClient.clearCache();
```

### Pagination

```dart
// Using pagination utilities
final paginatedResponse = await DioRequestHandler.get(
  'posts',
  parameters: {
    'page': 1,
    'per_page': 20,
  },
);

final pagination = PaginationHelper.fromResponse(paginatedResponse);
final hasMore = pagination.hasNextPage;
final totalPages = pagination.totalPages;
```

### JSON Utilities

```dart
// Safe JSON parsing
final jsonData = JsonUtils.tryParseJson(rawJson);

// Access nested values safely
final nestedValue = JsonUtils.getNestedValue(
  jsonData,
  'user.profile.name',
  'Default Name',
);
```

### Request Queueing

```dart
// Queue multiple requests
final responses = await Future.wait([
  DioRequestHandler.get('users'),
  DioRequestHandler.get('posts'),
  DioRequestHandler.get('comments'),
]);

// Rate limiting is handled automatically by RateLimitInterceptor
// Configure in ApiClient initialization (30 requests per minute by default)
final rateLimitedResponse = await DioRequestHandler.get(
  'high-frequency-endpoint',
  requestOptions: RequestOptionsModel(hasBearerToken: true),
);
```

### Retry Configuration

```dart
// Use predefined retry options for slow networks
final response = await DioRequestHandler.get(
  'unreliable-endpoint',
  requestOptions: RequestOptionsModel(
    retryOptions: RetryOptions.slowNetwork, // 5 attempts, 2 second intervals
  ),
);

// Custom retry configuration
final customRetryResponse = await DioRequestHandler.get(
  'custom-endpoint',
  requestOptions: RequestOptionsModel(
    retryOptions: RetryOptions(
      maxAttempts: 5,
      retryInterval: const Duration(seconds: 2),
      retryStatusCodes: [408, 429, 500, 502, 503, 504],
    ),
  ),
);
```

### Cancell Request

```dart
// Use canceel token for Cancell Request every time
final CancelToken testCancellToken = CancelToken();

final response = await DioRequestHandler.get(
  'test-endpoint',
  ccancelToken: testCancelToken,
);

// For use :
testCancelToken?.cancel('test_request_cancelled');
```

### Custom Response Types

```dart
class PaginatedResponse<T> {
  final List<T> items;
  final int total;
  final int page;

  PaginatedResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) converter,
  )   : items = (json['data'] as List)
            .map((item) => converter(item))
            .toList(),
        total = json['total'] ?? 0,
        page = json['page'] ?? 1;
}

// Use with typed response
final response = await DioRequestHandler.get<PaginatedResponse<User>>(
  'users',
  converter: (json) => PaginatedResponse.fromJson(
    json,
    (item) => User.fromJson(item),
  ),
);
```

## 🛠️ Best Practices

### 💡 Production-tested patterns for robust API integration

### 🚀 Essential Patterns

#### 1. **Initialize Early**

```dart
void main() async {
  await ApiClient.initialize();
  // ... rest of your app initialization
}
```

#### 2. **Handle Errors Consistently**

```dart
try {
  final response = await DioRequestHandler.get('endpoint');
  if (response is SuccessResponseModel) {
    // Handle success
  } else {
    // Use the typed error handling
    handleError(response.error);
  }
} catch (e) {
  // Handle unexpected errors
}
```

#### 3. **Use Type-Safe Responses**

```dart
class UserResponse {
  final String id;
  final String name;

  UserResponse.fromJson(Map<String, dynamic> json)
      : id = json['id'],
        name = json['name'];
}

final response = await DioRequestHandler.get<UserResponse>(
  'users/me',
  converter: (json) => UserResponse.fromJson(json),
);
```

### Error Handling Patterns

```dart
// Create a reusable error handler
Future<T> handleApiResponse<T>(ResponseModel response) async {
  if (response is SuccessResponseModel) {
    return response.data as T;
  }

  switch (response.error?.errorType) {
    case ErrorType.network:
      throw NetworkException(response.error!.message);
    case ErrorType.unauthorized:
      await handleUnauthorized();
      throw AuthException(response.error!.message);
    case ErrorType.validation:
      throw ValidationException(response.error!.message);
    default:
      throw ApiException(response.error?.message ?? 'Unknown error');
  }
}

// Use in your code
try {
  final users = await handleApiResponse<List<User>>(
    await DioRequestHandler.get('users'),
  );
  // Use users data
} on NetworkException catch (e) {
  // Handle network error
} on AuthException catch (e) {
  // Handle auth error
} on ValidationException catch (e) {
  // Handle validation error
} on ApiException catch (e) {
  // Handle other API errors
}
```

### 🏗️ Repository Pattern

```dart
class UserRepository {
  Future<User> getCurrentUser() async {
    final response = await DioRequestHandler.get<User>(
      'users/me',
      requestOptions: RequestOptionsModel(
        hasBearerToken: true,
        shouldCache: true,
        cacheMaxAge: const Duration(minutes: 5),
      ),
      converter: (json) => User.fromJson(json),
    );

    return handleApiResponse<User>(response);
  }

  Future<void> updateProfile(UserUpdateRequest request) async {
    final response = await DioRequestHandler.put(
      'users/me',
      data: request.toJson(),
      requestOptions: RequestOptionsModel(hasBearerToken: true),
    );

    await handleApiResponse(response);
  }
}
```

### ⚡ Performance Tips

#### 🚀 Optimization strategies for production apps

```dart
// 💾 Use caching strategically
final response = await DioRequestHandler.get(
  'static-data',
  requestOptions: RequestOptionsModel(
    cacheOptions: CacheOptions(
      shouldCache: true,
      cacheDuration: const Duration(hours: 1), // Cache static data longer
    ),
  ),
);

// 🔄 Batch requests when possible
final futures = [
  DioRequestHandler.get('users'),
  DioRequestHandler.get('posts'),
  DioRequestHandler.get('comments'),
];
final responses = await Future.wait(futures);

// ⚡ Use pagination for large datasets
final paginatedResponse = await PaginationUtils.fetchAllPages(
  'large-dataset',
  parameters: {'per_page': 50}, // Optimal page size
  maxPages: 10, // Limit to prevent memory issues
);

// 🎯 Optimize file uploads
final uploadResponse = await FileHandler.uploadBytes(
  'upload',
  compressedBytes, // Compress before upload
  'file.jpg',
  onProgress: (sent, total) {
    // Update UI efficiently
    if (sent % 1024 == 0) { // Update every KB
      updateProgressUI(sent / total);
    }
  },
);
```

## 🧪 Mock Support

### 🎭 Powerful mocking system for comprehensive testing

Dio Flow includes a sophisticated mocking system that makes testing your API integrations effortless:

```dart
void main() {
  // Enable mock mode
  MockDioFlow.enableMockMode();

  // Register mock responses
  MockDioFlow.mockResponse(
    'users',
    MockResponse.success([
      {'id': 1, 'name': 'John Doe'},
      {'id': 2, 'name': 'Jane Smith'},
    ]),
  );

  // Register response queue for testing pagination
  MockDioFlow.mockResponseQueue('posts', [
    MockResponse.success({'page': 1, 'data': [...]}),
    MockResponse.success({'page': 2, 'data': [...]}),
  ]);

  // Your tests will now use mocked responses
  final response = await DioRequestHandler.get('users');

  // Disable mock mode
  MockDioFlow.disableMockMode();
}
```

## 🔗 GraphQL Support

### ⚡ Native GraphQL integration with powerful query building

Dio Flow provides first-class GraphQL support with an intuitive query builder and comprehensive operation handling:

```dart
// Simple query
final response = await GraphQLHandler.query('''
  query GetUser($id: ID!) {
    user(id: $id) {
      id
      name
      email
    }
  }
''', variables: {'id': '123'});

// Using query builder
final query = GraphQLQueryBuilder.query()
    .operationName('GetUsers')
    .variables({'first': 'Int'})
    .body('users(first: $first) { id name }')
    .build();

// Mutations
final mutationResponse = await GraphQLHandler.mutation('''
  mutation CreateUser($input: CreateUserInput!) {
    createUser(input: $input) {
      id
      name
    }
  }
''', variables: {'input': {'name': 'John', 'email': 'john@example.com'}});

// Batch operations
final operations = [
  GraphQLOperation(query: 'query { users { id } }'),
  GraphQLOperation(query: 'query { posts { id } }'),
];
final batchResponse = await GraphQLHandler.batch(operations);
```

## 📁 File Operations

### 📤📥 Seamless file handling across all platforms with progress tracking

Dio Flow provides comprehensive file operations that work consistently across all Flutter platforms, with intelligent platform-specific optimizations:

### Mobile/Desktop Platforms (iOS, Android, Windows, macOS, Linux)

```dart
// File upload from File object (Mobile/Desktop only)
final file = File('/path/to/file.jpg');
final uploadResponse = await FileHandler.uploadFile(
  'upload',
  file,
  fieldName: 'avatar',
  additionalData: {'userId': '123'},
  onProgress: (sent, total) {
    print('Upload: ${(sent/total*100).toStringAsFixed(1)}%');
  },
);

// File download to disk (Mobile/Desktop only)
final downloadResponse = await FileHandler.downloadFile(
  'files/123/download',
  '/local/path/file.pdf',
  onProgress: (received, total) {
    print('Download: ${(received/total*100).toStringAsFixed(1)}%');
  },
);
```

### Web Platform

```dart
// Upload from bytes (web-compatible)
final bytesUploadResponse = await FileHandler.uploadBytes(
  'upload',
  fileBytes, // Uint8List
  'filename.jpg',
  fieldName: 'avatar',
  additionalData: {'userId': '123'},
);

// Download as bytes (web-compatible)
final bytesResponse = await FileHandler.downloadBytes('files/123');
if (bytesResponse is SuccessResponseModel) {
  final bytes = bytesResponse.data['bytes'] as Uint8List;
  // Use bytes for web download (e.g., trigger browser download)
}
```

### Cross-Platform File Operations

```dart
// Multiple file upload (use bytes for web compatibility)
final files = {
  'document': documentBytes, // Uint8List for web
  'image': imageBytes,       // Uint8List for web
};
final multiUploadResponse = await FileHandler.uploadMultipleFiles(
  'upload-multiple',
  files,
);

// Upload from bytes (works on all platforms)
final bytesUploadResponse = await FileHandler.uploadBytes(
  'upload',
  fileBytes,
  'filename.jpg',
);
```

> **Note**: On web platform, direct file system access is restricted by browser security. Use `FileHandler.uploadBytes()` and `FileHandler.downloadBytes()` for web-compatible file operations.

## 🔍 Troubleshooting

### 🛠️ Quick solutions to common issues

### 🚨 Common Issues & Solutions

1. **Authentication Issues**:

   - Ensure `hasBearerToken` is set correctly in `RequestOptionsModel`
   - Check if tokens are properly managed in `TokenManager`

2. **Caching Problems**:

   - Verify `shouldCache` is enabled in request options
   - Check cache duration settings
   - Try clearing cache with `ApiClient.clearCache()`

3. **Network Errors**:

   - Check connectivity status
   - Verify retry options are configured
   - Examine cURL logs for request details

4. **Mock Issues**:

   - Ensure `MockDioFlow.enableMockMode()` is called before requests
   - Verify mock responses are registered for the correct endpoints
   - Check that endpoint paths match exactly

5. **GraphQL Errors**:

   - Validate GraphQL syntax in queries
   - Check that variables match the schema
   - Ensure the GraphQL endpoint is correctly configured

6. **File Upload Issues**:
   - Verify file permissions and paths
   - Check server file size limits
   - Ensure correct Content-Type headers for multipart uploads

### 🔍 Debug Mode

```dart
// Enable detailed logging
DioFlowConfig.initialize(
  baseUrl: 'https://api.example.com',
  // Debug logging is enabled by default in development
);

// All requests are automatically logged with cURL commands
final response = await DioRequestHandler.get(
  'users',
  requestOptions: RequestOptionsModel(hasBearerToken: true),
);
```

---

## 📚 Quick Reference

### ⚡ Common operations at a glance

#### 🔗 API Calls Cheat Sheet

```dart
// GET request
final users = await DioRequestHandler.get('users');

// POST with data
final created = await DioRequestHandler.post('users', data: userData);

// PUT update
final updated = await DioRequestHandler.put('users/123', data: updates);

// DELETE
final deleted = await DioRequestHandler.delete('users/123');

// With authentication
final profile = await DioRequestHandler.get(
  'profile',
  requestOptions: RequestOptionsModel(hasBearerToken: true),
);

// With caching
final cached = await DioRequestHandler.get(
  'static-data',
  requestOptions: RequestOptionsModel(
    cacheOptions: CacheOptions(
      shouldCache: true,
      cacheDuration: Duration(minutes: 30),
    ),
  ),
);
```

#### 🔑 Authentication Cheat Sheet

```dart
// Set tokens
await TokenManager.setTokens(
  accessToken: 'access_token',
  refreshToken: 'refresh_token',
  expiry: DateTime.now().add(Duration(hours: 1)),
);

// Check if authenticated
final isAuthenticated = await TokenManager.hasAccessToken();

// Get current token (auto-refreshes if needed)
final token = await TokenManager.getAccessToken();

// Clear tokens (logout)
await TokenManager.clearTokens();
```

#### 📁 File Operations Cheat Sheet

```dart
// Upload file (mobile/desktop)
final upload = await FileHandler.uploadFile('upload', file);

// Upload bytes (all platforms)
final upload = await FileHandler.uploadBytes('upload', bytes, 'file.jpg');

// Download file (mobile/desktop)
final download = await FileHandler.downloadFile('files/123', '/path/file.pdf');

// Download bytes (all platforms)
final download = await FileHandler.downloadBytes('files/123');

// Get file information without downloading
final fileInfo = await FileHandler.getFileInfo('files/123');
```

#### 🧪 Testing Cheat Sheet

```dart
// Enable mocking
MockDioFlow.enableMockMode();

// Mock success response
MockDioFlow.mockResponse('users', MockResponse.success([...]));

// Mock error response
MockDioFlow.mockResponse('users', MockResponse.failure('Error message'));

// Mock network error
MockDioFlow.mockResponse('users', MockResponse.networkError());

// Disable mocking
MockDioFlow.disableMockMode();
```

---

## 🤝 Contributing

### We love contributions! Help make Dio Flow even better 💪

Contributions are welcome! Whether it's:

- 🐛 **Bug Reports**: Found an issue? Let us know!
- ✨ **Feature Requests**: Have an idea? We'd love to hear it!
- 📖 **Documentation**: Help improve our docs
- 🔧 **Code Contributions**: Submit a PR!

Please read our [Contributing Guide](CONTRIBUTING.md) for details on our code of conduct and the process for submitting pull requests.

### 🌟 Contributors

Thanks to all our amazing contributors who help make Dio Flow better!

---

## 📄 License

### 📜 MIT License - Free for everyone, everywhere

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

Made with ❤️ by the Flutter community

---

### 🌟 Star us on GitHub if Dio Flow helped you

[![GitHub stars](https://img.shields.io/github/stars/Moein-dev/dio_flow?style=social)](https://github.com/Moein-dev/dio_flow)

Happy coding! 🚀
