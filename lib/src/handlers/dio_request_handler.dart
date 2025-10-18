import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:dio_flow/dio_flow.dart';
import 'package:dio_flow/src/handlers/dio_flow_log.dart';
import 'package:dio_flow/src/handlers/dio_hndler_helper.dart';

class DioRequestHandler {
  DioRequestHandler._();

  static Future<ResponseModel> _executeRequest(
    dynamic endpoint, {
    Map<String, dynamic>? parameters,
    Map<String, dynamic>? pathParameters,
    dynamic data,
    required RequestOptionsModel requestOptions,
    String? methodOverride,
    CancelToken? cancelToken,
  }) async {
    // Handle Mock Data Process
    if (MockDioFlow.isMockEnabled) {
      return DioHndlerHelper.handleMockRequest(
        endpoint,
        methodOverride ?? HttpMethods.get,
      );
    }

    final CancelToken internalCancelToken = cancelToken ?? CancelToken();

    // Prepare Header
    Map<String, dynamic> headers = await DioHndlerHelper.prepareHeaders(
      hasBearerToken: requestOptions.hasBearerToken,
      additionalHeaders: requestOptions.customHeaders ?? {},
      isdataFile: data is FormData ? true : false,
    );

    // Provideded Uri template (may contain placeholders)
    final endpointTemplate = DioHndlerHelper.endpointPath(endpoint);

    // Resolve pathParameters into template -> endpointPath
    final endpointPath = DioHndlerHelper.resolvePath(
      endpointTemplate,
      pathParameters,
    );

    // Provided Options With Extra
    final dioOptions = requestOptions.toDioOptions(method: methodOverride);
    dioOptions.headers = {...dioOptions.headers ?? {}, ...headers};

    // prepare extra
    final Map<String, dynamic> baseExtra = {
      ...(dioOptions.extra ?? {}),
      'isRetry': dioOptions.extra?['isRetry'] ?? false,
      'retryCount': dioOptions.extra?['retryCount'] ?? 0,
      'isTokenRefreshed': false,
    };

    var newOptions = dioOptions.copyWith(extra: baseExtra);

    /// Create initial log curl
    final firstCurl = DioHndlerHelper.curlCommand(
      methodOverride: methodOverride!,
      baseUrl: DioFlowConfig.instance.baseUrl + endpointPath,
      endpointPath: endpointPath,
      data: data,
      parameters: parameters,
      headers: headers,
    );

    final int maxAttempts = requestOptions.retryOptions.maxAttempts;
    final Duration interval = requestOptions.retryOptions.retryInterval;

    /// start loop
    for (int attempt = 0; attempt < maxAttempts; attempt++) {
      final bool isLastAttempt = attempt == maxAttempts - 1;
      final bool firstAttempts = attempt == 0;

      final Map<String, dynamic> thisOptionExtra = {
        ...(newOptions.extra ?? {}),
        'isRetry': attempt > 0,
        'retryCount': firstAttempts ? 0 : attempt,
      };
      var optionsThisAttempt = newOptions.copyWith(extra: thisOptionExtra);

      /// Create log curl and Console Log for Request
      final curlCommand = DioHndlerHelper.curlCommand(
        methodOverride: methodOverride,
        baseUrl: DioFlowConfig.instance.baseUrl,
        endpointPath: endpointPath,
        data: data,
        parameters: parameters,
        headers: headers,
      );
      final bool cacheLoad = requestOptions.cacheOptions.shouldCache;
      if (firstAttempts) {
        DioFlowLog(
          type: DioLogType.request,
          url: DioFlowConfig.instance.baseUrl + endpointPath,
          method: newOptions.method,
          data: data,
          headers: Map<String, dynamic>.from(newOptions.headers ?? {}),
          parameters: parameters,
          extra: optionsThisAttempt.extra,
          logCurl: curlCommand,
          isCache: cacheLoad,
        ).log();
      }

      /// Start the application process from DIO
      try {
        Response response;
        final method = (methodOverride).toUpperCase();

        switch (method) {
          case HttpMethods.get:
            response = await ApiClient.dio.get(
              endpointPath,
              queryParameters: parameters,
              options: optionsThisAttempt,
              cancelToken: internalCancelToken,
            );
            break;
          case HttpMethods.post:
            response = await ApiClient.dio.post(
              endpointPath,
              queryParameters: parameters,
              data: data,
              options: optionsThisAttempt,
              cancelToken: internalCancelToken,
            );
            break;
          case HttpMethods.put:
            response = await ApiClient.dio.put(
              endpointPath,
              queryParameters: parameters,
              data: data,
              options: optionsThisAttempt,
              cancelToken: internalCancelToken,
            );
            break;
          case HttpMethods.patch:
            response = await ApiClient.dio.patch(
              endpointPath,
              queryParameters: parameters,
              data: data,
              options: optionsThisAttempt,
              cancelToken: internalCancelToken,
            );
            break;
          case HttpMethods.delete:
            response = await ApiClient.dio.delete(
              endpointPath,
              queryParameters: parameters,
              options: optionsThisAttempt,
              cancelToken: internalCancelToken,
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
            responseData = {
              'data': response.data,
              'status': response.statusCode,
            };
          }
        } else if (response.data == null) {
          responseData = {'status': response.statusCode, 'message': 'Success'};
        } else {
          responseData = {'data': response.data, 'status': response.statusCode};
        }

        responseData['extra'] = optionsThisAttempt.extra ?? {};

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
        final fromCache = response.extra['fromCache'] ?? false;

        /// Create log curl and Console Log for Response
        final responseCurlCommand = DioHndlerHelper.curlCommand(
          methodOverride: methodOverride,
          baseUrl: DioFlowConfig.instance.baseUrl,
          endpointPath: endpointPath,
          data: data,
          parameters: parameters,
          headers: headers,
        );

        /// 401 handle
        if (statusCode == 401 &&
            (optionsThisAttempt.extra?['isTokenRefreshed'] ?? false) != true && requestOptions.hasBearerToken) {
          try {
            await TokenManager.refreshAccessToken();
          } catch (_) {}

          final newToken = await TokenManager.getAccessToken();

          if (newToken != null && newToken.isNotEmpty) {
            newOptions = newOptions.copyWith(
              headers: {
                ...?optionsThisAttempt.headers,
                'Authorization': 'Bearer $newToken',
              },
              extra: {...?optionsThisAttempt.extra, 'isTokenRefreshed': true},
            );

            attempt = -1;
            continue;
          } else {
            return FailedResponseModel.fromJson(
              responseData,
              endpointPath: endpointPath,
              logCurl: responseCurlCommand,
              fromCache: fromCache,
            );
          }
        }

        /// return
        if (statusCode >= 200 && statusCode < 300) {
          return SuccessResponseModel.fromJson(
            responseData,
            endpointPath: endpointPath,
            logCurl: responseCurlCommand,
            fromCache: fromCache,
          );
        } else {
          if (!isLastAttempt &&
              DioHndlerHelper.shouldRetry(
                requestOptions.retryOptions,
                statusCode,
                null,
              )) {
            /// Create Console Log For this Atetempts
            if (!firstAttempts) {
              DioFlowLog(
                type: DioLogType.retry,
                url: DioFlowConfig.instance.baseUrl + endpointPath,
                method: newOptions.method,
                headers: Map<String, dynamic>.from(newOptions.headers ?? {}),
                parameters: parameters,
                extra: optionsThisAttempt.extra,
                logCurl: curlCommand,
                retryCount: attempt,
                maxAttempts: maxAttempts,
                statusCode: statusCode,
                message: response.statusMessage,
              ).log();
            }
            await Future.delayed(interval);
            continue;
          } else {
            return FailedResponseModel.fromJson(
              responseData,
              endpointPath: endpointPath,
              logCurl: responseCurlCommand,
              fromCache: fromCache,
            );
          }
        }
      } on DioException catch (error) {
        // determine user-friendly error type (if you need it)
        ErrorType errorType;
        if (error.requestOptions.extra['errorType'] == 'preparation_error') {
          errorType = ErrorType.validation;
        } else if (error.response != null) {
          errorType = ErrorType.fromStatusCode(
            error.response!.statusCode ?? 500,
          );
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

        errorResponseData['extra'] = optionsThisAttempt.extra ?? {};

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

        /// Create log curl and Console Log for Exeptions
        final exeptionCurlCommand = DioHndlerHelper.curlCommand(
          methodOverride: methodOverride,
          baseUrl: DioFlowConfig.instance.baseUrl,
          endpointPath: endpointPath,
          data: data,
          parameters: parameters,
          headers: headers,
        );

        // if cancell request
        if (error.type == DioExceptionType.cancel) {
          return FailedResponseModel.fromJson(
            {'status': 499, 'message': 'Request cancelled by user'},
            endpointPath: endpointPath,
            logCurl: exeptionCurlCommand,
          );
        }

        if (!isLastAttempt && DioHndlerHelper.shouldRetry(null, null, error)) {
          /// Create Console Log For this Atetempts
          DioFlowLog(
            type: DioLogType.retry,
            url: DioFlowConfig.instance.baseUrl + endpointPath,
            method: newOptions.method,
            data: data,
            headers: Map<String, dynamic>.from(newOptions.headers ?? {}),
            parameters: parameters,
            extra: optionsThisAttempt.extra,
            logCurl: curlCommand,
            isCache: cacheLoad,
            retryCount: attempt,
            maxAttempts: maxAttempts,
          ).log();
          await Future.delayed(interval);
          continue; // retry
        } else {
          return FailedResponseModel.fromJson(
            errorResponseData,
            endpointPath: endpointPath,
            logCurl: exeptionCurlCommand,
          );
        }
      } // end catch
    } // end for

    return FailedResponseModel.fromJson(
      {'status': 500, 'message': 'Request aborted after retries'},
      endpointPath: endpointPath,
      logCurl: firstCurl,
    );
  }

  static Future<ResponseModel> get(
    dynamic endpoint, {
    Map<String, dynamic>? parameters,
    Map<String, dynamic>? pathParameters,
    dynamic data,
    RequestOptionsModel requestOptions = const RequestOptionsModel(),
    CancelToken? cancelToken,
  }) async {
    return _executeRequest(
      endpoint,
      parameters: parameters,
      pathParameters: pathParameters,
      data: data,
      requestOptions: requestOptions,
      methodOverride: HttpMethods.get,
      cancelToken: cancelToken,
    );
  }

  static Future<ResponseModel> post(
    dynamic endpoint, {
    Map<String, dynamic>? parameters,
    Map<String, dynamic>? pathParameters,
    dynamic data,
    RequestOptionsModel requestOptions = const RequestOptionsModel(),
    CancelToken? cancelToken,
  }) async {
    return _executeRequest(
      endpoint,
      parameters: parameters,
      pathParameters: pathParameters,
      data: data,
      requestOptions: requestOptions,
      methodOverride: HttpMethods.post,
      cancelToken: cancelToken,
    );
  }

  static Future<ResponseModel> put(
    dynamic endpoint, {
    Map<String, dynamic>? parameters,
    Map<String, dynamic>? pathParameters,
    dynamic data,
    RequestOptionsModel requestOptions = const RequestOptionsModel(),
    CancelToken? cancelToken,
  }) async {
    return _executeRequest(
      endpoint,
      parameters: parameters,
      pathParameters: pathParameters,
      data: data,
      requestOptions: requestOptions,
      methodOverride: HttpMethods.put,
      cancelToken: cancelToken,
    );
  }

  static Future<ResponseModel> patch(
    dynamic endpoint, {
    Map<String, dynamic>? parameters,
    Map<String, dynamic>? pathParameters,
    dynamic data,
    RequestOptionsModel requestOptions = const RequestOptionsModel(),
    CancelToken? cancelToken,
  }) async {
    return _executeRequest(
      endpoint,
      parameters: parameters,
      pathParameters: pathParameters,
      data: data,
      requestOptions: requestOptions,
      methodOverride: HttpMethods.patch,
      cancelToken: cancelToken,
    );
  }

  static Future<ResponseModel> delete(
    dynamic endpoint, {
    Map<String, dynamic>? parameters,
    Map<String, dynamic>? pathParameters,
    RequestOptionsModel requestOptions = const RequestOptionsModel(),
    CancelToken? cancelToken,
  }) async {
    return _executeRequest(
      endpoint,
      parameters: parameters,
      pathParameters: pathParameters,
      requestOptions: requestOptions,
      methodOverride: HttpMethods.delete,
      cancelToken: cancelToken,
    );
  }
}
