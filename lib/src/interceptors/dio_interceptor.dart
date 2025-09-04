import 'dart:developer';
import 'package:dio/dio.dart';
import 'package:dio_flow/src/config/dio_flow_config.dart';
import 'package:dio_flow/src/utils/token_manager.dart';
import 'package:flutter/foundation.dart';
import 'package:log_curl_request/log_curl_request.dart';

class DioInterceptor extends Interceptor {
  final Dio dio;

  DioInterceptor()
    : dio = Dio(
        BaseOptions(
          baseUrl: DioFlowConfig.instance.baseUrl,
          connectTimeout: DioFlowConfig.instance.connectTimeout,
          receiveTimeout: DioFlowConfig.instance.receiveTimeout,
          sendTimeout: DioFlowConfig.instance.sendTimeout,
          validateStatus: (status) => true,
        ),
      );

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    try {
      options.headers.putIfAbsent("Content-Type", () => "application/json");
      options.headers.putIfAbsent("Accept", () => "application/json");

      if (kDebugMode) {
        LogCurlRequest.create(
          options.method,
          options.uri.toString(),
          parameters: options.queryParameters,
          data: options.data,
          headers: options.headers,
        );
      }
      handler.next(options);
    } catch (error) {
      String errorMessage = 'Request preparation failed';
      if (error is Exception) {
        errorMessage = error.toString();
      }
      final Map<String, dynamic> extra = {
        ...options.extra,
        'errorType': 'preparation_error',
      };
      handler.reject(
        DioException(
          requestOptions: options.copyWith(extra: extra),
          error: error,
          message: errorMessage,
          type: DioExceptionType.unknown,
        ),
      );
    }
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    try {
      if (kDebugMode) {
        if (response.requestOptions.extra.containsKey('log_curl')) {
          response.extra['log_curl'] =
              response.requestOptions.extra['log_curl'];
        }
      }
    } catch (_) {}
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final requestOptions = err.requestOptions;

    String cUrl = requestOptions.extra['log_curl'] ?? '';
    if (cUrl.isNotEmpty && kDebugMode) {
      if (err.response != null) {
        err.response!.extra = {...err.response!.extra, 'log_curl': cUrl};
      }
    }

    final isRetry = requestOptions.extra['isRetry'] == true;
    if (err.response?.statusCode == 401 && !isRetry) {
      try {
        await TokenManager.refreshAccessToken();
        final newToken = await TokenManager.getAccessToken();
        if (newToken != null) {
          final newOptions = requestOptions.copyWith(
            extra: {...requestOptions.extra, 'isRetry': true, 'log_curl': cUrl},
          );
          newOptions.headers["Authorization"] = "Bearer $newToken";
          final retriedResponse = await dio.fetch(newOptions);
          retriedResponse.extra = {...retriedResponse.extra, 'log_curl': cUrl};
          handler.resolve(retriedResponse);
          return;
        }
      } catch (_) {
        await TokenManager.clearTokens();
      }
    }

    handler.next(
      err.copyWith(
        requestOptions: requestOptions.copyWith(
          extra: {...requestOptions.extra, 'log_curl': cUrl},
        ),
      ),
    );
  }
}
