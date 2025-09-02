# 🌊 Dio Flow

[![pub package](https://img.shields.io/pub/v/dio_flow.svg)](https://pub.dev/packages/dio_flow)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)
[![Flutter](https://img.shields.io/badge/Flutter-3.7.0+-02569B?logo=flutter)](https://flutter.dev)

A powerful Flutter package that enhances Dio HTTP client with built-in support for caching, authentication, pagination, error handling, and standardized JSON utilities. Built for modern Flutter applications that need robust API integration.

## 📋 Table of Contents

- [Features](#-features)
- [Installation](#-installation)
- [Getting Started](#-getting-started)
- [Core Components](#-core-components)
- [Authentication](#-authentication)
- [Endpoint Configuration](#-endpoint-configuration)
- [Advanced Features](#-advanced-features)
- [Best Practices](#️-best-practices)
- [Mock Support](#-mock-support)
- [GraphQL Support](#-graphql-support)
- [File Operations](#-file-operations)
- [Troubleshooting](#-troubleshooting)
- [Contributing](#-contributing)
- [License](#-license)

## ✨ Features

- **🚀 Modern HTTP Client**: Built on top of Dio with enhanced features
- **🔄 Smart Response Handling**: Automatic conversion of responses to strongly-typed models
- **💾 Intelligent Caching**: Built-in response caching with configurable TTL
- **🔑 Token Management**: Robust authentication with token refresh support
- **🔁 Auto-Retry**: Configurable retry logic for failed requests
- **⚡ Rate Limiting**: Prevent API throttling with built-in rate limiting
- **📶 Network Awareness**: Automatic handling of connectivity changes
- **📊 Request Metrics**: Built-in performance tracking
- **🔍 Detailed Logging**: Complete request/response logging with cURL commands
- **📄 Pagination Support**: Built-in utilities for handling paginated responses
- **🛡️ Type Safety**: Strong typing throughout the library
- **🎯 Error Handling**: Comprehensive error handling with typed error responses
- **🧪 Mock Support**: Built-in mocking for testing without real HTTP calls
- **🔗 GraphQL Support**: Native GraphQL query, mutation, and subscription support
- **📁 File Operations**: Easy file upload/download with progress tracking
- **🔧 Extensible Architecture**: Plugin-based design for custom functionality

## 📦 Installation

Add to your pubspec.yaml:

```yaml
dependencies:
  dio_flow: ^1.3.0
```

## 🚀 Getting Started

### Basic Setup

```dart
import 'package:dio_flow/dio_flow.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Configure the client
  DioFlowConfig.initialize(
    baseUrl: 'https://api.example.com',
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 30),
    sendTimeout: const Duration(seconds: 30),
  );

  // 2. Initialize the client
  await ApiClient.initialize();

  runApp(MyApp());
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
    shouldCache: true,
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
if (response.isSuccess) {
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

The package includes several built-in interceptors:

1. **MetricsInterceptor**: Tracks request performance
2. **RateLimitInterceptor**: Prevents API throttling
3. **DioInterceptor**: Handles authentication and headers
4. **RetryInterceptor**: Manages request retries
5. **ConnectivityInterceptor**: Handles network state
6. **CacheInterceptor**: Manages response caching

## 🔑 Authentication

The package provides robust token management with persistent storage:

```dart
// Initialize token manager (call this in your main.dart)
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await TokenManager.initialize();

  // Register refresh logic (consumer-side). Optional — if you don't set it,
  // automatic refresh will be disabled and TokenManager will return null on expired token.
    TokenManager.setRefreshHandler((refreshToken) async {
    // Use DioRequestHandler to call refresh endpoint (consumer controls endpoint details).
    final refreshResp = await DioRequestHandler.post<Map<String, dynamic>>(
      'auth/refresh',
      data: {'refresh_token': refreshToken},
      requestOptions: RequestOptionsModel(hasBearerToken: false),
    );

    if (!refreshResp.isSuccess) {
      throw ApiException('Refresh failed: ${refreshResp.error?.message ?? 'unknown'}');
    }

    final data = refreshResp.data!;
    final expiresIn = (data['expires_in'] as int?) ?? 3600;

    return RefreshTokenResponse(
      accessToken: data['access_token'] as String,
      refreshToken: data['refresh_token'] as String,
      expiry: DateTime.now().add(Duration(seconds: expiresIn)),
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
    shouldCache: true,
    cacheMaxAge: const Duration(minutes: 5),
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

// Handle rate limiting automatically
final rateLimitedResponse = await DioRequestHandler.get(
  'high-frequency-endpoint',
  requestOptions: RequestOptionsModel(
    shouldRateLimit: true,
    rateLimit: 30, // requests per minute
  ),
);
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

1. **Initialize Early**:

   ```dart
   void main() async {
     await ApiClient.initialize();
     // ... rest of your app initialization
   }
   ```

2. **Handle Errors Consistently**:

   ```dart
   try {
     final response = await DioRequestHandler.get('endpoint');
     if (response.isSuccess) {
       // Handle success
     } else {
       // Use the typed error handling
       handleError(response.error);
     }
   } catch (e) {
     // Handle unexpected errors
   }
   ```

3. **Use Type-Safe Responses**:

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
  if (response.isSuccess) {
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

### Repository Pattern

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

## 🧪 Mock Support

DioFlow includes powerful mocking capabilities for testing:

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

Native GraphQL support with query builder:

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

Easy file upload and download with progress tracking:

```dart
// File upload
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

// Multiple file upload
final files = {
  'document': File('/path/to/doc.pdf'),
  'image': File('/path/to/image.jpg'),
};
final multiUploadResponse = await FileHandler.uploadMultipleFiles(
  'upload-multiple',
  files,
);

// File download
final downloadResponse = await FileHandler.downloadFile(
  'files/123/download',
  '/local/path/file.pdf',
  onProgress: (received, total) {
    print('Download: ${(received/total*100).toStringAsFixed(1)}%');
  },
);

// Download as bytes
final bytesResponse = await FileHandler.downloadBytes('files/123');
if (bytesResponse.isSuccess) {
  final bytes = bytesResponse.data['bytes'] as Uint8List;
  // Use bytes...
}

// Upload from bytes
final bytesUploadResponse = await FileHandler.uploadBytes(
  'upload',
  fileBytes,
  'filename.jpg',
);
```

## 🔍 Troubleshooting

Common issues and solutions:

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

### Debug Mode

```dart
// Enable detailed logging
DioFlowConfig.initialize(
  baseUrl: 'https://api.example.com',
  debugMode: true, // This will enable detailed logging
);

// Log specific requests
final response = await DioRequestHandler.get(
  'users',
  requestOptions: RequestOptionsModel(
    shouldLogRequest: true, // Log this specific request
  ),
);
```

## 🤝 Contributing

Contributions are welcome! Please read our [Contributing Guide](CONTRIBUTING.md) for details on our code of conduct and the process for submitting pull requests.

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
