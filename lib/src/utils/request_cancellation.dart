import 'package:dio/dio.dart';

class RequestCancellation {
  static final Map<String, CancelToken> _tokens = {};

  static CancelToken getToken(String key) {
    if (!_tokens.containsKey(key)) {
      _tokens[key] = CancelToken();
    }
    return _tokens[key]!;
  }

  static void cancel(String key, [String? reason]) {
    if (_tokens.containsKey(key)) {
      if (!_tokens[key]!.isCancelled) {
        _tokens[key]!.cancel(reason);
      }
      _tokens.remove(key);
    }
  }

  static void cancelAll([String? reason]) {
    for (final token in _tokens.values) {
      if (!token.isCancelled) {
        token.cancel(reason);
      }
    }
    _tokens.clear();
  }
} 