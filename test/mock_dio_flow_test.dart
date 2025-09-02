import 'package:flutter_test/flutter_test.dart';
import 'package:dio_flow/dio_flow.dart';

void main() {
  group('MockDioFlow', () {
    setUp(() {
      MockDioFlow.disableMockMode();
    });

    tearDown(() {
      MockDioFlow.disableMockMode();
    });

    test('should enable and disable mock mode', () {
      expect(MockDioFlow.isMockEnabled, isFalse);

      MockDioFlow.enableMockMode();
      expect(MockDioFlow.isMockEnabled, isTrue);

      MockDioFlow.disableMockMode();
      expect(MockDioFlow.isMockEnabled, isFalse);
    });

    test('should register and retrieve mock responses', () {
      final mockResponse = MockResponse.success({'message': 'Hello World'});

      MockDioFlow.mockResponse('test-endpoint', mockResponse);

      final retrieved = MockDioFlow.getMockResponse('test-endpoint', 'GET');
      expect(retrieved, isNotNull);
      expect(retrieved!.data['message'], equals('Hello World'));
      expect(retrieved.isSuccess, isTrue);
    });

    test('should handle mock response queue', () {
      final responses = [
        MockResponse.success({'count': 1}),
        MockResponse.success({'count': 2}),
        MockResponse.success({'count': 3}),
      ];

      MockDioFlow.mockResponseQueue('counter', responses);

      // First call
      final first = MockDioFlow.getMockResponse('counter', 'GET');
      expect(first!.data['count'], equals(1));

      // Second call
      final second = MockDioFlow.getMockResponse('counter', 'GET');
      expect(second!.data['count'], equals(2));

      // Third call
      final third = MockDioFlow.getMockResponse('counter', 'GET');
      expect(third!.data['count'], equals(3));

      // Fourth call should return null (queue exhausted)
      final fourth = MockDioFlow.getMockResponse('counter', 'GET');
      expect(fourth, isNull);
    });

    test('should clear mocks', () {
      MockDioFlow.mockResponse('test', MockResponse.success({}));
      expect(MockDioFlow.getMockResponse('test', 'GET'), isNotNull);

      MockDioFlow.clearMock('test');
      expect(MockDioFlow.getMockResponse('test', 'GET'), isNull);
    });

    test('should clear all mocks', () {
      MockDioFlow.mockResponse('test1', MockResponse.success({}));
      MockDioFlow.mockResponse('test2', MockResponse.success({}));

      MockDioFlow.clearAllMocks();

      expect(MockDioFlow.getMockResponse('test1', 'GET'), isNull);
      expect(MockDioFlow.getMockResponse('test2', 'GET'), isNull);
    });
  });

  group('MockResponse', () {
    test('should create success response', () {
      final response = MockResponse.success(
        {'id': 1, 'name': 'Test'},
        statusCode: 201,
        message: 'Created successfully',
      );

      expect(response.isSuccess, isTrue);
      expect(response.statusCode, equals(201));
      expect(response.message, equals('Created successfully'));
      expect(response.data['id'], equals(1));
      expect(response.data['name'], equals('Test'));
    });

    test('should create failure response', () {
      final response = MockResponse.failure(
        'Validation failed',
        statusCode: 422,
        data: {
          'errors': ['Name is required'],
        },
      );

      expect(response.isSuccess, isFalse);
      expect(response.statusCode, equals(422));
      expect(response.message, equals('Validation failed'));
      expect(response.errorType, equals(ErrorType.validation));
      expect(response.data['errors'], isA<List>());
    });

    test('should create network error response', () {
      final response = MockResponse.networkError();

      expect(response.isSuccess, isFalse);
      expect(response.statusCode, equals(0));
      expect(response.errorType, equals(ErrorType.network));
      expect(response.message, equals('Network error'));
    });

    test('should create timeout error response', () {
      final response = MockResponse.timeout();

      expect(response.isSuccess, isFalse);
      expect(response.statusCode, equals(408));
      expect(response.errorType, equals(ErrorType.timeout));
      expect(response.message, equals('Request timeout'));
    });

    test('should simulate delay', () async {
      final response = MockResponse.success(
        {},
        delay: const Duration(milliseconds: 100),
      );

      final stopwatch = Stopwatch()..start();
      await response.simulateDelay();
      stopwatch.stop();

      expect(stopwatch.elapsedMilliseconds, greaterThanOrEqualTo(90));
    });
  });

  group('MockDioFlow conversion', () {
    test('should convert success mock response to ResponseModel', () {
      final mockResponse = MockResponse.success({
        'message': 'Success',
      }, statusCode: 200);

      final responseModel = MockDioFlow.convertToResponseModel(mockResponse);

      expect(responseModel, isA<SuccessResponseModel>());
      expect(responseModel.statusCode, equals(200));
      expect(responseModel.data['message'], equals('Success'));
      expect(responseModel.logCurl, equals('MOCK REQUEST'));
    });

    test('should convert failure mock response to ResponseModel', () {
      final mockResponse = MockResponse.failure(
        'Error occurred',
        statusCode: 400,
        errorType: ErrorType.validation,
      );

      final responseModel = MockDioFlow.convertToResponseModel(mockResponse);

      expect(responseModel, isA<FailedResponseModel>());
      expect(responseModel.statusCode, equals(400));
      expect(
        (responseModel as FailedResponseModel).message,
        equals('Error occurred'),
      );
      expect(responseModel.errorType, equals(ErrorType.validation));
      expect(responseModel.logCurl, equals('MOCK REQUEST'));
    });
  });
}
