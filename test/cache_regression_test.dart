import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:dio_flow/dio_flow.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/scripted_adapter.dart';

const _cachedRequest = RequestOptionsModel(
  logModel: LogModel.disabledAllLog,
  cacheOptions: CacheOptions(
    shouldCache: true,
    cacheDuration: Duration(minutes: 5),
  ),
  retryOptions: RetryOptions(maxAttempts: 1, retryInterval: Duration.zero),
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({'host_key': 'keep'});
    DioFlowConfig.initialize(baseUrl: 'https://api.example.com');
    await ApiClient.initialize();
  });

  tearDown(ApiClient.reset);

  test('cache key is stable and isolated by query parameters', () async {
    final adapter = ScriptedAdapter([
      jsonStep({'value': 1}),
      jsonStep({'value': 2}),
    ]);
    ApiClient.dio.httpClientAdapter = adapter;

    final first = await DioRequestHandler.get(
      '/items',
      parameters: {'b': 2, 'a': 1},
      requestOptions: _cachedRequest,
    );
    final hit = await DioRequestHandler.get(
      '/items',
      parameters: {'a': 1, 'b': 2},
      requestOptions: _cachedRequest,
    );
    final isolated = await DioRequestHandler.get(
      '/items',
      parameters: {'a': 2, 'b': 2},
      requestOptions: _cachedRequest,
    );

    expect(first.data, {'value': 1});
    expect(hit.data, {'value': 1});
    expect(isolated.data, {'value': 2});
    expect(adapter.requests, hasLength(2));
  });

  test('expired entries are removed and fetched again', () async {
    final adapter = ScriptedAdapter([
      jsonStep({'value': 1}),
      jsonStep({'value': 2}),
    ]);
    ApiClient.dio.httpClientAdapter = adapter;
    final options = _cachedRequest.copyWith(
      cacheOptions: const CacheOptions(
        shouldCache: true,
        cacheDuration: Duration.zero,
      ),
    );

    await DioRequestHandler.get('/expired', requestOptions: options);
    final response = await DioRequestHandler.get(
      '/expired',
      requestOptions: options,
    );

    expect(response.data, {'value': 2});
    expect(adapter.requests, hasLength(2));
  });

  test('clearCache removes only DioFlow cache keys', () async {
    final adapter = ScriptedAdapter([
      jsonStep({'value': 1}),
    ]);
    ApiClient.dio.httpClientAdapter = adapter;
    await DioRequestHandler.get('/cached', requestOptions: _cachedRequest);
    final preferences = await SharedPreferences.getInstance();
    expect(
      preferences.getKeys().any((key) => key.startsWith('api_cache_')),
      isTrue,
    );

    await ApiClient.clearCache();

    expect(preferences.getString('host_key'), 'keep');
    expect(
      preferences.getKeys().any((key) => key.startsWith('api_cache_')),
      isFalse,
    );
  });

  test('non-JSON-encodable responses do not fail the request', () async {
    final adapter = ScriptedAdapter([
      (options, requestStream, cancelFuture) async {
        return ResponseBody(
          Stream.value(Uint8List.fromList([1, 2, 3])),
          200,
          headers: {
            Headers.contentTypeHeader: ['application/octet-stream'],
          },
        );
      },
    ]);
    ApiClient.dio.httpClientAdapter = adapter;

    final response = await DioRequestHandler.get(
      '/stream',
      requestOptions: _cachedRequest.copyWith(
        responseType: ResponseType.stream,
      ),
    );

    expect(response.isSuccess, isTrue);
    expect(adapter.requests, hasLength(1));
  });

  test(
    'reset closes both Dio clients and allows clean initialization',
    () async {
      final requestAdapter = ScriptedAdapter([
        jsonStep({'ok': true}),
      ]);
      final refreshAdapter = ScriptedAdapter([
        jsonStep({'ok': true}),
      ]);
      final oldDio = ApiClient.dio..httpClientAdapter = requestAdapter;
      final oldRefreshDio =
          ApiClient.refreshDio..httpClientAdapter = refreshAdapter;

      ApiClient.reset();

      expect(requestAdapter.closed, isTrue);
      expect(refreshAdapter.closed, isTrue);
      await ApiClient.initialize();
      expect(ApiClient.dio, isNot(same(oldDio)));
      expect(ApiClient.refreshDio, isNot(same(oldRefreshDio)));
    },
  );
}
