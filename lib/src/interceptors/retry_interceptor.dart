import 'dart:async';
import 'package:dio/dio.dart';

/// Interceptor that automatically retries failed network requests.
///
/// This interceptor handles transient network errors by retrying the request
/// after a specified delay, up to a maximum number of attempts. This improves
/// reliability for operations over unreliable networks.
class RetryInterceptor extends Interceptor {
  final Dio dio;

  RetryInterceptor({required this.dio});

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final Map<String, dynamic> extra = Map<String, dynamic>.from(
      err.requestOptions.extra,
    );

    final int maxAttempts = extra['maxAttempts'] ?? 3;
    final Duration retryInterval =
        extra['retryInterval'] ?? const Duration(seconds: 1);
    final int currentRetryCount = extra['retryCount'] ?? 0;
    final bool retryOnConnectionTimeout =
        extra['retryOnConnectionTimeout'] ?? true;
    final bool retryOnReceiveTimeout = extra['retryOnReceiveTimeout'] ?? true;

    if (_shouldRetry(
      err,
      currentRetryCount,
      maxAttempts,
      retryOnConnectionTimeout,
      retryOnReceiveTimeout,
    )) {
      final int newRetryCount = currentRetryCount + 1;

      final Map<String, dynamic> newExtra = {
        ...extra,
        'retryCount': newRetryCount,
      };

      final RequestOptions newOptions = err.requestOptions.copyWith(
        extra: newExtra,
        data:
            err.requestOptions.data is FormData
                ? (err.requestOptions.data as FormData).clone()
                : err.requestOptions.data,
      );

      await Future.delayed(retryInterval);

      try {
        final Response response = await dio.fetch(newOptions);
        handler.resolve(response);
      } on DioException catch (error) {
        handler.reject(error);
      }
    } else {
      handler.reject(err);
    }
  }

  bool _shouldRetry(
    DioException error,
    int retryCount,
    int maxAttempts,
    bool retryOnConnectionTimeout,
    bool retryOnReceiveTimeout,
  ) {
    return retryCount < maxAttempts &&
        error.type != DioExceptionType.cancel &&
        ((retryOnConnectionTimeout &&
                (error.type == DioExceptionType.connectionTimeout ||
                    error.type == DioExceptionType.sendTimeout ||
                    error.type == DioExceptionType.connectionError)) ||
            (retryOnReceiveTimeout &&
                error.type == DioExceptionType.receiveTimeout));
  }
}
