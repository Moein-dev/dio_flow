import 'package:flutter_test/flutter_test.dart';
import 'package:dio_flow/dio_flow.dart';

void main() {
  group('GraphQLHandler', () {
    test('should have required static methods', () {
      expect(GraphQLHandler.query, isA<Function>());
      expect(GraphQLHandler.mutation, isA<Function>());
      expect(GraphQLHandler.subscription, isA<Function>());
      expect(GraphQLHandler.batch, isA<Function>());
    });

    test('should have default endpoint', () {
      expect(GraphQLHandler.defaultEndpoint, equals('/graphql'));
    });

    test('should allow setting custom default endpoint', () {
      GraphQLHandler.defaultEndpoint = '/api/graphql';
      expect(GraphQLHandler.defaultEndpoint, equals('/api/graphql'));

      // Reset to default
      GraphQLHandler.defaultEndpoint = '/graphql';
    });
  });

  group('GraphQLOperation', () {
    test('should create operation with query only', () {
      final operation = GraphQLOperation(query: 'query { user { id name } }');

      expect(operation.query, equals('query { user { id name } }'));
      expect(operation.variables, isNull);
      expect(operation.operationName, isNull);
    });

    test('should create operation with variables', () {
      final operation = GraphQLOperation(
        query: 'query GetUser(\$id: ID!) { user(id: \$id) { id name } }',
        variables: {'id': '123'},
      );

      expect(operation.variables, isNotNull);
      expect(operation.variables!['id'], equals('123'));
    });

    test('should create operation with operation name', () {
      final operation = GraphQLOperation(
        query: 'query GetUser { user { id name } }',
        operationName: 'GetUser',
      );

      expect(operation.operationName, equals('GetUser'));
    });

    test('should convert to JSON correctly', () {
      final operation = GraphQLOperation(
        query: 'query GetUser(\$id: ID!) { user(id: \$id) { id name } }',
        variables: {'id': '123'},
        operationName: 'GetUser',
      );

      final json = operation.toJson();

      expect(
        json['query'],
        equals('query GetUser(\$id: ID!) { user(id: \$id) { id name } }'),
      );
      expect(json['variables'], equals({'id': '123'}));
      expect(json['operationName'], equals('GetUser'));
    });

    test('should convert to JSON without optional fields', () {
      final operation = GraphQLOperation(query: 'query { users { id name } }');

      final json = operation.toJson();

      expect(json['query'], equals('query { users { id name } }'));
      expect(json.containsKey('variables'), isFalse);
      expect(json.containsKey('operationName'), isFalse);
    });
  });

  group('GraphQLQueryBuilder', () {
    test('should build simple query', () {
      final query =
          GraphQLQueryBuilder.query()
              .operationName('GetUsers')
              .body('users { id name email }')
              .build();

      expect(query, equals('query GetUsers { users { id name email } }'));
    });

    test('should build query with variables', () {
      final query =
          GraphQLQueryBuilder.query()
              .operationName('GetUser')
              .variables({'id': 'ID!'})
              .body('user(id: \$id) { id name email }')
              .build();

      expect(
        query,
        equals('query GetUser(\$id: ID!) { user(id: \$id) { id name email } }'),
      );
    });

    test('should build mutation', () {
      final mutation =
          GraphQLQueryBuilder.mutation()
              .operationName('CreateUser')
              .variables({'input': 'CreateUserInput!'})
              .body('createUser(input: \$input) { id name email }')
              .build();

      expect(
        mutation,
        equals(
          'mutation CreateUser(\$input: CreateUserInput!) { createUser(input: \$input) { id name email } }',
        ),
      );
    });

    test('should build subscription', () {
      final subscription =
          GraphQLQueryBuilder.subscription()
              .operationName('UserUpdated')
              .variables({'userId': 'ID!'})
              .body('userUpdated(userId: \$userId) { id name email }')
              .build();

      expect(
        subscription,
        equals(
          'subscription UserUpdated(\$userId: ID!) { userUpdated(userId: \$userId) { id name email } }',
        ),
      );
    });

    test('should build query without operation name', () {
      final query =
          GraphQLQueryBuilder.query().body('users { id name }').build();

      expect(query, equals('query { users { id name } }'));
    });

    test('should build query without variables', () {
      final query =
          GraphQLQueryBuilder.query()
              .operationName('GetAllUsers')
              .body('users { id name }')
              .build();

      expect(query, equals('query GetAllUsers { users { id name } }'));
    });

    test('should handle multiple variables', () {
      final query =
          GraphQLQueryBuilder.query()
              .variables({
                'first': 'Int',
                'after': 'String',
                'filter': 'UserFilter',
              })
              .body(
                'users(first: \$first, after: \$after, filter: \$filter) { edges { node { id name } } }',
              )
              .build();

      expect(query, contains('\$first: Int'));
      expect(query, contains('\$after: String'));
      expect(query, contains('\$filter: UserFilter'));
    });
  });
}
