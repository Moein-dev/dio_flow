import 'package:flutter_test/flutter_test.dart';
import 'package:dio_flow/dio_flow.dart';
import 'package:dio_flow/src/models/api_exception.dart';

void main() {
  group('TokenManager', () {
    // Clear tokens before each test to ensure a clean state
    setUp(() {
      TokenManager.clearTokens();
    });

    test('setTokens should set tokens correctly', () async {
      final now = DateTime.now();
      final expiry = now.add(const Duration(hours: 1));

      TokenManager.setTokens(
        accessToken: 'test_access_token',
        refreshToken: 'test_refresh_token',
        expiry: expiry,
      );

      // Verify tokens were set by retrieving the access token
      final accessToken = await TokenManager.getAccessToken();
      expect(accessToken, equals('test_access_token'));
    });

    test('clearTokens should remove all tokens', () async {
      // Set tokens first
      TokenManager.setTokens(
        accessToken: 'test_access_token',
        refreshToken: 'test_refresh_token',
        expiry: DateTime.now().add(const Duration(hours: 1)),
      );

      // Clear tokens
      TokenManager.clearTokens();

      // Try to get access token, which should fail or return null
      // Note: This test assumes there's no autoRefresh mechanism or it's not implemented
      try {
        final accessToken = await TokenManager.getAccessToken();
        expect(accessToken, isNull);
      } catch (e) {
        // If getAccessToken throws an exception when tokens are cleared, that's also valid
        expect(e, isA<ApiException>());
      }
    });

    test(
      'getAccessToken should return null or throw when no tokens are set',
      () async {
        // No tokens have been set at this point
        try {
          final accessToken = await TokenManager.getAccessToken();
          expect(accessToken, isNull);
        } catch (e) {
          // If getAccessToken throws an exception when no tokens are set, that's also valid
          expect(e, isA<ApiException>());
        }
      },
    );

    test(
      'getAccessToken should return token when valid token is set',
      () async {
        // Set a token with future expiry
        TokenManager.setTokens(
          accessToken: 'valid_token',
          refreshToken: 'refresh_token',
          expiry: DateTime.now().add(const Duration(hours: 1)),
        );

        final accessToken = await TokenManager.getAccessToken();
        expect(accessToken, equals('valid_token'));
      },
    );

    // This test is marked as skip until refresh logic is implemented
    test(
      'getAccessToken should refresh when token is expired',
      () async {
        // Set an expired token
        TokenManager.setTokens(
          accessToken: 'expired_token',
          refreshToken: 'refresh_token',
          expiry: DateTime.now().subtract(const Duration(hours: 1)),
        );

        // Attempt to get the token - this would trigger a refresh
        // but since refresh isn't implemented, it should throw
        expect(
          () => TokenManager.getAccessToken(),
          throwsA(isA<ApiException>()),
        );
      },
      skip: 'Token refresh logic is not fully implemented',
    );
  });
}
