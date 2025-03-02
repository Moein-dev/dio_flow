import 'package:flutter_test/flutter_test.dart';
import 'package:dio_flow/dio_flow.dart';

void main() {
  group('JsonUtils - Parsing', () {
    test('tryParseJson should parse valid JSON', () {
      final validJson = '{"name": "John", "age": 30}';
      final result = JsonUtils.tryParseJson(validJson);

      expect(result, isNotNull);
      expect(result, isA<Map<String, dynamic>>());
      expect(result?['name'], equals('John'));
      expect(result?['age'], equals(30));
    });

    test('tryParseJson should return empty map for null or empty string', () {
      final emptyResult = JsonUtils.tryParseJson('');
      final nullResult = JsonUtils.tryParseJson(null);

      expect(emptyResult, isNotNull);
      expect(emptyResult, isA<Map<String, dynamic>>());
      expect(emptyResult?.isEmpty, isTrue);

      expect(nullResult, isNotNull);
      expect(nullResult, isA<Map<String, dynamic>>());
      expect(nullResult?.isEmpty, isTrue);
    });

    test('tryParseJson should return null for invalid JSON', () {
      final invalidJson = '{name: "John", age: 30}'; // Missing quotes
      final result = JsonUtils.tryParseJson(invalidJson);

      expect(result, isNull);
    });

    test('tryEncodeJson should encode valid objects to JSON strings', () {
      final map = {'name': 'John', 'age': 30};
      final result = JsonUtils.tryEncodeJson(map);

      expect(result, contains('"name":"John"'));
      expect(result, contains('"age":30'));
    });

    test('tryEncodeJson should handle pretty printing', () {
      final map = {
        'name': 'John',
        'nested': {'key': 'value'},
      };
      final result = JsonUtils.tryEncodeJson(map, pretty: true);

      expect(result, contains('\n'));
      expect(result, contains('  '));
    });

    test('tryEncodeJson should return empty string for null inputs', () {
      final result = JsonUtils.tryEncodeJson(null);
      expect(result, equals(''));
    });
  });

  group('JsonUtils - Nested Values', () {
    final testData = {
      'user': {
        'profile': {
          'name': 'John Doe',
          'details': {
            'age': 30,
            'location': {'city': 'New York', 'country': 'USA'},
          },
        },
      },
    };

    test('getNestedValue should retrieve deeply nested values', () {
      expect(
        JsonUtils.getNestedValue(testData, 'user.profile.name', ''),
        equals('John Doe'),
      );
      expect(
        JsonUtils.getNestedValue(testData, 'user.profile.details.age', 0),
        equals(30),
      );
      expect(
        JsonUtils.getNestedValue(
          testData,
          'user.profile.details.location.city',
          '',
        ),
        equals('New York'),
      );
    });

    test('getNestedValue should return default for missing paths', () {
      expect(
        JsonUtils.getNestedValue(testData, 'user.profile.email', 'N/A'),
        equals('N/A'),
      );
      expect(
        JsonUtils.getNestedValue(testData, 'user.settings', {}),
        equals({}),
      );
    });

    test('getNestedValue should handle lists in paths', () {
      final dataWithList = {
        'posts': [
          {'id': 1, 'title': 'First Post'},
          {'id': 2, 'title': 'Second Post'},
        ],
      };

      // The current implementation doesn't support list indices in paths directly
      // We can access the list, but not a specific item using dot notation
      final posts = JsonUtils.getNestedValue(dataWithList, 'posts', []);
      expect(posts.length, equals(2));
      expect((posts[0] as Map)['title'], equals('First Post'));
    });
  });

  group('JsonUtils - Key Normalization', () {
    test('normalizeJsonKeys should convert keys to lowercase by default', () {
      final input = {
        'FIRST_NAME': 'John',
        'Last-Name': 'Doe',
        'Email_Address': 'john@example.com',
      };

      final result = JsonUtils.normalizeJsonKeys(input);

      expect(result['first_name'], equals('John'));
      expect(result['last-name'], equals('Doe'));
      expect(result['email_address'], equals('john@example.com'));
    });

    test('normalizeJsonKeys should handle nested objects', () {
      final input = {
        'USER': {
          'PROFILE': {'FULL_NAME': 'John Doe'},
        },
      };

      final result = JsonUtils.normalizeJsonKeys(input);

      expect(result['user']['profile']['full_name'], equals('John Doe'));
    });

    test('normalizeJsonKeys should handle arrays', () {
      final input = {
        'USERS': [
          {'FIRST_NAME': 'John', 'LAST_NAME': 'Doe'},
          {'FIRST_NAME': 'Jane', 'LAST_NAME': 'Smith'},
        ],
      };

      final result = JsonUtils.normalizeJsonKeys(input);

      expect(result['users'][0]['first_name'], equals('John'));
      expect(result['users'][1]['last_name'], equals('Smith'));
    });

    test('normalizeJsonKeys should respect keysToLowerCase parameter', () {
      final input = {'FirstName': 'John', 'LAST_NAME': 'Doe'};

      final result = JsonUtils.normalizeJsonKeys(input, keysToLowerCase: false);

      // Since keysToLowerCase is false, keys should not be transformed
      expect(result['FirstName'], equals('John'));
      expect(result['LAST_NAME'], equals('Doe'));
    });
  });

  group('JsonUtils - Multiple Nested Values', () {
    test('can retrieve multiple nested values manually', () {
      final data = {
        'user': {'name': 'John', 'email': 'john@example.com'},
        'posts': [
          {'id': 1, 'title': 'First Post'},
          {'id': 2, 'title': 'Second Post'},
        ],
        'settings': {'notifications': true},
      };

      // Manually get each nested value
      final userName = JsonUtils.getNestedValue(data, 'user.name', '');
      final userEmail = JsonUtils.getNestedValue(data, 'user.email', '');
      final notificationSetting = JsonUtils.getNestedValue(
        data,
        'settings.notifications',
        false,
      );
      final userAge = JsonUtils.getNestedValue(data, 'user.age', null);

      // Verify individual values
      expect(userName, equals('John'));
      expect(userEmail, equals('john@example.com'));
      expect(notificationSetting, isTrue);
      expect(userAge, isNull);

      // We can't access list items by index using the current getNestedValue implementation
      final posts = JsonUtils.getNestedValue(data, 'posts', []);
      expect(posts.length, equals(2));
      expect((posts[0] as Map)['title'], equals('First Post'));
      expect((posts[1] as Map)['likes'], isNull);
    });
  });
}
