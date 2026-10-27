import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart' show ResponseType;
import 'package:dio_flow/dio_flow.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/scripted_adapter.dart';

void main() {
  setUp(() {
    DioFlowConfig.initialize(baseUrl: 'https://api.example.com');
    MockDioFlow.enableMockMode();
    MockDioFlow.clearAllMocks();
  });

  tearDown(() {
    MockDioFlow.disableMockMode();
    ApiClient.reset();
  });

  test('uploads bytes through the existing mock request flow', () async {
    MockDioFlow.mockResponse(
      '/upload',
      MockResponse.success({'uploaded': true}),
      method: 'POST',
    );

    final response = await FileHandler.uploadFile<Uint8List>('/upload', {
      'file': Uint8List.fromList([1, 2, 3]),
    }, UploadMethodsEnum.post);

    expect(response.isSuccess, isTrue);
    expect(response.data, {'uploaded': true});
  });

  test(
    'rejects unsupported file values without dispatching a request',
    () async {
      final response = await FileHandler.uploadFile<Object>('/upload', {
        'file': Object(),
      }, UploadMethodsEnum.post);

      expect(response.isFailure, isTrue);
      expect(response.message, 'Format Not Supported');
    },
  );

  test('calculates file progress safely', () {
    expect(FileProgress(50, 100).percentage, 50);
    expect(FileProgress(1, 0).percentage, 0);
  });

  test('forwards upload progress without consuming multipart data', () async {
    MockDioFlow.disableMockMode();
    SharedPreferences.setMockInitialValues({});
    await ApiClient.initialize();
    final adapter = ScriptedAdapter([
      jsonStep({'uploaded': true}),
    ]);
    ApiClient.dio.httpClientAdapter = adapter;
    final progress = <FileProgress>[];

    final response = await FileHandler.uploadFile<Uint8List>(
      '/folders/{id}/upload',
      {
        'front': Uint8List.fromList([1, 2, 3]),
        'back': Uint8List.fromList([4, 5]),
      },
      UploadMethodsEnum.post,
      pathParameters: {'id': 'a/b'},
      additionalData: {'title': 'identity'},
      requestOptions: const RequestOptionsModel(
        customHeaders: {'X-Upload': 'profile'},
      ),
      onProgress: (sent, total) => progress.add(FileProgress(sent, total)),
    );

    expect(response.isSuccess, isTrue);
    expect(progress, isNotEmpty);
    expect(progress.last.sent, progress.last.total);
    expect(adapter.requestBodies.single, isNotEmpty);
    expect(adapter.requests.single.path, '/folders/a%2Fb/upload');
    expect(adapter.requests.single.headers['X-Upload'], 'profile');
  });

  test(
    'preserves legacy multipart filenames and field serialization',
    () async {
      MockDioFlow.disableMockMode();
      SharedPreferences.setMockInitialValues({});
      await ApiClient.initialize();
      final adapter = ScriptedAdapter([
        jsonStep({'uploaded': true}),
      ]);
      ApiClient.dio.httpClientAdapter = adapter;

      final response = await FileHandler.uploadFile<Uint8List>(
        '/upload',
        {
          'avatar': Uint8List.fromList([1, 2, 3]),
        },
        UploadMethodsEnum.post,
        additionalData: {
          'scalar': 'profile',
          'colors': ['blue', 'green'],
          'metadata': {'role': 'avatar'},
        },
      );

      final body = latin1.decode(adapter.requestBodies.single);
      expect(response.isSuccess, isTrue);
      expect(body, contains('name="avatar"; filename="avatar"'));
      expect(body, contains('name="scalar"\r\n\r\nprofile'));
      expect(body, contains('name="colors"\r\n\r\n[blue, green]'));
      expect(body, contains('name="metadata"\r\n\r\n{role: avatar}'));
    },
  );

  test(
    'supports custom filenames and opt-in List and Map serialization',
    () async {
      MockDioFlow.disableMockMode();
      SharedPreferences.setMockInitialValues({});
      await ApiClient.initialize();
      final adapter = ScriptedAdapter([
        jsonStep({'uploaded': true}),
      ]);
      ApiClient.dio.httpClientAdapter = adapter;

      final response = await FileHandler.uploadFile<Uint8List>(
        '/upload',
        {
          'avatar': Uint8List.fromList([1, 2, 3]),
        },
        UploadMethodsEnum.post,
        fileNames: {'avatar': 'avatar.jpg'},
        additionalData: {
          'labels': ['profile', 'public'],
          'metadata': {'role': 'avatar', 'active': true},
        },
        listSerialization: MultipartListSerialization.repeatedFields,
        mapSerialization: MultipartMapSerialization.json,
      );

      final body = latin1.decode(adapter.requestBodies.single);
      expect(response.isSuccess, isTrue);
      expect(body, contains('name="avatar"; filename="avatar.jpg"'));
      expect('name="labels"'.allMatches(body), hasLength(2));
      expect(body, contains('name="labels"\r\n\r\nprofile'));
      expect(body, contains('name="labels"\r\n\r\npublic'));
      expect(
        body,
        contains('name="metadata"\r\n\r\n{"role":"avatar","active":true}'),
      );
    },
  );

  test('downloads bytes and invokes onBytes only after success', () async {
    MockDioFlow.disableMockMode();
    SharedPreferences.setMockInitialValues({});
    await ApiClient.initialize();
    ApiClient.dio.httpClientAdapter = ScriptedAdapter([
      bytesStep([7, 8, 9]),
    ]);
    Uint8List? handled;

    final response = await FileHandler.downloadAndHandle(
      '/download',
      UploadMethodsEnum.post,
      onBytes: (bytes) async => handled = bytes,
    );

    expect(response.isSuccess, isTrue);
    expect(response.data, Uint8List.fromList([7, 8, 9]));
    expect(handled, Uint8List.fromList([7, 8, 9]));
  });

  test('download failures use the standard failed response model', () async {
    MockDioFlow.disableMockMode();
    SharedPreferences.setMockInitialValues({});
    await ApiClient.initialize();
    ApiClient.dio.httpClientAdapter = ScriptedAdapter([
      jsonStep({'message': 'unavailable'}, statusCode: 503),
    ]);

    final response = await FileHandler.downloadBytes(
      '/download',
      UploadMethodsEnum.post,
      requestOptions: const RequestOptionsModel(
        responseType: ResponseType.bytes,
        retryOptions: RetryOptions(maxAttempts: 1),
      ),
    );

    expect(response, isA<FailedResponseModel>());
    expect(response.statusCode, 503);
  });
}
