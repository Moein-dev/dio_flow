import 'package:dio_flow/src/models/api_exception.dart';

class TokenManager {
  static String? _accessToken;
  static String? _refreshToken;
  static DateTime? _tokenExpiry;

  static Future<String?> getAccessToken() async {
    if (_accessToken == null || _isTokenExpired()) {
      await _refreshAccessToken();
    }
    return _accessToken;
  }

  static bool _isTokenExpired() {
    return _tokenExpiry?.isBefore(DateTime.now()) ?? true;
  }

  static Future<void> _refreshAccessToken() async {
    if (_refreshToken == null) {
      throw ApiException('No refresh token available');
    }
    // Implement token refresh logic using _refreshToken
  }

  static void setTokens({
    required String accessToken,
    required String refreshToken,
    required DateTime expiry,
  }) {
    _accessToken = accessToken;
    _refreshToken = refreshToken;
    _tokenExpiry = expiry;
  }

  static void clearTokens() {
    _accessToken = null;
    _refreshToken = null;
    _tokenExpiry = null;
  }
}
