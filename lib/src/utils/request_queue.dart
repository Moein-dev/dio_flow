import 'dart:async';
import 'package:dio/dio.dart';
import 'package:dio_flow/src/base/api_client.dart';
import 'package:dio_flow/src/utils/network_checker.dart';

class QueuedRequest {
  final String method;
  final String path;
  final Map<String, dynamic>? data;
  final Map<String, dynamic>? queryParameters;
  final Options? options;
  final Completer<Response> completer;

  QueuedRequest({
    required this.method,
    required this.path,
    this.data,
    this.queryParameters,
    this.options,
    required this.completer,
  });
}

class RequestQueue {
  static final List<QueuedRequest> _queue = [];
  static bool _isProcessing = false;
  static StreamSubscription? _connectivitySubscription;

  static void initialize() {
    _connectivitySubscription = NetworkChecker.connectionStream.listen((
      hasConnection,
    ) {
      if (hasConnection) {
        _processQueue();
      }
    });
  }

  static void dispose() {
    _connectivitySubscription?.cancel();
    _queue.clear();
    _isProcessing = false;
  }

  static Future<Response> enqueue(QueuedRequest request) async {
    _queue.add(request);
    if (!_isProcessing) {
      _processQueue();
    }
    return request.completer.future;
  }

  static Future<void> _processQueue() async {
    if (_isProcessing || _queue.isEmpty) return;
    _isProcessing = true;

    while (_queue.isNotEmpty) {
      if (!await NetworkChecker.hasConnection()) {
        _isProcessing = false;
        return;
      }

      final request = _queue.removeAt(0);
      try {
        final response = await ApiClient.dio.request(
          request.path,
          data: request.data,
          queryParameters: request.queryParameters,
          options: request.options?.copyWith(method: request.method),
        );
        request.completer.complete(response);
      } catch (e) {
        request.completer.completeError(e);
      }
    }

    _isProcessing = false;
  }

  static void clear() {
    for (final request in _queue) {
      request.completer.completeError(
        DioException(
          requestOptions: RequestOptions(path: request.path),
          error: 'Request cancelled due to queue clear',
        ),
      );
    }
    _queue.clear();
  }

  static int get queueLength => _queue.length;
  static bool get isProcessing => _isProcessing;
}
