import 'package:dio_flow/src/models/response/response_model.dart';

import '../models/response/error_type.dart';

/// Mock implementation for DioFlow to support testing without real HTTP calls.
///
/// This class allows developers to mock API responses during testing,
/// making unit tests faster and more reliable.
class MockDioFlow {
  static bool _isMockEnabled = false;
  static final Map<String, MockResponse> _mockResponses = {};
  static final Map<String, List<MockResponse>> _mockResponseQueues = {};

  /// Enables mock mode for testing.
  ///
  /// When mock mode is enabled, all HTTP requests will return mocked responses
  /// instead of making actual network calls.
  static void enableMockMode() {
    _isMockEnabled = true;
  }

  /// Disables mock mode and returns to normal HTTP behavior.
  static void disableMockMode() {
    _isMockEnabled = false;
    clearAllMocks();
  }

  /// Checks if mock mode is currently enabled.
  static bool get isMockEnabled => _isMockEnabled;

  /// Registers a mock response for a specific endpoint.
  ///
  /// Parameters:
  ///   endpoint - The API endpoint to mock (e.g., 'users', '/api/users')
  ///   response - The mock response to return
  ///   method - HTTP method (defaults to 'GET')
  ///
  /// Example:
  /// ```dart
  /// MockDioFlow.mockResponse(
  ///   'users',
  ///   MockResponse.success({'users': []}),
  /// );
  /// ```
  static void mockResponse(
    String endpoint,
    MockResponse response, {
    String method = 'GET',
  }) {
    final key = _createKey(endpoint, method);
    _mockResponses[key] = response;
  }

  /// Registers multiple mock responses for an endpoint that will be returned in sequence.
  ///
  /// This is useful for testing scenarios where the same endpoint should return
  /// different responses on subsequent calls.
  ///
  /// Parameters:
  ///   endpoint - The API endpoint to mock
  ///   responses - List of mock responses to return in order
  ///   method - HTTP method (defaults to 'GET')
  static void mockResponseQueue(
    String endpoint,
    List<MockResponse> responses, {
    String method = 'GET',
  }) {
    final key = _createKey(endpoint, method);
    _mockResponseQueues[key] = List.from(responses);
  }

  /// Gets the mock response for a specific endpoint and method.
  ///
  /// Returns null if no mock is registered for the given endpoint/method.
  static MockResponse? getMockResponse(String endpoint, String method) {
    final key = _createKey(endpoint, method);

    // Check if there's a queue of responses
    if (_mockResponseQueues.containsKey(key) &&
        _mockResponseQueues[key]!.isNotEmpty) {
      return _mockResponseQueues[key]!.removeAt(0);
    }

    // Check for single response
    return _mockResponses[key];
  }

  /// Clears all registered mock responses.
  static void clearAllMocks() {
    _mockResponses.clear();
    _mockResponseQueues.clear();
  }

  /// Clears mock responses for a specific endpoint.
  static void clearMock(String endpoint, {String method = 'GET'}) {
    final key = _createKey(endpoint, method);
    _mockResponses.remove(key);
    _mockResponseQueues.remove(key);
  }

  /// Creates a unique key for endpoint and method combination.
  static String _createKey(String endpoint, String method) {
    return '${method.toUpperCase()}:$endpoint';
  }

  /// Converts a MockResponse to a ResponseModel.
  static ResponseModel convertToResponseModel(MockResponse mockResponse) {
    if (mockResponse.isSuccess) {
      return SuccessResponseModel(
        data: mockResponse.data,
        statusCode: mockResponse.statusCode,
        message: mockResponse.message,
        logCurl: 'MOCK REQUEST',
      );
    } else {
      return FailedResponseModel(
        data: mockResponse.data,
        statusCode: mockResponse.statusCode,
        message: mockResponse.message ?? 'Mock error',
        logCurl: 'MOCK REQUEST',
        errorType: mockResponse.errorType,
      );
    }
  }
}

/// Represents a mock HTTP response for testing purposes.
class MockResponse {
  /// The response data.
  final dynamic data;

  /// The HTTP status code.
  final int statusCode;

  /// Optional response message.
  final String? message;

  /// Whether this represents a successful response.
  final bool isSuccess;

  /// The type of error (only for failed responses).
  final ErrorType? errorType;

  /// Delay to simulate network latency (optional).
  final Duration? delay;

  MockResponse._({
    required this.data,
    required this.statusCode,
    required this.isSuccess,
    this.message,
    this.errorType,
    this.delay,
  });

  /// Creates a successful mock response.
  ///
  /// Parameters:
  ///   data - The response data
  ///   statusCode - HTTP status code (defaults to 200)
  ///   message - Optional success message
  ///   delay - Optional delay to simulate network latency
  factory MockResponse.success(
    dynamic data, {
    int statusCode = 200,
    String? message,
    Duration? delay,
  }) {
    return MockResponse._(
      data: data,
      statusCode: statusCode,
      message: message,
      isSuccess: true,
      delay: delay,
    );
  }

  /// Creates a failed mock response.
  ///
  /// Parameters:
  ///   message - Error message
  ///   statusCode - HTTP status code (defaults to 400)
  ///   data - Optional error data
  ///   errorType - Type of error (auto-determined from status code if not provided)
  ///   delay - Optional delay to simulate network latency
  factory MockResponse.failure(
    String message, {
    int statusCode = 400,
    dynamic data,
    ErrorType? errorType,
    Duration? delay,
  }) {
    return MockResponse._(
      data: data,
      statusCode: statusCode,
      message: message,
      isSuccess: false,
      errorType: errorType ?? ErrorType.fromStatusCode(statusCode),
      delay: delay,
    );
  }

  /// Creates a network error mock response.
  factory MockResponse.networkError({
    String message = 'Network error',
    Duration? delay,
  }) {
    return MockResponse.failure(
      message,
      statusCode: 0,
      errorType: ErrorType.network,
      delay: delay,
    );
  }

  /// Creates a timeout error mock response.
  factory MockResponse.timeout({
    String message = 'Request timeout',
    Duration? delay,
  }) {
    return MockResponse.failure(
      message,
      statusCode: 408,
      errorType: ErrorType.timeout,
      delay: delay,
    );
  }

  /// Simulates the network delay if specified.
  Future<void> simulateDelay() async {
    if (delay != null) {
      await Future.delayed(delay!);
    }
  }
}
