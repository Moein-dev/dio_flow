import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:dio_flow/dio_flow.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/scripted_adapter.dart';

const _noLog = RequestOptionsModel(
  logModel: LogModel.disabledAllLog,
  retryOptions: RetryOptions(maxAttempts: 1, retryInterval: Duration.zero),
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    DioFlowConfig.initialize(baseUrl: 'https://api.example.com');
    await ApiClient.initialize();
  });

  tearDown(ApiClient.reset);

  test(
    'dispatches GET, POST, PUT, PATCH, and DELETE with parameters',
    () async {
      final adapter = ScriptedAdapter(List.filled(5, jsonStep({'ok': true})));
      ApiClient.dio.httpClientAdapter = adapter;

      await DioRequestHandler.get(
        '/users/{id}',
        pathParameters: {'id': 'a/b'},
        parameters: {'page': 2},
        requestOptions: _noLog,
      );
      await DioRequestHandler.post(
        '/users',
        data: {'name': 'A'},
        requestOptions: _noLog,
      );
      await DioRequestHandler.put(
        '/users/1',
        data: {'name': 'B'},
        requestOptions: _noLog,
      );
      await DioRequestHandler.patch(
        '/users/1',
        data: {'name': 'C'},
        requestOptions: _noLog,
      );
      await DioRequestHandler.delete('/users/1', requestOptions: _noLog);

      expect(adapter.requests.map((request) => request.method), [
        'GET',
        'POST',
        'PUT',
        'PATCH',
        'DELETE',
      ]);
      expect(adapter.requests.first.path, '/users/a%2Fb');
      expect(adapter.requests.first.queryParameters, {'page': 2});
      expect(adapter.requests[1].data, {'name': 'A'});
      expect(adapter.requests[2].data, {'name': 'B'});
      expect(adapter.requests[3].data, {'name': 'C'});
    },
  );

  test('normalizes Map, List, String, null, and bytes responses', () async {
    final adapter = ScriptedAdapter([
      jsonStep({'value': 1}),
      jsonStep([1, 2]),
      textStep('plain'),
      jsonStep(null),
      bytesStep([1, 2, 3]),
    ]);
    ApiClient.dio.httpClientAdapter = adapter;

    final map = await DioRequestHandler.get('/map', requestOptions: _noLog);
    final list = await DioRequestHandler.get('/list', requestOptions: _noLog);
    final text = await DioRequestHandler.get('/text', requestOptions: _noLog);
    final empty = await DioRequestHandler.get('/null', requestOptions: _noLog);
    final bytes = await DioRequestHandler.get(
      '/bytes',
      requestOptions: _noLog.copyWith(responseType: ResponseType.bytes),
    );

    expect(map.data, {'value': 1});
    expect(list.data, [1, 2]);
    expect(text.data, 'plain');
    expect(empty.data, isA<Map<String, dynamic>>());
    expect(bytes.data, Uint8List.fromList([1, 2, 3]));
  });

  test('maps non-2xx responses without throwing', () async {
    ApiClient.dio.httpClientAdapter = ScriptedAdapter([
      jsonStep({'message': 'missing'}, statusCode: 404),
    ]);

    final response = await DioRequestHandler.get(
      '/missing',
      requestOptions: _noLog,
    );

    expect(response, isA<FailedResponseModel>());
    expect(response.statusCode, 404);
    expect(response.message, 'missing');
  });

  test('retries configured status codes', () async {
    final adapter = ScriptedAdapter([
      jsonStep({'message': 'busy'}, statusCode: 503),
      jsonStep({'ok': true}),
    ]);
    ApiClient.dio.httpClientAdapter = adapter;

    final response = await DioRequestHandler.get(
      '/status-retry',
      requestOptions: _noLog.copyWith(
        retryOptions: const RetryOptions(
          maxAttempts: 2,
          retryInterval: Duration.zero,
        ),
      ),
    );

    expect(response.isSuccess, isTrue);
    expect(adapter.requests, hasLength(2));
  });

  test('network retry is independent of logging', () async {
    final adapter = ScriptedAdapter([
      errorStep(DioExceptionType.connectionTimeout),
      jsonStep({'ok': true}),
    ]);
    ApiClient.dio.httpClientAdapter = adapter;

    final response = await DioRequestHandler.get(
      '/network-retry',
      requestOptions: _noLog.copyWith(
        retryOptions: const RetryOptions(
          maxAttempts: 2,
          retryInterval: Duration.zero,
        ),
      ),
    );

    expect(response.isSuccess, isTrue);
    expect(adapter.requests, hasLength(2));
  });

  test('connection and receive timeout retry flags are honored', () async {
    final connectionAdapter = ScriptedAdapter([
      errorStep(DioExceptionType.connectionTimeout),
      jsonStep({'unexpected': true}),
    ]);
    ApiClient.dio.httpClientAdapter = connectionAdapter;

    final connectionResponse = await DioRequestHandler.get(
      '/connection-timeout',
      requestOptions: _noLog.copyWith(
        retryOptions: const RetryOptions(
          maxAttempts: 2,
          retryInterval: Duration.zero,
          retryOnConnectionTimeout: false,
        ),
      ),
    );

    expect(connectionResponse.isFailure, isTrue);
    expect(connectionAdapter.requests, hasLength(1));

    final receiveAdapter = ScriptedAdapter([
      errorStep(DioExceptionType.receiveTimeout),
      jsonStep({'unexpected': true}),
    ]);
    ApiClient.dio.httpClientAdapter = receiveAdapter;

    final receiveResponse = await DioRequestHandler.get(
      '/receive-timeout',
      requestOptions: _noLog.copyWith(
        retryOptions: const RetryOptions(
          maxAttempts: 2,
          retryInterval: Duration.zero,
          retryOnReceiveTimeout: false,
        ),
      ),
    );

    expect(receiveResponse.isFailure, isTrue);
    expect(receiveAdapter.requests, hasLength(1));
  });

  test('maxAttempts one disables retries', () async {
    final adapter = ScriptedAdapter([
      errorStep(DioExceptionType.connectionError),
      jsonStep({'unexpected': true}),
    ]);
    ApiClient.dio.httpClientAdapter = adapter;

    await DioRequestHandler.get('/no-retry', requestOptions: _noLog);

    expect(adapter.requests, hasLength(1));
  });

  test(
    'cancellation returns the cancellation response and does not retry',
    () async {
      final adapter = ScriptedAdapter([
        (options, requestStream, cancelFuture) async {
          await cancelFuture;
          throw DioException(
            requestOptions: options,
            type: DioExceptionType.cancel,
          );
        },
      ]);
      ApiClient.dio.httpClientAdapter = adapter;
      final cancelToken = CancelToken();

      final future = DioRequestHandler.get(
        '/cancel',
        cancelToken: cancelToken,
        requestOptions: _noLog.copyWith(
          retryOptions: const RetryOptions(
            maxAttempts: 3,
            retryInterval: Duration.zero,
          ),
        ),
      );
      cancelToken.cancel('test');
      final response = await future;

      expect(response.statusCode, 499);
      expect(adapter.requests, isEmpty);
    },
  );

  test('clones FormData when retrying', () async {
    final adapter = ScriptedAdapter([
      jsonStep({'message': 'busy'}, statusCode: 503),
      jsonStep({'ok': true}),
    ]);
    ApiClient.dio.httpClientAdapter = adapter;
    final formData = FormData.fromMap({
      'name': 'document',
      'file': MultipartFile.fromBytes([1, 2, 3], filename: 'test.bin'),
    });

    final response = await DioRequestHandler.post(
      '/upload',
      data: formData,
      requestOptions: _noLog.copyWith(
        retryOptions: const RetryOptions(
          maxAttempts: 2,
          retryInterval: Duration.zero,
        ),
      ),
    );

    expect(response.isSuccess, isTrue);
    expect(adapter.requestBodies, hasLength(2));
    expect(adapter.requestBodies.every((body) => body.isNotEmpty), isTrue);
    expect(adapter.requestBodies[1], adapter.requestBodies[0]);
  });

  test('refreshes a 401 request only once', () async {
    await TokenManager.initialize();
    await TokenManager.setTokens(
      accessToken: 'old',
      refreshToken: 'refresh',
      expiry: DateTime.now().add(const Duration(hours: 1)),
    );
    var refreshCount = 0;
    TokenManager.setRefreshHandler((refreshToken) async {
      refreshCount++;
      return RefreshTokenResponse(
        accessToken: 'new',
        refreshToken: refreshToken,
        expiry: DateTime.now().add(const Duration(hours: 1)),
      );
    });
    final adapter = ScriptedAdapter(
      List.filled(3, (options, requestStream, cancelFuture) async {
        return ResponseBody.fromString(
          '{"message":"unauthorized"}',
          401,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
      }),
    );
    ApiClient.dio.httpClientAdapter = adapter;

    final response = await DioRequestHandler.get(
      '/protected',
      requestOptions: _noLog.copyWith(hasBearerToken: true),
    );

    expect(response.statusCode, 401);
    expect(refreshCount, 1);
    expect(adapter.requests, hasLength(2));
    expect(adapter.requests.last.headers['Authorization'], 'Bearer new');
  });

  test('coordinates one refresh for concurrent 401 requests', () async {
    await TokenManager.initialize();
    await TokenManager.setTokens(
      accessToken: 'old',
      refreshToken: 'refresh',
      expiry: DateTime.now().add(const Duration(hours: 1)),
    );
    var refreshCount = 0;
    TokenManager.setRefreshHandler((refreshToken) async {
      refreshCount++;
      await Future<void>.delayed(const Duration(milliseconds: 20));
      return RefreshTokenResponse(
        accessToken: 'new',
        refreshToken: refreshToken,
        expiry: DateTime.now().add(const Duration(hours: 1)),
      );
    });
    final adapter = ScriptedAdapter(
      List.filled(6, (options, requestStream, cancelFuture) async {
        final authorized = options.headers['Authorization'] == 'Bearer new';
        return ResponseBody.fromString(
          authorized ? '{"ok":true}' : '{"message":"unauthorized"}',
          authorized ? 200 : 401,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
      }),
    );
    ApiClient.dio.httpClientAdapter = adapter;

    final responses = await Future.wait([
      DioRequestHandler.get(
        '/protected/1',
        requestOptions: _noLog.copyWith(hasBearerToken: true),
      ),
      DioRequestHandler.get(
        '/protected/2',
        requestOptions: _noLog.copyWith(hasBearerToken: true),
      ),
      DioRequestHandler.get(
        '/protected/3',
        requestOptions: _noLog.copyWith(hasBearerToken: true),
      ),
    ]);

    expect(responses.every((response) => response.isSuccess), isTrue);
    expect(refreshCount, 1);
    expect(adapter.requests, hasLength(6));
  });
}
