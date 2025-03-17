import 'package:dio/dio.dart';
import 'package:dio_flow/src/models/retry_options.dart';

/// Model class for configuring request options.
///
/// This class provides a way to customize how requests are made, including
/// authentication, caching, retries, and other Dio-specific options.
class RequestOptionsModel {
  /// Whether to include bearer token authentication header.
  final bool hasBearerToken;

  /// Whether to cache the response.
  final bool shouldCache;

  /// How long to cache the response.
  final Duration cacheDuration;

  /// Configuration for request retries.
  final RetryOptions? retryOptions;

  /// Custom headers to include in the request.
  final Map<String, dynamic>? headers;

  /// Extra parameters for the request.
  final Map<String, dynamic>? extra;

  /// The response type (e.g., json, stream, plain, bytes).
  final ResponseType? responseType;

  /// Custom status code validator.
  final ValidateStatus? validateStatus;

  /// Whether to receive data when status code indicates error.
  final bool? receiveDataWhenStatusError;

  /// Whether to follow redirects.
  final bool? followRedirects;

  /// Maximum number of redirects to follow.
  final int? maxRedirects;

  /// Whether to use persistent connection.
  final bool? persistentConnection;

  /// Whether this request requires authentication.
  final bool requiresAuth;

  /// Number of times to retry the request on failure.
  final int retryCount;

  /// Interval between retries.
  final Duration retryInterval;

  /// Creates a new request options model with the specified configuration.
  ///
  /// Most parameters are optional and have sensible defaults:
  /// - [hasBearerToken] defaults to true
  /// - [shouldCache] defaults to false
  /// - [cacheDuration] defaults to 5 minutes
  /// - [requiresAuth] defaults to true
  /// - [retryCount] defaults to 3
  /// - [retryInterval] defaults to 1 second
  const RequestOptionsModel({
    this.hasBearerToken = true,
    this.shouldCache = false,
    this.cacheDuration = const Duration(minutes: 5),
    this.retryOptions,
    this.headers,
    this.extra,
    this.responseType,
    this.validateStatus,
    this.receiveDataWhenStatusError,
    this.followRedirects,
    this.maxRedirects,
    this.persistentConnection,
    this.requiresAuth = true,
    this.retryCount = 3,
    this.retryInterval = const Duration(seconds: 1),
  });

  /// Creates a copy of this RequestOptionsModel with the specified fields replaced with new values.
  RequestOptionsModel copyWith({
    bool? hasBearerToken,
    bool? shouldCache,
    Duration? cacheDuration,
    RetryOptions? retryOptions,
    Map<String, dynamic>? headers,
    Map<String, dynamic>? extra,
    ResponseType? responseType,
    ValidateStatus? validateStatus,
    bool? receiveDataWhenStatusError,
    bool? followRedirects,
    int? maxRedirects,
    bool? persistentConnection,
    bool? requiresAuth,
    int? retryCount,
    Duration? retryInterval,
  }) {
    return RequestOptionsModel(
      hasBearerToken: hasBearerToken ?? this.hasBearerToken,
      shouldCache: shouldCache ?? this.shouldCache,
      cacheDuration: cacheDuration ?? this.cacheDuration,
      retryOptions: retryOptions ?? this.retryOptions,
      headers: headers ?? this.headers,
      extra: extra ?? this.extra,
      responseType: responseType ?? this.responseType,
      validateStatus: validateStatus ?? this.validateStatus,
      receiveDataWhenStatusError: receiveDataWhenStatusError ?? this.receiveDataWhenStatusError,
      followRedirects: followRedirects ?? this.followRedirects,
      maxRedirects: maxRedirects ?? this.maxRedirects,
      persistentConnection: persistentConnection ?? this.persistentConnection,
      requiresAuth: requiresAuth ?? this.requiresAuth,
      retryCount: retryCount ?? this.retryCount,
      retryInterval: retryInterval ?? this.retryInterval,
    );
  }

  /// Converts this model to Dio options.
  ///
  /// This method creates a new Options instance with all the relevant
  /// fields from this model.
  Options toDioOptions() {
    return Options(
      headers: headers,
      responseType: responseType,
      validateStatus: validateStatus,
      receiveDataWhenStatusError: receiveDataWhenStatusError,
      followRedirects: followRedirects,
      maxRedirects: maxRedirects,
      persistentConnection: persistentConnection,
      extra: {
        ...?extra,
        'requiresAuth': requiresAuth,
        'retryCount': retryCount,
        'retryInterval': retryInterval,
      },
    );
  }

  /// Predefined options for requests that should never be cached.
  static const RequestOptionsModel noApiCache = RequestOptionsModel(
    shouldCache: false,
  );

  /// Predefined options for requests with a short cache duration (1 minute).
  static const RequestOptionsModel shortApiCache = RequestOptionsModel(
    cacheDuration: Duration(minutes: 1),
  );

  /// Predefined options for requests with a medium cache duration (15 minutes).
  static const RequestOptionsModel mediumApiCache = RequestOptionsModel(
    cacheDuration: Duration(minutes: 15),
  );

  /// Predefined options for requests with a long cache duration (1 hour).
  static const RequestOptionsModel longApiCache = RequestOptionsModel(
    cacheDuration: Duration(hours: 1),
  );

  /// Predefined options for requests that require authentication.
  static const RequestOptionsModel authenticated = RequestOptionsModel(
    hasBearerToken: true,
  );
}
