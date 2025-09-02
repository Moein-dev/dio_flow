import 'dart:async';
import 'package:dio/dio.dart';
import 'package:dio_flow/src/config/dio_flow_config.dart';

/// Utility class for checking network connectivity.
///
/// This class provides methods to verify if the device has an active internet
/// connection by making lightweight HTTP requests to reliable endpoints. It can be used
/// to prevent network requests when there is no connectivity and to monitor
/// connectivity changes over time.
class NetworkChecker {
  static final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(seconds: 5),
      sendTimeout: const Duration(seconds: 5),
    ),
  );

  /// Checks if the device has an active internet connection.
  ///
  /// This method attempts to make lightweight HEAD requests to multiple reliable endpoints
  /// to verify connectivity. If any request succeeds, it indicates that the device has
  /// an active internet connection.
  ///
  /// Returns:
  ///   A `Future<bool>` that resolves to true if there is an active internet connection,
  ///   or false if there is no connectivity or none of the servers can be reached.
  static Future<bool> hasConnection() async {
    try {
      // Try multiple reliable endpoints with HEAD requests (lightweight)
      final endpoints = [
        'https://www.google.com/generate_204', // Google's connectivity check endpoint
        'https://cloudflare.com/cdn-cgi/trace', // Cloudflare's trace endpoint
        'https://httpbin.org/status/200', // HTTPBin status endpoint
      ];

      for (final endpoint in endpoints) {
        try {
          final response = await _dio.head(endpoint);
          if (response.statusCode != null &&
              response.statusCode! >= 200 &&
              response.statusCode! < 300) {
            return true;
          }
        } catch (_) {
          continue;
        }
      }

      // If all standard endpoints fail, try a simple GET to the configured API base URL
      try {
        final baseUrl = DioFlowConfig.instance.baseUrl;
        if (baseUrl.isNotEmpty) {
          final response = await _dio.head(baseUrl);
          return response.statusCode != null &&
              response.statusCode! >= 200 &&
              response.statusCode! < 500;
        }
      } catch (_) {
        // Ignore API endpoint failures as they might be due to authentication or other non-connectivity issues
      }

      return false;
    } catch (_) {
      return false;
    }
  }

  /// Provides a continuous stream of connectivity status updates.
  ///
  /// This stream emits a boolean value every 5 seconds indicating whether
  /// the device has an active internet connection. It can be used to monitor
  /// connectivity changes and react accordingly in the application.
  ///
  /// Returns:
  ///   A `Stream<bool>` that emits true when there is an active internet connection,
  ///   and false when there is no connectivity.
  static Stream<bool> get connectionStream async* {
    while (true) {
      yield await hasConnection();
      await Future.delayed(const Duration(seconds: 5));
    }
  }
}
