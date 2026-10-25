import 'dart:io';

import 'package:dio/dio.dart';

Future<MultipartFile?> multipartFileFromValue(
  Object? value, {
  required String fieldName,
}) async {
  if (value is! File) {
    return null;
  }

  return MultipartFile.fromFile(
    value.path,
    filename: value.uri.pathSegments.last,
  );
}
