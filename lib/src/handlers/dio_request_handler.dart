import 'dart:developer';
import 'package:dio/dio.dart';
import 'package:dio_flow/src/base/api_client.dart';
import 'package:dio_flow/src/base/api_endpoint_interface.dart';
import 'package:dio_flow/src/base/endpoint_provider.dart';
import 'package:dio_flow/src/models/request_options_model.dart';
import 'package:dio_flow/src/models/response/error_type.dart';
import 'package:dio_flow/src/models/response/response_model.dart';
import 'package:dio_flow/src/models/retry_options.dart';
import 'package:dio_flow/src/utils/http_methods.dart';
import 'package:log_curl_request/log_curl_request.dart';

/// Utility class for handling HTTP requests through Dio.
/// This class provides methods for executing different types of HTTP requests.
class DioRequestHandler {
  /// Private constructor to prevent instantiation.
  /// This ensures the class is used as a utility with static methods only.
  DioRequestHandler._();

  /// Default retry options for all requests made through this handler.
  /// This defines how many times a failed request should be retried and
  /// how long to wait between retries.
  static final RetryOptions retryOptions = RetryOptions(
    maxAttempts: 3,
    retryInterval: const Duration(seconds: 1),
  );

  /// Executes an HTTP request with the specified parameters.
  ///
  /// This is a private method used internally by the public HTTP method
  /// helpers (get, post, put, etc.) to perform the actual request.
  ///
  /// Parameters:
  ///   endpoint - The API endpoint to call (can be ApiEndpoint enum or ApiEndpointInterface)
  ///   parameters - Query parameters to include in the request URL
  ///   data - Request body data for POST, PUT, etc.
  ///   requestOptions - Request configuration options including cache control, auth, and headers
  ///   methodOverride - HTTP method to use if different from the one in requestOptions
  ///
  /// Returns:
  ///   A ResponseModel containing the response data or error information.
  ///
  /// The method handles both successful responses and errors, wrapping
  /// them appropriately in a ResponseModel or FailedResponseModel.
  static Future<ResponseModel> _executeRequest(
    dynamic endpoint, {
    Map<String, dynamic>? parameters,
    dynamic data,
    required RequestOptionsModel requestOptions,
    String? methodOverride,
  }) async {
    final headers = _header(hasBearerToken: requestOptions.hasBearerToken);
    ApiClient.dio.options.headers.addAll(headers);

    // Get the endpoint path based on the type of endpoint provided
    String endpointPath;
    if (endpoint is ApiEndpointInterface) {
      endpointPath = endpoint.path;
    } else if (endpoint is String) {
      try {
        // If a string is provided, first try to treat it as an endpoint name to look up
        endpointPath = EndpointProvider.instance.getEndpoint(endpoint).path;
      } catch (e) {
        // If not found in the registry, assume it's a direct path
        endpointPath = endpoint;
      }
    } else {
      throw ArgumentError(
        'Endpoint must be an ApiEndpointInterface or a registered endpoint name',
      );
    }

    // Convert our model to a Dio Options object
    final dioOptions = requestOptions.toDioOptions(method: methodOverride);

    final String logCurl = LogCurlRequest.create(
      dioOptions.method ?? 'GET',
      endpointPath,
      parameters: parameters,
      data: data,
      headers: headers,
      showDebugPrint: false,
    );

    final CancelToken cancelToken = CancelToken();

    try {
      Response<ResponseModel> response;

      switch (dioOptions.method?.toUpperCase() ?? HttpMethods.GET) {
        case HttpMethods.GET:
          response = await ApiClient.dio.get<ResponseModel>(
            endpointPath,
            queryParameters: parameters,
            options: dioOptions,
            data: data,
            cancelToken: cancelToken,
          );
          break;
        case HttpMethods.POST:
          response = await ApiClient.dio.post<ResponseModel>(
            endpointPath,
            queryParameters: parameters,
            data: data,
            options: dioOptions,
            cancelToken: cancelToken,
          );
          break;
        case HttpMethods.PUT:
          response = await ApiClient.dio.put<ResponseModel>(
            endpointPath,
            queryParameters: parameters,
            data: data,
            options: dioOptions,
            cancelToken: cancelToken,
          );
          break;
        case HttpMethods.PATCH:
          response = await ApiClient.dio.patch<ResponseModel>(
            endpointPath,
            queryParameters: parameters,
            options: dioOptions,
            cancelToken: cancelToken,
          );
          break;
        case HttpMethods.DELETE:
          response = await ApiClient.dio.delete<ResponseModel>(
            endpointPath,
            queryParameters: parameters,
            options: dioOptions,
            cancelToken: cancelToken,
          );
          break;
        default:
          throw Exception('Unsupported HTTP method: ${dioOptions.method}');
      }

      return response.data!;
    } on DioException catch (error, stackTrace) {
      // Determine error type based on Dio error type and status code
      ErrorType errorType;
      if (error.response != null) {
        // If we have a response, determine error type from status code
        errorType = ErrorType.fromStatusCode(error.response!.statusCode ?? 500);
      } else {
        // Otherwise, determine from the Dio error type
        errorType = ErrorType.fromDioErrorType(error.type);
      }

      return FailedResponseModel(
        statusCode: error.response?.statusCode ?? 500,
        message: error.message ?? 'Request failed',
        logCurl: error.requestOptions.extra["log_curl"] ?? logCurl,
        stackTrace: stackTrace,
        error: error,
        errorType: errorType,
      );
    } catch (e, stackTrace) {
      log(e.toString());

      // For non-Dio errors, set appropriate error type
      ErrorType errorType;
      if (e is FormatException) {
        errorType = ErrorType.parsing;
      } else if (e is ArgumentError) {
        errorType = ErrorType.validation;
      } else {
        errorType = ErrorType.unknown;
      }

      return FailedResponseModel(
        statusCode: 500,
        message: e.toString(),
        logCurl: logCurl,
        stackTrace: stackTrace,
        error: e,
        errorType: errorType,
      );
    }
  }

