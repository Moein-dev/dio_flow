import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';

const String maskedLogValue = '********';

bool isSensitiveLogKey(String key) {
  final normalized = key.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
  return normalized.contains('authorization') ||
      normalized.contains('accesstoken') ||
      normalized.contains('refreshtoken') ||
      normalized == 'token' ||
      normalized.contains('cookie') ||
      normalized.contains('apikey') ||
      normalized.contains('password') ||
      normalized.contains('passwd') ||
      normalized.contains('secret') ||
      normalized.contains('credential');
}

dynamic sanitizeLogValue(
  dynamic value, {
  String? key,
  bool maskSensitiveData = true,
}) {
  if (maskSensitiveData && key != null && isSensitiveLogKey(key)) {
    return maskedLogValue;
  }
  if (value is FormData) {
    return {
      'fields': [
        for (final field in value.fields)
          {
            'name': field.key,
            'value':
                maskSensitiveData && isSensitiveLogKey(field.key)
                    ? maskedLogValue
                    : field.value,
          },
      ],
      'files': [
        for (final file in value.files)
          {
            'field': file.key,
            'filename': file.value.filename,
            'contentType': file.value.contentType?.toString(),
            'length': file.value.length,
          },
      ],
    };
  }
  if (value is Uint8List) {
    return 'BinaryData(type: Uint8List, length: ${value.length} bytes)';
  }
  if (value is ByteBuffer) {
    return 'BinaryData(type: ByteBuffer, length: ${value.lengthInBytes} bytes)';
  }
  if (value is MultipartFile) {
    return {
      'filename': value.filename,
      'contentType': value.contentType?.toString(),
      'length': value.length,
    };
  }
  if (value is Map) {
    return {
      for (final entry in value.entries)
        entry.key.toString(): sanitizeLogValue(
          entry.value,
          key: entry.key.toString(),
          maskSensitiveData: maskSensitiveData,
        ),
    };
  }
  if (value is Iterable) {
    return value
        .map(
          (item) =>
              sanitizeLogValue(item, maskSensitiveData: maskSensitiveData),
        )
        .toList(growable: false);
  }
  if (value is Stream) {
    return 'BinaryData(type: ${value.runtimeType}, streaming: true)';
  }
  return value;
}

String formatLogValue(dynamic value, {bool maskSensitiveData = true}) {
  final sanitized = sanitizeLogValue(
    value,
    maskSensitiveData: maskSensitiveData,
  );
  if (sanitized == null) return 'null';
  if (sanitized is String) return sanitized;
  if (sanitized is num || sanitized is bool) return sanitized.toString();
  try {
    return const JsonEncoder.withIndent('  ').convert(sanitized);
  } catch (_) {
    try {
      return sanitized.toString();
    } catch (_) {
      return '<unprintable ${value.runtimeType}>';
    }
  }
}

String formatCopyLogValue(dynamic value, {bool maskSensitiveData = true}) {
  final sanitized = sanitizeLogValue(
    value,
    maskSensitiveData: maskSensitiveData,
  );
  try {
    return const JsonEncoder.withIndent('  ').convert(sanitized);
  } catch (_) {
    try {
      return jsonEncode(sanitized.toString());
    } catch (_) {
      return '"<unprintable ${value.runtimeType}>"';
    }
  }
}
