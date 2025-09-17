import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:dio_flow/dio_flow.dart';
import 'package:dio_flow/src/handlers/dio_flow_log.dart';
import 'package:dio_flow/src/handlers/dio_hndler_helper.dart';

/// for refreshToken Handle
class DioRefreshTokenRequestHandle {
  static Future<ResponseModel> _executeRequestForRefreshToken(
    dynamic endpoint, {
    Map<String, dynamic>? parameters,
    dynamic data,
    RequestOptionsModel requestOptions = const RequestOptionsModel(),
    String? methodOverride,
  }) async {
    /// Prepare Header
    Map<String, dynamic> headers = await DioHndlerHelper.prepareHeaders(
      hasBearerToken: requestOptions.hasBearerToken,
      additionalHeaders: requestOptions.headers ?? {},
    );

    /// Provideded Uri
    final endpointPath = DioHndlerHelper.endpointPath(endpoint);

    /// Provided Options With Extra
    final dioOptions = requestOptions.toDioOptions(method: methodOverride);
    dioOptions.headers = {...dioOptions.headers ?? {}, ...headers};

    final curlCommand = DioHndlerHelper.curlCommand(
      methodOverride: methodOverride!,
      baseUrl: DioFlowConfig.instance.baseUrl,
      endpointPath: endpointPath,
      data: data,
      parameters: parameters,
      headers: headers,
    );

    DioFlowLog(
      type: DioLogType.request,
      url: DioFlowConfig.instance.baseUrl + endpointPath,
      method: dioOptions.method,
      data: data,
      headers: Map<String, dynamic>.from(dioOptions.headers ?? {}),
      parameters: parameters,
      extra: dioOptions.extra,
      logCurl: curlCommand,
    ).log();

    try {
      Response response;
      final method = (methodOverride).toUpperCase();

      switch (method) {
        case HttpMethods.get:
          response = await ApiClient.refreshDio.get(
            endpointPath,
            queryParameters: parameters,
            options: dioOptions,
          );
          break;
        case HttpMethods.post:
          response = await ApiClient.refreshDio.post(
            endpointPath,
            queryParameters: parameters,
            data: data,
            options: dioOptions,
          );
          break;

        default:
          throw Exception('Unsupported HTTP method: ${dioOptions.method}');
      }

      // --- normalize response data ---
      Map<String, dynamic> responseData;
      if (response.data is Map<String, dynamic>) {
        responseData = Map<String, dynamic>.from(response.data);
      } else if (response.data is List) {
        responseData = {'data': response.data, 'status': response.statusCode};
      } else if (response.data is String &&
          (response.data as String).isNotEmpty) {
        try {
          responseData = Map<String, dynamic>.from(jsonDecode(response.data));
        } catch (_) {
          responseData = {'data': response.data, 'status': response.statusCode};
        }
      } else if (response.data == null) {
        responseData = {'status': response.statusCode, 'message': 'Success'};
      } else {
        responseData = {'data': response.data, 'status': response.statusCode};
      }

      // responseData['extra'] = dioOptions.extra ?? {};

      if (!responseData.containsKey('status') &&
          !responseData.containsKey('statusCode')) {
        responseData['status'] = response.statusCode;
      }

      // headers
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
      final String logCurl = curlCommand;

      if (statusCode >= 200 && statusCode < 300) {
        return SuccessResponseModel.fromJson(
          responseData,
          endpointPath: endpointPath,
          logCurl: logCurl,
          fromCache: false,
          isRefreshHandle: true,
        );
      } else {
        return FailedResponseModel.fromJson(
          responseData,
          endpointPath: endpointPath,
          logCurl: logCurl,
          fromCache: false,
          isRefreshHandle: true,
        );
      }
    } on DioException catch (error) {
      ErrorType errorType;
      if (error.requestOptions.extra['errorType'] == 'preparation_error') {
        errorType = ErrorType.validation;
      } else if (error.response != null) {
        errorType = ErrorType.fromStatusCode(error.response!.statusCode ?? 500);
      } else {
        errorType = ErrorType.fromDioErrorType(error.type);
      }

      // prepare errorResponseData safely (guard for nulls)
      Map<String, dynamic> errorResponseData;
      if (error.response?.data is Map<String, dynamic>) {
        errorResponseData = Map<String, dynamic>.from(error.response!.data);
      } else if (error.response?.data is List) {
        errorResponseData = {
          'data': error.response!.data,
          'status': error.response!.statusCode,
        };
      } else if (error.response?.data is String &&
          (error.response!.data as String).isNotEmpty) {
        try {
          errorResponseData = Map<String, dynamic>.from(
            jsonDecode(error.response!.data),
          );
        } catch (_) {
          errorResponseData = {
            'data': error.response!.data,
            'status': error.response!.statusCode,
          };
        }
      } else {
        errorResponseData = {
          'errorType': errorType.userFriendlyMessage,
          'message': error.message ?? 'Request failed',
        };
      }

      if (!errorResponseData.containsKey('status') &&
          !errorResponseData.containsKey('statusCode')) {
        errorResponseData['status'] = error.response?.statusCode ?? 500;
      }

      // Add relevant headers only if present
      if (error.response?.headers != null &&
          error.response!.headers.map.isNotEmpty) {
        final relevantHeaders = <String, dynamic>{};
        for (final h in [
          'content-type',
          'authorization',
          'x-total-count',
          'x-pagination-total',
          'x-total-pages',
        ]) {
          if (error.response!.headers.map.containsKey(h)) {
            relevantHeaders[h] = error.response!.headers.value(h);
          }
        }
        if (relevantHeaders.isNotEmpty) {
          errorResponseData['headers'] = relevantHeaders;
        }
      }

      return FailedResponseModel.fromJson(
        errorResponseData,
        endpointPath: endpointPath,
        logCurl: '',
        isRefreshHandle: true,
      );
    }
  }

  static Future<ResponseModel> get(
    dynamic endpoint, {
    Map<String, dynamic>? parameters,
    dynamic data,
    RequestOptionsModel requestOptions = const RequestOptionsModel(),
  }) async {
    return _executeRequestForRefreshToken(
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
    return _executeRequestForRefreshToken(
      endpoint,
      parameters: parameters,
      data: data,
      requestOptions: requestOptions,
      methodOverride: HttpMethods.post,
    );
  }
}
