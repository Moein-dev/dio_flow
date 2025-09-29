import 'package:dio/dio.dart';
import 'package:dio_flow/dio_flow.dart';
import 'package:log_curl_request/log_curl_request.dart';

/// Helper Method

class DioHndlerHelper {
  DioHndlerHelper._();

  static Future<Map<String, dynamic>> prepareHeaders({
    bool hasBearerToken = false,
    Map<String, dynamic> additionalHeaders = const {},
  }) async {
    final Map<String, dynamic> headers = {...additionalHeaders};
    headers.putIfAbsent("Content-Type", () => "application/json");
    headers.putIfAbsent("Accept", () => "application/json");
    if (hasBearerToken) {
      final token = await TokenManager.getAccessToken();
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    }
    return headers;
  }

  static Future<ResponseModel> handleMockRequest(
    dynamic endpoint,
    String method,
  ) async {
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

    final mockResponse = MockDioFlow.getMockResponse(endpointPath, method);
    if (mockResponse == null) {
      return FailedResponseModel(
        statusCode: 404,
        message: 'No mock response registered for $method $endpointPath',
        logCurl: 'MOCK REQUEST - NO RESPONSE REGISTERED',
        errorType: ErrorType.notFound,
      );
    }
    await mockResponse.simulateDelay();
    return MockDioFlow.convertToResponseModel(mockResponse);
  }

  static bool shouldRetry(
    RetryOptions? retryOption,
    int? statusCode,
    DioException? error,
  ) {
    if (statusCode != null) {
      if (retryOption!.retryStatusCodes.contains(statusCode)) {
        return true;
      } else {
        return false;
      }
    } else {
      if (error!.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.receiveTimeout ||
          error.type == DioExceptionType.sendTimeout ||
          error.type == DioExceptionType.connectionError) {
        return true;
      } else {
        return false;
      }
    }
  }

  static String endpointPath(dynamic endpoint) {
    if (endpoint is ApiEndpointInterface) {
      return endpoint.path;
    } else if (endpoint is String) {
      try {
        return EndpointProvider.instance.getEndpoint(endpoint).path;
      } catch (e) {
        return endpoint;
      }
    } else {
      throw ArgumentError(
        'Endpoint must be an ApiEndpointInterface or a registered endpoint name',
      );
    }
  }

  /// Resolve placeholders like /users/{id}/posts/{postId}
  /// using provided pathParameters map.
  /// Values are encoded with Uri.encodeComponent.
  static String resolvePath(
    String template,
    Map<String, dynamic>? pathParameters,
  ) {
    if (pathParameters == null || pathParameters.isEmpty) {
      return template;
    }
    var resolved = template;
    pathParameters.forEach((key, value) {
      final replacement =
          value == null ? '' : Uri.encodeComponent(value.toString());
      resolved = resolved.replaceAll('{$key}', replacement);
    });
    return resolved;
  }

  static String curlCommand({
    required String methodOverride,
    required String baseUrl,
    required String endpointPath,
    Map<String, dynamic>? parameters,
    dynamic data,
    Map<String, dynamic>? headers,
  }) {
    try {
      return LogCurlRequest.create(
        methodOverride,
        baseUrl + endpointPath,
        parameters: parameters,
        data: data,
        headers: Map<String, dynamic>.from(headers ?? {}),
        showDebugPrint: false,
      );
    } catch (e) {
      return 'Failed to generate cURL: $e';
    }
  }
}
