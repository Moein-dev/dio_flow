import 'dart:io';
import 'package:dio_flow/src/config/dio_flow_config.dart';

/// Utility class for checking network connectivity.
///
/// This class provides methods to verify if the device has an active internet
/// connection by attempting to look up the application's base URL. It can be used
/// to prevent network requests when there is no connectivity and to monitor
/// connectivity changes over time.
class NetworkChecker {
  /// Checks if the device has an active internet connection.
  ///
  /// This method attempts to resolve the application's base URL to an IP address.
  /// If successful, it indicates that the device has an active internet connection
  /// and can reach the application's server.
  ///
  /// Returns:
  ///   A Future<bool> that resolves to true if there is an active internet connection,
  ///   or false if there is no connectivity or the server cannot be reached.
  static Future<bool> hasConnection() async {
    try {
      final List<InternetAddress> result = await InternetAddress.lookup(
        DioFlowConfig.instance.baseUrl.replaceAll(RegExp(r'https?:\/\/'), ''),
      );
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException catch (_) {
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
