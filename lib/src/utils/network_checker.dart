import 'dart:io';
import 'package:dio_flow/src/config/dio_flow_config.dart';

/// Utility class for checking network connectivity.
///
/// This class provides methods to verify if the device has an active internet
/// connection by attempting to look up multiple reliable domains. It can be used
/// to prevent network requests when there is no connectivity and to monitor
/// connectivity changes over time.
class NetworkChecker {
  /// Checks if the device has an active internet connection.
  ///
  /// This method attempts to resolve multiple reliable domains to verify connectivity.
  /// If any lookup succeeds, it indicates that the device has an active internet connection.
  ///
  /// Returns:
  ///   A Future<bool> that resolves to true if there is an active internet connection,
  ///   or false if there is no connectivity or none of the servers can be reached.
  static Future<bool> hasConnection() async {
    try {
      // Try multiple reliable domains
      final domains = [
        'google.com',
        'cloudflare.com',
        '1.1.1.1',
      ];

      for (final domain in domains) {
        try {
          final result = await InternetAddress.lookup(domain);
          if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
            return true;
          }
        } catch (_) {
          continue;
        }
      }

      // If all lookups fail, try the API domain as a last resort
      final apiDomain = DioFlowConfig.instance.baseUrl.replaceAll(
        RegExp(r'https?:\/\/'),
        '',
      ).split('/')[0];
      
      final result = await InternetAddress.lookup(apiDomain);
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
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
  ///   A Stream<bool> that emits true when there is an active internet connection,
  ///   and false when there is no connectivity.
  static Stream<bool> get connectionStream async* {
    while (true) {
      yield await hasConnection();
      await Future.delayed(const Duration(seconds: 5));
    }
  }
}
