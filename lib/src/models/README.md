# Request options

`RequestOptionsModel` groups authentication, retry, cache, logging, header, and
Dio response settings without changing the request methods.

```dart
final response = await DioRequestHandler.get(
  '/reports/{id}',
  pathParameters: {'id': 42},
  parameters: {'include': 'summary'},
  requestOptions: const RequestOptionsModel(
    hasBearerToken: true,
    cacheOptions: CacheOptions(
      shouldCache: true,
      cacheDuration: Duration(minutes: 15),
    ),
    retryOptions: RetryOptions(
      maxAttempts: 3,
      retryInterval: Duration(seconds: 1),
      retryOnConnectionTimeout: true,
      retryOnReceiveTimeout: true,
    ),
  ),
);
```

Caching is opt-in. To bypass it, use the default options or
`CacheOptions.noApiCache`.

```dart
final response = await DioRequestHandler.get(
  '/reports',
  requestOptions: const RequestOptionsModel(
    cacheOptions: CacheOptions.noApiCache,
  ),
);
```

To clear only responses stored by DioFlow:

```dart
await ApiClient.clearCache();
```
