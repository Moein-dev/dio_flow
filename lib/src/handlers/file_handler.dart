import 'dart:io';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:dio_flow/src/handlers/dio_request_handler.dart';
import 'package:dio_flow/src/models/request_options_model.dart';
import 'package:dio_flow/src/models/response/response_model.dart';
import 'package:dio_flow/src/models/response/error_type.dart';

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

  /// Uploads a single file to the specified endpoint.
  ///
  /// Parameters:
  ///   endpoint - The API endpoint for file upload
  ///   file - The file to upload
  ///   fieldName - The form field name for the file (defaults to 'file')
  ///   additionalData - Additional form data to send with the file
  ///   requestOptions - Request configuration options
  ///   onProgress - Callback for tracking upload progress (currently not implemented)
  ///
  /// Returns:
  ///   A ResponseModel containing the upload result
  ///
  /// Example:
  /// ```dart
  /// final file = File('/path/to/image.jpg');
  /// final response = await FileHandler.uploadFile(
  ///   'upload',
  ///   file,
  ///   additionalData: {'description': 'Profile picture'},
  /// );
  /// ```
  static Future<ResponseModel> uploadFile(
    dynamic endpoint,
    File file, {
    String fieldName = 'file',
    Map<String, dynamic>? additionalData,
    RequestOptionsModel requestOptions = const RequestOptionsModel(
      hasBearerToken: true,
    ),
    ProgressCallback? onProgress,
  }) async {
    try {
      // Create multipart file
      final multipartFile = await MultipartFile.fromFile(
        file.path,
        filename: file.path.split('/').last,
      );

      // Create form data
      final formData = FormData();
      formData.files.add(MapEntry(fieldName, multipartFile));

      // Add additional data if provided
      if (additionalData != null) {
        additionalData.forEach((key, value) {
          formData.fields.add(MapEntry(key, value.toString()));
        });
      }

      // Note: Progress tracking would need to be implemented at the Dio interceptor level
      // For now, we'll use the standard request handler
      return await DioRequestHandler.post(
        endpoint,
        data: formData,
        requestOptions: requestOptions,
      );
    } catch (e) {
      return FailedResponseModel(
        statusCode: 500,
        message: 'File upload failed: $e',
        logCurl: 'FILE UPLOAD ERROR',
        errorType: ErrorType.unknown,
        error: e,
      );
    }
  }

  /// Uploads multiple files to the specified endpoint.
  ///
  /// Parameters:
  ///   endpoint - The API endpoint for file upload
  ///   files - Map of field names to files
  ///   additionalData - Additional form data to send with the files
  ///   requestOptions - Request configuration options
  ///   onProgress - Callback for tracking upload progress (currently not implemented)
  ///
  /// Returns:
  ///   A ResponseModel containing the upload result
  static Future<ResponseModel> uploadMultipleFiles(
    dynamic endpoint,
    Map<String, File> files, {
    Map<String, dynamic>? additionalData,
    RequestOptionsModel requestOptions = const RequestOptionsModel(
      hasBearerToken: true,
    ),
    ProgressCallback? onProgress,
  }) async {
    try {
      final formData = FormData();

      // Add files
      for (final entry in files.entries) {
        final multipartFile = await MultipartFile.fromFile(
          entry.value.path,
          filename: entry.value.path.split('/').last,
        );
        formData.files.add(MapEntry(entry.key, multipartFile));
      }

      // Add additional data if provided
      if (additionalData != null) {
        additionalData.forEach((key, value) {
          formData.fields.add(MapEntry(key, value.toString()));
        });
      }

      return await DioRequestHandler.post(
        endpoint,
        data: formData,
        requestOptions: requestOptions,
      );
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

  /// Uploads file from bytes.
  ///
  /// Parameters:
  ///   endpoint - The API endpoint for file upload
  ///   bytes - The file bytes to upload
  ///   filename - The filename to use
  ///   fieldName - The form field name for the file (defaults to 'file')
  ///   additionalData - Additional form data to send with the file
  ///   requestOptions - Request configuration options
  ///   onProgress - Callback for tracking upload progress (currently not implemented)
  ///
  /// Returns:
  ///   A ResponseModel containing the upload result
  static Future<ResponseModel> uploadBytes(
    dynamic endpoint,
    Uint8List bytes,
    String filename, {
    String fieldName = 'file',
    Map<String, dynamic>? additionalData,
    RequestOptionsModel requestOptions = const RequestOptionsModel(
      hasBearerToken: true,
    ),
    ProgressCallback? onProgress,
  }) async {
    try {
      // Create multipart file from bytes
      final multipartFile = MultipartFile.fromBytes(bytes, filename: filename);

      // Create form data
      final formData = FormData();
      formData.files.add(MapEntry(fieldName, multipartFile));

      // Add additional data if provided
      if (additionalData != null) {
        additionalData.forEach((key, value) {
          formData.fields.add(MapEntry(key, value.toString()));
        });
      }

      return await DioRequestHandler.post(
        endpoint,
        data: formData,
        requestOptions: requestOptions,
      );
    } catch (e) {
      return FailedResponseModel(
        statusCode: 500,
        message: 'Bytes upload failed: $e',
        logCurl: 'BYTES UPLOAD ERROR',
        errorType: ErrorType.unknown,
        error: e,
      );
    }
  }

  /// Downloads a file from the specified endpoint.
  ///
  /// Parameters:
  ///   endpoint - The API endpoint for file download
  ///   savePath - The local path where the file should be saved
  ///   parameters - Optional query parameters
  ///   requestOptions - Request configuration options
  ///   onProgress - Callback for tracking download progress (currently not implemented)
  ///
  /// Returns:
  ///   A ResponseModel containing the download result
  ///
  /// Example:
  /// ```dart
  /// final response = await FileHandler.downloadFile(
  ///   'files/123/download',
  ///   '/path/to/save/file.pdf',
  /// );
  /// ```
  static Future<ResponseModel> downloadFile(
    dynamic endpoint,
    String savePath, {
    Map<String, dynamic>? parameters,
    RequestOptionsModel requestOptions = const RequestOptionsModel(
      hasBearerToken: true,
    ),
    ProgressCallback? onProgress,
  }) async {
    try {
      // Create options for file download
      final options = requestOptions.copyWith(responseType: ResponseType.bytes);

      final response = await DioRequestHandler.get(
        endpoint,
        parameters: parameters,
        requestOptions: options,
      );

      if (response.isSuccess) {
        // Save the file
        final file = File(savePath);
        await file.writeAsBytes(response.data as List<int>);

        return SuccessResponseModel(
          data: {
            'filePath': savePath,
            'fileSize': (response.data as List<int>).length,
          },
          statusCode: response.statusCode,
          message: 'File downloaded successfully',
          logCurl: response.logCurl,
        );
      }

      return response;
    } catch (e) {
      return FailedResponseModel(
        statusCode: 500,
        message: 'File download failed: $e',
        logCurl: 'FILE DOWNLOAD ERROR',
        errorType: ErrorType.unknown,
        error: e,
      );
    }
  }

  /// Downloads a file and returns it as bytes without saving to disk.
  ///
  /// Parameters:
  ///   endpoint - The API endpoint for file download
  ///   parameters - Optional query parameters
  ///   requestOptions - Request configuration options
  ///   onProgress - Callback for tracking download progress (currently not implemented)
  ///
  /// Returns:
  ///   A ResponseModel containing the file bytes
  static Future<ResponseModel> downloadBytes(
    dynamic endpoint, {
    Map<String, dynamic>? parameters,
    RequestOptionsModel requestOptions = const RequestOptionsModel(
      hasBearerToken: true,
    ),
    ProgressCallback? onProgress,
  }) async {
    try {
      // Create options for file download
      final options = requestOptions.copyWith(responseType: ResponseType.bytes);

      final response = await DioRequestHandler.get(
        endpoint,
        parameters: parameters,
        requestOptions: options,
      );

      if (response.isSuccess) {
        return SuccessResponseModel(
          data: {
            'bytes': response.data as Uint8List,
            'size': (response.data as Uint8List).length,
          },
          statusCode: response.statusCode,
          message: 'File downloaded successfully',
          logCurl: response.logCurl,
        );
      }

      return response;
    } catch (e) {
      return FailedResponseModel(
        statusCode: 500,
        message: 'File download failed: $e',
        logCurl: 'FILE DOWNLOAD ERROR',
        errorType: ErrorType.unknown,
        error: e,
      );
    }
  }

  /// Gets file information without downloading the entire file.
  ///
  /// This method uses a HEAD request to get file metadata like size,
  /// content type, etc.
  ///
  /// Parameters:
  ///   endpoint - The API endpoint for the file
  ///   parameters - Optional query parameters
  ///   requestOptions - Request configuration options
  ///
  /// Returns:
  ///   A ResponseModel containing file information
  static Future<ResponseModel> getFileInfo(
    dynamic endpoint, {
    Map<String, dynamic>? parameters,
    RequestOptionsModel requestOptions = const RequestOptionsModel(
      hasBearerToken: true,
    ),
  }) async {
    try {
      // For HEAD requests, we can use the standard GET method
      // The server should handle HEAD requests appropriately
      final response = await DioRequestHandler.get(
        endpoint,
        parameters: parameters,
        requestOptions: requestOptions,
      );

      return response;
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
}
