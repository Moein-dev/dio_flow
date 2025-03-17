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
- [Making Requests](#-making-requests)
- [Response Handling](#-response-handling)
- [Advanced Features](#-advanced-features)
- [Best Practices](#-best-practices)
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

## 📦 Installation

Add to your pubspec.yaml:

```yaml
dependencies:
  dio_flow: ^1.1.6
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

## 🤝 Contributing

Contributions are welcome! Please read our [Contributing Guide](CONTRIBUTING.md) for details on our code of conduct and the process for submitting pull requests.

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
