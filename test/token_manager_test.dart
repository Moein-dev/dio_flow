import 'package:flutter_test/flutter_test.dart';
import 'package:dio_flow/dio_flow.dart';

void main() {
  group('TokenManager', () {
    test('TokenManager class exists and has required methods', () {
      // Test that the TokenManager class exists and has the expected static methods
      expect(TokenManager.initialize, isA<Function>());
      expect(TokenManager.setTokens, isA<Function>());
      expect(TokenManager.clearTokens, isA<Function>());
      expect(TokenManager.getAccessToken, isA<Function>());
      expect(TokenManager.hasAccessToken, isA<Function>());
      expect(TokenManager.setRefreshHandler, isA<Function>());
    });

    test('RefreshTokenResponse model should work correctly', () {
      final now = DateTime.now();
      final expiry = now.add(const Duration(hours: 1));

      final response = RefreshTokenResponse(
        accessToken: 'new_access_token',
        refreshToken: 'new_refresh_token',
        expiry: expiry,
      );

      expect(response.accessToken, equals('new_access_token'));
      expect(response.refreshToken, equals('new_refresh_token'));
      expect(response.expiry, equals(expiry));
    });

    test('ApiException should work correctly', () {
      final exception = ApiException('Test error message');

      expect(exception.message, equals('Test error message'));
      expect(exception.statusCode, equals(500)); // Default status code
      expect(exception.toString(), contains('Test error message'));
      expect(exception.toString(), contains('Status: 500'));
    });

    test('ApiException with custom status code', () {
      final exception = ApiException('Custom error', statusCode: 404);

      expect(exception.message, equals('Custom error'));
      expect(exception.statusCode, equals(404));
      expect(exception.toString(), contains('Custom error'));
      expect(exception.toString(), contains('Status: 404'));
    });
  });
}
