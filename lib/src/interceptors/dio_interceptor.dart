import 'package:dio/dio.dart';
import 'package:dio_flow/src/config/dio_flow_config.dart';
import 'package:dio_flow/src/models/response/response_model.dart';
import 'package:dio_flow/src/utils/response_validator.dart';
import 'package:dio_flow/src/utils/token_manager.dart';
import 'package:log_curl_request/log_curl_request.dart';
import 'dart:convert';

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
  DioInterceptor() : dio = Dio(BaseOptions(
    baseUrl: DioFlowConfig.instance.baseUrl,
    connectTimeout: DioFlowConfig.instance.connectTimeout,
    receiveTimeout: DioFlowConfig.instance.receiveTimeout,
    sendTimeout: DioFlowConfig.instance.sendTimeout,
  ));

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
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    try {
      options.headers.addAll({
        "Content-Type": "application/json",
        "Accept": "application/json",
      });

      final token = await TokenManager.getAccessToken();
      if (token != null) {
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
    try {
      // Validate the response
      ResponseValidator.validate(response);
      
      // Prepare the data for ResponseModel.fromJson
      Map<String, dynamic> data;
      if (response.data is Map<String, dynamic>) {
        // Use the response data directly if it's already a Map
        data = Map<String, dynamic>.from(response.data);
      } else if (response.data is String && (response.data as String).isNotEmpty) {
        // If data is a string, it might be raw JSON that wasn't automatically parsed
        try {
          data = jsonDecode(response.data) as Map<String, dynamic>;
        } catch (_) {
          // If can't parse as JSON, wrap it in a Map
          data = {"raw_string_data": response.data};
        }
      } else if (response.data is List) {
        // If data is a List, wrap it in a map with a "data" key
        data = {"data": response.data};
      } else if (response.data == null) {
        // If data is null, create an empty map
        data = {};
      } else {
        // For any other type, wrap it in a map with a "data" key
        data = {"data": response.data};
      }
      
      // Ensure status and logCurl are added to the data
      data["status"] = response.statusCode;
      data["log_curl"] = response.requestOptions.extra["log_curl"] ?? "";
      
      // Create the standardized response model
      response.data = ResponseModel.fromJson(data);
      
      handler.next(response);
    } catch (error) {
      handler.reject(
        DioException(
          requestOptions: response.requestOptions,
          error: error,
          message: 'Response parsing failed',
        ),
      );
    }
  }

  /// Intercepts errors to handle authentication failures.
  /// 
  /// This method checks for 401 Unauthorized responses and clears authentication
  /// tokens when they are detected, forcing the user to log in again.
  /// 
  /// Parameters:
  ///   err - The error that occurred during the request
  ///   handler - The error handler used to continue error processing
  /// 
  /// Always rejects the request with the error, after performing any needed cleanup.
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    try {
      if (err.response?.statusCode == 401) {
        TokenManager.clearTokens();
      }
      handler.reject(err);
    } catch (error) {
      handler.reject(err);
    }
  }
} 