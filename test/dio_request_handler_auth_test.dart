import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio_flow/dio_flow.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  
  SharedPreferences.setMockInitialValues({});

  group('TokenManager - Token Refresh Flow', () {
    setUp(() async {
      await TokenManager.initialize();
      await TokenManager.clearTokens();
    });

    tearDown(() async {
      await TokenManager.clearTokens();
    });

    test('refreshAccessToken should call refresh handler and update tokens', () async {
      final now = DateTime.now();
      final expiry = now.add(const Duration(hours: 1));
      final newExpiry = now.add(const Duration(hours: 2));

      await TokenManager.setTokens(
        accessToken: 'old_access_token',
        refreshToken: 'old_refresh_token',
        expiry: expiry,
      );

      TokenManager.setRefreshHandler((refreshToken) async {
        expect(refreshToken, equals('old_refresh_token'));
        return RefreshTokenResponse(
          accessToken: 'new_access_token',
          refreshToken: 'new_refresh_token',
          expiry: newExpiry,
        );
      });

      await TokenManager.refreshAccessToken();

      final newToken = await TokenManager.getAccessToken();
      expect(newToken, equals('new_access_token'));
    });

    test('refreshAccessToken should prevent concurrent refresh calls', () async {
      final now = DateTime.now();
      final expiry = now.add(const Duration(hours: 1));

      await TokenManager.setTokens(
        accessToken: 'old_access_token',
        refreshToken: 'refresh_token',
        expiry: expiry,
      );

      var callCount = 0;
      TokenManager.setRefreshHandler((refreshToken) async {
        callCount++;
        await Future.delayed(const Duration(milliseconds: 100));
        return RefreshTokenResponse(
          accessToken: 'new_access_token_$callCount',
          refreshToken: 'refresh_token',
          expiry: now.add(const Duration(hours: 2)),
        );
      });

      final futures = [
        TokenManager.refreshAccessToken(),
        TokenManager.refreshAccessToken(),
        TokenManager.refreshAccessToken(),
      ];

      await Future.wait(futures);

      expect(callCount, equals(1));
    });

    test('getAccessToken should refresh when token is expired', () async {
      final now = DateTime.now();
      final pastExpiry = now.subtract(const Duration(hours: 1));
      final futureExpiry = now.add(const Duration(hours: 1));

      await TokenManager.setTokens(
        accessToken: 'expired_token',
        refreshToken: 'refresh_token',
        expiry: pastExpiry,
      );

      TokenManager.setRefreshHandler((refreshToken) async {
        return RefreshTokenResponse(
          accessToken: 'fresh_access_token',
          refreshToken: 'refresh_token',
          expiry: futureExpiry,
        );
      });

      final token = await TokenManager.getAccessToken();
      expect(token, equals('fresh_access_token'));
    });

    test('hasAccessToken should return true after successful refresh', () async {
      final now = DateTime.now();
      final pastExpiry = now.subtract(const Duration(hours: 1));
      final futureExpiry = now.add(const Duration(hours: 1));

      await TokenManager.setTokens(
        accessToken: 'expired_token',
        refreshToken: 'refresh_token',
        expiry: pastExpiry,
      );

      TokenManager.setRefreshHandler((refreshToken) async {
        return RefreshTokenResponse(
          accessToken: 'fresh_token',
          refreshToken: 'refresh_token',
          expiry: futureExpiry,
        );
      });

      final hasToken = await TokenManager.hasAccessToken();
      expect(hasToken, equals(true));
    });

    test('refreshAccessToken should throw when no refresh token available', () async {
      await TokenManager.clearTokens();
      TokenManager.setRefreshHandler((refreshToken) async {
        return RefreshTokenResponse(
          accessToken: 'token',
          refreshToken: 'token',
          expiry: DateTime.now().add(const Duration(hours: 1)),
        );
      });

      expect(
        TokenManager.refreshAccessToken(),
        throwsA(isA<ApiException>()),
      );
    });

    test('refreshAccessToken should throw when no handler configured', () async {
      final now = DateTime.now();
      await TokenManager.setTokens(
        accessToken: 'token',
        refreshToken: 'refresh_token',
        expiry: now.add(const Duration(hours: 1)),
      );

      expect(
        TokenManager.refreshAccessToken(),
        throwsA(isA<ApiException>()),
      );
    });

    test('refreshAccessToken should throw on handler error and propagate', () async {
      final now = DateTime.now();
      await TokenManager.setTokens(
        accessToken: 'token',
        refreshToken: 'refresh_token',
        expiry: now.add(const Duration(hours: 1)),
      );

      TokenManager.setRefreshHandler((refreshToken) async {
        throw ApiException('Refresh failed', statusCode: 401);
      });

      expect(
        TokenManager.refreshAccessToken(),
        throwsA(isA<ApiException>()),
      );
    });

    test('getAccessToken should return null when refresh fails', () async {
      final now = DateTime.now();
      final pastExpiry = now.subtract(const Duration(hours: 1));

      await TokenManager.setTokens(
        accessToken: 'expired_token',
        refreshToken: 'refresh_token',
        expiry: pastExpiry,
      );

      TokenManager.setRefreshHandler((refreshToken) async {
        throw ApiException('Refresh failed', statusCode: 401);
      });

      final token = await TokenManager.getAccessToken();
      expect(token, isNull);
    });

    test('hasAccessToken should return false when refresh fails', () async {
      final now = DateTime.now();
      final pastExpiry = now.subtract(const Duration(hours: 1));

      await TokenManager.setTokens(
        accessToken: 'expired_token',
        refreshToken: 'refresh_token',
        expiry: pastExpiry,
      );

      TokenManager.setRefreshHandler((refreshToken) async {
        throw ApiException('Refresh failed', statusCode: 401);
      });

      final hasToken = await TokenManager.hasAccessToken();
      expect(hasToken, equals(false));
    });

    test('getAccessToken should return token without refresh when not expired', () async {
      final now = DateTime.now();
      final futureExpiry = now.add(const Duration(hours: 1));

      await TokenManager.setTokens(
        accessToken: 'valid_token',
        refreshToken: 'refresh_token',
        expiry: futureExpiry,
      );

      var handlerCalled = false;
      TokenManager.setRefreshHandler((refreshToken) async {
        handlerCalled = true;
        return RefreshTokenResponse(
          accessToken: 'new_token',
          refreshToken: 'refresh_token',
          expiry: futureExpiry,
        );
      });

      final token = await TokenManager.getAccessToken();
      expect(token, equals('valid_token'));
      expect(handlerCalled, equals(false));
    });

    test('refreshAccessToken should validate returned tokens', () async {
      final now = DateTime.now();
      await TokenManager.setTokens(
        accessToken: 'token',
        refreshToken: 'refresh_token',
        expiry: now.add(const Duration(hours: 1)),
      );

      TokenManager.setRefreshHandler((refreshToken) async {
        return RefreshTokenResponse(
          accessToken: '',
          refreshToken: 'new_refresh',
          expiry: now.add(const Duration(hours: 2)),
        );
      });

      expect(
        TokenManager.refreshAccessToken(),
        throwsA(isA<ApiException>()),
      );
    });

    test('setTokens should persist and load tokens correctly', () async {
      final now = DateTime.now();
      final expiry = now.add(const Duration(hours: 1));

      await TokenManager.setTokens(
        accessToken: 'persisted_access',
        refreshToken: 'persisted_refresh',
        expiry: expiry,
      );

      final token = await TokenManager.getAccessToken();
      expect(token, equals('persisted_access'));
    });
  });
}