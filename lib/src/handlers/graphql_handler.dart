import 'package:dio_flow/src/handlers/dio_request_handler.dart';
import 'package:dio_flow/src/models/request_options_model.dart';
import 'package:dio_flow/src/models/response/response_model.dart';

import '../models/response/error_type.dart';

/// Handler for GraphQL operations using DioFlow.
///
/// This class provides a convenient interface for making GraphQL queries,
/// mutations, and subscriptions while leveraging all the features of DioFlow
/// like authentication, caching, retry logic, etc.
class GraphQLHandler {
  /// Private constructor to prevent instantiation.
  GraphQLHandler._();

  /// The default GraphQL endpoint path.
  /// Can be overridden when making requests.
  static String defaultEndpoint = '/graphql';

  /// Executes a GraphQL query.
  ///
  /// Parameters:
  ///   query - The GraphQL query string
  ///   variables - Optional variables for the query
  ///   endpoint - Custom GraphQL endpoint (defaults to '/graphql')
  ///   requestOptions - Request configuration options
  ///   converter - Optional converter function for typed responses
  ///
  /// Returns:
  ///   A ResponseModel containing the query result
  ///
  /// Example:
  /// ```dart
  /// final response = await GraphQLHandler.query('''
  ///   query GetUser($id: ID!) {
  ///     user(id: $id) {
  ///       id
  ///       name
  ///       email
  ///     }
  ///   }
  /// ''', variables: {'id': '123'});
  /// ```
  static Future<ResponseModel> query(
    String query, {
    Map<String, dynamic>? variables,
    String? endpoint,
    RequestOptionsModel requestOptions = const RequestOptionsModel(),
    T Function<T>(Map<String, dynamic>)? converter,
  }) async {
    return _executeGraphQLRequest(
      query: query,
      variables: variables,
      endpoint: endpoint,
      requestOptions: requestOptions,
      converter: converter,
    );
  }

  /// Executes a GraphQL mutation.
  ///
  /// Parameters:
  ///   mutation - The GraphQL mutation string
  ///   variables - Optional variables for the mutation
  ///   endpoint - Custom GraphQL endpoint (defaults to '/graphql')
  ///   requestOptions - Request configuration options
  ///   converter - Optional converter function for typed responses
  ///
  /// Returns:
  ///   A ResponseModel containing the mutation result
  ///
  /// Example:
  /// ```dart
  /// final response = await GraphQLHandler.mutation('''
  ///   mutation CreateUser($input: CreateUserInput!) {
  ///     createUser(input: $input) {
  ///       id
  ///       name
  ///       email
  ///     }
  ///   }
  /// ''', variables: {
  ///   'input': {
  ///     'name': 'John Doe',
  ///     'email': 'john@example.com'
  ///   }
  /// });
  /// ```
  static Future<ResponseModel> mutation(
    String mutation, {
    Map<String, dynamic>? variables,
    String? endpoint,
    RequestOptionsModel requestOptions = const RequestOptionsModel(
      hasBearerToken: true, // Mutations usually require authentication
    ),
    T Function<T>(Map<String, dynamic>)? converter,
  }) async {
    return _executeGraphQLRequest(
      query: mutation,
      variables: variables,
      endpoint: endpoint,
      requestOptions: requestOptions,
      converter: converter,
    );
  }

  /// Executes a GraphQL subscription.
  ///
  /// Note: This method makes a single HTTP request. For real-time subscriptions,
  /// you would typically use WebSockets or Server-Sent Events.
  ///
  /// Parameters:
  ///   subscription - The GraphQL subscription string
  ///   variables - Optional variables for the subscription
  ///   endpoint - Custom GraphQL endpoint (defaults to '/graphql')
  ///   requestOptions - Request configuration options
  ///   converter - Optional converter function for typed responses
  ///
  /// Returns:
  ///   A ResponseModel containing the subscription result
  static Future<ResponseModel> subscription(
    String subscription, {
    Map<String, dynamic>? variables,
    String? endpoint,
    RequestOptionsModel requestOptions = const RequestOptionsModel(
      hasBearerToken: true,
    ),
    T Function<T>(Map<String, dynamic>)? converter,
  }) async {
    return _executeGraphQLRequest(
      query: subscription,
      variables: variables,
      endpoint: endpoint,
      requestOptions: requestOptions,
      converter: converter,
    );
  }

