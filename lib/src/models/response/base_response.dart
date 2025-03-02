/// Abstract class representing a standardized API response.
///
/// This class serves as a base for all API responses in the application,
/// providing a consistent structure for handling different types of responses.
/// It includes common properties like data, status code, message, and metadata,
/// as well as utility methods to determine if the response was successful.
///
/// Type parameter:
///   T - The type of data contained in the response
abstract class BaseResponse<T> {
  /// The data payload returned by the API.
  ///
  /// This can be null if the API doesn't return any data or if there was an error.
  final T? data;
  
  /// The HTTP status code of the response.
  ///
  /// Status codes in the 200-299 range indicate success,
  /// while other ranges indicate various types of errors.
  final int statusCode;
  
  /// A message describing the response or error.
  ///
  /// This is typically used for error messages or success confirmations.
  final String? message;
  
  /// Additional metadata associated with the response.
  ///
  /// This can include pagination information, timestamps, or any other
  /// supplementary data provided by the API.
  final Map<String, dynamic>? meta;

  /// Creates a new BaseResponse instance.
  ///
  /// Parameters:
  ///   data - The response data payload
  ///   statusCode - The HTTP status code (required)
  ///   message - A descriptive message about the response
  ///   meta - Additional metadata associated with the response
  BaseResponse({
    this.data,
    required this.statusCode,
    this.message,
    this.meta,
  });

  /// Indicates whether the response was successful.
  ///
  /// Returns true if the status code is in the 200-299 range,
  /// which is the standard range for successful HTTP responses.
  bool get isSuccess => statusCode >= 200 && statusCode < 300;
  
  /// Indicates whether the response represents an error.
  ///
  /// Returns true if the status code is outside the 200-299 range.
  bool get isError => !isSuccess;
  
  /// Converts the response to a JSON map.
  ///
  /// This method must be implemented by subclasses to provide
  /// serialization functionality for the specific response type.
  ///
  /// Returns:
  ///   A Map<String, dynamic> representation of the response
  Map<String, dynamic> toJson();
} 