import 'package:colorful_log_plus/colorful_log_plus.dart';
import 'package:dio/dio.dart';
import 'package:dio_flow/src/config/dio_flow_config.dart';
import 'package:dio_flow/src/interceptors/cache_interceptor.dart';
import 'package:dio_flow/src/interceptors/connectivity_interceptor.dart';
import 'package:dio_flow/src/interceptors/dio_interceptor.dart';
import 'package:dio_flow/src/interceptors/metrics_interceptor.dart';
import 'package:dio_flow/src/interceptors/rate_limit_interceptor.dart';
import 'package:dio_flow/src/interceptors/retry_interceptor.dart';
import 'package:dio_flow/src/models/retry_options.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A singleton client that manages Dio HTTP client and its interceptors.
/// This client handles API requests, caching, rate limiting, and error handling.
class ApiClient {
  static Dio? _dio;
  static CacheInterceptor? _cacheInterceptor;

  /// Returns the singleton Dio instance, creating it if it doesn't exist yet.
  ///
  /// This getter ensures that we always use the same configured Dio instance
  /// throughout the application.
  ///
  /// Returns:
  ///   A configured Dio instance with all necessary interceptors.
  static Dio get dio {
    _dio ??= _createDio();
    return _dio!;
  }

  /// Initializes the API client by setting up the cache interceptor.
  ///
  /// This method should be called during app initialization, before any API calls
  /// are made. Typically this would be in your app's main() function or during
  /// the initialization phase of your dependency injection setup.
  ///
  /// Note: Before calling this method, ensure DioFlowConfig is initialized
  /// using DioFlowConfig.initialize(baseUrl: 'https://api.example.com').
  ///
  /// Example:
  /// ```dart
  /// void main() async {
  ///   WidgetsFlutterBinding.ensureInitialized();
  ///   DioFlowConfig.initialize(baseUrl: 'https://api.example.com');
  ///   await ApiClient.initialize();
  ///   runApp(MyApp());
  /// }
  /// ```
  ///
  /// Throws:
  ///   A StateError if the API client is used before initialization.
  static Future<void> initialize() async {
    // Check if DioFlowConfig is initialized
    DioFlowConfig.instance; // This will throw if not initialized

    final prefs = await SharedPreferences.getInstance();
    _cacheInterceptor = CacheInterceptor(
      prefs: prefs,
      maxAge: const Duration(
        minutes: 5,
      ), // Maximum time to keep cached responses before they expire
    );
  }

  /// Clears all cached API responses.
  ///
  /// This method can be used when the user logs out or when cached data
  /// needs to be refreshed completely.
  ///
  /// Returns:
  ///   A Future that completes when the cache has been cleared.
  static Future<void> clearCache() async {
    await _cacheInterceptor?.clearCache();
  }

  /// Creates and configures a new Dio instance with all required interceptors.
  ///
  /// This method sets up the base URL, timeouts, and adds interceptors in the
  /// correct order to handle connectivity, rate limiting, metrics, auth,
  /// retries, caching, and logging.
  ///
  /// Returns:
  ///   A fully configured Dio instance.
  ///
  /// Throws:
  ///   StateError if called before the ApiClient is initialized.
  static Dio _createDio() {
    if (_cacheInterceptor == null) {
      throw StateError(
        'ApiClient must be initialized before use. Call ApiClient.initialize() first.',
      );
    }

    final config = DioFlowConfig.instance;

    final dio = Dio(
      BaseOptions(
        baseUrl: config.baseUrl,
        connectTimeout: config.connectTimeout,
        receiveTimeout: config.receiveTimeout,
        sendTimeout: config.sendTimeout,
        validateStatus: (status) => status != null && status < 500,
      ),
    );

    final retryOptions = RetryOptions(
      maxAttempts: 3,
      retryInterval: const Duration(seconds: 1),
    );

    dio.interceptors.addAll([
      ConnectivityInterceptor(),
      RateLimitInterceptor(
        maxRequests: 30,
        interval: const Duration(minutes: 1),
      ),
      MetricsInterceptor(),
      DioInterceptor(),
      RetryInterceptor(options: retryOptions, dio: dio),
      _cacheInterceptor!,
      LogInterceptor(
        requestBody: true,
        responseBody: true,
        logPrint: (object) => debugLog(message: '[DIO] $object'),
      ),
    ]);

    return dio;
  }

  /// Resets the Dio instance, closing any active connections.
  ///
  /// This method is useful during testing or when reconfiguration is needed.
  /// It closes the existing Dio instance and sets it to null, so a new instance
  /// will be created the next time the 'dio' getter is called.
  static void reset() {
    _dio?.close();
    _dio = null;
  }
}
