import 'package:dio/dio.dart';
import 'package:dio_flow/src/config/dio_flow_config.dart';
import 'package:dio_flow/src/utils/token_manager.dart';
import 'package:log_curl_request/log_curl_request.dart';

/// Interceptor that handles common Dio request/response processing.
///
/// This interceptor adds authentication headers, logs cURL commands for debugging,
/// validates responses, and handles authentication failures by clearing tokens.
class DioInterceptor extends Interceptor {
  /// Dio instance for making internal requests, like token refresh.
  final Dio dio;

  /// Creates a new Dio interceptor with a configured Dio instance.
  ///
  /// The internal Dio instance is configured with the application's base URL
  /// and default timeouts.
  DioInterceptor()
      : dio = Dio(
          BaseOptions(
            baseUrl: DioFlowConfig.instance.baseUrl,
            connectTimeout: DioFlowConfig.instance.connectTimeout,
            receiveTimeout: DioFlowConfig.instance.receiveTimeout,
            sendTimeout: DioFlowConfig.instance.sendTimeout,
            validateStatus: (status) => true, // Accept all status codes
          ),
        );

  /// Intercepts outgoing requests to add authentication and prepare for logging.
  ///
  /// This method:
  /// 1. Adds standard headers (Content-Type, Accept)
  /// 2. Retrieves and adds the authentication token if available
  /// 3. Creates a cURL command for debugging and logging
  ///
  /// Parameters:
  ///   options - The original request options
  ///   handler - The request handler used to continue or reject the request
  ///
  /// May reject the request if token retrieval or preparation fails.
  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    try {
      options.headers.addAll({
        "Content-Type": "application/json",
        "Accept": "application/json",
      });

      final token = await TokenManager.getAccessToken();
      if (token != null && options.extra['requiresAuth'] != false) {
        options.headers["Authorization"] = "Bearer $token";
      }

      final String logCurl = LogCurlRequest.create(
        options.method,
        options.uri.toString(),
        parameters: options.queryParameters,
        data: options.data,
        headers: options.headers,
      );

      options.extra.addAll({"log_curl": logCurl});
      handler.next(options);
    } catch (error) {
      handler.reject(
        DioException(
          requestOptions: options,
          error: error,
          message: 'Request preparation failed',
        ),
      );
    }
  }

  /// Intercepts responses to validate and standardize the response format.
  ///
  /// This method:
  /// 1. Validates the response using ResponseValidator
  /// 2. Formats the response data into a standardized ResponseModel
  /// 3. Includes the status code and cURL command in the response data
  ///
  /// Parameters:
  ///   response - The response from the server
  ///   handler - The response handler used to continue or reject the response
  ///
  /// May reject the response if validation or parsing fails.
  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    // Always allow the response through, let the handler deal with it
    handler.next(response);
  }

  /// Intercepts errors to handle them appropriately.
  ///
  /// This method:
  /// 1. Checks if we got a response (not a connection error)
  /// 2. Marks connection errors for retry
  /// 3. Passes other errors through
  ///
  /// Parameters:
  ///   err - The error that occurred
  ///   handler - The error handler used to continue or reject
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    // If we got a response, it's not a connection error
    if (err.response != null) {
      handler.next(err);
      return;
    }

    // For connection errors, mark as retry
    if (err.type == DioExceptionType.connectionError) {
      final retryOptions = err.requestOptions.copyWith(
        extra: {
          ...err.requestOptions.extra,
          'isRetry': true,
        },
      );
      handler.reject(err.copyWith(requestOptions: retryOptions));
      return;
    }

    handler.next(err);
  }
}
