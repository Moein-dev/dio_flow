import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:dio_flow/dio_flow.dart';
import 'package:dio_flow/src/handlers/dio_hndler_helper.dart';
import 'package:dio_flow/src/handlers/file_value_adapter_stub.dart'
    if (dart.library.io) 'package:dio_flow/src/handlers/file_value_adapter_io.dart';
import 'package:flutter/foundation.dart';

/// Callback function for tracking upload/download progress.
///
/// Parameters:
///   sent - Number of bytes sent/received so far
///   total - Total number of bytes to send/receive
typedef ProgressCallback = void Function(int sent, int total);

/// Information about file upload/download progress.
class FileProgress {
  final int sent;
  final int total;
  final double percentage;

  FileProgress(this.sent, this.total)
    : percentage = total > 0 ? (sent / total) * 100 : 0;

  @override
  String toString() => '${percentage.toStringAsFixed(1)}% ($sent/$total bytes)';
}

/// Handler for file upload and download operations using DioFlow.
///
/// This class provides convenient methods for uploading and downloading files
/// while leveraging all DioFlow features like authentication, retry logic, etc.
class FileHandler {
  /// Private constructor to prevent instantiation.
  FileHandler._();

  // ───────────────────────────────────────────────────────────────────────────
  //  Upload methods
  // ───────────────────────────────────────────────────────────────────────────

  /// Uploads multiple files to the specified endpoint.
  ///
  /// Parameters:
  ///   endpoint       - The API endpoint for file upload
  ///   files          - Map of fieldName -> File/Uint8List
  ///   methodTypes    - HTTP method (usually POST/PUT/PATCH)
  ///   additionalData - Additional form data to send with the files
  ///   requestOptions - Request configuration options
  ///   onProgress     - Callback for tracking upload progress
  ///
  /// Returns:
  ///   A ResponseModel containing the upload result
  ///
  /// Note: For web, pass Uint8List values instead of File.
  static Future<ResponseModel> uploadFile<T>(
    dynamic endpoint,
    Map<String, T> files,
    UploadMethodsEnum methodTypes, {
    Map<String, dynamic>? additionalData,
    RequestOptionsModel requestOptions = const RequestOptionsModel(),
    ProgressCallback? onProgress,
    Map<String, dynamic>? parameters,
    Map<String, dynamic>? pathParameters,
    CancelToken? cancelToken,
  }) async {
    try {
      final formData = FormData();
      var payloadLength = 0;
      var progressEmitted = false;

      for (final entry in files.entries) {
        if (entry.value is Uint8List) {
          // Handle bytes (web-compatible)
          final multipartFile = MultipartFile.fromBytes(
            entry.value as Uint8List,
            filename: entry.key,
          );
          formData.files.add(MapEntry(entry.key, multipartFile));
          payloadLength += multipartFile.length;
        } else {
          final multipartFile = await multipartFileFromValue(
            entry.value,
            fieldName: entry.key,
          );
          if (multipartFile == null) {
            return FailedResponseModel(
              statusCode: 500,
              message: 'Format Not Supported',
              logCurl: 'Format Not Supported',
              errorType: ErrorType.unknown,
            );
          }
          formData.files.add(MapEntry(entry.key, multipartFile));
          payloadLength += multipartFile.length;
        }
      }

      if (additionalData != null) {
        additionalData.forEach((key, value) {
          final stringValue = value.toString();
          formData.fields.add(MapEntry(key, stringValue));
          payloadLength += utf8.encode(stringValue).length;
        });
      }

      final response = await _sendRequestWithMethod(
        methodTypes,
        endpoint,
        data: formData,
        parameters: parameters,
        pathParameters: pathParameters,
        cancelToken: cancelToken,
        requestOptions:
            onProgress == null
                ? requestOptions
                : requestOptions.copyWith(
                  userExtra: {
                    ...?requestOptions.customExtra,
                    DioHndlerHelper.uploadProgressExtraKey: (
                      int sent,
                      int total,
                    ) {
                      progressEmitted = true;
                      onProgress(sent, total);
                    },
                  },
                ),
      );
      if (onProgress != null && !progressEmitted && response.isSuccess) {
        onProgress(payloadLength, payloadLength);
      }
      return response;
    } catch (e) {
      return FailedResponseModel(
        statusCode: 500,
        message: 'Multiple file upload failed: $e',
        logCurl: 'MULTIPLE FILE UPLOAD ERROR',
        errorType: ErrorType.unknown,
        error: e,
      );
    }
  }

