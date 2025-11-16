import 'package:dio/dio.dart' show FormData;
import 'package:dio_flow/dio_flow.dart';
import 'package:dio_flow/src/models/log_model.dart';
import 'package:flutter/foundation.dart';

enum DioLogType { request, response, error, retry }

class DioFlowLog {
  final LogModel logModel;
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
    required this.logModel,
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

  Map<String, String> get copyableFields {
    final map = <String, String>{};

    if (type == DioLogType.request) {
      final curlString = logCurl ?? _generateCurl();
      if (curlString != null && curlString.isNotEmpty) {
        map['curl'] = curlString;
      }
    }

    return map;
  }

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

    void addWrapped(String label, dynamic value, {int? maxContentLength}) {
      if (value == null) return;
      String content = value.toString();
      if (maxContentLength != null && content.length > maxContentLength) {
        content = '${content.substring(0, maxContentLength - 3)}...';
      }
      final wrapped = _wrapToLinesWithPrefix(
        '║ $label: ',
        content,
        maxLineLength,
      );
      for (final l in wrapped) {
        outLines.add('$colorCode$l$resetColor');
      }
    }

    if (type == DioLogType.request && logModel.isRequestEnabled) {
      if (url != null) outLines.add('$colorCode║ URL: $url$resetColor');
      if (method != null) {
        outLines.add('$colorCode║ Method: $method$resetColor');
      }
      if (isRefreshHandle) {
        outLines.add(
          '$colorCode║ * This request for handle 401 error. *$resetColor',
        );
      }
      if (isCache) {
        outLines.add('$colorCode║ * This request is caching. *$resetColor');
      }
      if (headers != null) {
        addWrapped('Headers', headers, maxContentLength: 800);
      }
      if (parameters != null) {
        addWrapped('Parameters', parameters, maxContentLength: 600);
      }
      if (extra != null) {
        addWrapped('Extra', extra, maxContentLength: 600);
      }
      if (data != null) {
        final dataString = data.toString();
        addWrapped('Data', dataString, maxContentLength: 400);
      }
    } else if (type == DioLogType.retry && logModel.isRetryEnabled) {
      outLines.add(
        '$colorCode║ * Retry the request based on the RetryOption... * $resetColor',
      );
      if (statusCode != null) {
        outLines.add('$colorCode║ Status Code: $statusCode$resetColor');
      }
      if (message != null) {
        outLines.add('$colorCode║ Message: $message$resetColor');
      }
      if (retryCount != null) {
        outLines.add(
          '$colorCode║ * ${numberToOrdinalUpTo10(retryCount! + 2)} attempt of $maxAttempts attempts * $resetColor',
        );
      }
      if (url != null) {
        outLines.add('$colorCode║ URL: $url$resetColor');
      }
      if (method != null) {
        outLines.add('$colorCode║ Method: $method$resetColor');
      }
      if (isCache) {
        outLines.add('$colorCode║ * This request is caching. *$resetColor');
      }
      if (headers != null) {
        addWrapped('Headers', headers, maxContentLength: 800);
      }
      if (parameters != null) {
        addWrapped('Parameters', parameters, maxContentLength: 600);
      }
      if (extra != null) {
        addWrapped('Extra', extra, maxContentLength: 600);
      }
    } else if (type == DioLogType.response && logModel.isResponseEnabled) {
      if (url != null) outLines.add('$colorCode║ URL: $url$resetColor');
      if (method != null) {
        outLines.add('$colorCode║ Method: $method$resetColor');
      }
      if (isRefreshHandle) {
        outLines.add(
          '$colorCode║ * Token successfully refreshed. *$resetColor',
        );
      }
      if (isCache) {
        outLines.add(
          '$colorCode║ * The stored response has been returned. *$resetColor',
        );
      }
      if (statusCode != null) {
        outLines.add('$colorCode║ Status Code: $statusCode$resetColor');
      }
      if (message != null) {
        outLines.add('$colorCode║ Message: $message$resetColor');
      }
      if (headers != null) {
        addWrapped('Headers', headers, maxContentLength: 800);
      }
      if (parameters != null) {
        addWrapped('Parameters', parameters, maxContentLength: 600);
      }
      if (extra != null) {
        addWrapped('Extra', extra, maxContentLength: 600);
      }

      final curlString = logCurl ?? _generateCurl();
      if (curlString != null) {
        addWrapped('Curl', curlString, maxContentLength: 600);
      }

      if (data != null) {
        final dataString = data.toString();
        addWrapped('Data', dataString);
      }
    } else if (type == DioLogType.error && logModel.isErrorEnabled) {
      if (url != null) outLines.add('$colorCode║ URL: $url$resetColor');
      if (method != null) {
        outLines.add('$colorCode║ Method: $method$resetColor');
      }
      if (isRefreshHandle) {
        outLines.add('$colorCode║ * Token refresh failed... *$resetColor');
      }
      if (statusCode != null) {
        outLines.add('$colorCode║ Status Code: $statusCode$resetColor');
      }
      if (errorType != null) {
        outLines.add(
          '$colorCode║ ErrorType: ${errorType!.userFriendlyMessage} $resetColor',
        );
      }
      if (message != null) {
        outLines.add('$colorCode║ Message: $message$resetColor');
      }
      if (error != null) {
        addWrapped('Error', error, maxContentLength: 800);
      }
      if (stackTrace != null) {
        addWrapped('Stack Trace', stackTrace, maxContentLength: 800);
      }
      if (headers != null) {
        addWrapped('Headers', headers, maxContentLength: 800);
      }
      if (parameters != null) {
        addWrapped('Parameters', parameters, maxContentLength: 600);
      }
      if (extra != null) {
        addWrapped('Extra', extra, maxContentLength: 600);
      }

      final curlString = logCurl ?? _generateCurl();
      if (curlString != null) {
        addWrapped('Curl', curlString, maxContentLength: 600);
      }
    }

