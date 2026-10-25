import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';

typedef AdapterStep =
    Future<ResponseBody> Function(
      RequestOptions options,
      Stream<Uint8List>? requestStream,
      Future<void>? cancelFuture,
    );

class ScriptedAdapter implements HttpClientAdapter {
  ScriptedAdapter(this.steps);

  final List<AdapterStep> steps;
  final List<RequestOptions> requests = [];
  final List<List<int>> requestBodies = [];
  var closed = false;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    final body = <int>[];
    if (requestStream != null) {
      await for (final chunk in requestStream) {
        body.addAll(chunk);
      }
    }
    requestBodies.add(body);

    final index = requests.length - 1;
    final step = steps[index < steps.length ? index : steps.length - 1];
    return step(options, null, cancelFuture);
  }

  @override
  void close({bool force = false}) {
    closed = true;
  }
}

AdapterStep jsonStep(Object? data, {int statusCode = 200}) {
  return (options, requestStream, cancelFuture) async {
    return ResponseBody.fromString(
      data == null ? '' : jsonEncode(data),
      statusCode,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  };
}

AdapterStep textStep(String data, {int statusCode = 200}) {
  return (options, requestStream, cancelFuture) async {
    return ResponseBody.fromString(
      data,
      statusCode,
      headers: {
        Headers.contentTypeHeader: [Headers.textPlainContentType],
      },
    );
  };
}

AdapterStep bytesStep(List<int> data, {int statusCode = 200}) {
  return (options, requestStream, cancelFuture) async {
    return ResponseBody.fromBytes(
      data,
      statusCode,
      headers: {
        Headers.contentTypeHeader: ['application/octet-stream'],
      },
    );
  };
}

AdapterStep errorStep(DioExceptionType type) {
  return (options, requestStream, cancelFuture) async {
    throw DioException(requestOptions: options, type: type);
  };
}
