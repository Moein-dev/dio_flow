import 'package:dio_flow/src/models/api_exception.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TokenManager {
  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _tokenExpiryKey = 'token_expiry';
  
  static String? _accessToken;
  static String? _refreshToken;
  static DateTime? _tokenExpiry;
  static SharedPreferences? _prefs;

  static Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    await _loadTokens();
  }

  static Future<void> _loadTokens() async {
    if (_prefs == null) {
      throw ApiException('TokenManager not initialized. Call initialize() first.');
    }

    _accessToken = _prefs!.getString(_accessTokenKey);
    _refreshToken = _prefs!.getString(_refreshTokenKey);
    
    final expiryTimestamp = _prefs!.getInt(_tokenExpiryKey);
    if (expiryTimestamp != null) {
      _tokenExpiry = DateTime.fromMillisecondsSinceEpoch(expiryTimestamp);
    }
  }

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

  static Future<void> setTokens({
    required String accessToken,
    required String refreshToken,
    required DateTime expiry,
  }) async {
    if (_prefs == null) {
      throw ApiException('TokenManager not initialized. Call initialize() first.');
    }

    await Future.wait([
      _prefs!.setString(_accessTokenKey, accessToken),
      _prefs!.setString(_refreshTokenKey, refreshToken),
      _prefs!.setInt(_tokenExpiryKey, expiry.millisecondsSinceEpoch),
    ]);

    _accessToken = accessToken;
    _refreshToken = refreshToken;
    _tokenExpiry = expiry;
  }

  static Future<void> clearTokens() async {
    if (_prefs == null) {
      throw ApiException('TokenManager not initialized. Call initialize() first.');
    }

    await Future.wait([
      _prefs!.remove(_accessTokenKey),
      _prefs!.remove(_refreshTokenKey),
      _prefs!.remove(_tokenExpiryKey),
    ]);

    _accessToken = null;
    _refreshToken = null;
    _tokenExpiry = null;
  }
}
