# 🌊 Dio Flow

[![pub package](https://img.shields.io/pub/v/dio_flow.svg)](https://pub.dev/packages/dio_flow)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)
[![Flutter](https://img.shields.io/badge/Flutter-3.7.0+-02569B?logo=flutter)](https://flutter.dev)

A powerful Flutter package that enhances Dio HTTP client with built-in support for caching, authentication, pagination, error handling, and standardized JSON utilities.


## 📋 Table of Contents

- [Features](#-features)
- [Installation](#-installation)
- [Getting Started](#-getting-started)
- [API Client](#-api-client)
- [Endpoints](#-endpoints)
- [Making Requests](#-making-requests)
- [Response Models](#-response-models)
- [Authentication](#-authentication)
- [Pagination](#-pagination)
- [JSON Utilities](#-json-utilities)
- [Error Handling](#-error-handling)
- [Caching](#-caching)
- [Logging](#-logging)
- [Interceptors](#-interceptors)
- [Available Utilities](#-available-utilities)
- [Advanced Usage](#-advanced-usage)
- [Troubleshooting](#-troubleshooting)
- [Contributing](#-contributing)
- [License](#-license)

## ✨ Features

- **🚀 Simplified API**: Clean wrappers around Dio for easy HTTP requests
- **💾 Caching**: Automatic response caching with configurable TTL
- **🔑 Authentication**: Token management with auto-refresh support
- **❌ Error Handling**: Standardized error handling and response models
- **🔄 Retries**: Automatic retry for failed requests
- **⏱️ Rate Limiting**: Prevent overwhelming APIs with too many requests
- **📶 Connectivity**: Automatic handling of connectivity changes
- **📊 Metrics**: Performance tracking for API requests
- **📝 Logging**: Detailed request/response logging with cURL commands
- **📄 Pagination**: Utilities for handling paginated API responses
- **🔍 JSON Utilities**: Tools for working with complex JSON structures

## 📦 Installation

Add this to your package's pubspec.yaml file:

```yaml
dependencies:
  dio_flow: ^1.0.0
```

Then run:

```bash
flutter pub get
```

## 🚀 Getting Started

### Basic Setup

```dart
import 'package:dio_flow/dio_flow.dart';
import 'package:flutter/material.dart';

void main() {
  // Initialize the API client configuration
  DioFlowConfig.initialize(
    baseUrl: 'https://api.example.com',
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 30),
    sendTimeout: const Duration(seconds: 30),
  );
  
  runApp(MyApp());
}
```

## 🌐 API Client

The API client is the core of dio_flow. It provides a simplified interface for making HTTP requests.

### Initialization

```dart
// Initialize with default configuration
DioFlowConfig.initialize(
  baseUrl: 'https://api.example.com',
);

// Initialize with custom timeouts
DioFlowConfig.initialize(
  baseUrl: 'https://api.example.com',
  connectTimeout: const Duration(seconds: 10),
  receiveTimeout: const Duration(seconds: 10),
  sendTimeout: const Duration(seconds: 10),
);

// Initialize with custom headers
DioFlowConfig.initialize(
  baseUrl: 'https://api.example.com',
  headers: {
    'Accept': 'application/json',
    'User-Agent': 'MyApp/1.0.0',
  },
);
```

### Custom Configuration

```dart
// Add interceptors
final logInterceptor = LogInterceptor(
  requestBody: true,
  responseBody: true,
);
ApiClient.dio.interceptors.add(logInterceptor);

// Set base options
ApiClient.dio.options.validateStatus = (status) {
  return status != null && status >= 200 && status < 300;
};
```

## 🔄 Endpoints

Endpoints allow you to define and manage your API routes in a centralized way.

### Basic Endpoint Registration

```dart
// Register endpoints
EndpointProvider.instance.register('users', '/api/users');
EndpointProvider.instance.register('user', '/api/users/{id}');
EndpointProvider.instance.register('posts', '/api/posts');

// Register multiple endpoints at once
EndpointProvider.instance.registerAll({
  'comments': '/api/comments',
  'likes': '/api/likes',
});
```

### Dynamic Path Parameters

```dart
// Get an endpoint with path parameters
final userEndpoint = EndpointProvider.instance.getEndpoint('user');
final userPath = userEndpoint.getPath({'id': '123'}); // Returns '/api/users/123'
```

### Custom Endpoint Classes

```dart
// Define a custom endpoint
class SearchEndpoint implements ApiEndpointInterface {
  @override
  final String path = '/api/search';
  
  String buildSearchQuery(String query, List<String> filters) {
    final queryParams = Uri.encodeQueryComponent(query);
    final filtersParam = filters.join(',');
    return '$path?q=$queryParams&filters=$filtersParam';
  }
}

// Register the custom endpoint
final searchEndpoint = SearchEndpoint();
EndpointProvider.instance.register('search', searchEndpoint);

// Use the custom endpoint
final endpoint = EndpointProvider.instance.getEndpoint('search') as SearchEndpoint;
final searchUrl = endpoint.buildSearchQuery('flutter', ['articles', 'tutorials']);
```

## 📡 Making Requests

Use `DioRequestHandler` to make API requests with simplified methods.

### GET Requests

```dart
// Basic GET request
final response = await DioRequestHandler.get('users');

// GET with query parameters
final userResponse = await DioRequestHandler.get(
  'users',
  parameters: {'role': 'admin', 'active': true},
);

// GET with path parameters
final userDetailResponse = await DioRequestHandler.get(
  'user',
  pathParameters: {'id': '123'},
);
```

### POST Requests

```dart
// Basic POST request
final createResponse = await DioRequestHandler.post(
  'users',
  data: {'name': 'John Doe', 'email': 'john@example.com'},
);

// POST with form data
final formData = FormData.fromMap({
  'name': 'John Doe',
  'profile_picture': await MultipartFile.fromFile(
    './profile.jpg',
    filename: 'profile.jpg',
  ),
});

final uploadResponse = await DioRequestHandler.post(
  'users',
  data: formData,
);
```

### PUT Requests

```dart
// Basic PUT request
final updateResponse = await DioRequestHandler.put(
  'user',
  pathParameters: {'id': '123'},
  data: {'name': 'John Updated', 'email': 'john.updated@example.com'},
);
```

### DELETE Requests

```dart
// Basic DELETE request
final deleteResponse = await DioRequestHandler.delete(
  'user',
  pathParameters: {'id': '123'},
);
```

### Request Options

```dart
// Set custom options for a request
final response = await DioRequestHandler.get(
  'users',
  requestOptions: RequestOptionsModel(
    requireAuth: true,           // Requires authentication
    cacheResponse: true,         // Enable caching
    cacheTTL: Duration(hours: 1), // Cache time-to-live
    retryCount: 3,               // Number of retries on failure
    retryInterval: Duration(seconds: 2), // Interval between retries
  ),
);
```

## 📊 Response Models

dio_flow provides standardized response models for consistent handling of API responses.

### Success Response

```dart
// Handle a successful response
final response = await DioRequestHandler.get('users');

if (response is SuccessResponseModel) {
  final data = response.data;
  final meta = response.meta; // Pagination metadata if available
  
  print('Got ${data.length} users');
  print('Total users: ${meta?['total']}');
}
```

### Failed Response

```dart
// Handle a failed response
final response = await DioRequestHandler.get('invalid-endpoint');

if (response is FailedResponseModel) {
  final statusCode = response.statusCode;
  final errorMessage = response.message;
  final errorData = response.data;
  
  print('Error $statusCode: $errorMessage');
  print('Additional error data: $errorData');
}
```

## 🔑 Authentication

dio_flow includes a token management system for handling authentication.

### Setting Tokens

```dart
// After successful login
TokenManager.setTokens(
  accessToken: 'your_access_token',
  refreshToken: 'your_refresh_token',
  expiry: DateTime.now().add(Duration(hours: 1)),
);
```

### Using Tokens

```dart
// Get the current access token
final token = await TokenManager.getAccessToken();

// Check if the user is authenticated
final isAuthenticated = await TokenManager.isAuthenticated();

// Clear tokens (logout)
await TokenManager.clearTokens();
```

### Custom Token Refresh

```dart
// Set up a custom token refresh function
TokenManager.setTokenRefreshFunction((refreshToken) async {
  // Make a request to refresh the token
  final response = await DioRequestHandler.post(
    'auth/refresh',
    data: {'refresh_token': refreshToken},
    requestOptions: RequestOptionsModel(requireAuth: false),
  );
  
  if (response is SuccessResponseModel) {
    return TokenResponse(
      accessToken: response.data['access_token'],
      refreshToken: response.data['refresh_token'],
      expiry: DateTime.parse(response.data['expires_at']),
    );
  }
  
  throw Exception('Failed to refresh token');
});
```

## 📄 Pagination

dio_flow provides utilities to simplify working with paginated APIs.

### Automatic Pagination

```dart
// Fetch all pages automatically
final response = await PaginationUtils.fetchAllPages(
  'posts',
  parameters: {'status': 'published'},
  pageParamName: 'page',
  perPageParamName: 'per_page',
  startPage: 1,
  itemsPerPage: 20,
);

if (response is SuccessResponseModel) {
  final allPosts = response.data as List;
  print('Fetched ${allPosts.length} posts across multiple pages');
}
```

### Manual Pagination

```dart
// Create a pagination helper
final helper = PaginationHelper(
  endpoint: 'products',
  pageParamName: 'page',
  perPageParamName: 'limit',
  startPage: 1,
  itemsPerPage: 10,
  // Additional fixed parameters
  additionalParams: {'category': 'electronics'},
);

// Fetch the first page
final firstPageResponse = await helper.fetchPage();

if (firstPageResponse is SuccessResponseModel) {
  // Display the first page of data
  displayProducts(firstPageResponse.data);
  
  // Check if there are more pages
  if (helper.hasMorePages) {
    // Load the next page when needed
    final nextPageResponse = await helper.fetchNextPage();
    
    if (nextPageResponse is SuccessResponseModel) {
      // Append the new data
      appendProducts(nextPageResponse.data);
    }
  }
}
```

### Custom Pagination Metadata

```dart
// For APIs with custom pagination metadata structure
final helper = PaginationHelper(
  endpoint: 'articles',
  pageParamName: 'page',
  perPageParamName: 'size',
  startPage: 1,
  itemsPerPage: 10,
  metaMapping: (responseData) {
    // Extract custom pagination metadata
    final meta = responseData['_meta'];
    return PaginationMeta(
      currentPage: meta['currentPage'],
      lastPage: meta['totalPages'],
      perPage: meta['itemsPerPage'],
      total: meta['totalItems'],
    );
  },
);
```

## 🔍 JSON Utilities

dio_flow includes utilities for working with JSON data.

### Safe Parsing

```dart
// Safely parse JSON without throwing exceptions
final jsonString = '{"name": "John", "age": 30}';
final parsedJson = JsonUtils.tryParseJson(jsonString);

// Handle invalid JSON
final invalidJson = '{name: John}'; // Missing quotes
final result = JsonUtils.tryParseJson(invalidJson);
print(result); // null
```

### Nested Value Access

```dart
// Access nested values with dot notation
final data = {
  'user': {
    'profile': {
      'name': 'John Doe',
      'details': {
        'age': 30,
        'location': {
          'city': 'New York',
          'country': 'USA'
        }
      }
    }
  }
};

// Get nested values safely
final name = JsonUtils.getNestedValue(data, 'user.profile.name');
print(name); // John Doe

final city = JsonUtils.getNestedValue(data, 'user.profile.details.location.city');
print(city); // New York

// Provide default values for missing paths
final phone = JsonUtils.getNestedValue(data, 'user.profile.phone', 'N/A');
print(phone); // N/A
```

### Key Normalization

```dart
// Normalize inconsistent JSON keys
final weirdJson = {
  'First_Name': 'John',
  'LAST-NAME': 'Doe',
  'EMAIL_ADDRESS': 'john@example.com',
  'Phone_NUMBER': '123-456-7890',
  'user-SETTINGS': {
    'THEME_PREFERENCE': 'dark',
    'NOTIFICATIONS_ENABLED': true
  }
};

// Convert to camelCase (default)
final camelCased = JsonUtils.normalizeJsonKeys(weirdJson);
print(camelCased);
// Output:
// {
//   'firstName': 'John',
//   'lastName': 'Doe',
//   'emailAddress': 'john@example.com',
//   'phoneNumber': '123-456-7890',
//   'userSettings': {
//     'themePreference': 'dark',
//     'notificationsEnabled': true
//   }
// }

// Convert to snake_case
final snakeCased = JsonUtils.normalizeJsonKeys(
  weirdJson,
  keysToLowerCase: true,
  separatorToUse: '_',
);
print(snakeCased);
// Output:
// {
//   'first_name': 'John',
//   'last_name': 'Doe',
//   'email_address': 'john@example.com',
//   'phone_number': '123-456-7890',
//   'user_settings': {
//     'theme_preference': 'dark',
//     'notifications_enabled': true
//   }
// }
```

### Advanced Type Mapping

```dart
// Convert JSON data to specific types
final jsonData = {
  'count': '42',      // String that should be an int
  'price': '29.99',   // String that should be a double
  'active': 'true',   // String that should be a boolean
  'created': '2023-05-15T14:30:00Z' // String that should be a DateTime
};

// Map types automatically
final convertedData = JsonUtils.mapJsonTypes(jsonData, {
  'count': int,
  'price': double,
  'active': bool,
  'created': DateTime,
});

print(convertedData['count'].runtimeType);    // int
print(convertedData['price'].runtimeType);    // double
print(convertedData['active'].runtimeType);   // bool
print(convertedData['created'].runtimeType);  // DateTime
```

## ❌ Error Handling

dio_flow provides a standardized approach to error handling.

### Basic Error Handling

```dart
try {
  final response = await DioRequestHandler.get('users');
  
  if (response is SuccessResponseModel) {
    // Handle success
    print('Success: ${response.data}');
  } else {
    // Handle error
    final error = response as FailedResponseModel;
    print('Error ${error.statusCode}: ${error.message}');
  }
} catch (e) {
  // Handle unexpected errors
  print('Unexpected error: $e');
}
```

### Error Type Handling

```dart
Future<void> fetchData() async {
  try {
    final response = await DioRequestHandler.get('protected-resource');
    
    if (response is SuccessResponseModel) {
      // Handle success
    } else {
      final error = response as FailedResponseModel;
      
      // Handle specific error codes
      switch (error.statusCode) {
        case 401:
          handleUnauthorized();
          break;
        case 403:
          handleForbidden();
          break;
        case 404:
          handleNotFound();
          break;
        case 429:
          handleRateLimited();
          break;
        case 500:
        case 502:
        case 503:
          handleServerError();
          break;
        default:
          handleGenericError(error);
          break;
      }
    }
  } on DioException catch (e) {
    // Handle Dio specific errors
    if (e.type == DioExceptionType.connectionTimeout) {
      handleTimeout();
    } else if (e.type == DioExceptionType.connectionError) {
      handleConnectionError();
    } else {
      handleGenericDioError(e);
    }
  } catch (e) {
    // Handle other errors
    handleUnexpectedError(e);
  }
}
```

## 💾 Caching

dio_flow includes a built-in caching system for API responses.

### Basic Caching

```dart
// Enable caching for a request
final response = await DioRequestHandler.get(
  'frequently-accessed-data',
  requestOptions: RequestOptionsModel(
    cacheResponse: true,
    cacheTTL: Duration(hours: 1),
  ),
);
```

### Cache Management

```dart
// Clear the entire cache
await CacheManager.clearCache();

// Clear cache for a specific endpoint
await CacheManager.clearCacheForEndpoint('users');

// Check if a response is cached
final isCached = await CacheManager.hasCache('users');
```

## 📝 Logging

dio_flow includes comprehensive logging features.

### Basic Logging

```dart
// Enable logging with cURL commands
ApiClient.enableLogging(
  includeRequestBody: true,
  includeResponseBody: true,
  includeCurlCommands: true,
  logLevel: LogLevel.info,
);
```

### Custom Logger

```dart
// Set up a custom logger
ApiClient.setLogger((message, {LogLevel? level}) {
  switch (level) {
    case LogLevel.error:
      print('❌ ERROR: $message');
      break;
    case LogLevel.warning:
      print('⚠️ WARNING: $message');
      break;
    case LogLevel.info:
      print('ℹ️ INFO: $message');
      break;
    case LogLevel.debug:
      print('🔍 DEBUG: $message');
      break;
    default:
      print('📝 LOG: $message');
      break;
  }
});
```

## 🔗 Interceptors

dio_flow comes with several built-in interceptors to enhance your API requests.

### Authentication Interceptor

Automatically adds authentication tokens to requests.

```dart
// Enable authentication interceptor (enabled by default)
ApiClient.useAuthInterceptor(true);

// The interceptor automatically adds the token to requests marked with requireAuth
final response = await DioRequestHandler.get(
  'protected-endpoint',
  requestOptions: RequestOptionsModel(requireAuth: true),
);

// Under the hood, the interceptor adds the following header:
// headers['Authorization'] = 'Bearer ${await TokenManager.getAccessToken()}';
```

### Retry Interceptor

Automatically retries failed requests based on specified conditions.

```dart
// Configure retry behavior globally
ApiClient.configureRetry(
  retryCount: 3,                          // Maximum retry attempts
  retryInterval: Duration(seconds: 2),    // Base interval between retries
  retryStatusCodes: [408, 500, 502, 503], // HTTP status codes to retry on
  exponentialBackoff: true,               // Use exponential backoff for intervals
);

// Retry settings can be overridden per request
final response = await DioRequestHandler.get(
  'unstable-endpoint',
  requestOptions: RequestOptionsModel(
    retryCount: 5,                       // Override default retry count
    retryInterval: Duration(seconds: 1), // Override default retry interval
  ),
);
```

### Cache Interceptor

Caches responses and serves them when the same request is made again.

```dart
// Configure caching globally
ApiClient.configureCaching(
  defaultCacheDuration: Duration(minutes: 30), // Default TTL for cached responses
  maxCacheSize: 50,                            // Maximum number of cached responses
  excludedEndpoints: ['auth/login', 'users/create'], // Endpoints that should never be cached
);

// Cache settings can be specified per request
final response = await DioRequestHandler.get(
  'frequently-accessed-data',
  requestOptions: RequestOptionsModel(
    cacheResponse: true,                 // Enable caching for this request
    cacheTTL: Duration(hours: 2),        // Override default cache TTL
    cacheKey: 'custom-cache-key',        // Use a custom key for this cache entry
    forceRefresh: false,                 // If true, ignore cache and make a new request
  ),
);

// Clear cache for an endpoint
await CacheManager.clearCacheForEndpoint('users');
```

### Logging Interceptor

Logs all requests, responses, and errors.

```dart
// Configure logging
ApiClient.configureLogging(
  level: LogLevel.info,                // Log level (error, warning, info, debug)
  includeRequestBody: true,            // Log request bodies
  includeResponseBody: true,           // Log response bodies
  includeCurlCommand: true,            // Include equivalent cURL commands
  includeRequestHeaders: true,         // Log request headers
  includeResponseHeaders: true,        // Log response headers
  maskSensitiveHeaders: ['Authorization', 'Cookie'], // Mask sensitive headers in logs
  logFormat: '[{method}] {url} - {statusCode}',     // Custom log format
);

// Custom logger
ApiClient.setCustomLogger((log, {LogLevel? level}) {
  // Send logs to a custom logging service
  if (level == LogLevel.error) {
    ErrorReportingService.capture(log);
  }
  
  // Also print to console
  print('${level?.name.toUpperCase() ?? 'LOG'}: $log');
});
```

### Rate Limit Interceptor

Prevents overwhelming the API with too many requests.

```dart
// Configure rate limiting
ApiClient.configureRateLimiting(
  requestsPerTimeWindow: 30,          // Maximum requests allowed
  timeWindow: Duration(minutes: 1),   // Time window for rate limiting
  perEndpoint: true,                  // Apply rate limit per endpoint instead of globally
);

// The rate limit interceptor will queue requests that exceed the limit
// and execute them once the time window resets
```

### Connectivity Interceptor

Handles request attempts during no connectivity.

```dart
// Configure connectivity handling
ApiClient.configureConnectivity(
  retryOnConnectivityEstablished: true,  // Auto-retry requests that failed due to connectivity
  showConnectivityNotifications: true,   // Show notifications when connectivity changes
  onConnectivityChanged: (connected) {
    // Handle connectivity changes
    print('Connection status changed: ${connected ? 'online' : 'offline'}');
  },
);
```

## 🧰 Available Utilities

dio_flow provides several utility classes to help with common tasks.

### JsonUtils

Utilities for working with JSON data.

```dart
// Safe JSON parsing with error handling
final jsonString = '{"name": "John", "age": 30}';
final json = JsonUtils.tryParseJson(jsonString);
if (json == null) {
  print('Failed to parse JSON');
} else {
  print('Parsed JSON: $json');
}

// Get nested values with dot notation
final data = {'user': {'profile': {'name': 'John'}}};
final name = JsonUtils.getNestedValue(
  data,                 // The JSON object
  'user.profile.name',  // Path to the desired value
  defaultValue: 'N/A',  // Default value if path doesn't exist
);

// Check if a path exists in JSON
final hasEmail = JsonUtils.hasPath(data, 'user.profile.email'); // false

// Extract multiple values at once
final extracted = JsonUtils.extractValues(data, [
  'user.profile.name',
  'user.profile.age',
  'user.settings.theme'
], defaultValue: null);
// Returns: {'user.profile.name': 'John', 'user.profile.age': null, 'user.settings.theme': null}

// Convert map keys to consistent format
final normalized = JsonUtils.normalizeJsonKeys(
  {'First_Name': 'John', 'LAST-NAME': 'Doe'},
  keysToLowerCase: true,   // Convert to lowercase
  separatorToUse: '_',     // Use snake_case format
);
// Returns: {'first_name': 'John', 'last_name': 'Doe'}

// Convert string values to appropriate types
final typed = JsonUtils.convertStringValues({
  'count': '42',
  'active': 'true',
  'price': '29.99',
});
// Returns: {'count': 42, 'active': true, 'price': 29.99}

// Flatten nested JSON
final flattened = JsonUtils.flattenJson({
  'user': {
    'profile': {
      'name': 'John',
      'age': 30
    }
  }
});
// Returns: {'user.profile.name': 'John', 'user.profile.age': 30}
```

### DateTimeUtils

Utilities for working with dates and times.

```dart
// Parse date strings safely
final date = DateTimeUtils.tryParse('2023-05-15T14:30:00Z');
if (date != null) {
  print('Parsed date: $date');
}

// Format date to string
final formattedDate = DateTimeUtils.format(
  DateTime.now(),
  format: 'yyyy-MM-dd HH:mm:ss',  // Custom format
);

// Get relative time
final relativeTime = DateTimeUtils.getRelativeTime(
  DateTime.now().subtract(Duration(minutes: 30)),
);
// Returns: '30 minutes ago'

// Check if date is in the past
final isPast = DateTimeUtils.isPast(
  DateTime.now().subtract(Duration(days: 1)),
);

// Get difference in human readable format
final difference = DateTimeUtils.getHumanReadableDifference(
  DateTime.now(),
  DateTime.now().add(Duration(days: 5, hours: 2)),
);
// Returns: '5 days and 2 hours'
```

### StringUtils

Utilities for working with strings.

```dart
// Capitalize first letter
final capitalized = StringUtils.capitalize('hello world');
// Returns: 'Hello world'

// Convert to camel case
final camelCase = StringUtils.toCamelCase('user_first_name');
// Returns: 'userFirstName'

// Convert to snake case
final snakeCase = StringUtils.toSnakeCase('userFirstName');
// Returns: 'user_first_name'

// Truncate string with ellipsis
final truncated = StringUtils.truncate(
  'This is a very long string that needs to be truncated',
  maxLength: 20,
);
// Returns: 'This is a very long...'

// Check if string is valid JSON
final isJson = StringUtils.isValidJson('{"name": "John"}');

// Generate a random string
final random = StringUtils.generateRandomString(
  length: 10,
  includeNumbers: true,
  includeSpecialChars: false,
);
```

### PaginationUtils

Advanced utilities for pagination.

```dart
// Fetch all pages at once
final allData = await PaginationUtils.fetchAllPages(
  'posts',
  parameters: {'category': 'tech'},    // Base query parameters
  pageParamName: 'page',               // Name of the page parameter
  perPageParamName: 'per_page',        // Name of the per-page parameter
  startPage: 1,                        // Starting page number
  itemsPerPage: 20,                    // Items per page
  maxPages: 10,                        // Maximum pages to fetch (optional)
  // Custom function to check if more pages exist based on response
  hasMorePages: (response) {
    final total = response.meta['total'] as int;
    final current = response.meta['current_page'] as int;
    final perPage = response.meta['per_page'] as int;
    return current * perPage < total;
  },
);

// Process pages one by one with a callback
await PaginationUtils.processAllPages(
  'users',
  parameters: {'status': 'active'},
  pageParamName: 'page',
  onPageReceived: (pageData, pageNumber) async {
    // Process each page as it arrives
    print('Received page $pageNumber with ${pageData.length} items');
    await processUserBatch(pageData);
    // Return true to continue fetching, false to stop
    return pageNumber < 5;
  },
);

// Create a scroll pagination controller for Flutter widgets
final controller = PaginationUtils.createScrollPaginationController(
  endpoint: 'products',
  parameters: {'category': 'electronics'},
  itemsPerPage: 20,
  // Optional: Transform response data to your model
  itemBuilder: (item) => Product.fromJson(item),
);

// Use with ListView
ListView.builder(
  controller: controller.scrollController,
  itemCount: controller.items.length + (controller.isLoading ? 1 : 0),
  itemBuilder: (context, index) {
    if (index == controller.items.length) {
      return CircularProgressIndicator();
    }
    final product = controller.items[index];
    return ProductCard(product: product);
  },
);
```

### RequestUtils

Utilities for working with API requests.

```dart
// Build URL with query parameters
final url = RequestUtils.buildUrl(
  'https://api.example.com/users',
  {'search': 'john', 'sort': 'name'},
);
// Returns: 'https://api.example.com/users?search=john&sort=name'

// Create form data with files
final formData = await RequestUtils.createFormData({
  'name': 'John Doe',
  'avatar': FileItem(path: '/path/to/image.jpg', filename: 'avatar.jpg'),
  'documents': [
    FileItem(path: '/path/to/doc1.pdf', filename: 'doc1.pdf'),
    FileItem(path: '/path/to/doc2.pdf', filename: 'doc2.pdf'),
  ],
});

// Validate request parameters
final errors = RequestUtils.validateParameters(
  {
    'email': 'john@example',
    'age': '25',
    'role': null,
  },
  {
    'email': (value) => value.contains('@') && value.contains('.'),
    'age': (value) => int.tryParse(value) != null && int.parse(value) >= 18,
    'role': (value) => value != null,
  },
);
// Returns: {'email': false, 'role': false}

// Retry a request with custom logic
final response = await RequestUtils.retryRequest(
  () => DioRequestHandler.get('unstable-endpoint'),
  retryIf: (error) => error is DioException && 
      [DioExceptionType.connectionTimeout, DioExceptionType.receiveTimeout].contains(error.type),
  maxRetries: 3,
  delayBetweenRetries: Duration(seconds: 2),
);
```

## 🔧 Advanced Usage

### Custom Interceptors

```dart
// Create a custom interceptor
class CustomInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    // Modify the request before it's sent
    options.headers['X-Custom-Header'] = 'CustomValue';
    handler.next(options);
  }
  
  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    // Process the response
    print('Response received with status code: ${response.statusCode}');
    handler.next(response);
  }
  
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    // Handle or transform errors
    print('Error occurred: ${err.message}');
    handler.next(err);
  }
}

// Add the interceptor
ApiClient.dio.interceptors.add(CustomInterceptor());
```

### Combining Features

```dart
// Combine multiple features in a repository pattern
class UserRepository {
  Future<List<User>> getUsers({int page = 1, bool forceRefresh = false}) async {
    final response = await DioRequestHandler.get(
      'users',
      parameters: {
        'page': page,
        'per_page': 20,
      },
      requestOptions: RequestOptionsModel(
        requireAuth: true,
        cacheResponse: !forceRefresh,
        cacheTTL: Duration(minutes: 15),
        retryCount: 2,
      ),
    );
    
    if (response is SuccessResponseModel) {
      return (response.data as List)
          .map((json) => User.fromJson(json))
          .toList();
    } else {
      final error = response as FailedResponseModel;
      throw ApiException(error.message, error.statusCode);
    }
  }
  
  Future<User?> getUserById(String id) async {
    final response = await DioRequestHandler.get(
      'user',
      pathParameters: {'id': id},
      requestOptions: RequestOptionsModel(
        requireAuth: true,
        cacheResponse: true,
      ),
    );
    
    if (response is SuccessResponseModel) {
      return User.fromJson(response.data);
    } else if ((response as FailedResponseModel).statusCode == 404) {
      return null; // User not found
    } else {
      throw ApiException(response.message, response.statusCode);
    }
  }
  
  Future<User> createUser(User user) async {
    final response = await DioRequestHandler.post(
      'users',
      data: user.toJson(),
      requestOptions: RequestOptionsModel(requireAuth: true),
    );
    
    if (response is SuccessResponseModel) {
      return User.fromJson(response.data);
    } else {
      final error = response as FailedResponseModel;
      throw ApiException(error.message, error.statusCode);
    }
  }
}
```

## ❓ Troubleshooting

### Common Issues

**Authentication Token Not Being Sent**

```dart
// Make sure you've set tokens with the TokenManager
TokenManager.setTokens(
  accessToken: 'your_access_token',
  refreshToken: 'your_refresh_token',
  expiry: DateTime.now().add(Duration(hours: 1)),
);

// Ensure your request requires authentication
final response = await DioRequestHandler.get(
  'protected-endpoint',
  requestOptions: RequestOptionsModel(requireAuth: true), // Important!
);
```

**Handling Certificate Issues**

```dart
// Disable certificate verification (not recommended for production)
ApiClient.dio.httpClientAdapter = IOHttpClientAdapter(
  createHttpClient: () {
    final client = HttpClient();
    client.badCertificateCallback = (cert, host, port) => true;
    return client;
  },
);
```

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
