import 'dart:io';
import 'package:dio/dio.dart';
import 'package:dio_flow/src/handlers/dio_request_handler.dart';
import 'package:dio_flow/src/models/request_options_model.dart';
import 'package:dio_flow/src/models/response/response_model.dart';
import 'package:dio_flow/src/models/response/error_type.dart';

/// Callback function for tracking upload/download progress.
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

/// IO implementation of FileHandler for mobile and desktop platforms.
class FileHandlerImpl {
  /// Uploads a single file to the specified endpoint.
  static Future<ResponseModel> uploadFile(
    dynamic endpoint,
    dynamic file, {
    String fieldName = 'file',
    Map<String, dynamic>? additionalData,
    RequestOptionsModel requestOptions = const RequestOptionsModel(
      hasBearerToken: true,
    ),
    ProgressCallback? onProgress,
  }) async {
    try {
      if (file == null || file is! File) {
        return FailedResponseModel(
          statusCode: 400,
          message: 'Invalid file provided',
          logCurl: 'FILE UPLOAD ERROR',
          errorType: ErrorType.unknown,
          error: ArgumentError('File cannot be null and must be a File object'),
        );
      }

      final multipartFile = await MultipartFile.fromFile(
        file.path,
        filename: file.path.split('/').last,
      );

      final formData = FormData();
      formData.files.add(MapEntry(fieldName, multipartFile));

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
        message: 'File upload failed: $e',
        logCurl: 'FILE UPLOAD ERROR',
        errorType: ErrorType.unknown,
        error: e,
      );
    }
  }

  /// Downloads a file from the specified endpoint.
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
      if (savePath.isEmpty) {
        return FailedResponseModel(
          statusCode: 400,
          message: 'Save path cannot be empty',
          logCurl: 'FILE DOWNLOAD ERROR',
          errorType: ErrorType.unknown,
          error: ArgumentError('Save path is required'),
        );
      }

      final options = requestOptions.copyWith(responseType: ResponseType.bytes);

      final response = await DioRequestHandler.get(
        endpoint,
        parameters: parameters,
        requestOptions: options,
      );

      if (response.isSuccess) {
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
}
