import 'package:dio_flow/dio_flow.dart';
import 'package:dio_flow/src/handlers/dio_flow_log.dart';
import 'package:dio_flow/src/models/log_model.dart';

part 'success_response_model.dart';
part 'failed_response_model.dart';

/// Abstract class representing a standardized API response in the application.
///
/// This class serves as the base model for all API responses, providing a consistent
/// structure for handling both successful and failed responses.
abstract class ResponseModel {
  /// The data payload returned by the API.
  final dynamic data;

  /// The HTTP status code of the response.
  final int? statusCode;

  /// A message describing the response or error.
  final String? message;

  /// Links for pagination or related resources.
  final LinksModel? links;

  /// Additional metadata associated with the response.
  final MetaModel? meta;

  /// The cURL command used for the request.
  final String logCurl;

  /// Stack trace for error responses.
  final StackTrace? stackTrace;

  /// The error object if the request failed.
  final dynamic error;

  /// The categorized error type.
  final ErrorType? errorType;

  /// HTTP response headers.
  ///
  /// These are transport-layer metadata and are intentionally kept
  /// separate from the main response payload (`data`).
  final Map<String, dynamic>? headers;

  /// Additional internal/request metadata.
  ///
  /// Examples:
  /// - retry info
  /// - cache metadata
  /// - request flags
  final Map<String, dynamic>? extra;

  /// Creates a new ResponseModel instance.
  ResponseModel({
    required this.logCurl,
    this.error,
    this.data,
    this.statusCode,
    this.message,
    this.links,
    this.meta,
    this.stackTrace,
    this.errorType,
    this.headers,
    this.extra,
  });

  /// Factory constructor that creates the appropriate response model.
  factory ResponseModel.fromJson(
    Map<String, dynamic> json, {
    bool forceSuccess = false,
    bool forceFailure = false,
  }) {
    final statusCode =
        json["status"] ?? json["statusCode"] ?? json["code"];

    if (forceSuccess) {
      return SuccessResponseModel.fromJson(json);
    } else if (forceFailure) {
      return FailedResponseModel.fromJson(json);
    }

    if (statusCode == null) {
      final hasErrorIndicators =
          json.containsKey("error") ||
          json.containsKey("errors") ||
          (json.containsKey("message") && !json.containsKey("data"));

      return hasErrorIndicators
          ? FailedResponseModel.fromJson(json)
          : SuccessResponseModel.fromJson(json);
    }

    if (statusCode is int && statusCode >= 200 && statusCode <= 299) {
      return SuccessResponseModel.fromJson(json);
    } else {
      return FailedResponseModel.fromJson(json);
    }
  }

  /// Creates a success response model directly from any data.
  static ResponseModel success({
    required dynamic data,
    int statusCode = 200,
    String logCurl = "",
    Map<String, dynamic>? headers,
    Map<String, dynamic>? extra,
  }) {
    return SuccessResponseModel(
      data: data,
      statusCode: statusCode,
      logCurl: logCurl,
      headers: headers,
      extra: extra,
    );
  }

  /// Creates a failed response model directly from an error.
  static ResponseModel failure({
    required String message,
    int statusCode = 400,
    dynamic error,
    dynamic data,
    StackTrace? stackTrace,
    String logCurl = "",
    Map<String, dynamic>? headers,
    Map<String, dynamic>? extra,
  }) {
    return FailedResponseModel(
      message: message,
      statusCode: statusCode,
      error: error,
      data: data,
      stackTrace: stackTrace,
      logCurl: logCurl,
      headers: headers,
      extra: extra,
    );
  }
}

/// Extension to add convenience methods to ResponseModel
extension ResponseModelExtension on ResponseModel {
  /// Returns true if this is a successful response.
  bool get isSuccess => this is SuccessResponseModel;

  /// Returns true if this is a failed response.
  bool get isFailure => this is FailedResponseModel;
}