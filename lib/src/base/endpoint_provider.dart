import 'package:dio_flow/src/base/api_endpoint_interface.dart';

/// Provider for managing API endpoints in the application.
///
/// This class allows users to register their own custom endpoints
/// for use with the DioRequestHandler. Endpoints can be registered
/// individually or loaded from a configuration file.
class EndpointProvider {
  // Private constructor to enforce singleton pattern
  EndpointProvider._();
  
  // Singleton instance
  static final EndpointProvider _instance = EndpointProvider._();
  
  /// Gets the singleton instance of EndpointProvider.
  static EndpointProvider get instance => _instance;
  
  // Store of registered endpoints
  final Map<String, ApiEndpointInterface> _endpoints = {};
  
  /// Registers a new endpoint with the specified name and path.
  ///
  /// Parameters:
  ///   name - The unique name/key for the endpoint
  ///   endpoint - The endpoint implementation or path
  ///
  /// Returns:
  ///   The EndpointProvider instance for method chaining
  EndpointProvider register(String name, dynamic endpoint) {
    if (endpoint is String) {
      _endpoints[name] = ApiEndpointFactory.create(endpoint);
    } else if (endpoint is ApiEndpointInterface) {
      _endpoints[name] = endpoint;
    } else {
      throw ArgumentError(
        'Endpoint must be either a String path or an ApiEndpointInterface implementation',
      );
    }
    return this;
  }
  
  /// Registers multiple endpoints at once.
  ///
  /// Parameters:
  ///   endpoints - A map of endpoint names to paths or implementations
  ///
  /// Returns:
  ///   The EndpointProvider instance for method chaining
  EndpointProvider registerAll(Map<String, dynamic> endpoints) {
    endpoints.forEach((name, endpoint) {
      register(name, endpoint);
    });
    return this;
  }
  
  /// Gets an endpoint by its registered name.
  ///
  /// Parameters:
  ///   name - The name of the endpoint to retrieve
  ///
  /// Returns:
  ///   The requested ApiEndpointInterface
  ///
  /// Throws:
  ///   ArgumentError if no endpoint is registered with the given name
  ApiEndpointInterface getEndpoint(String name) {
    final endpoint = _endpoints[name];
    if (endpoint == null) {
      throw ArgumentError('No endpoint registered with name: $name');
    }
    return endpoint;
  }
  
  /// Clears all registered endpoints.
  ///
  /// This is useful during testing or when reconfiguring the application.
  void clear() {
    _endpoints.clear();
  }
} 