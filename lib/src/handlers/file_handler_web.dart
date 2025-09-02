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

/// Web implementation of FileHandler for web platform.
class FileHandlerImpl {
  /// Uploads a single file to the specified endpoint.
  /// Note: On web, File objects are not available. Use uploadBytes instead.
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
    return FailedResponseModel(
      statusCode: 500,
      message:
          'File upload from File object is not supported on web. Use uploadBytes instead.',
      logCurl: 'WEB FILE UPLOAD ERROR',
      errorType: ErrorType.unknown,
      error: UnsupportedError('File upload not supported on web'),
    );
  }

  /// Downloads a file from the specified endpoint.
  /// Note: On web, files cannot be saved directly to disk. Use downloadBytes instead.
  static Future<ResponseModel> downloadFile(
    dynamic endpoint,
    String savePath, {
    Map<String, dynamic>? parameters,
    RequestOptionsModel requestOptions = const RequestOptionsModel(
      hasBearerToken: true,
    ),
    ProgressCallback? onProgress,
  }) async {
    return FailedResponseModel(
      statusCode: 500,
      message:
          'File download to disk is not supported on web. Use downloadBytes instead.',
      logCurl: 'WEB FILE DOWNLOAD ERROR',
      errorType: ErrorType.unknown,
      error: UnsupportedError('File download to disk not supported on web'),
    );
  }
}
