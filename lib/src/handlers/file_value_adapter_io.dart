import 'dart:io';

import 'package:dio/dio.dart';

Future<MultipartFile?> multipartFileFromValue(
  Object? value, {
  required String fieldName,
  String? filename,
}) async {
  if (value is! File) {
    return null;
  }

  return MultipartFile.fromFile(
    value.path,
    filename: filename ?? value.uri.pathSegments.last,
  );
}
