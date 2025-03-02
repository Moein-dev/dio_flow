import 'dart:async';
import 'package:dio/dio.dart';
import 'package:dio_flow/src/models/retry_options.dart';
import 'package:dio_flow/src/utils/network_checker.dart';

/// Interceptor that automatically retries failed network requests.
/// 
/// This interceptor handles transient network errors by retrying the request
/// after a specified delay, up to a maximum number of attempts. This improves
/// reliability for operations over unreliable networks.
class RetryInterceptor extends Interceptor {
  /// Configuration options for retry behavior.
  final RetryOptions options;
  
  /// Dio instance for making retry requests.
  final Dio dio;

  /// Creates a retry interceptor with the specified options and Dio instance.
  /// 
  /// Parameters:
  ///   options - Configuration for retry behavior (max attempts, interval)
  ///   dio - Dio instance to use for retry requests
  RetryInterceptor({
    required this.options,
    required this.dio,
  });

  /// Intercepts errors to retry failed requests when appropriate.
  /// 
  /// This method:
  /// 1. Checks if the error is retryable based on error type and retry count
  /// 2. Waits for the specified retry interval
  /// 3. Verifies network connectivity before retrying
  /// 4. Executes the retry request and resolves with the response if successful
  /// 5. Passes along the error if retries are exhausted or not applicable
  /// 
  /// Parameters:
  ///   err - The error that occurred during the request
  ///   handler - The error handler used to continue error processing or resolve with a response
  /// 
  /// Returns:
  ///   A Future that completes when the retry operation is done, either with
  ///   a successful response or by passing the error to the next handler.
  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    var extra = err.requestOptions.extra;
    var retryCount = extra['retryCount'] as int? ?? 0;

    if (_shouldRetry(err, retryCount)) {
      try {
        retryCount += 1;
        extra['retryCount'] = retryCount;

        await Future.delayed(options.retryInterval);
        
        // Check for network connectivity before retrying
        if (!await NetworkChecker.hasConnection()) {
          return handler.next(err);
        }

        final response = await _retry(err.requestOptions);
        return handler.resolve(response);
      } on DioException catch (e) {
        return handler.next(e);
      }
    }

    return handler.next(err);
  }

  /// Determines if a request should be retried based on the error and retry count.
  /// 
  /// This method checks:
  /// 1. If the current retry count is less than the maximum allowed attempts
  /// 2. If the error is not a cancellation (which should never be retried)
  /// 3. If the error is a network-related error that might be resolved by retrying
  /// 
  /// Parameters:
  ///   error - The error that occurred during the request
  ///   retryCount - The current number of retry attempts
  /// 
  /// Returns:
  ///   true if the request should be retried, false otherwise
  bool _shouldRetry(DioException error, int retryCount) {
    return retryCount < options.maxAttempts &&
           error.type != DioExceptionType.cancel &&
           (error.type == DioExceptionType.connectionTimeout ||
            error.type == DioExceptionType.receiveTimeout ||
            error.type == DioExceptionType.sendTimeout ||
            error.type == DioExceptionType.connectionError);
  }

  /// Executes a retry request with the original request options.
  /// 
  /// This method creates a new request with the same parameters as the original,
  /// but using the current Dio instance to execute it.
  /// 
  /// Parameters:
  ///   requestOptions - The options from the original failed request
  /// 
  /// Returns:
  ///   A Future that resolves to the response from the retry request
  /// 
  /// Throws:
  ///   DioException if the retry request fails
  Future<Response<dynamic>> _retry(RequestOptions requestOptions) {
    final options = Options(
      method: requestOptions.method,
      headers: requestOptions.headers,
      extra: requestOptions.extra,
      validateStatus: requestOptions.validateStatus,
      responseType: requestOptions.responseType,
      contentType: requestOptions.contentType,
    );

    return dio.request<dynamic>(
      requestOptions.path,
      data: requestOptions.data,
      queryParameters: requestOptions.queryParameters,
      options: options,
    );
  }
} 