import 'package:dio/dio.dart';

/// A model representing all configurable options for API requests.
///
/// This model provides a structured way to specify common request options,
/// including auth, headers, and cache control, without needing to directly
/// manipulate the Dio Options object. It makes request configuration more
/// consistent, readable, and type-safe.
class RequestOptionsModel {
  /// Whether to attach the bearer token to the request
  final bool hasBearerToken;

  /// Whether to disable caching for this specific request
  final bool noCache;

  /// Custom cache duration for this request, overriding the default
  final Duration? cacheMaxAge;

  /// Content type for the request (e.g., 'application/json')
  final String? contentType;

  /// Response type to expect (defaults to JSON)
  final ResponseType responseType;

  /// Additional headers to include with the request
  final Map<String, dynamic>? headers;

  /// Additional custom parameters for the request
  final Map<String, dynamic>? extra;

  /// Whether to log the curl command for this request
  final bool logCurl;

  /// Creates a new RequestOptionsModel with the specified parameters.
  ///
  /// Parameters:
  ///   hasBearerToken - Whether to include the auth token (default: false)
  ///   noCache - Whether to disable caching for this request (default: false)
  ///   cacheMaxAge - Custom cache duration for this request (default: null, uses global setting)
  ///   contentType - Content type header (default: application/json)
  ///   responseType - Response type (default: ResponseType.json)
  ///   headers - Additional headers to include (default: empty map)
  ///   extra - Additional parameters for the Dio options (default: empty map)
  ///   logCurl - Whether to log the curl command (default: true)
  const RequestOptionsModel({
    this.hasBearerToken = false,
    this.noCache = false,
    this.cacheMaxAge,
    this.contentType,
    this.responseType = ResponseType.json,
    this.headers,
    this.extra,
    this.logCurl = true,
  });

  /// Converts this model to a Dio Options object.
  ///
  /// This method creates a properly configured Dio Options object with
  /// all the settings specified in this model.
  ///
  /// Parameters:
  ///   method - The HTTP method for the request (GET, POST, etc.)
  ///
  /// Returns:
  ///   A configured Dio Options object ready to use with requests
  Options toDioOptions({String? method}) {
    // Start with a base extra map
    final Map<String, dynamic> extraMap = {};

    // Add cache-related options
    if (noCache) {
      extraMap['no_cache'] = true;
    }
    if (cacheMaxAge != null) {
      extraMap['cache_maxAge'] = cacheMaxAge;
    }

    // Add any custom extra params
    if (extra != null && extra!.isNotEmpty) {
      extraMap.addAll(extra!);
    }

    // Create the Options object
    return Options(
      method: method,
      contentType: contentType ?? 'application/json',
      responseType: responseType,
      headers: headers,
      extra: extraMap,
    );
  }

  /// Creates a copy of this model with the specified changes.
  ///
  /// This method allows for easily creating modified versions of an existing
  /// RequestOptionsModel without changing the original.
  ///
  /// Returns:
  ///   A new RequestOptionsModel with the specified changes
  RequestOptionsModel copyWith({
    bool? hasBearerToken,
    bool? noCache,
    Duration? cacheMaxAge,
    String? contentType,
    ResponseType? responseType,
    Map<String, dynamic>? headers,
    Map<String, dynamic>? extra,
    bool? logCurl,
  }) {
    return RequestOptionsModel(
      hasBearerToken: hasBearerToken ?? this.hasBearerToken,
      noCache: noCache ?? this.noCache,
      cacheMaxAge: cacheMaxAge ?? this.cacheMaxAge,
      contentType: contentType ?? this.contentType,
      responseType: responseType ?? this.responseType,
      headers: headers ?? this.headers,
      extra: extra ?? this.extra,
      logCurl: logCurl ?? this.logCurl,
    );
  }

  /// Predefined options for requests that should never be cached.
  static const RequestOptionsModel noApiCache = RequestOptionsModel(
    noCache: true,
  );

  /// Predefined options for requests with a short cache duration (1 minute).
  static const RequestOptionsModel shortApiCache = RequestOptionsModel(
    cacheMaxAge: Duration(minutes: 1),
  );

  /// Predefined options for requests with a medium cache duration (15 minutes).
  static const RequestOptionsModel mediumApiCache = RequestOptionsModel(
    cacheMaxAge: Duration(minutes: 15),
  );

  /// Predefined options for requests with a long cache duration (1 hour).
  static const RequestOptionsModel longApiCache = RequestOptionsModel(
    cacheMaxAge: Duration(hours: 1),
  );

  /// Predefined options for requests that require authentication.
  static const RequestOptionsModel authenticated = RequestOptionsModel(
    hasBearerToken: true,
  );
}