  /// Performs a GET request to the specified API endpoint.
  ///
  /// Parameters:
  ///   endpoint - The API endpoint to call (can be a registered endpoint name,
  ///              an ApiEndpointInterface implementation, or a String path)
  ///   parameters - Optional query parameters to include in the URL
  ///   data - Optional request body data (uncommon for GET requests)
  ///   requestOptions - Request configuration options including cache control and auth
  ///
  /// Returns:
  ///   A ResponseModel containing the response data or error information.
  static Future<ResponseModel> get(
    dynamic endpoint, {
    Map<String, dynamic>? parameters,
    dynamic data,
    RequestOptionsModel requestOptions = const RequestOptionsModel(),
  }) async {
    return _executeRequest(
      endpoint,
      parameters: parameters,
      data: data,
      requestOptions: requestOptions,
      methodOverride: HttpMethods.GET,
    );
  }

  /// Performs a POST request to the specified API endpoint.
  ///
  /// Parameters:
  ///   endpoint - The API endpoint to call (can be a registered endpoint name,
  ///              an ApiEndpointInterface implementation, or a String path)
  ///   parameters - Optional query parameters to include in the URL
  ///   data - Request body data to be sent
  ///   requestOptions - Request configuration options including cache control and auth
  ///
  /// Returns:
  ///   A ResponseModel containing the response data or error information.
  static Future<ResponseModel> post(
    dynamic endpoint, {
    Map<String, dynamic>? parameters,
    dynamic data,
    RequestOptionsModel requestOptions = const RequestOptionsModel(),
  }) async {
    return _executeRequest(
      endpoint,
      parameters: parameters,
      data: data,
      requestOptions: requestOptions,
      methodOverride: HttpMethods.POST,
    );
  }

  /// Performs a PUT request to the specified API endpoint.
  ///
  /// Parameters:
  ///   endpoint - The API endpoint to call (can be a registered endpoint name,
  ///              an ApiEndpointInterface implementation, or a String path)
  ///   parameters - Optional query parameters to include in the URL
  ///   data - Request body data to be sent for updating a resource
  ///   requestOptions - Request configuration options including cache control and auth
  ///
  /// Returns:
  ///   A ResponseModel containing the response data or error information.
  static Future<ResponseModel> put(
    dynamic endpoint, {
    Map<String, dynamic>? parameters,
    dynamic data,
    RequestOptionsModel requestOptions = const RequestOptionsModel(),
  }) async {
    return _executeRequest(
      endpoint,
      parameters: parameters,
      data: data,
      requestOptions: requestOptions,
      methodOverride: HttpMethods.PUT,
    );
  }

  /// Performs a PATCH request to the specified API endpoint.
  ///
  /// Parameters:
  ///   endpoint - The API endpoint to call (can be a registered endpoint name,
  ///              an ApiEndpointInterface implementation, or a String path)
  ///   parameters - Optional query parameters to include in the URL
  ///   requestOptions - Request configuration options including cache control and auth
  ///
  /// Returns:
  ///   A ResponseModel containing the response data or error information.
  static Future<ResponseModel> patch(
    dynamic endpoint, {
    Map<String, dynamic>? parameters,
    RequestOptionsModel requestOptions = const RequestOptionsModel(
      hasBearerToken: true,
    ),
  }) async {
    return _executeRequest(
      endpoint,
      parameters: parameters,
      requestOptions: requestOptions,
      methodOverride: HttpMethods.PATCH,
    );
  }

  /// Performs a DELETE request to the specified API endpoint.
  ///
  /// Parameters:
  ///   endpoint - The API endpoint to call (can be a registered endpoint name,
  ///              an ApiEndpointInterface implementation, or a String path)
  ///   parameters - Optional query parameters to include in the URL
  ///   requestOptions - Request configuration options including cache control and auth
  ///
  /// Returns:
  ///   A ResponseModel containing the response data or error information.
  static Future<ResponseModel> delete(
    dynamic endpoint, {
    Map<String, dynamic>? parameters,
    RequestOptionsModel requestOptions = const RequestOptionsModel(
      hasBearerToken: true,
    ),
  }) async {
    return _executeRequest(
      endpoint,
      parameters: parameters,
      requestOptions: requestOptions,
      methodOverride: HttpMethods.DELETE,
    );
  }

  /// Creates headers for the HTTP request.
  ///
  /// Parameters:
  ///   hasBearerToken - Whether to include an authorization token
  ///
  /// Returns:
  ///   A map of header key-value pairs.
  ///
  /// Currently returns an empty map, to be extended with actual headers
  /// such as authorization tokens, content type, etc.
  static Map<String, dynamic> _header({bool hasBearerToken = false}) {
    final Map<String, dynamic> data = {};
    return data;
  }
}
