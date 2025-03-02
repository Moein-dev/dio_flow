/// Enum representing specific types of errors that can occur in API requests.
///
/// This provides a more granular categorization of errors beyond just HTTP status codes,
/// allowing for more specific handling and recovery strategies.
enum ErrorType {
  /// Network errors like no internet connection, timeout, etc.
  network,

  /// Authentication errors like invalid credentials, expired token, etc.
  authentication,

  /// Authorization errors like insufficient permissions, forbidden access, etc.
  authorization,

  /// Request errors like invalid parameters, missing required fields, etc.
  validation,

  /// Server errors like internal server error, service unavailable, etc.
  server,

  /// Resource not found errors
  notFound,

  /// Parsing errors like invalid JSON, unexpected format, etc.
  parsing,

  /// Timeout errors when a request takes too long
  timeout,

  /// Cancellation errors when a request is manually cancelled
  cancelled,

  /// Rate limit errors when too many requests are made
  rateLimit,

  /// Unknown or uncategorized errors
  unknown;

  /// Converts an HTTP status code to a specific error type.
  ///
  /// This provides a default mapping from common HTTP status codes
  /// to more specific error types.
  ///
  /// Parameters:
  ///   statusCode - HTTP status code to convert
  ///
  /// Returns:
  ///   The corresponding ErrorType
  static ErrorType fromStatusCode(int statusCode) {
    switch (statusCode) {
      case 400:
        return ErrorType.validation;
      case 401:
        return ErrorType.authentication;
      case 403:
        return ErrorType.authorization;
      case 404:
        return ErrorType.notFound;
      case 408:
        return ErrorType.timeout;
      case 422:
        return ErrorType.validation;
      case 429:
        return ErrorType.rateLimit;
      default:
        if (statusCode >= 500 && statusCode < 600) {
          return ErrorType.server;
        }
        return ErrorType.unknown;
    }
  }

  /// Maps a Dio error type to an ErrorType.
  ///
  /// This is useful for converting Dio's internal error types
  /// to our application-specific error types.
  ///
  /// Parameters:
  ///   dioErrorType - The Dio error type to convert
  ///
  /// Returns:
  ///   The corresponding ErrorType
  static ErrorType fromDioErrorType(dynamic dioErrorType) {
    // Use string comparison to avoid direct dependency on specific Dio version
    final typeString = dioErrorType.toString();

    if (typeString.contains('connectTimeout') ||
        typeString.contains('sendTimeout') ||
        typeString.contains('receiveTimeout')) {
      return ErrorType.timeout;
    } else if (typeString.contains('cancel')) {
      return ErrorType.cancelled;
    } else if (typeString.contains('connectionError')) {
      return ErrorType.network;
    } else {
      return ErrorType.unknown;
    }
  }

  /// Returns a user-friendly error message for this error type.
  ///
  /// This provides default error messages that can be shown to users
  /// for each error type.
  ///
  /// Returns:
  ///   A user-friendly error message
  String get userFriendlyMessage {
    switch (this) {
      case ErrorType.network:
        return 'Network error. Please check your internet connection and try again.';
      case ErrorType.authentication:
        return 'Authentication failed. Please sign in again.';
      case ErrorType.authorization:
        return 'You do not have permission to access this resource.';
      case ErrorType.validation:
        return 'Invalid request. Please check your input and try again.';
      case ErrorType.server:
        return 'Server error. Please try again later.';
      case ErrorType.notFound:
        return 'The requested resource was not found.';
      case ErrorType.parsing:
        return 'Error processing the response. Please try again.';
      case ErrorType.timeout:
        return 'Request timed out. Please try again.';
      case ErrorType.cancelled:
        return 'Request was cancelled.';
      case ErrorType.rateLimit:
        return 'Too many requests. Please try again later.';
      case ErrorType.unknown:
        return 'An unexpected error occurred. Please try again.';
    }
  }
}
