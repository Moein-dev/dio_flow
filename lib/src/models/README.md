# Network Request Options Guide

This guide explains how to use the `RequestOptionsModel` to control cache behavior and other settings in your API requests.

## Basic Usage

The `RequestOptionsModel` provides a structured way to configure API requests, including cache control, authentication, and more:

```dart
// Make a standard GET request (default caching behavior)
final response = await DioRequestHandler.get(ApiEndpoint.allData);

// Make a GET request with authentication
final response = await DioRequestHandler.get(
  ApiEndpoint.todayData,
  requestOptions: RequestOptionsModel(hasBearerToken: true),
);

// Make a POST request with data (posts are not cached by default)
final response = await DioRequestHandler.post(
  ApiEndpoint.register,
  data: {'email': 'user@example.com', 'password': '123456'},
);
```

## Cache Control Examples

The `RequestOptionsModel` makes it easy to control caching behavior:

### Disable Caching

For requests that always need fresh data:

```dart
// Using the noCache flag
final response = await DioRequestHandler.get(
  ApiEndpoint.allData,
  requestOptions: RequestOptionsModel(noCache: true),
);

// Or using the predefined constant
final response = await DioRequestHandler.get(
  ApiEndpoint.dataInRange,
  requestOptions: RequestOptionsModel.noApiCache,
);
```

### Custom Cache Duration

For requests that need different cache durations:

```dart
// Short cache (1 minute)
final response = await DioRequestHandler.get(
  ApiEndpoint.todayData,
  requestOptions: RequestOptionsModel.shortApiCache,
);

// Medium cache (15 minutes)
final response = await DioRequestHandler.get(
  ApiEndpoint.allData,
  requestOptions: RequestOptionsModel.mediumApiCache,
);

// Long cache (1 hour)
final response = await DioRequestHandler.get(
  ApiEndpoint.todayData,
  requestOptions: RequestOptionsModel.longApiCache,
);

// Custom duration
final response = await DioRequestHandler.get(
  ApiEndpoint.dataInRange,
  requestOptions: RequestOptionsModel(
    cacheMaxAge: Duration(minutes: 45),
  ),
);
```

### Combining Options

You can combine cache settings with other options:

```dart
// Authenticated request with custom cache duration
final response = await DioRequestHandler.get(
  ApiEndpoint.todayData,
  requestOptions: RequestOptionsModel(
    hasBearerToken: true,
    cacheMaxAge: Duration(minutes: 10),
  ),
);

// Or using copyWith on a predefined option
final response = await DioRequestHandler.get(
  ApiEndpoint.allData,
  requestOptions: RequestOptionsModel.mediumApiCache.copyWith(
    hasBearerToken: true,
  ),
);
```

## Advanced Configuration

For more complex scenarios:

```dart
// Custom headers and response type
final response = await DioRequestHandler.get(
  ApiEndpoint.todayData,
  requestOptions: RequestOptionsModel(
    hasBearerToken: true,
    headers: {'X-Custom-Header': 'value'},
    responseType: ResponseType.plain,
    cacheMaxAge: Duration(minutes: 5),
  ),
);

// Raw binary data download (no caching)
final response = await DioRequestHandler.get(
  ApiEndpoint.downloadFile,
  requestOptions: RequestOptionsModel(
    responseType: ResponseType.bytes,
    noCache: true,
  ),
);
```

## Clearing the Cache

To clear all cached responses:

```dart
// Clear all cached responses
await ApiClient.clearCache();
``` 