/// Interface for API endpoints.
///
/// This abstract class provides a common interface for all API endpoints.
/// Users can implement this interface to define their own custom endpoints.
abstract class ApiEndpointInterface {
  /// The relative path of the endpoint.
  /// 
  /// This path is appended to the base URL when making API requests.
  String get path;
}

/// Factory for creating API endpoints from strings.
///
/// This class allows creating endpoint instances dynamically at runtime
/// from path strings, which is useful for dynamically defined endpoints.
class ApiEndpointFactory {
  /// Creates a new endpoint with the specified path.
  ///
  /// Parameters:
  ///   path - The relative path for this endpoint.
  ///
  /// Returns:
  ///   An ApiEndpointInterface instance with the given path.
  static ApiEndpointInterface create(String path) {
    return _SimpleApiEndpoint(path);
  }
}

/// Simple implementation of ApiEndpointInterface.
///
/// This private class is used internally by the factory to create
/// endpoints with specific paths.
class _SimpleApiEndpoint implements ApiEndpointInterface {
  @override
  final String path;
  
  const _SimpleApiEndpoint(this.path);
} 