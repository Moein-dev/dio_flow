import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:dio_flow/dio_flow.dart';
import 'package:dio_flow/src/handlers/dio_flow_log.dart';
import 'package:dio_flow/src/handlers/dio_log_formatter.dart';

/// Helper Method

class DioHndlerHelper {
  DioHndlerHelper._();

  static const String uploadProgressExtraKey =
      '_dio_flow_internal_upload_progress';

  static Future<Map<String, dynamic>> prepareHeaders({
    bool hasBearerToken = false,
    Map<String, dynamic> additionalHeaders = const {},
    bool isdataFile = false,
  }) async {
    final Map<String, dynamic> headers = {...additionalHeaders};
    if (!isdataFile) {
      headers.putIfAbsent("Content-Type", () => "application/json");
    }
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
    String method, {
    Map<String, dynamic>? parameters,
    dynamic data,
    RequestOptionsModel requestOptions = const RequestOptionsModel(),
  }) async {
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

    final logModel = requestOptions.logModel ?? LogModel.disabledAllLog;
    final stopwatch = Stopwatch()..start();
    if (logModel.defaultLog) {
      DioFlowLog(
        logModel: logModel,
        type: DioLogType.request,
        url: DioFlowConfig.instance.baseUrl + endpointPath,
        method: method,
        parameters: parameters,
        data: data,
        headers: requestOptions.customHeaders,
        isMock: true,
      ).log();
    }

    final mockResponse = MockDioFlow.getMockResponse(endpointPath, method);
    if (mockResponse == null) {
      stopwatch.stop();
      if (logModel.defaultLog) {
        DioFlowLog(
          logModel: logModel,
          type: DioLogType.error,
          url: DioFlowConfig.instance.baseUrl + endpointPath,
          method: method,
          statusCode: 404,
          message: 'No mock response registered',
          isMock: true,
          duration: stopwatch.elapsed,
        ).log();
      }
      return FailedResponseModel(
        statusCode: 404,
        message: 'No mock response registered for $method $endpointPath',
        logCurl: 'MOCK REQUEST - NO RESPONSE REGISTERED',
        errorType: ErrorType.notFound,
      );
    }
    await mockResponse.simulateDelay();
    stopwatch.stop();
    if (logModel.defaultLog) {
      DioFlowLog(
        logModel: logModel,
        type: mockResponse.isSuccess ? DioLogType.response : DioLogType.error,
        url: DioFlowConfig.instance.baseUrl + endpointPath,
        method: method,
        statusCode: mockResponse.statusCode,
        message: mockResponse.message,
        data: mockResponse.data,
        errorType: mockResponse.errorType,
        isMock: true,
        duration: stopwatch.elapsed,
      ).log();
    }
    return MockDioFlow.convertToResponseModel(mockResponse);
  }

  static bool shouldRetry(
    RetryOptions retryOption,
    int? statusCode,
    DioException? error,
  ) {
    if (statusCode != null) {
      return retryOption.retryStatusCodes.contains(statusCode);
    }

    return switch (error?.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.connectionError => retryOption.retryOnConnectionTimeout,
      DioExceptionType.receiveTimeout => retryOption.retryOnReceiveTimeout,
      _ => false,
    };
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
    bool includeSensitiveData = false,
  }) {
    try {
      final uri = Uri.parse('$baseUrl$endpointPath').replace(
        queryParameters:
            parameters == null || parameters.isEmpty
                ? null
                : parameters.map(
                  (key, value) => MapEntry(
                    key,
                    !includeSensitiveData && isSensitiveLogKey(key)
                        ? maskedLogValue
                        : _queryValue(value),
                  ),
                ),
      );
      final buffer = StringBuffer(
        'curl -X ${_shellQuote(methodOverride.toUpperCase())}',
      )..write(' ${_shellQuote(uri.toString())}');

      for (final entry in (headers ?? {}).entries) {
        if (entry.key.toLowerCase() == 'content-length') {
          continue;
        }
        final value =
            !includeSensitiveData && _isSensitiveHeader(entry.key)
                ? maskedLogValue
                : entry.value.toString();
        buffer.write(' -H ${_shellQuote('${entry.key}: $value')}');
      }

      if (data is FormData) {
        for (final field in data.fields) {
          final value =
              !includeSensitiveData && isSensitiveLogKey(field.key)
                  ? maskedLogValue
                  : field.value;
          buffer.write(' -F ${_shellQuote('${field.key}=$value')}');
        }
        for (final file in data.files) {
          final filename = file.value.filename ?? 'file';
          final contentType = file.value.contentType.toString();
          buffer.write(
            ' -F ${_shellQuote('${file.key}=@$filename;type=$contentType')}',
          );
        }
      } else if (data != null) {
        dynamic valueToSanitize = data;
        if (data is String) {
          try {
            valueToSanitize = jsonDecode(data);
          } catch (_) {
            valueToSanitize = data;
          }
        }
        final sanitizedData = sanitizeLogValue(
          valueToSanitize,
          maskSensitiveData: !includeSensitiveData,
        );
        final body =
            sanitizedData is String ? sanitizedData : jsonEncode(sanitizedData);
        buffer.write(' --data-raw ${_shellQuote(body)}');
      }

      return buffer.toString();
    } catch (_) {
      return 'Unable to generate cURL';
    }
  }

  static bool _isSensitiveHeader(String name) {
    return isSensitiveLogKey(name);
  }

  static String _shellQuote(String value) {
    return "'${value.replaceAll("'", "'\"'\"'")}'";
  }

  static dynamic _queryValue(dynamic value) {
    if (value is Iterable) {
      return value.map((item) => item.toString()).toList();
    }
    return value?.toString() ?? '';
  }
}
