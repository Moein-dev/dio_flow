part of 'response_model.dart';

/// Concrete implementation of [ResponseModel] for failed API responses.
class FailedResponseModel extends ResponseModel {
  /// Creates a new FailedResponseModel instance.
  FailedResponseModel({
    required super.statusCode,
    required super.message,
    required super.logCurl,
    super.data,
    super.stackTrace,
    super.error,
    super.errorType,
    super.headers,
    super.extra,
  });

  /// Factory constructor that creates a FailedResponseModel from JSON data.
  factory FailedResponseModel.fromJson(
    Map<String, dynamic> json, {
    LogModel logModel = LogModel.defaultLogModel,
    String endpointPath = '',
    String logCurl = '',
    bool fromCache = false,
    bool isRefreshHandle = false,
    Map<String, dynamic>? headers,
    Map<String, dynamic>? extra,
    Duration? duration,
    String? method,
  }) {
    // Extract status code
    final statusCode =
        json["status"] ?? json["statusCode"] ?? json["code"] ?? 400;

    // Extract message/error
    final message = _extractErrorMessage(json);
    final error = _extractError(json);

    // Determine error type
    final errorType = ErrorType.fromStatusCode(statusCode);

    // Logging
    if (logModel.defaultLog) {
      DioFlowLog(
        logModel: logModel,
        url: DioFlowConfig.instance.baseUrl + endpointPath,
        method: method,
        type: DioLogType.error,
        statusCode: statusCode,
        message: message,
        error: error,
        data: json,
        headers: headers,
        logCurl: logCurl,
        isCache: fromCache,
        extra: extra,
        isRefreshHandle: isRefreshHandle,
        duration: duration,
      ).log();
    }

    return FailedResponseModel(
      logCurl: logCurl,
      statusCode: statusCode,
      message: message,
      error: error,
      data: json,
      errorType: errorType,
      headers: headers,
      extra: extra,
    );
  }

  /// Extracts error message from API response.
  static String _extractErrorMessage(Map<String, dynamic> json) {
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
      return (json["errors"] as List).map((e) => e.toString()).join(", ");
    } else if (json.containsKey("detail")) {
      return json["detail"].toString();
    } else if (json.containsKey("msg")) {
      return json["msg"].toString();
    } else if (json.containsKey("reason")) {
      return json["reason"].toString();
    }

    return "Unknown error";
  }

  /// Extracts raw error object from response.
  static dynamic _extractError(Map<String, dynamic> json) {
    if (json.containsKey("error")) {
      return json["error"];
    } else if (json.containsKey("errors")) {
      return json["errors"];
    }

    return null;
  }

  /// Returns a user-friendly error message.
  String get userFriendlyMessage {
    if (errorType != null) {
      return errorType!.userFriendlyMessage;
    }

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

    if (message != null && message!.isNotEmpty && message!.length < 100) {
      return message!;
    }

    return "An error occurred. Please try again.";
  }

  /// Returns debugging information.
  String get debugInfo {
    final buffer = StringBuffer();

    buffer.writeln("Status Code: ${statusCode ?? 'Unknown'}");
    buffer.writeln("Error Type: ${errorType?.name ?? 'Unknown'}");
    buffer.writeln("Message: ${message ?? 'No message'}");

    if (error != null) {
      buffer.writeln("Error: $error");
    }

    if (headers != null) {
      buffer.writeln("Headers: $headers");
    }

    if (extra != null) {
      buffer.writeln("Extra: $extra");
    }

    buffer.writeln("cURL: $logCurl");

    if (stackTrace != null) {
      buffer.writeln("Stack Trace:\n$stackTrace");
    }

    return buffer.toString();
  }
}