  // ───────────────────────────────────────────────────────────────────────────
  //  File info (HEAD-like)
  // ───────────────────────────────────────────────────────────────────────────

  /// Gets file information without downloading the entire file.
  ///
  /// This method typically uses a lightweight request (like HEAD) on server side
  /// but here we simply delegate to the standard GET wrapper. The backend is
  /// expected to respond with metadata (size, content-type, etc.)
  ///
  /// Parameters:
  ///   endpoint       - The API endpoint for the file
  ///   parameters     - Optional query parameters
  ///   requestOptions - Request configuration options
  ///
  /// Returns:
  ///   A ResponseModel containing file information
  static Future<ResponseModel> getFileInfo(
    dynamic endpoint, {
    Map<String, dynamic>? parameters,
    RequestOptionsModel requestOptions = const RequestOptionsModel(),
    Map<String, dynamic>? pathParameters,
    CancelToken? cancelToken,
  }) async {
    try {
      return await DioRequestHandler.get(
        endpoint,
        pathParameters: pathParameters,
        parameters: parameters,
        cancelToken: cancelToken,
        requestOptions: requestOptions,
      );
    } catch (e) {
      return FailedResponseModel(
        statusCode: 500,
        message: 'Failed to get file info: $e',
        logCurl: 'FILE INFO ERROR',
        errorType: ErrorType.unknown,
        error: e,
      );
    }
  }

  // ───────────────────────────────────────────────────────────────────────────
  //  Download methods
  // ───────────────────────────────────────────────────────────────────────────

  /// Downloads a file as raw bytes (memory).
  /// Example:
  /// ```dart
  /// final response = await FileHandler.downloadBytes(
  ///   'files/123',
  ///   UploadMethodsEnum.post,
  ///   requestOptions: RequestOptionsModel(
  ///     responseType: ResponseType.bytes,
  ///   ),
  /// );
  ///
  /// if (response is SuccessResponseModel) {
  ///   final bytes = response.data as Uint8List;
  ///   // use bytes...
  /// }
  /// ```
  static Future<ResponseModel> downloadBytes(
    dynamic endpoint,
    UploadMethodsEnum methodTypes, {
    Map<String, dynamic>? parameters,
    Map<String, dynamic>? pathParameters,
    RequestOptionsModel requestOptions = const RequestOptionsModel(
      responseType: ResponseType.bytes,
    ),
    CancelToken? cancelToken,
  }) async {
    try {
      return await _sendRequestWithMethod(
        methodTypes,
        endpoint,
        parameters: parameters,
        pathParameters: pathParameters,
        cancelToken: cancelToken,
        requestOptions: requestOptions,
      );
    } catch (e) {
      return FailedResponseModel(
        statusCode: 500,
        message: 'File download (bytes) failed: $e',
        logCurl: 'FILE DOWNLOAD BYTES ERROR',
        errorType: ErrorType.unknown,
        error: e,
      );
    }
  }

