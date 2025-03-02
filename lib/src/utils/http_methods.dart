/// Utility class containing constants for HTTP methods.
///
/// This class provides string constants for common HTTP methods,
/// reducing the risk of typos and making the code more maintainable.
class HttpMethods {
  /// Private constructor to prevent instantiation.
  /// This ensures the class is used as a utility with static constants only.
  HttpMethods._();
  
  /// HTTP GET method.
  static const String GET = 'GET';
  
  /// HTTP POST method.
  static const String POST = 'POST';
  
  /// HTTP PUT method.
  static const String PUT = 'PUT';
  
  /// HTTP DELETE method.
  static const String DELETE = 'DELETE';
  
  /// HTTP PATCH method.
  static const String PATCH = 'PATCH';
  
  /// HTTP HEAD method.
  static const String HEAD = 'HEAD';
  
  /// HTTP OPTIONS method.
  static const String OPTIONS = 'OPTIONS';
  
  /// Returns true if the given method is valid.
  ///
  /// Parameters:
  ///   method - The HTTP method to validate
  ///
  /// Returns:
  ///   True if the method is a valid HTTP method
  static bool isValid(String method) {
    final upperMethod = method.toUpperCase();
    return upperMethod == GET ||
           upperMethod == POST ||
           upperMethod == PUT ||
           upperMethod == DELETE ||
           upperMethod == PATCH ||
           upperMethod == HEAD ||
           upperMethod == OPTIONS;
  }
} 