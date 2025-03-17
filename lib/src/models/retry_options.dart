/// Configuration options for request retries.
class RetryOptions {
  /// Maximum number of retry attempts.
  final int maxAttempts;

  /// Delay between retry attempts.
  final Duration retryInterval;

  /// Status codes that should trigger a retry.
  final List<int> retryStatusCodes;

  /// Whether to retry on connection timeout.
  final bool retryOnConnectionTimeout;

  /// Whether to retry on receive timeout.
  final bool retryOnReceiveTimeout;

  /// Creates a new RetryOptions instance.
  ///
  /// Parameters:
  /// - [maxAttempts]: Maximum number of retry attempts (default: 3)
  /// - [retryInterval]: Delay between retries (default: 1 second)
  /// - [retryStatusCodes]: HTTP status codes that should trigger a retry (default: [408, 500, 502, 503, 504])
  /// - [retryOnConnectionTimeout]: Whether to retry on connection timeout (default: true)
  /// - [retryOnReceiveTimeout]: Whether to retry on receive timeout (default: true)
  const RetryOptions({
    this.maxAttempts = 3,
    this.retryInterval = const Duration(seconds: 1),
    this.retryStatusCodes = const [408, 500, 502, 503, 504],
    this.retryOnConnectionTimeout = true,
    this.retryOnReceiveTimeout = true,
  });

  /// Creates a copy of this RetryOptions with the specified fields replaced with new values.
  RetryOptions copyWith({
    int? maxAttempts,
    Duration? retryInterval,
    List<int>? retryStatusCodes,
    bool? retryOnConnectionTimeout,
    bool? retryOnReceiveTimeout,
  }) {
    return RetryOptions(
      maxAttempts: maxAttempts ?? this.maxAttempts,
      retryInterval: retryInterval ?? this.retryInterval,
      retryStatusCodes: retryStatusCodes ?? this.retryStatusCodes,
      retryOnConnectionTimeout: retryOnConnectionTimeout ?? this.retryOnConnectionTimeout,
      retryOnReceiveTimeout: retryOnReceiveTimeout ?? this.retryOnReceiveTimeout,
    );
  }

  /// Default retry options with standard settings.
  static const RetryOptions defaultOptions = RetryOptions();

  /// Retry options optimized for slow or unreliable networks.
  static const RetryOptions slowNetwork = RetryOptions(
    maxAttempts: 5,
    retryInterval: Duration(seconds: 2),
  );

  /// Retry options for critical operations that need more attempts.
  static const RetryOptions critical = RetryOptions(
    maxAttempts: 7,
    retryInterval: Duration(seconds: 1),
    retryStatusCodes: [408, 429, 500, 502, 503, 504],
  );
}
