import 'dart:collection';
import 'package:dio/dio.dart';

/// Interceptor that enforces rate limiting for API requests.
/// 
/// This interceptor tracks the number of requests made within a specified time interval
/// and rejects requests that exceed the defined limit. This helps prevent API abuse
/// and ensures compliance with API rate limits.
class RateLimitInterceptor extends Interceptor {
  /// The time window during which requests are counted towards the rate limit.
  final Duration interval;
  
  /// The maximum number of requests allowed within the specified interval.
  final int maxRequests;
  
  /// Queue storing timestamps of recent requests for rate limiting calculations.
  final Queue<DateTime> _requestTimestamps = Queue();

  /// Creates a new rate limit interceptor with the specified parameters.
  /// 
  /// Parameters:
  ///   interval - The time window for rate limiting (default: 1 minute)
  ///   maxRequests - The maximum number of requests allowed in the interval (default: 30)
  RateLimitInterceptor({
    this.interval = const Duration(minutes: 1),
    this.maxRequests = 30,
  });

  /// Intercepts outgoing requests to enforce rate limiting.
  /// 
  /// This method:
  /// 1. Removes timestamps outside the current interval window
  /// 2. Checks if the number of recent requests exceeds the maximum allowed
  /// 3. Rejects the request with an appropriate error message if rate limit is exceeded
  /// 4. Otherwise, adds the current timestamp to the queue and allows the request
  /// 
  /// Parameters:
  ///   options - The original request options
  ///   handler - The request handler used to continue or reject the request
  /// 
  /// Returns:
  ///   A Future that completes when the rate limit check is done and
  ///   the request is either allowed to proceed or rejected.
  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final now = DateTime.now();
    
    // Remove timestamps outside the interval window
    while (_requestTimestamps.isNotEmpty &&
           now.difference(_requestTimestamps.first) > interval) {
      _requestTimestamps.removeFirst();
    }

    if (_requestTimestamps.length >= maxRequests) {
      final oldestRequest = _requestTimestamps.first;
      final waitTime = interval - now.difference(oldestRequest);
      
      return handler.reject(
        DioException(
          requestOptions: options,
          error: 'Rate limit exceeded',
          message: 'Please wait ${waitTime.inSeconds} seconds before retrying',
          type: DioExceptionType.badResponse,
        ),
      );
    }

    _requestTimestamps.add(now);
    return handler.next(options);
  }
} 