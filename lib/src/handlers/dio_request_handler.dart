// dio_request_handler.dart

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

/// Utility class for handling HTTP requests through Dio.
///
class DioRequestHandler {
  DioRequestHandler._();

  static final RetryOptions retryOptions = RetryOptions(
    maxAttempts: 3,
    retryInterval: const Duration(seconds: 1),
  );

    static Future<ResponseModel> _executeRequest(
    dynamic endpoint, {
    Map<String, dynamic>? parameters,
    dynamic data,
    required RequestOptionsModel requestOptions,
    String? methodOverride,
  }) async {
    if (MockDioFlow.isMockEnabled) {
      return _handleMockRequest(endpoint, methodOverride ?? HttpMethods.get);
    }

    final headers = await _prepareHeaders(
      hasBearerToken: requestOptions.hasBearerToken,
      additionalHeaders: requestOptions.headers ?? {},
    );

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
      throw ArgumentError(
        'Endpoint must be an ApiEndpointInterface or a registered endpoint name',
      );
    }

    final dioOptions = requestOptions.toDioOptions(method: methodOverride);
    dioOptions.headers = {...dioOptions.headers ?? {}, ...headers};

    dioOptions.extra = {
      ...dioOptions.extra ?? {},
      'retryCount': retryOptions.maxAttempts,
      'retryInterval': retryOptions.retryInterval.inMilliseconds,
      'isRetry': dioOptions.extra?['isRetry'] ?? false,
    };

    final CancelToken cancelToken = CancelToken();

    int maxAttempts = retryOptions.maxAttempts;
    final Duration interval = retryOptions.retryInterval;

    for (int attempt = 0; attempt < maxAttempts; attempt++) {
      dioOptions.extra = {
        ...dioOptions.extra ?? {},
        'isRetry': attempt > 0,
        'retryCount': (maxAttempts - attempt),
      };

      try {
        Response response;
        final method = (methodOverride ?? HttpMethods.get).toUpperCase();

        switch (method) {
          case HttpMethods.get:
            response = await ApiClient.dio.get(
              endpointPath,
              queryParameters: parameters,
              options: dioOptions,
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
              data: data,
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

        Map<String, dynamic> responseData;
        if (response.data is Map<String, dynamic>) {
          responseData = Map<String, dynamic>.from(response.data);
        } else if (response.data is List) {
          responseData = {'data': response.data, 'status': response.statusCode};
        } else if (response.data is String && response.data.isNotEmpty) {
          try {
            responseData =
                Map<String, dynamic>.from(jsonDecode(response.data));
          } catch (_) {
            responseData = {'data': response.data, 'status': response.statusCode};
          }
        } else if (response.data == null) {
          responseData = {'status': response.statusCode, 'message': 'Success'};
        } else {
          responseData = {'data': response.data, 'status': response.statusCode};
        }

        if (!responseData.containsKey('status') &&
            !responseData.containsKey('statusCode')) {
          responseData['status'] = response.statusCode;
        }

        final logCurlFromResponse = response.extra['log_curl'];
        final logCurlFromRequest = response.requestOptions.extra['log_curl'];
        if (logCurlFromResponse != null) {
          responseData['log_curl'] = logCurlFromResponse;
        } else if (logCurlFromRequest != null) {
          responseData['log_curl'] = logCurlFromRequest;
        }

        if (response.headers.map.isNotEmpty) {
          final relevantHeaders = <String, dynamic>{};
          for (final h in [
            'content-type',
            'authorization',
            'x-total-count',
            'x-pagination-total',
            'x-total-pages',
          ]) {
            if (response.headers.map.containsKey(h)) {
              relevantHeaders[h] = response.headers.value(h);
            }
          }
          if (relevantHeaders.isNotEmpty) {
            responseData['headers'] = relevantHeaders;
          }
        }

        final statusCode = response.statusCode ?? 500;
        if (statusCode >= 200 && statusCode < 300) {
          return SuccessResponseModel.fromJson(responseData);
        } else {
          return FailedResponseModel.fromJson(responseData);
        }
      } on DioException catch (error, stackTrace) {
        final isLast = attempt == maxAttempts - 1;

        String logCurl = 'No log available';
        try {
          logCurl = dioOptions.extra?['log_curl'] ??
              error.requestOptions.extra['log_curl'] ??
              error.response?.extra['log_curl'] ??
              'No log available';
        } catch (_) {}

        final statusCode = error.response?.statusCode;
        if (statusCode != 401 && !isLast) {
          if (interval.inMilliseconds > 0) {
            await Future.delayed(interval);
          }
          continue;
        }

        ErrorType errorType;
        if (error.requestOptions.extra['errorType'] == 'preparation_error') {
          errorType = ErrorType.validation;
        } else if (error.response != null) {
          errorType = ErrorType.fromStatusCode(error.response!.statusCode ?? 500);
        } else {
          errorType = ErrorType.fromDioErrorType(error.type);
        }

        final bool isRetry = attempt > 0;

        return FailedResponseModel(
          statusCode: error.response?.statusCode ?? 500,
          message: isRetry
              ? 'Request failed after ${attempt + 1} attempts: ${error.message}'
              : error.message ?? 'Request failed',
          logCurl: logCurl,
          stackTrace: stackTrace,
          error: error,
          errorType: errorType,
        );
      }
    }

    return FailedResponseModel(
      statusCode: 500,
      message: 'Unknown error after retries',
      logCurl: dioOptions.extra?['log_curl'] ?? 'No log available',
      errorType: ErrorType.unknown,
    );
  }

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

  static Future<ResponseModel> patch(
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
      methodOverride: HttpMethods.patch,
    );
  }

  static Future<ResponseModel> delete(
    dynamic endpoint, {
    Map<String, dynamic>? parameters,
    RequestOptionsModel requestOptions = const RequestOptionsModel(),
  }) async {
    return _executeRequest(
      endpoint,
      parameters: parameters,
      requestOptions: requestOptions,
      methodOverride: HttpMethods.delete,
    );
  }

  static Future<Map<String, dynamic>> _prepareHeaders({
    bool hasBearerToken = false,
    Map<String, dynamic> additionalHeaders = const {},
  }) async {
    final Map<String, dynamic> headers = {...additionalHeaders};
    if (hasBearerToken) {
      final token = await TokenManager.getAccessToken();
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    }
    return headers;
  }

  static Future<ResponseModel> _handleMockRequest(
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
}
