# Dio Flow

A Flutter package providing an enhanced Dio client with built-in support for caching, retry, rate limiting, authentication, and more.

## Features

- **Simplified API**: Clean wrappers around Dio for easy HTTP requests
- **Caching**: Automatic response caching with configurable TTL
- **Authentication**: Token management with auto-refresh support
- **Error Handling**: Standardized error handling and response models
- **Retries**: Automatic retry for failed requests
- **Rate Limiting**: Prevent overwhelming APIs with too many requests
- **Connectivity**: Automatic handling of connectivity changes
- **Metrics**: Performance tracking for API requests
- **Logging**: Detailed request/response logging with cURL commands

## Getting Started

### Installation

Add this to your package's pubspec.yaml file:

```yaml
dependencies:
  dio_flow: ^0.0.1
```

### Configuration

Before using any functionality in the package, you need to configure it with your API's base URL:

```dart
import 'package:dio_flow/dio_flow.dart';

void main() async {
  // Initialize the configuration with your API's base URL
  DioFlowConfig.initialize(
    baseUrl: 'https://api.example.com',
    // Optional: Configure timeouts
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 30),
    sendTimeout: const Duration(seconds: 30),
  );
  
  // Initialize the API client
  await ApiClient.initialize();
  
  // Now you can start using the package
  runApp(MyApp());
}
```

### Basic Usage

Make API requests using the built-in request handler:

```dart
import 'package:dio_flow/dio_flow.dart';

Future<void> fetchData() async {
  try {
    final response = await DioRequestHandler.get(
      ApiEndpoint.todayData,
      // Optional parameters
      parameters: {'filter': 'active'},
      requestOptions: RequestOptionsModel(
        requireAuth: true,
        cacheResponse: true,
      ),
    );
    
    // Access data from standardized response model
    final data = response.data;
    print('Received data: $data');
  } catch (e) {
    print('Error fetching data: $e');
  }
}
```

## Advanced Usage

### Custom Endpoints

You can define your own API endpoints in multiple ways:

```dart
// Register during initialization
void initializeApp() async {
  // Initialize config
  DioFlowConfig.initialize(baseUrl: 'https://api.example.com');
  
  // Register endpoints
  EndpointProvider.instance
    .register('users', '/api/users')
    .register('userProfile', '/api/users/profile');
    
  // Register multiple endpoints at once
  EndpointProvider.instance.registerAll({
    'products': '/api/products',
    'orders': '/api/orders',
  });
  
  // Initialize API client
  await ApiClient.initialize();
}

// Using endpoints with the request handler
Future<void> fetchUsers() async {
  final response = await DioRequestHandler.get(
    'users', // Use the registered endpoint name
    requestOptions: RequestOptionsModel(
      requireAuth: true,
      cacheResponse: true,
    ),
  );
  
  print('Users: ${response.data}');
}
```

#### Advanced Custom Endpoints

For more complex scenarios, you can create custom endpoint implementations:

```dart
class SearchEndpoint implements ApiEndpointInterface {
  @override
  final String path = '/api/search';
  
  // You can add custom methods for your endpoints
  String buildSearchUrl(String query) {
    return '$path?q=${Uri.encodeComponent(query)}';
  }
}

// Register and use your custom endpoint
void setupEndpoints() {
  final searchEndpoint = SearchEndpoint();
  EndpointProvider.instance.register('search', searchEndpoint);
}

// Then use it in requests
Future<void> search(String query) async {
  final endpoint = EndpointProvider.instance.getEndpoint('search') as SearchEndpoint;
  print('Search URL: ${endpoint.buildSearchUrl(query)}');
  
  // Use for requests
  final response = await DioRequestHandler.get(
    endpoint,
    parameters: {'q': query},
    requestOptions: RequestOptionsModel(),
  );
}
```

### Authentication

Set authentication tokens after user login:

```dart
// After successful login:
TokenManager.setTokens(
  accessToken: 'your_access_token',
  refreshToken: 'your_refresh_token',
  expiry: DateTime.now().add(Duration(hours: 1)),
);
```

### Direct Dio Access

Access the underlying Dio instance for advanced use cases:

```dart
final dio = ApiClient.dio;
// Use dio directly if needed
```

## License

This project is licensed under the MIT License - see the LICENSE file for details.
