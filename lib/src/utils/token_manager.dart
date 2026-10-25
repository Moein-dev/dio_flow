import 'dart:async';
import 'package:dio_flow/dio_flow.dart';
import 'package:shared_preferences/shared_preferences.dart';

typedef RefreshTokenHandler =
    Future<RefreshTokenResponse> Function(String refreshToken);

class TokenManager {
  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _tokenExpiryKey = 'token_expiry';

  static String? _accessToken;
  static String? _refreshToken;
  static DateTime? _tokenExpiry;
  static SharedPreferences? _prefs;

  static RefreshTokenHandler? _refreshHandler;
  static Completer<void>? _refreshCompleter;

  static Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();

    await _loadTokens();
  }

  static void setRefreshHandler(RefreshTokenHandler handler) {
    _refreshHandler = handler;
  }

  static Future<void> _loadTokens() async {
    if (_prefs == null) {
      throw ApiException(
        'TokenManager not initialized. Call initialize() first.',
      );
    }

    _accessToken = _prefs!.getString(_accessTokenKey);
    _refreshToken = _prefs!.getString(_refreshTokenKey);

    final expiryTimestamp = _prefs!.getInt(_tokenExpiryKey);
    if (expiryTimestamp != null) {
      _tokenExpiry = DateTime.fromMillisecondsSinceEpoch(expiryTimestamp);
    } else {
      _tokenExpiry = null;
    }
  }

  static Future<bool> hasAccessToken() async {
    if (_accessToken == null) return false;

    if (!_isTokenExpired()) return true;

    if (_refreshHandler == null || _refreshToken == null) return false;

    try {
      await refreshAccessToken();
      return true;
    } catch (_) {
      return false;
    }
  }

  static Future<String?> getAccessToken() async {
    if (_accessToken != null) {
      if (!_isTokenExpired()) {
        return _accessToken;
      } else {
        if (_refreshHandler == null || _refreshToken == null) {
          return null;
        } else {
          try {
            await refreshAccessToken();
            return _accessToken;
          } catch (_) {
            return null;
          }
        }
      }
    }

    return null;
  }

  static bool _isTokenExpired() {
    if (_tokenExpiry == null) return false;
    return _tokenExpiry!.isBefore(DateTime.now());
  }

  static Future<void> refreshAccessToken() {
    if (_refreshToken == null) {
      return Future.error(ApiException('No refresh token available'));
    }

    if (_refreshHandler == null) {
      return Future.error(
        ApiException(
          'No refresh handler configured. Set a RefreshHandler before refreshing.',
        ),
      );
    }

    if (_refreshCompleter != null) {
      return _refreshCompleter!.future;
    }

    final completer = Completer<void>();
    _refreshCompleter = completer;
    _performRefresh(completer);
    return completer.future;
  }

  static Future<void> _performRefresh(Completer<void> completer) async {
    try {
      final RefreshTokenResponse res = await _refreshHandler!(_refreshToken!);

      if (res.accessToken.isEmpty) {
        throw ApiException('Refresh handler returned invalid tokens');
      }

      await setTokens(
        accessToken: res.accessToken,
        refreshToken: res.refreshToken ?? _refreshToken!,
        expiry: res.expiry,
      );

      completer.complete();
    } catch (error, stackTrace) {
      if (!completer.isCompleted) {
        completer.completeError(error, stackTrace);
      }
    } finally {
      if (identical(_refreshCompleter, completer)) {
        _refreshCompleter = null;
      }
    }
  }

  static Future<void> setTokens({
    required String accessToken,
    required String refreshToken,
    DateTime? expiry,
  }) async {
    if (_prefs == null) {
      throw ApiException(
        'TokenManager not initialized. Call initialize() first.',
      );
    }

    final futures = <Future<bool>>[
      _prefs!.setString(_accessTokenKey, accessToken),
      _prefs!.setString(_refreshTokenKey, refreshToken),
    ];

    if (expiry != null) {
      futures.add(_prefs!.setInt(_tokenExpiryKey, expiry.millisecondsSinceEpoch));
    } else {
      futures.add(_prefs!.remove(_tokenExpiryKey));
    }

    await Future.wait(futures);

    _accessToken = accessToken;
    _refreshToken = refreshToken;
    _tokenExpiry = expiry;
  }

  static Future<void> clearTokens() async {
    if (_prefs == null) {
      throw ApiException(
        'TokenManager not initialized. Call initialize() first.',
      );
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