    outLines.add(
      '$colorCode╚═════════════════════════════════════════════════════════════════╝$resetColor',
    );

    for (final line in outLines) {
      if (kDebugMode) {
        print(line);
      }
    }

    final bool shouldPrintCurlCopy = type == DioLogType.request;
    final curlStringFull =
        shouldPrintCurlCopy ? (logCurl ?? _generateCurl()) : null;
    final hasCurl = curlStringFull != null && curlStringFull.isNotEmpty;

    if (hasCurl && kDebugMode) {
      if (kDebugMode) {
        print('');
      }
      _printCopyChunks('CURL_REQUEST', curlStringFull);
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

    final int contSpaces = firstPrefix.length > 2 ? firstPrefix.length - 2 : 2;
    final String contPrefix = '║ ${''.padLeft(contSpaces)}';

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

  String? _generateCurl() {
    if (url == null || method == null) return null;

    final buffer = StringBuffer();
    buffer.write("curl -X $method '$url'");

    headers?.forEach((key, value) {
      if (key.toLowerCase() == 'content-length') return;
      buffer.write(" -H '$key: $value'");
    });

    final body = data;
    if (body != null) {
      if (body is FormData) {
        for (final field in body.fields) {
          final name = field.key;
          final value = field.value.toString().replaceAll("'", "\\'");
          buffer.write(" -F '$name=$value'");
        }

        for (final fileEntry in body.files) {
          final name = fileEntry.key;
          final mf = fileEntry.value;

          final filename =
              (mf.filename ?? 'file').toString().replaceAll("'", "\\'");
          final contentType = mf.contentType?.toString();

          if (contentType != null && contentType.isNotEmpty) {
            buffer.write(" -F '$name=@$filename;type=$contentType'");
          } else {
            buffer.write(" -F '$name=@$filename'");
          }
        }
      } else {
        final raw = body.toString().replaceAll("'", "\\'");
        buffer.write(" --data-raw '$raw'");
      }
    }

    return buffer.toString();
  }

  void _printCopyChunks(String label, String value) {
    if (!kDebugMode) return;

    const int chunkSize = 800;
    if (value.length <= chunkSize) {
      if (kDebugMode) {
        print('$label >> $value');
      }
      return;
    }

    int index = 0;
    while (index < value.length) {
      final end =
          (index + chunkSize < value.length) ? index + chunkSize : value.length;
      final chunk = value.substring(index, end);
      if (kDebugMode) {
        print('$label >> $chunk');
      }
      index = end;
    }
  }
}
