import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Interceptor for caching HTTP responses to improve performance and reduce network usage.
///
/// This interceptor caches successful GET responses in SharedPreferences and serves
/// them for subsequent identical requests until they expire based on the defined maxAge.
class CacheInterceptor extends Interceptor {
  /// SharedPreferences instance used for storing and retrieving cached responses.
  final SharedPreferences prefs;

  /// The maximum duration for which a cached response is considered valid.
  final Duration maxAge;

  /// Prefix used for all cache keys in SharedPreferences to identify them easily.
  static const String _cachePrefix = 'api_cache_';

  /// Creates a new cache interceptor with the provided preferences and max age.
  ///
  /// Parameters:
  ///   prefs - SharedPreferences instance for storing cache data
  ///   maxAge - Maximum duration for which cached responses are valid (default: 5 minutes)
  CacheInterceptor({
    required this.prefs,
    this.maxAge = const Duration(minutes: 5),
  });

  /// Intercepts outgoing requests to serve cached responses when available.
  ///
  /// This method checks if there's a valid cached response for GET requests
  /// and serves it instead of making a network request. If no valid cache is
  /// found, it allows the request to proceed normally.
  ///
  /// Parameters:
  ///   options - The original request options
  ///   handler - The request handler used to continue or resolve the request
  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (options.method != 'GET') {
      return handler.next(options);
    }

    // Skip caching if explicitly disabled for this request
    if (options.extra['no_cache'] == true) {
      return handler.next(options);
    }

    // Use request-specific cache duration if provided
    final requestMaxAge = options.extra['cache_maxAge'] as Duration? ?? maxAge;

    final cacheKey = _generateCacheKey(options);
    final cachedData = prefs.getString(cacheKey);

    if (cachedData != null) {
      final cacheEntry = json.decode(cachedData);
      final timestamp = DateTime.fromMillisecondsSinceEpoch(
        cacheEntry['timestamp'],
      );

      if (DateTime.now().difference(timestamp) < requestMaxAge) {
        final response = Response(
          requestOptions: options,
          data: cacheEntry['data'],
          statusCode: 200,
          headers: Headers.fromMap(
            Map<String, List<String>>.from(
              (cacheEntry['headers'] as Map<String, dynamic>).map(
                (key, value) => MapEntry(
                  key,
                  (value as List<dynamic>).map((e) => e.toString()).toList(),
                ),
              ),
            ),
          ),
        );
        return handler.resolve(response);
      }

      await prefs.remove(cacheKey);
    }

    return handler.next(options);
  }

  /// Intercepts responses to cache successful GET responses.
  ///
  /// This method stores successful GET responses in SharedPreferences for future
  /// use, including the data, headers, and a timestamp for expiration checking.
  ///
  /// Parameters:
  ///   response - The response from the server
  ///   handler - The response handler used to continue the response processing
  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) async {
    if (response.requestOptions.method == 'GET' && response.statusCode == 200) {
      final cacheKey = _generateCacheKey(response.requestOptions);
      final cacheEntry = {
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'data': response.data,
        'headers': response.headers.map,
      };
      await prefs.setString(cacheKey, json.encode(cacheEntry));
    }
    return handler.next(response);
  }

  /// Generates a unique cache key for a request based on its method, path, and query parameters.
  ///
  /// This ensures that different requests get different cache entries, even if they
  /// only differ in their query parameters.
  ///
  /// Parameters:
  ///   options - The request options containing method, path, and query parameters
  ///
  /// Returns:
  ///   A string key that uniquely identifies the request for caching purposes
  String _generateCacheKey(RequestOptions options) {
    final buffer =
        StringBuffer()
          ..write(_cachePrefix)
          ..write(options.method)
          ..write(options.path);
    if (options.queryParameters.isNotEmpty) {
      buffer.write('?');
      // Convert all parameter values to strings
      final stringParams = options.queryParameters.map(
        (key, value) => MapEntry(key, value?.toString() ?? ''),
      );
      buffer.write(Uri(queryParameters: stringParams).query);
    }

    return buffer.toString();
  }

  /// Clears all cached responses stored by this interceptor.
  ///
  /// This is useful when all cached data needs to be invalidated, such as
  /// after a user logs out or when the API version changes.
  ///
  /// Returns:
  ///   A Future that completes when all cache entries have been removed
  Future<void> clearCache() async {
    final keys = prefs.getKeys().where((key) => key.startsWith(_cachePrefix));
    for (final key in keys) {
      await prefs.remove(key);
    }
  }
}
