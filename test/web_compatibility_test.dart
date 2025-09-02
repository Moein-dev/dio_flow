import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:dio_flow/dio_flow.dart';

void main() {
  group('Web Compatibility Tests', () {
    setUpAll(() {
      // Initialize DioFlow for testing
      DioFlowConfig.initialize(
        baseUrl: 'https://jsonplaceholder.typicode.com',
        connectTimeout: const Duration(seconds: 5),
        receiveTimeout: const Duration(seconds: 3),
        sendTimeout: const Duration(seconds: 3),
      );
    });

    test('NetworkChecker should work without dart:io', () async {
      // This test ensures NetworkChecker doesn't use dart:io
      // which would break web compatibility
      final hasConnection = await NetworkChecker.hasConnection();

      // The result can be true or false depending on network,
      // but it should not throw an error on web
      expect(hasConnection, isA<bool>());
    });

    test('FileHandler should handle web platform gracefully', () async {
      // Test that FileHandler methods return appropriate errors on web
      // instead of crashing due to dart:io usage

      final result = await FileHandler.uploadFile(
        'test-endpoint',
        null, // This would be a File object on mobile/desktop
      );

      // This should return a FailedResponseModel with appropriate message
      expect(result, isA<FailedResponseModel>());

      final failedResult = result as FailedResponseModel;
      expect(failedResult.message, contains('Invalid file'));
    });

    test('Basic API requests should work on web', () async {
      // Register a test endpoint
      EndpointProvider.instance.register('test-posts', '/posts');

      // This should work on all platforms including web
      final response = await DioRequestHandler.get(
        'test-posts',
        parameters: {'_limit': 1},
      );

      // The response should be successful (assuming network is available)
      // or at least not crash due to platform incompatibility
      expect(response, isA<ResponseModel>());
    });

    test('JsonUtils should work on web', () {
      // Test JSON utilities which should be platform-independent
      final testJson = '{"name": "test", "nested": {"value": 42}}';
      final parsed = JsonUtils.tryParseJson(testJson);

      expect(parsed, isNotNull);
      expect(parsed!['name'], equals('test'));

      final nestedValue = JsonUtils.getNestedValue(parsed, 'nested.value', 0);
      expect(nestedValue, equals(42));
    });

    test('Bytes-based file operations should work on web', () async {
      // Test that bytes-based operations work on web
      final testBytes = Uint8List.fromList([1, 2, 3, 4, 5]);

      final result = await FileHandler.uploadBytes(
        'test-upload',
        testBytes,
        'test.bin',
      );

      // This should work on web (though the endpoint might not exist)
      expect(result, isA<ResponseModel>());
    });
  });
}
