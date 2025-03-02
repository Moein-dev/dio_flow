import 'package:flutter_test/flutter_test.dart';

import 'package:dio_flow/dio_flow.dart';

void main() {
  group('Error Types', () {
    test('Error type from status code', () {
      expect(ErrorType.fromStatusCode(400), equals(ErrorType.validation));
      expect(ErrorType.fromStatusCode(401), equals(ErrorType.authentication));
      expect(ErrorType.fromStatusCode(403), equals(ErrorType.authorization));
      expect(ErrorType.fromStatusCode(404), equals(ErrorType.notFound));
      expect(ErrorType.fromStatusCode(500), equals(ErrorType.server));
      expect(ErrorType.fromStatusCode(0), equals(ErrorType.unknown));
    });
    
    test('User friendly messages', () {
      expect(ErrorType.network.userFriendlyMessage, contains('Network error'));
      expect(ErrorType.authentication.userFriendlyMessage, contains('Authentication failed'));
      expect(ErrorType.timeout.userFriendlyMessage, contains('timed out'));
    });
  });
  
  group('Failed Response Model', () {
    test('Create with error type', () {
      final model = FailedResponseModel(
        statusCode: 404,
        message: 'Not found',
        logCurl: 'curl example.com',
        errorType: ErrorType.notFound,
      );
      
      expect(model.errorType, equals(ErrorType.notFound));
      expect(model.userFriendlyMessage, contains('not found'));
    });
    
    test('Debug info contains error details', () {
      final model = FailedResponseModel(
        statusCode: 500,
        message: 'Server error',
        logCurl: 'curl example.com',
        errorType: ErrorType.server,
        error: Exception('Test error'),
        stackTrace: StackTrace.current,
      );
      
      final debugInfo = model.debugInfo;
      expect(debugInfo, contains('Status Code: 500'));
      expect(debugInfo, contains('Error Type: server'));
      expect(debugInfo, contains('Message: Server error'));
      expect(debugInfo, contains('Test error'));
      expect(debugInfo, contains('Stack Trace:'));
    });
  });
}
