import 'package:dio/dio.dart';
import 'package:dio_flow/dio_flow.dart';
import 'package:dio_flow/src/utils/network_checker.dart';

/// Interceptor that checks for internet connectivity before making API requests.
///
/// This interceptor prevents requests from being made when there is no internet
/// connection, providing a better user experience by failing fast with a clear
/// error message instead of waiting for network timeouts.
class ConnectivityInterceptor extends Interceptor {
  /// Intercepts outgoing requests to check for internet connectivity.
  ///
  /// This method checks if the device has an active internet connection before
  /// allowing the request to proceed. If there is no connection, it rejects the
  /// request immediately with a connection error.
  ///
  /// Parameters:
  ///   options - The original request options
  ///   handler - The request handler used to continue or reject the request
  ///
  /// Returns:
  ///   A Future that completes when the connectivity check is done and
  ///   the request is either allowed to proceed or rejected.
  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (!await NetworkChecker.hasConnection()) {
      return handler.reject(
        DioException(
          requestOptions: options,
          type: DioExceptionType.connectionError,
          message: 'No internet connection',
        ),
      );
    } else {
      return handler.next(options);
    }
  }
}
