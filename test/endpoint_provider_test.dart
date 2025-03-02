import 'package:flutter_test/flutter_test.dart';
import 'package:dio_flow/dio_flow.dart';

void main() {
  group('EndpointProvider', () {
    // Clear all endpoints before each test
    setUp(() {
      EndpointProvider.instance.clear();
    });

    test('should register a string endpoint', () {
      // Register an endpoint by string
      EndpointProvider.instance.register('users', '/api/users');

      // Get the registered endpoint
      final endpoint = EndpointProvider.instance.getEndpoint('users');

      // Verify it's an ApiEndpointInterface
      expect(endpoint, isA<ApiEndpointInterface>());

      // Check that the path was set correctly
      expect(endpoint.path, equals('/api/users'));
    });

    test('should register an ApiEndpointInterface', () {
      // Create a custom endpoint implementation
      final customEndpoint = ApiEndpointFactory.create('/api/custom');

      // Register the custom endpoint
      EndpointProvider.instance.register('custom', customEndpoint);

      // Get the registered endpoint
      final endpoint = EndpointProvider.instance.getEndpoint('custom');

      // Verify it's the same instance
      expect(identical(endpoint, customEndpoint), isTrue);
      expect(endpoint.path, equals('/api/custom'));
    });

    test('should throw ArgumentError for invalid endpoint type', () {
      // Attempt to register an invalid endpoint (neither String nor ApiEndpointInterface)
      expect(
        () => EndpointProvider.instance.register('invalid', 123),
        throwsArgumentError,
      );
    });

    test('should register multiple endpoints at once', () {
      // Register multiple endpoints with a map
      EndpointProvider.instance.registerAll({
        'users': '/api/users',
        'posts': '/api/posts',
        'comments': '/api/comments',
      });

      // Verify all endpoints were registered correctly
      expect(
        EndpointProvider.instance.getEndpoint('users').path,
        equals('/api/users'),
      );
      expect(
        EndpointProvider.instance.getEndpoint('posts').path,
        equals('/api/posts'),
      );
      expect(
        EndpointProvider.instance.getEndpoint('comments').path,
        equals('/api/comments'),
      );
    });

    test('should throw ArgumentError for non-existent endpoint', () {
      // Attempt to get an endpoint that hasn't been registered
      expect(
        () => EndpointProvider.instance.getEndpoint('non-existent'),
        throwsArgumentError,
      );
    });

    test('should clear all endpoints', () {
      // Register some endpoints
      EndpointProvider.instance.registerAll({
        'users': '/api/users',
        'posts': '/api/posts',
      });

      // Clear all endpoints
      EndpointProvider.instance.clear();

      // Verify endpoints were cleared
      expect(
        () => EndpointProvider.instance.getEndpoint('users'),
        throwsArgumentError,
      );
      expect(
        () => EndpointProvider.instance.getEndpoint('posts'),
        throwsArgumentError,
      );
    });

    test('should support method chaining for register and registerAll', () {
      // Use method chaining to register endpoints
      EndpointProvider.instance
          .register('users', '/api/users')
          .register('posts', '/api/posts')
          .registerAll({'comments': '/api/comments', 'likes': '/api/likes'});

      // Verify all endpoints were registered
      expect(
        EndpointProvider.instance.getEndpoint('users').path,
        equals('/api/users'),
      );
      expect(
        EndpointProvider.instance.getEndpoint('posts').path,
        equals('/api/posts'),
      );
      expect(
        EndpointProvider.instance.getEndpoint('comments').path,
        equals('/api/comments'),
      );
      expect(
        EndpointProvider.instance.getEndpoint('likes').path,
        equals('/api/likes'),
      );
    });
  });
}
