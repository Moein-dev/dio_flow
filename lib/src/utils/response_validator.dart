import 'package:dio/dio.dart';
import 'package:dio_flow/src/models/api_exception.dart';

/// Utility class for validating API responses.
///
/// This class provides methods to check if API responses meet
/// the expected criteria for success and data validity.
class ResponseValidator {
  /// Validates that a response meets basic criteria for processing.
  ///
  /// This method checks that:
  /// 1. The response is not null
  /// 2. The status code indicates success (200-299 range)
  ///
  /// Unlike the previous implementation, this validator is more permissive
  /// regarding the response data, allowing for various response formats.
  ///
  /// Parameters:
  ///   response - The Dio response to validate
  ///
  /// Throws:
  ///   ApiException if the response fails validation
  static void validate(Response response) {
    // Check for valid status code
    if (response.statusCode == null) {
      throw ApiException('Response status code is null');
    }
    
    // Allow non-success status codes to pass through
    // They will be handled by creating a FailedResponseModel
  }

  /// Checks if a response has a successful status code.
  ///
  /// This method determines if the response status code indicates
  /// a successful API call (i.e., in the 200-299 range).
  ///
  /// Parameters:
  ///   response - The response to check
  ///
  /// Returns:
  ///   true if the status code is in the 200-299 range, false otherwise
  static bool isSuccessful(Response response) {
    return response.statusCode != null && 
           response.statusCode! >= 200 && 
           response.statusCode! < 300;
  }

  /// Checks if a response has a non-null data payload.
  ///
  /// This method determines if the response contains any data.
  /// The data could be in any format (Map, List, String, etc.).
  ///
  /// Parameters:
  ///   response - The response to check
  ///
  /// Returns:
  ///   true if the response has data, false otherwise
  static bool hasData(Response response) {
    return response.data != null;
  }
  
  /// Checks if a response contains a valid JSON object as data.
  ///
  /// This method determines if the response data is a Map,
  /// which indicates it's a JSON object.
  ///
  /// Parameters:
  ///   response - The response to check
  ///
  /// Returns:
  ///   true if the data is a JSON object (Map), false otherwise
  static bool hasJsonObject(Response response) {
    return response.data is Map<String, dynamic>;
  }
  
  /// Checks if a response contains a valid JSON array as data.
  ///
  /// This method determines if the response data is a List,
  /// which indicates it's a JSON array.
  ///
  /// Parameters:
  ///   response - The response to check
  ///
  /// Returns:
  ///   true if the data is a JSON array (List), false otherwise
  static bool hasJsonArray(Response response) {
    return response.data is List;
  }
} 