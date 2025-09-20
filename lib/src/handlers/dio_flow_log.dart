// ignore_for_file: curly_braces_in_flow_control_structures, no_leading_underscores_for_local_identifiers

import 'package:dio_flow/dio_flow.dart';
import 'package:flutter/foundation.dart';

enum DioLogType { request, response, error, retry }

class DioFlowLog {
  final DioLogType type;
  final String? url;
  final String? method;
  final dynamic data;
  final int? statusCode;
  final String? message;
  final dynamic error;
  final String? logCurl;
  final StackTrace? stackTrace;
  final Map<String, dynamic>? headers;
  final Map<String, dynamic>? parameters;
  final Map<String, dynamic>? extra;
  final int? retryCount;
  final bool isCache;
  final ErrorType? errorType;
  final int? maxAttempts;
  final bool isRefreshHandle;

  DioFlowLog({
    required this.type,
    this.url,
    this.method,
    this.data,
    this.statusCode,
    this.message,
    this.error,
    this.stackTrace,
    this.headers,
    this.retryCount,
    this.parameters,
    this.extra,
    this.logCurl,
    this.isCache = false,
    this.errorType,
    this.maxAttempts,
    this.isRefreshHandle = false,
  });

  void log() {
    if (!kDebugMode) return;

    String colorCode;
    String typeLabel;

    switch (type) {
      case DioLogType.request:
        colorCode = '\x1B[33m';
        typeLabel = 'REQUEST';
        break;
      case DioLogType.response:
        colorCode = '\x1B[32m';
        typeLabel = 'RESPONSE';
        break;
      case DioLogType.error:
        colorCode = '\x1B[31m';
        typeLabel = 'ERROR';
        break;
      case DioLogType.retry:
        colorCode = '\x1B[38;5;81m';
        typeLabel = 'RETRY';
        break;
    }

    final resetColor = '\x1B[0m';
    const int maxLineLength = 100;
    final List<String> outLines = [];

    outLines.add(
      '$colorCode╔═══════════════════════════ $typeLabel ═══════════════════════════╗$resetColor',
    );

    // helper: truncate and append '...' if over limit
    String _maybeTruncate(String s, int maxLen) {
      if (s.length <= maxLen) return s;
      return '${s.substring(0, maxLen - 3)}...';
    }

    void addWrapped(String label, dynamic value, {int maxContentLength = 200}) {
      if (value == null) return;
      final content = _maybeTruncate(value.toString(), maxContentLength);
      final wrapped = _wrapToLinesWithPrefix(
        '║ $label: ',
        content,
        maxLineLength,
      );
      for (final l in wrapped) {
        outLines.add('$colorCode$l$resetColor');
      }
    }

    if (type == DioLogType.request) {
      if (url != null) outLines.add('$colorCode║ URL: $url$resetColor');
      if (method != null)
        outLines.add('$colorCode║ Method: $method$resetColor');
      if (isRefreshHandle) {
        outLines.add(
          '$colorCode║ * This request for handle 401 error. *$resetColor',
        );
      }
      if (isCache)
        outLines.add('$colorCode║ * This request is caching. *$resetColor');
      if (headers != null)
        addWrapped('Headers', headers, maxContentLength: 800);
      if (parameters != null)
        addWrapped('Parameters', parameters, maxContentLength: 600);
      if (extra != null) addWrapped('Extra', extra, maxContentLength: 600);
      if (logCurl != null) addWrapped('Curl', logCurl, maxContentLength: 1200);
    } else if (type == DioLogType.retry) {
      outLines.add(
        '$colorCode║ * Retry the request based on the RetryOption... * $resetColor',
      );
      if (statusCode != null)
        outLines.add('$colorCode║ Status Code: $statusCode$resetColor');
      if (message != null)
        outLines.add('$colorCode║ Message: $message$resetColor');
      if (retryCount != null) {
        outLines.add(
          '$colorCode║ * ${numberToOrdinalUpTo10(retryCount! + 2)} attempt of $maxAttempts attempts * $resetColor',
        );
      }
      if (url != null) outLines.add('$colorCode║ URL: $url$resetColor');
      if (method != null)
        outLines.add('$colorCode║ Method: $method$resetColor');
      if (isCache)
        outLines.add('$colorCode║ * This request is caching. *$resetColor');
      if (headers != null)
        addWrapped('Headers', headers, maxContentLength: 800);
      if (parameters != null)
        addWrapped('Parameters', parameters, maxContentLength: 600);
      if (extra != null) addWrapped('Extra', extra, maxContentLength: 600);
      if (logCurl != null) addWrapped('Curl', logCurl, maxContentLength: 1200);
    } else if (type == DioLogType.response) {
      if (url != null) outLines.add('$colorCode║ URL: $url$resetColor');
      if (method != null)
        outLines.add('$colorCode║ Method: $method$resetColor');
      if (isRefreshHandle) {
        outLines.add(
          '$colorCode║ * Token successfully refreshed. *$resetColor',
        );
      }
      if (isCache)
        outLines.add(
          '$colorCode║ * The stored response has been returned. *$resetColor',
        );
      if (statusCode != null)
        outLines.add('$colorCode║ Status Code: $statusCode$resetColor');
      if (message != null)
        outLines.add('$colorCode║ Message: $message$resetColor');
      if (headers != null)
        addWrapped('Headers', headers, maxContentLength: 800);
      if (parameters != null)
        addWrapped('Parameters', parameters, maxContentLength: 600);
      if (extra != null) addWrapped('Extra', extra, maxContentLength: 600);
      if (logCurl != null) addWrapped('Curl', logCurl, maxContentLength: 1200);
      if (data != null) {
        final dataString = data.toString();
        const int maxDataLength = 400;
        final truncatedData =
            dataString.length > maxDataLength
                ? '${dataString.substring(0, maxDataLength - 3)}...'
                : dataString;
        addWrapped('Data', truncatedData, maxContentLength: maxDataLength);
      }
    } else {
      if (url != null) outLines.add('$colorCode║ URL: $url$resetColor');
      if (method != null)
        outLines.add('$colorCode║ Method: $method$resetColor');
      if (isRefreshHandle) {
        outLines.add('$colorCode║ * Token refresh failed... *$resetColor');
      }
      if (statusCode != null)
        outLines.add('$colorCode║ Status Code: $statusCode$resetColor');
      if (errorType != null)
        outLines.add(
          '$colorCode║ ErrorType: ${errorType!.userFriendlyMessage} $resetColor',
        );
      if (message != null)
        outLines.add('$colorCode║ Message: $message$resetColor');
      if (error != null) addWrapped('Error', error, maxContentLength: 1200);
      if (stackTrace != null)
        addWrapped('Stack Trace', stackTrace, maxContentLength: 1200);
      if (headers != null)
        addWrapped('Headers', headers, maxContentLength: 800);
      if (parameters != null)
        addWrapped('Parameters', parameters, maxContentLength: 600);
      if (extra != null) addWrapped('Extra', extra, maxContentLength: 600);
      if (logCurl != null) addWrapped('Curl', logCurl, maxContentLength: 1200);
    }

    outLines.add(
      '$colorCode╚═════════════════════════════════════════════════════════════════╝$resetColor',
    );

    for (final line in outLines) {
      if (kDebugMode) {
        print(line);
      }
    }
  }

