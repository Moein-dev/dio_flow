import 'dart:typed_data';

import 'package:dio_flow/dio_flow.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('public library and bytes file APIs compile without dart:io', () {
    final bytes = Uint8List.fromList([1, 2, 3]);

    expect(bytes, hasLength(3));
    expect(FileHandler.uploadFile<Uint8List>, isA<Function>());
    expect(NetworkChecker.hasConnection, isA<Function>());
  });
}
