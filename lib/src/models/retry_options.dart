/// Configuration class for retry behavior in network requests.
///
/// This class defines the parameters that control how failed network requests
/// are retried, including the maximum number of attempts and the time interval
/// between retries.
class RetryOptions {
  /// The maximum number of retry attempts for a failed request.
  ///
  /// This includes the initial request, so a value of 3 means
  /// the initial request plus 2 retry attempts.
  final int maxAttempts;

  /// The time interval to wait between retry attempts.
  ///
  /// This delay helps prevent overwhelming the server with rapid
  /// retry requests and allows time for transient issues to resolve.
  final Duration retryInterval;

  /// Creates a new RetryOptions instance with the specified parameters.
  ///
  /// Parameters:
  ///   maxAttempts - The maximum number of retry attempts (required)
  ///   retryInterval - The time interval to wait between retries (required)
  const RetryOptions({required this.maxAttempts, required this.retryInterval});
}
