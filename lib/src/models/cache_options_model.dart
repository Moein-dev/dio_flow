class CacheOptions {
  /// Whether to cache the response.
  final bool shouldCache;

  /// How long to cache the response.
  final Duration cacheDuration;

  const CacheOptions({
    this.shouldCache = false,
    this.cacheDuration = const Duration(minutes: 5),
  });

  CacheOptions copyWith({bool? shouldCache, Duration? cacheDuration}) {
    return CacheOptions(
      shouldCache: shouldCache ?? this.shouldCache,
      cacheDuration: cacheDuration ?? this.cacheDuration,
    );
  }

  static const CacheOptions defaultOptions = CacheOptions();

  /// Predefined options for requests that should never be cached.
  static const CacheOptions noApiCache = CacheOptions(shouldCache: false);

  /// Predefined options for requests with a short cache duration (1 minute).
  static const CacheOptions shortApiCache = CacheOptions(
    shouldCache: true,
    cacheDuration: Duration(minutes: 1),
  );

  /// Predefined options for requests with a medium cache duration (15 minutes).
  static const CacheOptions mediumApiCache = CacheOptions(
    shouldCache: true,
    cacheDuration: Duration(minutes: 15),
  );

  /// Predefined options for requests with a long cache duration (1 hour).
  static const CacheOptions longApiCache = CacheOptions(
    shouldCache: true,
    cacheDuration: Duration(hours: 1),
  );
}