  static List<String> _wrapToLinesWithPrefix(
    String firstPrefix,
    String content,
    int maxLineLength,
  ) {
    final List<String> lines = [];
    if (content.isEmpty) {
      lines.add(firstPrefix);
      return lines;
    }

    final trimmed = content.trim();
    final firstCap = maxLineLength - firstPrefix.length;

    // create continuation prefix that shows the box border and aligns with firstPrefix
    final int contSpaces = firstPrefix.length > 2 ? firstPrefix.length - 2 : 2;
    final String contPrefix = '║ ' + ''.padLeft(contSpaces);

    final contCap = maxLineLength - contPrefix.length;

    if (firstCap <= 10) {
      lines.add(firstPrefix + trimmed);
      return lines;
    }

    String remaining = trimmed;

    int findSplit(String s, int limit) {
      if (s.length <= limit) return s.length;
      final commaIdx = s.lastIndexOf(', ', limit);
      if (commaIdx != -1) return commaIdx + 2;
      final spaceIdx = s.lastIndexOf(' ', limit);
      if (spaceIdx != -1) return spaceIdx + 1;
      return limit;
    }

    final firstCut = findSplit(remaining, firstCap);
    lines.add(firstPrefix + remaining.substring(0, firstCut).trimRight());
    remaining = remaining.substring(firstCut).trimLeft();

    while (remaining.isNotEmpty) {
      final cut = findSplit(remaining, contCap);
      lines.add(contPrefix + remaining.substring(0, cut).trimRight());
      remaining = remaining.substring(cut).trimLeft();
    }

    return lines;
  }

  String numberToOrdinalUpTo10(int n) {
    const ordinals = [
      "",
      "first",
      "second",
      "third",
      "fourth",
      "fifth",
      "sixth",
      "seventh",
      "eighth",
      "ninth",
      "tenth",
    ];

    if (n >= 1 && n <= 10) {
      return ordinals[n];
    } else {
      return "out of range (only 1..10 supported)";
    }
  }
}
