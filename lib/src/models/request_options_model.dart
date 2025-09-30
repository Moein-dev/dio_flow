import 'package:dio/dio.dart';
import 'package:dio_flow/src/models/cache_options_model.dart';
import 'package:dio_flow/src/models/retry_options.dart';

/// Model class for configuring request options.
///
/// This class provides a way to customize how requests are made, including
/// authentication, caching, retries, and other Dio-specific options.
class RequestOptionsModel {
  final bool hasBearerToken;

  /// for cache settings handled
  final CacheOptions cacheOptions;

  /// Configuration for request retries.
  final RetryOptions retryOptions;

  /// user extra
  final Map<String, dynamic>? customExtra;

  /// Custom headers to include in the request.
  final Map<String, dynamic>? customHeaders;

  /// The response type (e.g., json, stream, plain, bytes).
  final ResponseType? responseType;

  /// Whether to receive data when status code indicates error.
  final bool? receiveDataWhenStatusError;

  /// Whether to follow redirects.
  final bool? followRedirects;

  /// Maximum number of redirects to follow.
  final int? maxRedirects;

  /// Whether to use persistent connection.
  final bool? persistentConnection;

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
    this.hasBearerToken = false,
    this.cacheOptions = CacheOptions.defaultOptions,
    this.retryOptions = RetryOptions.defaultOptions,
    this.customHeaders,
    this.responseType,
    this.receiveDataWhenStatusError,
    this.followRedirects,
    this.maxRedirects,
    this.persistentConnection,
    this.customExtra,
  });

  RetryOptions get effectiveRetryOptions => retryOptions;

  CacheOptions get effectiveCacheOptions => cacheOptions;

  /// Creates a copy of this RequestOptionsModel with the specified fields replaced with new values.
  RequestOptionsModel copyWith({
    bool? hasBearerToken,
    RetryOptions? retryOptions,
    CacheOptions? cacheOptions,
    Map<String, dynamic>? headers,
    ResponseType? responseType,
    ValidateStatus? validateStatus,
    bool? receiveDataWhenStatusError,
    bool? followRedirects,
    int? maxRedirects,
    bool? persistentConnection,
    Map<String, dynamic>? userExtra,
  }) {
    return RequestOptionsModel(
      hasBearerToken: hasBearerToken ?? this.hasBearerToken,
      retryOptions: retryOptions ?? this.retryOptions,
      cacheOptions: cacheOptions ?? this.cacheOptions,
      customHeaders: headers ?? customHeaders,
      responseType: responseType ?? this.responseType,
      receiveDataWhenStatusError:
          receiveDataWhenStatusError ?? this.receiveDataWhenStatusError,
      followRedirects: followRedirects ?? this.followRedirects,
      maxRedirects: maxRedirects ?? this.maxRedirects,
      persistentConnection: persistentConnection ?? this.persistentConnection,
      customExtra: userExtra ?? customExtra,
    );
  }

  /// Converts this model to Dio options.
  ///
  /// This method creates a new Options instance with all the relevant
  /// fields from this model.
  ///
  /// Parameters:
  ///   method - Optional HTTP method to override the default
  Options toDioOptions({String? method}) {
    return Options(
      method: method,
      headers: customHeaders,
      responseType: responseType,
      receiveDataWhenStatusError: receiveDataWhenStatusError,
      followRedirects: followRedirects,
      maxRedirects: maxRedirects,
      persistentConnection: persistentConnection,
      extra: {
        ...customExtra ?? {},
        'maxAttempts': effectiveRetryOptions.maxAttempts,
        'retryInterval': effectiveRetryOptions.retryInterval,
        'shouldCache': effectiveCacheOptions.shouldCache,
        'cacheDuration': effectiveCacheOptions.cacheDuration,
      },
    );
  }

  /// Creates a RequestOptionsModel from Dio Options.
  ///
  /// This factory constructor allows converting from Dio's Options
  /// back to our RequestOptionsModel format.
  factory RequestOptionsModel.fromDioOptions(Options options) {
    final extra = options.extra ?? <String, dynamic>{};

    final int retryCountFromExtra =
        extra['retryCount'] is int
            ? extra['retryCount'] as int
            : RetryOptions.defaultOptions.maxAttempts;
    final dynamic rawInterval = extra['retryInterval'];
    final Duration retryIntervalFromExtra =
        rawInterval is int
            ? Duration(milliseconds: rawInterval)
            : (rawInterval is Duration
                ? rawInterval
                : RetryOptions.defaultOptions.retryInterval);

    return RequestOptionsModel(
      customHeaders: options.headers,
      responseType: options.responseType,
      receiveDataWhenStatusError: options.receiveDataWhenStatusError,
      followRedirects: options.followRedirects,
      maxRedirects: options.maxRedirects,
      persistentConnection: options.persistentConnection,
      retryOptions: RetryOptions(
        maxAttempts: retryCountFromExtra,
        retryInterval: retryIntervalFromExtra,
        retryStatusCodes: RetryOptions.defaultOptions.retryStatusCodes,
        retryOnConnectionTimeout:
            RetryOptions.defaultOptions.retryOnConnectionTimeout,
        retryOnReceiveTimeout:
            RetryOptions.defaultOptions.retryOnReceiveTimeout,
      ),
    );
  }
}
