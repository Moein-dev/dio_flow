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

  /// Prefix used for all cache keys in SharedPreferences to identify them easily.
  static const String _cachePrefix = 'api_cache_';

  CacheInterceptor({required this.prefs});

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final bool shouldCache = options.extra['shouldCache'];
    final Duration cacheDuration = options.extra['cacheDuration'];

    if (!shouldCache) {
      return handler.next(options);
    } else {
      final cacheKey = _generateCacheKey(options);
      final cachedData = prefs.getString(cacheKey);

      if (cachedData != null) {
        final cacheEntry = json.decode(cachedData);
        final timestamp = DateTime.fromMillisecondsSinceEpoch(
          cacheEntry['timestamp'],
        );

        if (DateTime.now().difference(timestamp) < cacheDuration) {
          final response = Response(
            requestOptions: options,
            data: cacheEntry['data'],
            statusCode: 200,
            statusMessage: 'OK (from cache)',
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
            extra: {...options.extra, 'fromCache': true},
          );

          return handler.resolve(response);
        }
        await prefs.remove(cacheKey);
      }
    }
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) async {
    final bool shouldCache = response.requestOptions.extra['shouldCache'];

    if (shouldCache && response.statusCode == 200) {
      final cacheKey = _generateCacheKey(response.requestOptions);
      final cacheEntry = {
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'data': response.data,
        'headers': response.headers.map,
      };
      await prefs.setString(cacheKey, json.encode(cacheEntry));
    }

    handler.next(response);
  }

  /// Generates a unique cache key for a request based on its method, path, and query parameters.
  String _generateCacheKey(RequestOptions options) {
    final buffer =
        StringBuffer()
          ..write(_cachePrefix)
          ..write(options.method)
          ..write(options.path);

    if (options.queryParameters.isNotEmpty) {
      buffer.write('?');
      final stringParams = options.queryParameters.map(
        (key, value) => MapEntry(key, value?.toString() ?? ''),
      );
      buffer.write(Uri(queryParameters: stringParams).query);
    }

    return buffer.toString();
  }

  /// Clears all cached responses stored by this interceptor.
  Future<void> clearCache() async {
    final keys = prefs.getKeys().where((key) => key.startsWith(_cachePrefix));
    for (final key in keys) {
      await prefs.remove(key);
    }
  }
}
