import 'package:dio_flow/dio_flow.dart';
import 'package:dio_flow/src/handlers/dio_flow_log.dart';

part 'success_response_model.dart';
part 'failed_response_model.dart';

/// Abstract class representing a standardized API response in the application.
///
/// This class serves as the base model for all API responses, providing a consistent
/// structure for handling both successful and failed responses. It contains common
/// properties like data, status code, message, pagination links, and metadata.
///
/// The class uses a factory constructor to create either a [SuccessResponseModel]
/// or [FailedResponseModel] based on the status code in the response.
abstract class ResponseModel {
  /// The data payload returned by the API.
  ///
  /// This can be any type of data, including null, depending on the API response.
  /// For successful responses, this typically contains the requested information.
  /// For failed responses, this might contain additional error details.
  final dynamic data;

  /// The HTTP status code of the response.
  ///
  /// Status codes in the 200-299 range indicate success,
  /// while other ranges indicate various types of errors.
  final int? statusCode;

  /// A message describing the response or error.
  ///
  /// This is typically used for error messages or success confirmations.
  final String? message;

  /// Links for pagination or related resources.
  ///
  /// This typically contains URLs for navigating through paginated results,
  /// such as next, previous, first, and last page links.
  final LinksModel? links;

  /// Additional metadata associated with the response.
  ///
  /// This can include pagination information, timestamps, or any other
  /// supplementary data provided by the API.
  final MetaModel? meta;

  /// The cURL command used for the request, logged for debugging purposes.
  ///
  /// This helps with troubleshooting by providing the exact request that was made.
  final String logCurl;

  /// Stack trace for error responses, useful for debugging.
  ///
  /// This is typically only populated for error responses and helps
  /// identify where in the code the error occurred.
  final StackTrace? stackTrace;

  /// The error object if the request failed.
  ///
  /// This can contain detailed error information beyond just the message.
  final dynamic error;

  /// The type of error that occurred.
  ///
  /// This provides a more specific categorization of the error beyond just
  /// the HTTP status code, making it easier to handle specific error cases.
  /// Only populated for error responses.
  final ErrorType? errorType;

  /// Creates a new ResponseModel instance.
  ///
  /// Parameters:
  ///   logCurl - The cURL command used for the request (required)
  ///   error - The error object if the request failed
  ///   data - The response data payload
  ///   statusCode - The HTTP status code
  ///   message - A descriptive message about the response
  ///   links - Pagination or related resource links
  ///   meta - Additional metadata associated with the response
  ///   stackTrace - Stack trace for error responses
  ///   errorType - Categorized type of error that occurred
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
  });

  /// Factory constructor that creates the appropriate response model based on the status code.
  ///
  /// This constructor examines the "status" field in the JSON response and:
  /// - Returns a [SuccessResponseModel] if the status is in the 200-299 range
  /// - Returns a [FailedResponseModel] for all other status codes
  ///
  /// If the response does not match the expected structure, this method will
  /// attempt to adapt it to fit the expected model while preserving the original data.
  ///
  /// Parameters:
  ///   json - A Map containing the API response data
  ///   forceSuccess - Force creation of SuccessResponseModel regardless of status code
  ///   forceFailure - Force creation of FailedResponseModel regardless of status code
  ///
  /// Returns:
  ///   Either a SuccessResponseModel or FailedResponseModel
  factory ResponseModel.fromJson(
    Map<String, dynamic> json, {
    bool forceSuccess = false,
    bool forceFailure = false,
  }) {
    // Extract or default values
    final statusCode = json["status"] ?? json["statusCode"] ?? json["code"];

    // Check if we should force a particular response type
    if (forceSuccess) {
      return SuccessResponseModel.fromJson(json);
    } else if (forceFailure) {
      return FailedResponseModel.fromJson(json);
    }

    // Determine response type based on status code
    // If status code is null, check if there's an error field/property
    if (statusCode == null) {
      final hasErrorIndicators =
          json.containsKey("error") ||
          json.containsKey("errors") ||
          json.containsKey("message") && !json.containsKey("data");

      return hasErrorIndicators
          ? FailedResponseModel.fromJson(json)
          : SuccessResponseModel.fromJson(json);
    }

    // Process based on status code
    if (statusCode is int && statusCode >= 200 && statusCode <= 299) {
      return SuccessResponseModel.fromJson(json);
    } else {
      return FailedResponseModel.fromJson(json);
    }
  }

  /// Creates a success response model directly from any data.
  ///
  /// This is useful when you need to wrap data that didn't come from an API
  /// in a consistent ResponseModel format.
  ///
  /// Parameters:
  ///   data - Any data to wrap in a success response
  ///   statusCode - Optional status code (defaults to 200)
  ///   logCurl - Optional cURL command (defaults to empty string)
  ///
  /// Returns:
  ///   A SuccessResponseModel containing the provided data
  static ResponseModel success({
    required dynamic data,
    int statusCode = 200,
    String logCurl = "",
  }) {
    return SuccessResponseModel(
      data: data,
      statusCode: statusCode,
      logCurl: logCurl,
    );
  }

  /// Creates a failed response model directly from an error.
  ///
  /// This is useful when you need to wrap an error that didn't come from an API
  /// in a consistent ResponseModel format.
  ///
  /// Parameters:
  ///   message - Error message describing what went wrong
  ///   statusCode - Optional status code (defaults to 400)
  ///   error - Optional error object with more details
  ///   data - Optional data associated with the error
  ///   stackTrace - Optional stack trace for debugging
  ///   logCurl - Optional cURL command (defaults to empty string)
  ///
  /// Returns:
  ///   A FailedResponseModel representing the error
  static ResponseModel failure({
    required String message,
    int statusCode = 400,
    dynamic error,
    dynamic data,
    StackTrace? stackTrace,
    String logCurl = "",
  }) {
    return FailedResponseModel(
      message: message,
      statusCode: statusCode,
      error: error,
      data: data,
      stackTrace: stackTrace,
      logCurl: logCurl,
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
