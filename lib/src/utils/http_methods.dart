/// Utility class containing constants for HTTP methods.
///
/// This class provides string constants for common HTTP methods,
/// reducing the risk of typos and making the code more maintainable.
class HttpMethods {
  /// Private constructor to prevent instantiation.
  /// This ensures the class is used as a utility with static constants only.
  HttpMethods._();

  /// HTTP GET method.
  static const String get = 'GET';

  /// HTTP POST method.
  static const String post = 'POST';

  /// HTTP PUT method.
  static const String put = 'PUT';

  /// HTTP DELETE method.
  static const String delete = 'DELETE';

  /// HTTP PATCH method.
  static const String patch = 'PATCH';

  /// HTTP HEAD method.
  static const String head = 'HEAD';

  /// HTTP OPTIONS method.
  static const String options = 'OPTIONS';

  /// Returns true if the given method is valid.
  ///
  /// Parameters:
  ///   method - The HTTP method to validate
  ///
  /// Returns:
  ///   True if the method is a valid HTTP method
  static bool isValid(String method) {
    final upperMethod = method.toUpperCase();
    return upperMethod == get ||
        upperMethod == post ||
        upperMethod == put ||
        upperMethod == delete ||
        upperMethod == patch ||
        upperMethod == head ||
        upperMethod == options;
  }
}
