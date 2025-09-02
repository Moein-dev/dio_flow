import 'dart:developer';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:dio_flow/src/base/api_client.dart';
import 'package:dio_flow/src/base/api_endpoint_interface.dart';
import 'package:dio_flow/src/base/endpoint_provider.dart';
import 'package:dio_flow/src/models/request_options_model.dart';
import 'package:dio_flow/src/models/response/error_type.dart';
import 'package:dio_flow/src/models/response/response_model.dart';
import 'package:dio_flow/src/models/retry_options.dart';
import 'package:dio_flow/src/utils/http_methods.dart';
import 'package:dio_flow/src/utils/token_manager.dart';
import 'package:dio_flow/src/utils/mock_dio_flow.dart';
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
    String logCurl = '';

    // Check if mock mode is enabled
    if (MockDioFlow.isMockEnabled) {
      return _handleMockRequest(endpoint, methodOverride ?? HttpMethods.get);
    }

    try {
      final headers = await _header(
        hasBearerToken: requestOptions.hasBearerToken,
      );
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

      // Create full URL by combining base URL and endpoint path
      final String fullUrl =
          Uri.parse(
            ApiClient.dio.options.baseUrl,
          ).resolve(endpointPath).toString();

      logCurl = LogCurlRequest.create(
        dioOptions.method ?? 'GET',
        fullUrl,
        parameters: parameters,
        data: data,
        headers: headers,
        showDebugPrint: false,
      );

      final CancelToken cancelToken = CancelToken();
      Response response;

      switch (methodOverride?.toUpperCase() ?? HttpMethods.get) {
        case HttpMethods.get:
          response = await ApiClient.dio.get(
            endpointPath,
            queryParameters: parameters,
            options: dioOptions,
            data: data,
            cancelToken: cancelToken,
          );
          break;
        case HttpMethods.post:
          response = await ApiClient.dio.post(
            endpointPath,
            queryParameters: parameters,
            data: data,
            options: dioOptions,
            cancelToken: cancelToken,
          );
          break;
        case HttpMethods.put:
          response = await ApiClient.dio.put(
            endpointPath,
            queryParameters: parameters,
            data: data,
            options: dioOptions,
            cancelToken: cancelToken,
          );
          break;
        case HttpMethods.patch:
          response = await ApiClient.dio.patch(
            endpointPath,
            queryParameters: parameters,
            options: dioOptions,
            cancelToken: cancelToken,
          );
          break;
        case HttpMethods.delete:
          response = await ApiClient.dio.delete(
            endpointPath,
            queryParameters: parameters,
            options: dioOptions,
            cancelToken: cancelToken,
          );
          break;
        default:
          throw Exception('Unsupported HTTP method: ${dioOptions.method}');
      }

      // Convert response data to Map<String, dynamic> if it's not already
      Map<String, dynamic> responseData;
      if (response.data is Map<String, dynamic>) {
        responseData = Map<String, dynamic>.from(response.data);
      } else if (response.data is List) {
        // Handle array responses by wrapping them in a data field
        responseData = {'data': response.data, 'status': response.statusCode};
      } else if (response.data is String && response.data.isNotEmpty) {
        try {
          // Try to parse string as JSON first
          final decoded = Map<String, dynamic>.from(jsonDecode(response.data));
          responseData = decoded;
        } catch (e) {
          // If not JSON, wrap the string in a data field
          responseData = {'data': response.data, 'status': response.statusCode};
        }
      } else if (response.data == null) {
        // Handle null responses (like for 204 No Content)
        responseData = {'status': response.statusCode, 'message': 'Success'};
      } else {
        // For any other type, wrap it in a data field
        responseData = {'data': response.data, 'status': response.statusCode};
      }

      // Ensure status code is present
      if (!responseData.containsKey('status') &&
          !responseData.containsKey('statusCode')) {
        responseData['status'] = response.statusCode;
      }

      // Add log curl
      responseData['log_curl'] = logCurl;

      // Add headers if they contain important information
      if (response.headers.map.isNotEmpty) {
        final relevantHeaders = <String, dynamic>{};
        final headersToInclude = [
          'content-type',
          'authorization',
          'x-total-count',
          'x-pagination-total',
          'x-total-pages',
        ];

        for (final header in headersToInclude) {
          if (response.headers.map.containsKey(header)) {
            relevantHeaders[header] = response.headers.value(header);
          }
        }

        if (relevantHeaders.isNotEmpty) {
          responseData['headers'] = relevantHeaders;
        }
      }

      // Create appropriate response model based on status code
      final statusCode = response.statusCode ?? 500;
      if (statusCode >= 200 && statusCode < 300) {
        return SuccessResponseModel.fromJson(responseData);
      } else {
        return FailedResponseModel.fromJson(responseData);
      }
    } on DioException catch (error, stackTrace) {
      // Determine error type based on Dio error type and status code
      ErrorType errorType;

      // Check for preparation errors first
      if (error.requestOptions.extra.containsKey('errorType') &&
          error.requestOptions.extra['errorType'] == 'preparation_error') {
        errorType = ErrorType.validation;
      } else if (error.response != null) {
        // If we have a response, determine error type from status code
        errorType = ErrorType.fromStatusCode(error.response!.statusCode ?? 500);
      } else {
        // Otherwise, determine from the Dio error type
        errorType = ErrorType.fromDioErrorType(error.type);
      }

      // Check if this is a retry attempt
      final bool isRetry = error.requestOptions.extra.containsKey('isRetry');
      final String message =
          isRetry
              ? 'Request failed after retry: ${error.message}'
              : error.message ?? 'Request failed';

      return FailedResponseModel(
        statusCode: error.response?.statusCode ?? 500,
        message: message,
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
      methodOverride: HttpMethods.get,
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
      methodOverride: HttpMethods.post,
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
      methodOverride: HttpMethods.put,
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
      methodOverride: HttpMethods.patch,
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
      methodOverride: HttpMethods.delete,
    );
  }

  /// Creates headers for the HTTP request.
  ///
  /// Parameters:
  ///   hasBearerToken - Whether to include an authorization token
  ///
  /// Returns:
  ///   A map of header key-value pairs.
  static Future<Map<String, dynamic>> _header({
    bool hasBearerToken = false,
  }) async {
    final Map<String, dynamic> headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (hasBearerToken) {
      try {
        final token = await TokenManager.getAccessToken();
        if (token != null && token.isNotEmpty) {
          headers['Authorization'] = 'Bearer $token';
        }
      } catch (e) {
        // If token retrieval fails, continue without authorization header
        // The request will likely fail with 401, which can be handled by the caller
      }
    }

    return headers;
  }

  /// Handles mock requests when mock mode is enabled.
  ///
  /// Parameters:
  ///   endpoint - The API endpoint being called
  ///   method - The HTTP method being used
  ///
  /// Returns:
  ///   A ResponseModel based on the registered mock response
  static Future<ResponseModel> _handleMockRequest(
    dynamic endpoint,
    String method,
  ) async {
    // Get the endpoint path
    String endpointPath;
    if (endpoint is ApiEndpointInterface) {
      endpointPath = endpoint.path;
    } else if (endpoint is String) {
      try {
        endpointPath = EndpointProvider.instance.getEndpoint(endpoint).path;
      } catch (e) {
        endpointPath = endpoint;
      }
    } else {
      endpointPath = endpoint.toString();
    }

    // Get mock response
    final mockResponse = MockDioFlow.getMockResponse(endpointPath, method);

    if (mockResponse == null) {
      // No mock registered, return a default error
      return FailedResponseModel(
        statusCode: 404,
        message: 'No mock response registered for $method $endpointPath',
        logCurl: 'MOCK REQUEST - NO RESPONSE REGISTERED',
        errorType: ErrorType.notFound,
      );
    }

    // Simulate network delay if specified
    await mockResponse.simulateDelay();

    // Convert mock response to ResponseModel
    return MockDioFlow.convertToResponseModel(mockResponse);
  }
}
