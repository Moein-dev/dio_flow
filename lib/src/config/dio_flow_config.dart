/// Configuration for the dio_flow package.
///
/// This class provides configuration options for the dio_flow package,
/// allowing users to customize behavior like the base URL for API requests.
class DioFlowConfig {
  /// The singleton instance of DioFlowConfig.
  static DioFlowConfig? _instance;

  /// The base URL for API requests.
  final String baseUrl;

  /// The time to wait for a connection to be established.
  final Duration connectTimeout;

  /// The time to wait for receiving data.
  final Duration receiveTimeout;

  /// The time to wait for sending data.
  final Duration sendTimeout;

  /// Private constructor to prevent direct instantiation.
  DioFlowConfig._({
    required this.baseUrl,
    this.connectTimeout = const Duration(seconds: 30),
    this.receiveTimeout = const Duration(seconds: 30),
    this.sendTimeout = const Duration(seconds: 30),
  });

  /// Initializes the configuration for dio_flow package.
  ///
  /// This method must be called before using any functionality in the package.
  /// It sets up the required configuration like the base URL for API requests.
  ///
  /// Example:
  /// ```dart
  /// void main() {
  ///   DioFlowConfig.initialize(baseUrl: 'https://api.example.com');
  ///   runApp(MyApp());
  /// }
  /// ```
  ///
  /// Parameters:
  ///   baseUrl - The base URL for all API requests
  ///   connectTimeout - The time to wait for a connection to be established (defaults to 30 seconds)
  ///   receiveTimeout - The time to wait for receiving data (defaults to 30 seconds)
  ///   sendTimeout - The time to wait for sending data (defaults to 30 seconds)
  static void initialize({
    required String baseUrl,
    Duration connectTimeout = const Duration(seconds: 30),
    Duration receiveTimeout = const Duration(seconds: 30),
    Duration sendTimeout = const Duration(seconds: 30),
  }) {
    _instance = DioFlowConfig._(
      baseUrl: baseUrl,
      connectTimeout: connectTimeout,
      receiveTimeout: receiveTimeout,
      sendTimeout: sendTimeout,
    );
  }

  /// Gets the current configuration instance.
  ///
  /// This getter provides access to the configuration values needed throughout
  /// the package. It throws an error if accessed before initialization.
  ///
  /// Returns:
  ///   The singleton DioFlowConfig instance with all configuration values.
  ///
  /// Throws:
  ///   StateError if called before initializing the configuration.
  static DioFlowConfig get instance {
    if (_instance == null) {
      throw StateError(
        'DioFlowConfig must be initialized before use. '
        'Call DioFlowConfig.initialize() first.',
      );
    }
    return _instance!;
  }

  /// Resets the configuration instance.
  ///
  /// This method is primarily used for testing or when reconfiguration is needed.
  static void reset() {
    _instance = null;
  }
}


String removeAfterThirdSlash(String url) {
  int slashCount = 0;
  for (int i = 0; i < url.length; i++) {
    if (url.codeUnitAt(i) == '/'.codeUnitAt(0)) {
      slashCount++;
      if (slashCount == 3) {
        return url.substring(0, i);
      }
    }
  }
  return url; 
}