part of 'response_model.dart';

/// Concrete implementation of [ResponseModel] for failed API responses.
///
/// This class represents API responses with status codes outside the 200-299 range,
/// which indicate errors or failures. It provides specific handling for
/// error responses, including proper parsing of error messages and status codes.
class FailedResponseModel extends ResponseModel {
  /// Creates a new FailedResponseModel instance.
  ///
  /// Parameters:
  ///   statusCode - The HTTP status code indicating the error (required)
  ///   message - A descriptive error message (required)
  ///   logCurl - The cURL command used for the request (required)
  ///   data - Additional error data or context
  ///   stackTrace - Stack trace for debugging the error
  ///   error - The original error object
  ///   errorType - Categorized type of error that occurred
  FailedResponseModel({
    required super.statusCode,
    required super.message,
    required super.logCurl,
    super.data,
    super.stackTrace,
    super.error,
    super.errorType,
  });

  /// Factory constructor that creates a FailedResponseModel from JSON data.
  ///
  /// This constructor parses the JSON response and extracts:
  /// - The cURL log for debugging
  /// - The error status code
  /// - The error message
  /// - The error details and context
  ///
  /// This method is designed to handle various error response structures by:
  /// 1. Extracting error messages from common locations
  /// 2. Setting appropriate status codes
  /// 3. Preserving original error data for debugging
  ///
  /// Parameters:
  ///   json - A Map containing the API error response data
  ///
  /// Returns:
  ///   A new FailedResponseModel instance populated with the parsed error data
  factory FailedResponseModel.fromJson(
    Map<String, dynamic> json, {
    String endpointPath = '',
    String logCurl = '',
    bool fromCache = false,
    bool isRefreshHandle = false,
  }) {

    // Extract the status code or default to 400 (Bad Request)
    final statusCode =
        json["status"] ?? json["statusCode"] ?? json["code"] ?? 400;

    final extra = json['extra'];

    // Extract the error message using a flexible approach
    final message = _extractErrorMessage(json);

    // Extract the error object if available
    final error = _extractError(json);

    // Determine the error type based on status code
    final errorType = ErrorType.fromStatusCode(statusCode);

    DioFlowLog(
      url: DioFlowConfig.instance.baseUrl + endpointPath,
      type: DioLogType.error,
      statusCode: statusCode,
      message: message,
      error: error,
      logCurl: logCurl,
      isCache: fromCache,
      extra: extra,
      isRefreshHandle: isRefreshHandle,
    ).log();

    return FailedResponseModel(
      logCurl: logCurl,
      statusCode: statusCode,
      message: message,
      error: error,
      data: json,
      errorType: errorType,
    );
  }

  /// Extracts an error message from a response using a flexible strategy.
  ///
  /// This method attempts to find the most appropriate error message by
  /// checking various common locations in API error responses.
  ///
  /// Parameters:
  ///   json - The response JSON to extract an error message from
  ///
  /// Returns:
  ///   The extracted error message or a default message if none is found
  static String _extractErrorMessage(Map<String, dynamic> json) {
    // Check for common error message field names
    if (json.containsKey("message") && json["message"] != null) {
      return json["message"].toString();
    } else if (json.containsKey("error") && json["error"] is String) {
      return json["error"];
    } else if (json.containsKey("error") &&
        json["error"] is Map &&
        json["error"].containsKey("message")) {
      return json["error"]["message"].toString();
    } else if (json.containsKey("errors") &&
        json["errors"] is List &&
        (json["errors"] as List).isNotEmpty) {
      // Join multiple errors if present as a list
      return (json["errors"] as List).map((e) => e.toString()).join(", ");
    } else if (json.containsKey("detail")) {
      return json["detail"].toString();
    } else if (json.containsKey("msg")) {
      return json["msg"].toString();
    } else if (json.containsKey("reason")) {
      return json["reason"].toString();
    }

    // Default message if no specific error message field is found
    return "Unknown error";
  }

  /// Extracts error data from a response.
  ///
  /// This method looks for error data in various formats and locations.
  ///
  /// Parameters:
  ///   json - The response JSON to extract error data from
  ///
  /// Returns:
  ///   The extracted error data or null if none is found
  static dynamic _extractError(Map<String, dynamic> json) {
    if (json.containsKey("error")) {
      return json["error"];
    } else if (json.containsKey("errors")) {
      return json["errors"];
    }
    return null;
  }

  /// Returns a user-friendly error message.
  ///
  /// This method uses both the status code and error message to generate
  /// a user-friendly error message that can be displayed to the user.
  ///
  /// Returns:
  ///   A user-friendly error message
  String get userFriendlyMessage {
    // If we have an error type, use its predefined user-friendly message
    if (errorType != null) {
      return errorType!.userFriendlyMessage;
    }

    // Otherwise, generate a message based on status code
    if (statusCode != null) {
      if (statusCode! >= 500) {
        return "Server error. Please try again later.";
      } else if (statusCode! == 401) {
        return "Authentication failed. Please sign in again.";
      } else if (statusCode! == 403) {
        return "You don't have permission to access this resource.";
      } else if (statusCode! == 404) {
        return "The requested resource was not found.";
      } else if (statusCode! == 429) {
        return "Too many requests. Please try again later.";
      }
    }

    // Use the original error message if it's suitable for users
    if (message != null && message!.isNotEmpty && message!.length < 100) {
      // Simple heuristic: if message is short, it's probably user-friendly
      return message!;
    }

    // Default message
    return "An error occurred. Please try again.";
  }

  /// Returns debugging information about the error.
  ///
  /// This method compiles various information about the error into a single
  /// string that can be used for debugging purposes.
  ///
  /// Returns:
  ///   A string containing debugging information
  String get debugInfo {
    final buffer = StringBuffer();

    buffer.writeln("Status Code: ${statusCode ?? 'Unknown'}");
    buffer.writeln("Error Type: ${errorType?.name ?? 'Unknown'}");
    buffer.writeln("Message: ${message ?? 'No message'}");

    if (error != null) {
      buffer.writeln("Error: $error");
    }

    buffer.writeln("cURL: $logCurl");

    if (stackTrace != null) {
      buffer.writeln("Stack Trace:\n$stackTrace");
    }

    return buffer.toString();
  }
}
