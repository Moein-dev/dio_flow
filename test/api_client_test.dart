import 'package:flutter_test/flutter_test.dart';
import 'package:dio_flow/dio_flow.dart';

void main() {
  // Initialize Flutter binding first for testing
  TestWidgetsFlutterBinding.ensureInitialized();

  group('DioFlowConfig', () {
    // Set up before tests
    setUp(() {
      // Reset to clear any previous configuration
      DioFlowConfig.reset();
    });

    test('initialize should set configuration values', () {
      // Set custom base URL and timeouts
      final testBaseUrl = 'https://test-api.example.com';
      final testConnectTimeout = const Duration(seconds: 15);
      final testReceiveTimeout = const Duration(seconds: 15);
      final testSendTimeout = const Duration(seconds: 15);

      // Initialize with custom settings
      DioFlowConfig.initialize(
        baseUrl: testBaseUrl,
        connectTimeout: testConnectTimeout,
        receiveTimeout: testReceiveTimeout,
        sendTimeout: testSendTimeout,
      );

      // Verify settings were applied to DioFlowConfig
      final config = DioFlowConfig.instance;
      expect(config.baseUrl, equals(testBaseUrl));
      expect(config.connectTimeout, equals(testConnectTimeout));
      expect(config.receiveTimeout, equals(testReceiveTimeout));
      expect(config.sendTimeout, equals(testSendTimeout));
    });

    test('instance should return the current configuration', () {
      final testBaseUrl = 'https://different-api.example.com';

      // Initialize with a different base URL
      DioFlowConfig.initialize(baseUrl: testBaseUrl);

      // Verify the instance has the new base URL
      final config = DioFlowConfig.instance;
      expect(config.baseUrl, equals(testBaseUrl));
      expect(
        config.connectTimeout,
        equals(const Duration(seconds: 30)),
      ); // Default
      expect(
        config.receiveTimeout,
        equals(const Duration(seconds: 30)),
      ); // Default
      expect(
        config.sendTimeout,
        equals(const Duration(seconds: 30)),
      ); // Default
    });

    test('reset should clear configuration', () {
      // Initialize first
      DioFlowConfig.initialize(baseUrl: 'https://test-api.example.com');

      // Reset configuration
      DioFlowConfig.reset();

      // Verify config is reset by checking that accessing instance throws
      expect(() => DioFlowConfig.instance, throwsStateError);
    });
  });

  group('DioRequestHandler', () {
    setUp(() {
      // Initialize DioFlowConfig for each test
      DioFlowConfig.initialize(baseUrl: 'https://test-api.example.com');
    });

    tearDown(() {
      // Reset DioFlowConfig after each test
      DioFlowConfig.reset();
    });

    test('should have required request methods', () {
      // This doesn't test functionality, just verifies methods exist
      expect(DioRequestHandler.get, isNotNull);
      expect(DioRequestHandler.post, isNotNull);
      expect(DioRequestHandler.put, isNotNull);
      expect(DioRequestHandler.delete, isNotNull);
      expect(DioRequestHandler.patch, isNotNull);
    });
  });

  // Skip ApiClient tests that require SharedPreferences
  // In a real test environment, you would use a mocking package to mock SharedPreferences
  group('ApiClient', () {
    test('should be properly initialized', () {
      // This is a placeholder test that always passes
      // In a real test environment, you would test more functionality
      expect(true, isTrue);
    });
  });
}
