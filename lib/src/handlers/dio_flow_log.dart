import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:dio_flow/dio_flow.dart';
import 'package:dio_flow/src/handlers/console_style_support_stub.dart'
    if (dart.library.io) 'package:dio_flow/src/handlers/console_style_support_io.dart';
import 'package:dio_flow/src/handlers/dio_hndler_helper.dart';
import 'package:dio_flow/src/handlers/dio_log_formatter.dart';
import 'package:flutter/foundation.dart';

enum DioLogType { request, response, error, retry }

class DioFlowLog {
  static bool? ansiColorsEnabledOverride;
  static bool _sensitiveCopyWarningPrinted = false;

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
  final bool isMock;
  final Duration? duration;

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
    this.isMock = false,
    this.duration,
  });

  Map<String, String> get copyableFields {
    if (type != DioLogType.request || !logModel.defaultLog) {
      return const {};
    }
    final curl = logCurl ?? _generateCurl();
    return curl == null || curl.isEmpty ? const {} : {'curl': curl};
  }

  void log() {
    if (!kDebugMode || !logModel.defaultLog || !_isTypeEnabled) return;

    final associatedCurl = logCurl ?? _generateCurl();
    final curlCopy =
        type == DioLogType.request &&
                associatedCurl != null &&
                associatedCurl.isNotEmpty
            ? associatedCurl
            : null;
    final responseCopy =
        (type == DioLogType.response || type == DioLogType.error) &&
                data != null
            ? formatCopyLogValue(
              data,
              maskSensitiveData: !logModel.includeSensitiveDataInCopyLogs,
            )
            : null;
    final plainText = _buildPlainText();

    try {
      logModel.logSink?.call(
        DioFlowRawLog(
          type: type.name.toUpperCase(),
          plainText: plainText,
          curl:
              associatedCurl == null || associatedCurl.isEmpty
                  ? null
                  : associatedCurl,
          responseJson: responseCopy,
        ),
      );
    } catch (_) {
      // A diagnostic sink must never change request behavior.
    }

    if (logModel.includeSensitiveDataInCopyLogs &&
        (curlCopy != null || responseCopy != null) &&
        !_sensitiveCopyWarningPrinted) {
      _sensitiveCopyWarningPrinted = true;
      debugPrint(
        '[DioFlow][WARNING] Copy logs include explicitly enabled sensitive data.',
        wrapWidth: null,
      );
    }

    final buffer = StringBuffer(_buildVisualFrame());
    if (curlCopy != null) {
      buffer
        ..write('\n\nCURL COPY >>\n')
        ..write(curlCopy);
    }
    if (responseCopy != null) {
      buffer
        ..write('\n\nRESPONSE COPY >>\n')
        ..write(responseCopy);
    }
    debugPrint(buffer.toString(), wrapWidth: null);
  }

  static void resetSensitiveCopyWarningForTesting() {
    _sensitiveCopyWarningPrinted = false;
  }

  String _buildVisualFrame() {
    final buffer = StringBuffer(
      '[DioFlow][${type.name.toUpperCase()}]\n$_topBorder',
    );
    for (final field in _fields) {
      if (field.value != null) {
        _writeFramedField(buffer, field.label, field.value, color: field.color);
      }
    }
    buffer.write('\n${_styleSuffix(_bottomBorder, _typeColor)}');
    return buffer.toString();
  }

  String _buildPlainText() {
    final buffer = StringBuffer('Type: ${type.name.toUpperCase()}');
    for (final field in _fields) {
      if (field.value != null) {
        buffer
          ..write('\n${field.label}: ')
          ..write(formatLogValue(field.value));
      }
    }
    return buffer.toString();
  }

  List<({String label, dynamic value, String color})> get _fields {
    final source =
        isMock
            ? 'mock'
            : type == DioLogType.request && isCache
            ? 'cache lookup'
            : type == DioLogType.response && isCache
            ? 'cache (hit)'
            : type == DioLogType.response && extra?['shouldCache'] == true
            ? 'network (cache miss)'
            : null;
    final sourceColor =
        isMock
            ? _magenta
            : source?.contains('cache') == true
            ? _blue
            : _typeColor;
    final operation =
        type == DioLogType.request && data is FormData
            ? 'upload'
            : type == DioLogType.response && _containsBinary(data)
            ? 'download'
            : null;
    final commonContext = <({String label, dynamic value, String color})>[
      (label: 'Source', value: source, color: sourceColor),
      (label: 'Operation', value: operation, color: _cyan),
      (
        label: 'Refresh Token',
        value: isRefreshHandle ? true : null,
        color: _orange,
      ),
    ];

    return switch (type) {
      DioLogType.request => [
        (label: 'URL', value: url, color: _typeColor),
        (label: 'Method', value: method, color: _typeColor),
        ...commonContext,
        (label: 'Query', value: parameters, color: _typeColor),
        (label: 'Headers', value: headers, color: _typeColor),
        (label: 'Body', value: data, color: _typeColor),
        (label: 'Extra', value: extra, color: _typeColor),
      ],
      DioLogType.response => [
        (label: 'Status Code', value: statusCode, color: _typeColor),
        (label: 'Duration', value: _formattedDuration, color: _typeColor),
        (label: 'URL', value: url, color: _typeColor),
        (label: 'Method', value: method, color: _typeColor),
        ...commonContext,
        (label: 'Headers', value: headers, color: _typeColor),
        (label: 'Data', value: data, color: _typeColor),
        (label: 'Message', value: message, color: _typeColor),
        (label: 'Extra', value: extra, color: _typeColor),
      ],
      DioLogType.error => [
        (label: 'Status Code', value: statusCode, color: _typeColor),
        (label: 'Duration', value: _formattedDuration, color: _typeColor),
        (label: 'URL', value: url, color: _typeColor),
        (label: 'Method', value: method, color: _typeColor),
        ...commonContext,
        (label: 'Headers', value: headers, color: _typeColor),
        (label: 'Data', value: data, color: _typeColor),
        (label: 'Message', value: message, color: _typeColor),
        (label: 'Error Type', value: errorType?.name, color: _typeColor),
        (label: 'Error', value: error, color: _typeColor),
        (label: 'Extra', value: extra, color: _typeColor),
        (
          label: 'Stack Trace',
          value: stackTrace?.toString(),
          color: _typeColor,
        ),
      ],
      DioLogType.retry => [
        (label: 'Status Code', value: statusCode, color: _typeColor),
        (label: 'Duration', value: _formattedDuration, color: _typeColor),
        (
          label: 'Attempt',
          value: retryCount == null ? null : (retryCount! + 2),
          color: _typeColor,
        ),
        (label: 'Max Attempts', value: maxAttempts, color: _typeColor),
        (label: 'URL', value: url, color: _typeColor),
        (label: 'Method', value: method, color: _typeColor),
        ...commonContext,
        (label: 'Query', value: parameters, color: _typeColor),
        (label: 'Headers', value: headers, color: _typeColor),
        (label: 'Body', value: data, color: _typeColor),
        (label: 'Message', value: message, color: _typeColor),
        (label: 'Extra', value: extra, color: _typeColor),
      ],
    };
  }

  String get _topBorder {
    const width = 68;
    final title = [
      type.name.toUpperCase(),
      for (final tag in _contextTags) tag.label,
    ].join(' · ');
    final remaining = (width - title.length - 2).clamp(2, width);
    final left = remaining ~/ 2;
    final right = remaining - left;
    final styledTitle = StringBuffer(
      _styleSuffix(' ${type.name.toUpperCase()}', _typeColor),
    );
    for (final tag in _contextTags) {
      styledTitle.write(_styleSuffix(' · ${tag.label}', tag.color));
    }
    styledTitle.write(_styleSuffix(' ', _typeColor));
    return '${_styleSuffix('╭${'─' * left}', _typeColor)}'
        '$styledTitle'
        '${_styleSuffix('${'─' * right}╮', _typeColor)}';
  }

  String get _bottomBorder => '╰${'─' * 66}╯';

  List<({String label, String color})> get _contextTags => [
    if (isRefreshHandle) (label: 'REFRESH TOKEN', color: _orange),
    if (isCache)
      (
        label: type == DioLogType.response ? 'CACHE HIT' : 'CACHE LOOKUP',
        color: _blue,
      )
    else if (type == DioLogType.response && extra?['shouldCache'] == true)
      (label: 'CACHE MISS', color: _blue),
    if (isMock) (label: 'MOCK', color: _magenta),
    if (type == DioLogType.request && data is FormData)
      (label: 'UPLOAD', color: _cyan),
    if (type == DioLogType.response && _containsBinary(data))
      (label: 'DOWNLOAD', color: _cyan),
  ];

  String? get _formattedDuration {
    if (duration == null) return null;
    final milliseconds =
        duration!.inMicroseconds / Duration.microsecondsPerMillisecond;
    final value = milliseconds
        .toStringAsFixed(3)
        .replaceFirst(RegExp(r'\.?0+$'), '');
    return '${value}ms';
  }

  String get _typeColor => switch (type) {
    DioLogType.request => _yellow,
    DioLogType.response => _green,
    DioLogType.error => _red,
    DioLogType.retry => _brightCyan,
  };

  bool get _useAnsiColors => ansiColorsEnabledOverride ?? supportsAnsiConsole;

  String _styleSuffix(String value, String color) {
    if (!_useAnsiColors) return value;
    return '$color$value$_reset';
  }

  bool get _isTypeEnabled => switch (type) {
    DioLogType.request => logModel.isRequestEnabled,
    DioLogType.response => logModel.isResponseEnabled,
    DioLogType.error => logModel.isErrorEnabled,
    DioLogType.retry => logModel.isRetryEnabled,
  };

  void _writeFramedField(
    StringBuffer buffer,
    String label,
    dynamic value, {
    required String color,
  }) {
    final lines = formatLogValue(value).split('\n');
    buffer.write('\n${_styleSuffix('│ $label:', color)}');
    if (lines.length == 1) {
      buffer.write(' ${lines.single}');
      return;
    }
    for (final line in lines) {
      buffer.write('\n${_styleSuffix('│ ', _typeColor)}$line');
    }
  }

  bool _containsBinary(dynamic value) {
    if (value is Uint8List || value is ByteBuffer) return true;
    if (value is Map) return value.values.any(_containsBinary);
    if (value is Iterable) return value.any(_containsBinary);
    return false;
  }

  String? _generateCurl() {
    if (url == null || method == null) return null;
    final uri = Uri.tryParse(url!);
    if (uri == null) return null;
    return DioHndlerHelper.curlCommand(
      methodOverride: method!,
      baseUrl: uri.origin,
      endpointPath: uri.path,
      parameters: parameters,
      data: data,
      headers: headers,
      includeSensitiveData: logModel.includeSensitiveDataInCopyLogs,
    );
  }

  String numberToOrdinalUpTo10(int n) {
    const ordinals = [
      '',
      'first',
      'second',
      'third',
      'fourth',
      'fifth',
      'sixth',
      'seventh',
      'eighth',
      'ninth',
      'tenth',
    ];
    return n >= 1 && n <= 10
        ? ordinals[n]
        : 'out of range (only 1..10 supported)';
  }
}

const _reset = '\x1B[0m';
const _yellow = '\x1B[33m';
const _green = '\x1B[32m';
const _red = '\x1B[31m';
const _cyan = '\x1B[36m';
const _brightCyan = '\x1B[38;5;81m';
const _orange = '\x1B[38;5;208m';
const _blue = '\x1B[34m';
const _magenta = '\x1B[35m';