  /// Downloads a text-based file (e.g. CSV, plain-text, logs).
  /// Example:
  /// ```dart
  /// final response = await FileHandler.downloadText(
  ///   'logs/today',
  ///   UploadMethodsEnum.post,
  ///   requestOptions: RequestOptionsModel(
  ///     responseType: ResponseType.plain,
  ///   ),
  /// );
  ///
  /// if (response is SuccessResponseModel) {
  ///   final text = response.data as String;
  ///   // Process the downloaded text.
  /// }
  /// ```
  static Future<ResponseModel> downloadText(
    dynamic endpoint,
    UploadMethodsEnum methodTypes, {
    Map<String, dynamic>? parameters,
    Map<String, dynamic>? pathParameters,
    RequestOptionsModel requestOptions = const RequestOptionsModel(
      responseType: ResponseType.plain,
    ),
    CancelToken? cancelToken,
  }) async {
    try {
      return await _sendRequestWithMethod(
        methodTypes,
        endpoint,
        parameters: parameters,
        pathParameters: pathParameters,
        cancelToken: cancelToken,
        requestOptions: requestOptions,
      );
    } catch (e) {
      return FailedResponseModel(
        statusCode: 500,
        message: 'File download (text) failed: $e',
        logCurl: 'FILE DOWNLOAD TEXT ERROR',
        errorType: ErrorType.unknown,
        error: e,
      );
    }
  }

  /// Downloads a file and (optionally) lets you handle the bytes to save to disk.
  /// Example:
  /// ```dart
  /// final file = File('/path/to/save.pdf');
  /// final response = await FileHandler.downloadAndHandle(
  ///   'files/report',
  ///   UploadMethodsEnum.post,
  ///   requestOptions: RequestOptionsModel(
  ///     responseType: ResponseType.bytes,
  ///   ),
  ///   onBytes: (bytes) async {
  ///     await file.writeAsBytes(bytes);
  ///   },
  /// );
  /// ```
  static Future<ResponseModel> downloadAndHandle(
    dynamic endpoint,
    UploadMethodsEnum methodTypes, {
    Map<String, dynamic>? parameters,
    Map<String, dynamic>? pathParameters,
    RequestOptionsModel requestOptions = const RequestOptionsModel(
      responseType: ResponseType.bytes,
    ),
    CancelToken? cancelToken,
    Future<void> Function(Uint8List bytes)? onBytes,
  }) async {
    try {
      final response = await downloadBytes(
        endpoint,
        methodTypes,
        parameters: parameters,
        pathParameters: pathParameters,
        requestOptions: requestOptions,
        cancelToken: cancelToken,
      );

      if (onBytes != null &&
          response is SuccessResponseModel &&
          response.data is Uint8List) {
        await onBytes(response.data as Uint8List);
      }

      return response;
    } catch (e) {
      return FailedResponseModel(
        statusCode: 500,
        message: 'File download & handle failed: $e',
        logCurl: 'FILE DOWNLOAD HANDLE ERROR',
        errorType: ErrorType.unknown,
        error: e,
      );
    }
  }

  // ───────────────────────────────────────────────────────────────────────────
  //  Shared internal request helper
  // ───────────────────────────────────────────────────────────────────────────

  /// Shared internal helper for choosing the HTTP method once.
  static Future<ResponseModel> _sendRequestWithMethod(
    UploadMethodsEnum methodTypes,
    dynamic endpoint, {
    Map<String, dynamic>? parameters,
    Map<String, dynamic>? pathParameters,
    CancelToken? cancelToken,
    dynamic data,
    RequestOptionsModel requestOptions = const RequestOptionsModel(),
  }) {
    switch (methodTypes) {
      case UploadMethodsEnum.get:
        return DioRequestHandler.get(
          endpoint,
          pathParameters: pathParameters,
          parameters: parameters,
          cancelToken: cancelToken,
          requestOptions: requestOptions,
        );
      case UploadMethodsEnum.post:
        return DioRequestHandler.post(
          endpoint,
          pathParameters: pathParameters,
          parameters: parameters,
          cancelToken: cancelToken,
          data: data,
          requestOptions: requestOptions,
        );
      case UploadMethodsEnum.put:
        return DioRequestHandler.put(
          endpoint,
          pathParameters: pathParameters,
          parameters: parameters,
          cancelToken: cancelToken,
          data: data,
          requestOptions: requestOptions,
        );
      case UploadMethodsEnum.patch:
        return DioRequestHandler.patch(
          endpoint,
          pathParameters: pathParameters,
          parameters: parameters,
          cancelToken: cancelToken,
          data: data,
          requestOptions: requestOptions,
        );
    }
  }
}