  /// Executes a batch of GraphQL operations.
  ///
  /// Parameters:
  ///   operations - List of GraphQL operations to execute
  ///   endpoint - Custom GraphQL endpoint (defaults to '/graphql')
  ///   requestOptions - Request configuration options
  ///
  /// Returns:
  ///   A ResponseModel containing the batch results
  static Future<ResponseModel> batch(
    List<GraphQLOperation> operations, {
    String? endpoint,
    RequestOptionsModel requestOptions = const RequestOptionsModel(
      hasBearerToken: true,
    ),
  }) async {
    final batchData = operations.map((op) => op.toJson()).toList();

    return DioRequestHandler.post(
      endpoint ?? defaultEndpoint,
      data: batchData,
      requestOptions: requestOptions,
    );
  }

  /// Internal method to execute GraphQL requests.
  static Future<ResponseModel> _executeGraphQLRequest({
    required String query,
    Map<String, dynamic>? variables,
    String? endpoint,
    required RequestOptionsModel requestOptions,
    T Function<T>(Map<String, dynamic>)? converter,
  }) async {
    final data = <String, dynamic>{'query': query};

    if (variables != null && variables.isNotEmpty) {
      data['variables'] = variables;
    }

    final response = await DioRequestHandler.post(
      endpoint ?? defaultEndpoint,
      data: data,
      requestOptions: requestOptions,
    );

    // Handle GraphQL-specific error format
    if (response.isSuccess) {
      final responseData = response.data as Map<String, dynamic>?;
      if (responseData != null && responseData.containsKey('errors')) {
        // GraphQL returned errors
        return FailedResponseModel(
          statusCode: 400,
          message: 'GraphQL errors occurred',
          data: responseData,
          logCurl: response.logCurl,
          errorType: ErrorType.validation,
        );
      }

      // Extract data from GraphQL response
      if (responseData != null && responseData.containsKey('data')) {
        final graphqlData = responseData['data'];

        if (converter != null) {
          try {
            final convertedData = converter(
              graphqlData as Map<String, dynamic>,
            );
            return SuccessResponseModel(
              data: convertedData,
              statusCode: response.statusCode,
              logCurl: response.logCurl,
            );
          } catch (e) {
            return FailedResponseModel(
              statusCode: 500,
              message: 'Failed to convert GraphQL response: $e',
              data: graphqlData,
              logCurl: response.logCurl,
              errorType: ErrorType.parsing,
            );
          }
        }

        return SuccessResponseModel(
          data: graphqlData,
          statusCode: response.statusCode,
          logCurl: response.logCurl,
        );
      }
    }

    return response;
  }
}

/// Represents a single GraphQL operation for batch requests.
class GraphQLOperation {
  /// The GraphQL query/mutation/subscription string.
  final String query;

  /// Optional variables for the operation.
  final Map<String, dynamic>? variables;

  /// Optional operation name.
  final String? operationName;

  /// Creates a new GraphQL operation.
  GraphQLOperation({required this.query, this.variables, this.operationName});

  /// Converts the operation to JSON format for batch requests.
  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{'query': query};

    if (variables != null && variables!.isNotEmpty) {
      json['variables'] = variables;
    }

    if (operationName != null && operationName!.isNotEmpty) {
      json['operationName'] = operationName;
    }

    return json;
  }
}

/// Utility class for building GraphQL queries programmatically.
class GraphQLQueryBuilder {
  final StringBuffer _buffer = StringBuffer();

  /// Creates a new query builder.
  GraphQLQueryBuilder.query() {
    _buffer.write('query ');
  }

  /// Creates a new mutation builder.
  GraphQLQueryBuilder.mutation() {
    _buffer.write('mutation ');
  }

  /// Creates a new subscription builder.
  GraphQLQueryBuilder.subscription() {
    _buffer.write('subscription ');
  }

  /// Adds an operation name.
  GraphQLQueryBuilder operationName(String name) {
    _buffer.write(name);
    return this;
  }

  /// Adds variables definition.
  GraphQLQueryBuilder variables(Map<String, String> variables) {
    if (variables.isNotEmpty) {
      _buffer.write('(');
      final entries = variables.entries.map((e) => '\$${e.key}: ${e.value}');
      _buffer.write(entries.join(', '));
      _buffer.write(')');
    }
    return this;
  }

  /// Adds the query body.
  GraphQLQueryBuilder body(String body) {
    // Add space only if buffer doesn't end with space
    final currentContent = _buffer.toString();
    if (!currentContent.endsWith(' ')) {
      _buffer.write(' ');
    }
    _buffer.write('{ $body }');
    return this;
  }

  /// Builds the final GraphQL string.
  String build() {
    return _buffer.toString();
  }
}
