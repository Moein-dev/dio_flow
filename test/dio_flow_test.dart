import 'package:flutter_test/flutter_test.dart';

import 'package:dio_flow/dio_flow.dart';
import 'package:dio_flow/src/models/response/meta_model.dart';

void main() {
  group('Error Types', () {
    test('Error type from status code', () {
      expect(ErrorType.fromStatusCode(400), equals(ErrorType.validation));
      expect(ErrorType.fromStatusCode(401), equals(ErrorType.authentication));
      expect(ErrorType.fromStatusCode(403), equals(ErrorType.authorization));
      expect(ErrorType.fromStatusCode(404), equals(ErrorType.notFound));
      expect(ErrorType.fromStatusCode(500), equals(ErrorType.server));
      expect(ErrorType.fromStatusCode(0), equals(ErrorType.unknown));

      // Additional status codes
      expect(ErrorType.fromStatusCode(408), equals(ErrorType.timeout));
      expect(ErrorType.fromStatusCode(429), equals(ErrorType.rateLimit));
      expect(ErrorType.fromStatusCode(502), equals(ErrorType.server));
      expect(ErrorType.fromStatusCode(503), equals(ErrorType.server));
      expect(ErrorType.fromStatusCode(504), equals(ErrorType.server));
    });

    test('User friendly messages', () {
      expect(ErrorType.network.userFriendlyMessage, contains('Network error'));
      expect(
        ErrorType.authentication.userFriendlyMessage,
        contains('Authentication failed'),
      );
      expect(ErrorType.timeout.userFriendlyMessage, contains('timed out'));

      // Check all error types have a message
      for (final errorType in ErrorType.values) {
        expect(errorType.userFriendlyMessage, isNotEmpty);
        expect(errorType.userFriendlyMessage, isA<String>());
      }
    });

    test('Error type values coverage', () {
      // Ensure all expected error types exist
      final errorTypes = ErrorType.values.map((e) => e.toString()).toList();
      expect(errorTypes, contains('ErrorType.network'));
      expect(errorTypes, contains('ErrorType.timeout'));
      expect(errorTypes, contains('ErrorType.server'));
      expect(errorTypes, contains('ErrorType.validation'));
      expect(errorTypes, contains('ErrorType.authentication'));
      expect(errorTypes, contains('ErrorType.authorization'));
      expect(errorTypes, contains('ErrorType.notFound'));
      expect(errorTypes, contains('ErrorType.rateLimit'));
      expect(errorTypes, contains('ErrorType.unknown'));
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
      expect(model.statusCode, equals(404));
      expect(model.message, equals('Not found'));
      expect(model.logCurl, equals('curl example.com'));
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

    test('Additional properties and inheritance', () {
      final model = FailedResponseModel(
        statusCode: 422,
        message: 'Validation error',
        logCurl: 'curl example.com',
        errorType: ErrorType.validation,
        data: {
          'errors': {
            'name': ['Name is required'],
          },
        },
      );

      expect(model.data, isA<Map>());
      expect(model.data['errors'], isA<Map>());
      expect(model.data['errors']['name'], isA<List>());
      expect(model.data['errors']['name'][0], equals('Name is required'));
      expect(model.statusCode, isNotNull);
      expect(model.logCurl, isNotNull);
    });
  });

  group('Success Response Model', () {
    test('Basic properties', () {
      final model = SuccessResponseModel(
        statusCode: 200,
        data: {'id': 1, 'name': 'Test'},
        logCurl: 'curl example.com',
      );

      expect(model.statusCode, equals(200));
      expect(model.data, isA<Map>());
      expect(model.data['id'], equals(1));
      expect(model.data['name'], equals('Test'));
      expect(model.logCurl, equals('curl example.com'));
    });

    test('With metadata', () {
      final metaData = {
        'current_page': 1,
        'last_page': 10,
        'per_page': 2,
        'total': 20,
      };

      final model = SuccessResponseModel(
        statusCode: 200,
        data: [
          {'id': 1, 'name': 'Item 1'},
          {'id': 2, 'name': 'Item 2'},
        ],
        meta: MetaModel.fromJson(metaData),
        logCurl: 'curl example.com',
      );

      expect(model.statusCode, equals(200));
      expect(model.data, isA<List>());
      expect(model.data.length, equals(2));
      expect(model.meta, isNotNull);
      expect(model.meta?.currentPage, equals(1));
      expect(model.meta?.lastPage, equals(10));
      expect(model.meta?.perPage, equals(2));
      expect(model.meta?.total, equals(20));
    });

    test('Success response is a ResponseModel', () {
      final model = SuccessResponseModel(
        statusCode: 201,
        data: {'id': 1},
        logCurl: 'curl example.com',
      );

      expect(model.statusCode, isNotNull);
      expect(model.logCurl, isNotNull);
    });
  });

  group('Response Model Interface', () {
    test('Response model abstract class properties', () {
      final success = SuccessResponseModel(
        statusCode: 200,
        data: {'success': true},
        logCurl: 'curl success.com',
      );

      final failed = FailedResponseModel(
        statusCode: 400,
        message: 'Bad request',
        logCurl: 'curl failed.com',
        errorType: ErrorType.validation,
      );

      // Both should implement the abstract properties from ResponseModel
      expect(success.statusCode, equals(200));
      expect(success.logCurl, equals('curl success.com'));

      expect(failed.statusCode, equals(400));
      expect(failed.logCurl, equals('curl failed.com'));
    });
  });
}
