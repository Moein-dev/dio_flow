import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:dio_flow/dio_flow.dart';
import 'package:dio_flow/src/handlers/dio_flow_log.dart';
import 'package:dio_flow/src/handlers/dio_hndler_helper.dart';
import 'package:dio_flow/src/handlers/dio_log_formatter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/scripted_adapter.dart';

class _Unprintable {
  @override
  String toString() => throw StateError('cannot stringify');
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late DebugPrintCallback originalDebugPrint;
  late List<String> output;

  setUp(() {
    originalDebugPrint = debugPrint;
    output = [];
    DioFlowLog.ansiColorsEnabledOverride = false;
    DioFlowLog.resetSensitiveCopyWarningForTesting();
    debugPrint = (message, {wrapWidth}) {
      if (message != null) output.add(message);
    };
  });

  tearDown(() {
    debugPrint = originalDebugPrint;
    DioFlowLog.ansiColorsEnabledOverride = null;
    DioFlowLog.resetSensitiveCopyWarningForTesting();
    MockDioFlow.disableMockMode();
    ApiClient.reset();
  });

  Future<ScriptedAdapter> initializeWith(List<AdapterStep> steps) async {
    SharedPreferences.setMockInitialValues({});
    DioFlowConfig.initialize(baseUrl: 'https://api.example.com');
    await ApiClient.initialize();
    final adapter = ScriptedAdapter(steps);
    ApiClient.dio.httpClientAdapter = adapter;
    return adapter;
  }

  test('logging is disabled by default', () {
    final events = <DioFlowRawLog>[];
    expect(const LogModel().defaultLog, isFalse);
    expect(const RequestOptionsModel().logModel!.defaultLog, isFalse);

    DioFlowLog(
      logModel: LogModel(logSink: events.add),
      type: DioLogType.request,
      url: 'https://api.example.com/users',
      method: 'GET',
    ).log();

    expect(output, isEmpty);
    expect(events, isEmpty);
  });

  test('semantic colors affect decoration but not JSON or cURL values', () {
    DioFlowLog.ansiColorsEnabledOverride = true;

    DioFlowLog(
      logModel: const LogModel(defaultLog: true),
      type: DioLogType.request,
      url: 'https://api.example.com/users',
      method: 'POST',
      data: {
        'profile': {'name': 'Ada'},
      },
      logCurl: "curl -X 'POST' 'https://api.example.com/users'",
    ).log();
    DioFlowLog(
      logModel: const LogModel(defaultLog: true),
      type: DioLogType.response,
      statusCode: 200,
      data: {
        'profile': {'name': 'Ada'},
      },
    ).log();
    DioFlowLog(
      logModel: const LogModel(defaultLog: true),
      type: DioLogType.error,
      statusCode: 500,
    ).log();
    DioFlowLog(
      logModel: const LogModel(defaultLog: true),
      type: DioLogType.retry,
      retryCount: 0,
      maxAttempts: 2,
    ).log();

    expect(output[0], allOf(contains('REQUEST'), contains('\x1B[33m')));
    expect(output[1], allOf(contains('RESPONSE'), contains('\x1B[32m')));
    expect(output[2], allOf(contains('ERROR'), contains('\x1B[31m')));
    expect(output[3], allOf(contains('RETRY'), contains('\x1B[38;5;81m')));

    final curlCopy = _extractCopy(output[0], 'CURL COPY >>');
    final responseCopy = _extractCopy(output[1], 'RESPONSE COPY >>');
    expect(curlCopy, isNot(contains('\x1B')));
    expect(responseCopy, isNot(contains('\x1B')));
    expect(jsonDecode(responseCopy)['profile']['name'], 'Ada');
  });

  test('context tags keep distinct semantic colors', () {
    DioFlowLog.ansiColorsEnabledOverride = true;
    final formData = FormData.fromMap({
      'file': MultipartFile.fromBytes([1], filename: 'a.bin'),
    });

    DioFlowLog(
      logModel: const LogModel(defaultLog: true),
      type: DioLogType.request,
      data: formData,
      isRefreshHandle: true,
      isCache: true,
      isMock: true,
    ).log();
    DioFlowLog(
      logModel: const LogModel(defaultLog: true),
      type: DioLogType.response,
      data: Uint8List.fromList([1, 2, 3]),
      isCache: true,
    ).log();

    expect(output.first, contains('\x1B[38;5;208m'));
    expect(output.first, contains('\x1B[34m'));
    expect(output.first, contains('\x1B[35m'));
    expect(output.first, contains('\x1B[36m'));
    expect(output.last, contains('\x1B[32m'));
    expect(output.last, contains('\x1B[34m'));
    expect(output.last, contains('\x1B[36m'));
    expect(formData.isFinalized, isFalse);
  });

  test('plain fallback keeps type and content without ANSI escapes', () {
    DioFlowLog(
      logModel: const LogModel(defaultLog: true),
      type: DioLogType.response,
      statusCode: 200,
      isCache: true,
      data: {'ok': true},
    ).log();

    expect(output.single, startsWith('[DioFlow][RESPONSE]'));
    expect(output.single, contains('CACHE HIT'));
    expect(output.single, contains('"ok": true'));
    expect(output.single, isNot(contains('\x1B')));
  });

  test('automatic Web styling never emits raw ANSI escapes', () {
    DioFlowLog.ansiColorsEnabledOverride = null;

    DioFlowLog(
      logModel: const LogModel(defaultLog: true),
      type: DioLogType.request,
      url: 'https://api.example.com/users',
      method: 'GET',
    ).log();

    expect(output.single, contains('[DioFlow][REQUEST]'));
    if (kIsWeb) {
      expect(output.single, isNot(contains('\x1B')));
    }
  });

  test('disabled request does not build a response cURL', () async {
    SharedPreferences.setMockInitialValues({});
    DioFlowConfig.initialize(baseUrl: 'https://api.example.com');
    await ApiClient.initialize();
    ApiClient.dio.httpClientAdapter = ScriptedAdapter([
      jsonStep({'ok': true}),
    ]);

    final response = await DioRequestHandler.get('/users');

    expect(response.isSuccess, isTrue);
    expect(response.logCurl, isEmpty);
    expect(output, isEmpty);
  });

  test('enabled log is searchable, complete, pretty, and masked', () {
    final longValue = List.filled(1200, 'x').join();
    DioFlowLog(
      logModel: const LogModel(defaultLog: true),
      type: DioLogType.request,
      url: 'https://api.example.com/users',
      method: 'POST',
      parameters: {
        'page': 2,
        'access_token': 'query-secret',
        'token': 'query-token',
      },
      headers: {
        'Authorization': 'Bearer header-secret',
        'Cookie': 'session=cookie-secret',
        'X-API-Key': 'header-api-key',
        'Content-Type': 'application/json',
      },
      data: {
        'profile': {
          'password': 'body-password',
          'secret': 'body-secret',
          'api_key': 'body-api-key',
          'value': longValue,
        },
      },
      logCurl: "curl -X 'POST' 'https://api.example.com/users'",
    ).log();

    final log = output.single;
    expect(log, startsWith('[DioFlow][REQUEST]'));
    expect(log, contains('\n│   "profile": {'));
    expect(log, contains(longValue));
    expect(log, contains('"password": "********"'));
    expect(log, contains('"secret": "********"'));
    expect(log, contains('"api_key": "********"'));
    expect(log, contains('"access_token": "********"'));
    expect(log, contains('"token": "********"'));
    expect(log, contains('"Authorization": "********"'));
    expect(log, contains('"Cookie": "********"'));
    expect(log, contains('"X-API-Key": "********"'));
    expect(log, isNot(contains('body-password')));
    expect(log, isNot(contains('body-secret')));
    expect(log, isNot(contains('body-api-key')));
    expect(log, isNot(contains('query-secret')));
    expect(log, isNot(contains('query-token')));
    expect(log, isNot(contains('header-secret')));
    expect(log, isNot(contains('cookie-secret')));
    expect(log, isNot(contains('header-api-key')));
    expect('\nCURL COPY >>\n'.allMatches(log), hasLength(1));
    expect('https://api.example.com/users'.allMatches(log), hasLength(2));
  });

  test('formats primitives and unsafe values without throwing', () {
    expect(formatLogValue(null), 'null');
    expect(formatLogValue(true), 'true');
    expect(formatLogValue(12), '12');
    expect(formatLogValue('plain'), 'plain');
    expect(() => formatLogValue(_Unprintable()), returnsNormally);
  });

  test('describes FormData and binary data without consuming either', () {
    final formData = FormData.fromMap({
      'password': 'secret',
      'title': 'report',
      'file': MultipartFile.fromBytes([1, 2, 3], filename: 'report.bin'),
    });

    final formLog = formatLogValue(formData);
    final binaryLog = formatLogValue(Uint8List.fromList([1, 2, 3, 4]));

    expect(formData.isFinalized, isFalse);
    expect(formLog, contains('"filename": "report.bin"'));
    expect(formLog, contains('"length": 3'));
    expect(formLog, contains('"value": "********"'));
    expect(formLog, isNot(contains('Instance of')));
    expect(binaryLog, contains('length: 4 bytes'));
    expect(binaryLog, isNot(contains('[1, 2, 3, 4]')));
  });

  test('cURL masks sensitive headers, query, body, and form fields', () {
    final command = DioHndlerHelper.curlCommand(
      methodOverride: 'POST',
      baseUrl: 'https://api.example.com',
      endpointPath: '/users',
      parameters: {'page': 2},
      data: {'name': "O'Reilly", 'refreshToken': 'body-secret'},
      headers: {
        'Authorization': 'Bearer secret',
        'Cookie': 'session=cookie-secret',
        'x-api-key': 'private',
        'Content-Type': 'application/json',
      },
    );
    final formData = FormData.fromMap({
      'api_key': 'form-secret',
      'file': MultipartFile.fromBytes([1], filename: 'a.bin'),
    });
    final formCommand = DioHndlerHelper.curlCommand(
      methodOverride: 'POST',
      baseUrl: 'https://api.example.com',
      endpointPath: '/upload',
      data: formData,
    );
    final explicitCommand = DioHndlerHelper.curlCommand(
      methodOverride: 'POST',
      baseUrl: 'https://api.example.com',
      endpointPath: '/users',
      parameters: {'access_token': 'demo-access-token-123'},
      data: {'password': 'demo-password'},
      headers: {'Authorization': 'Bearer demo-access-token-123'},
      includeSensitiveData: true,
    );

    expect(command, contains('https://api.example.com/users?page=2'));
    expect(command, contains('Authorization: ********'));
    expect(command, contains('Cookie: ********'));
    expect(command, contains('x-api-key: ********'));
    expect(command, contains('"refreshToken":"********"'));
    expect(command, isNot(contains('Bearer secret')));
    expect(command, isNot(contains('body-secret')));
    expect(command, isNot(contains('cookie-secret')));
    expect(command, isNot(contains('private')));
    expect(formCommand, contains('api_key=********'));
    expect(formCommand, isNot(contains('form-secret')));
    expect(formData.isFinalized, isFalse);
    expect(explicitCommand, contains('demo-access-token-123'));
    expect(explicitCommand, contains('demo-password'));
  });

  test('copy logs mask by default and preserve explicit sensitive values', () {
    const token = 'demo-access-token-123';

    DioFlowLog(
      logModel: const LogModel(defaultLog: true),
      type: DioLogType.response,
      statusCode: 200,
      data: {
        'access_token': token,
        'profile': {'name': 'Ada'},
      },
    ).log();

    final maskedResponseCopy = _extractCopy(output.single, 'RESPONSE COPY >>');
    expect(maskedResponseCopy, contains('"access_token": "********"'));
    expect(maskedResponseCopy, isNot(contains(token)));
    expect(jsonDecode(maskedResponseCopy), isA<Map<String, dynamic>>());

    output.clear();
    final sinkOutput = <DioFlowRawLog>[];
    final explicitModel = LogModel(
      defaultLog: true,
      includeSensitiveDataInCopyLogs: true,
      logSink: sinkOutput.add,
    );
    DioFlowLog(
      logModel: explicitModel,
      type: DioLogType.request,
      url: 'https://api.example.com/secure',
      method: 'POST',
      headers: {'Authorization': 'Bearer $token'},
      data: {'password': 'demo-password'},
    ).log();
    DioFlowLog(
      logModel: explicitModel,
      type: DioLogType.response,
      url: 'https://api.example.com/secure',
      method: 'POST',
      statusCode: 200,
      data: {'access_token': token, 'ok': true},
    ).log();

    expect(
      output.where((line) => line.startsWith('[DioFlow][WARNING]')),
      hasLength(1),
    );
    final requestLog = output.singleWhere(
      (line) => line.startsWith('[DioFlow][REQUEST]'),
    );
    final responseLog = output.singleWhere(
      (line) => line.startsWith('[DioFlow][RESPONSE]'),
    );
    final visualRequest = requestLog.split('\n\nCURL COPY >>').first;
    expect(visualRequest, contains('"Authorization": "********"'));
    expect(visualRequest, contains('"password": "********"'));
    expect(visualRequest, isNot(contains(token)));

    final explicitCurl = _extractCopy(requestLog, 'CURL COPY >>');
    final explicitResponse = _extractCopy(responseLog, 'RESPONSE COPY >>');
    expect(explicitCurl, contains(token));
    expect(explicitCurl, contains('demo-password'));
    expect(explicitResponse, contains(token));
    expect(jsonDecode(explicitResponse)['access_token'], token);
    expect(sinkOutput, hasLength(2));
    expect(sinkOutput.first.curl, contains(token));
    expect(sinkOutput.last.responseJson, contains(token));
  });

  test('raw sink receives plain undecorated output before debugPrint', () {
    final events = <DioFlowRawLog>[];
    DioFlowLog.ansiColorsEnabledOverride = true;

    DioFlowLog(
      logModel: LogModel(defaultLog: true, logSink: events.add),
      type: DioLogType.response,
      url: 'https://api.example.com/users',
      method: 'GET',
      statusCode: 200,
      data: {
        'data': [
          {'id': 1, 'name': 'Ada'},
        ],
      },
    ).log();

    expect(events, hasLength(1));
    final event = events.single;
    expect(event.type, 'RESPONSE');
    expect(event.plainText, contains('Status Code: 200'));
    expect(event.plainText, isNot(contains('I/flutter')));
    expect(event.plainText, isNot(contains('\x1B')));
    expect(event.plainText, isNot(contains('╭')));
    expect(event.plainText, isNot(contains('[DioFlow]')));
    expect(event.responseJson, isNot(contains('\x1B')));
    expect(jsonDecode(event.responseJson!)['data'], hasLength(1));
  });

  test(
    'a failing raw sink does not affect request or retry behavior',
    () async {
      final adapter = await initializeWith([
        jsonStep({'message': 'busy'}, statusCode: 503),
        jsonStep({'ok': true}),
      ]);

      final response = await DioRequestHandler.get(
        '/retry-with-failing-sink',
        requestOptions: RequestOptionsModel(
          logModel: LogModel(
            defaultLog: true,
            logSink: (_) => throw StateError('sink failed'),
          ),
          retryOptions: const RetryOptions(
            maxAttempts: 2,
            retryInterval: Duration.zero,
          ),
        ),
      );

      expect(response.isSuccess, isTrue);
      expect(adapter.requests, hasLength(2));
      expect(
        output.where((line) => line.startsWith('[DioFlow][RETRY]')),
        hasLength(1),
      );
    },
  );

  test('mock logging reports source and duration only when enabled', () async {
    DioFlowConfig.initialize(baseUrl: 'https://api.example.com');
    MockDioFlow.enableMockMode();
    MockDioFlow.mockResponse('/mock', MockResponse.success({'ok': true}));

    await DioRequestHandler.get(
      '/mock',
      requestOptions: const RequestOptionsModel(
        logModel: LogModel(defaultLog: true),
      ),
    );

    expect(output, hasLength(2));
    expect(output.first, startsWith('[DioFlow][REQUEST]'));
    expect(output.first, contains('MOCK'));
    expect(output.first, contains('Source: mock'));
    expect(output.last, startsWith('[DioFlow][RESPONSE]'));
    expect(output.last, contains('Duration:'));
  });

  test(
    'retry and cache activity are logged once at their actual stage',
    () async {
      final adapter = await initializeWith([
        jsonStep({'message': 'busy'}, statusCode: 503),
        jsonStep({'ok': true}),
        jsonStep({'cached': true}),
      ]);
      const enabled = LogModel(defaultLog: true);

      await DioRequestHandler.get(
        '/retry',
        requestOptions: const RequestOptionsModel(
          logModel: enabled,
          retryOptions: RetryOptions(
            maxAttempts: 2,
            retryInterval: Duration.zero,
          ),
        ),
      );

      expect(
        output.where((line) => line.startsWith('[DioFlow][REQUEST]')),
        hasLength(1),
      );
      expect(
        output.where((line) => line.startsWith('[DioFlow][RETRY]')),
        hasLength(1),
      );
      expect(
        output.where((line) => line.startsWith('[DioFlow][RESPONSE]')),
        hasLength(1),
      );

      output.clear();
      const cacheOptions = RequestOptionsModel(
        logModel: enabled,
        retryOptions: RetryOptions(maxAttempts: 1),
        cacheOptions: CacheOptions(
          shouldCache: true,
          cacheDuration: Duration(minutes: 1),
        ),
      );
      await DioRequestHandler.get('/cache', requestOptions: cacheOptions);
      final cacheLookupLog = output.singleWhere(
        (line) => line.startsWith('[DioFlow][REQUEST]'),
      );
      expect(cacheLookupLog, contains('CACHE LOOKUP'));
      expect(cacheLookupLog, contains('Source: cache lookup'));
      expect(cacheLookupLog, isNot(contains('Source: cache (hit)')));
      expect(
        output.singleWhere((line) => line.startsWith('[DioFlow][RESPONSE]')),
        contains('CACHE MISS'),
      );
      output.clear();
      await DioRequestHandler.get('/cache', requestOptions: cacheOptions);

      expect(adapter.requests, hasLength(3));
      expect(
        output.singleWhere((line) => line.startsWith('[DioFlow][RESPONSE]')),
        allOf(contains('CACHE HIT'), contains('Source: cache')),
      );
    },
  );

  test(
    'large request and response JSON remain complete and decodable',
    () async {
      final largeValue = 'begin-${List.filled(20000, 'x').join()}-end';
      await initializeWith([
        jsonStep({
          'data': {
            'large': largeValue,
            'nested': {
              'items': List.generate(
                100,
                (index) => {'index': index, 'active': index.isEven},
              ),
            },
          },
        }),
      ]);

      final response = await DioRequestHandler.post(
        '/large',
        data: {
          'payload': {'large': largeValue, 'tail': 'request-complete'},
        },
        requestOptions: const RequestOptionsModel(
          logModel: LogModel(defaultLog: true),
          retryOptions: RetryOptions(maxAttempts: 1),
        ),
      );

      expect(response.isSuccess, isTrue);
      final requestJson = jsonDecode(
        _extractFramedField(
          output.singleWhere((line) => line.startsWith('[DioFlow][REQUEST]')),
          'Body',
        ),
      );
      final responseJson = jsonDecode(
        _extractCopy(
          output.singleWhere((line) => line.startsWith('[DioFlow][RESPONSE]')),
          'RESPONSE COPY >>',
        ),
      );

      expect(requestJson['payload']['large'], largeValue);
      expect(requestJson['payload']['tail'], 'request-complete');
      expect(responseJson['data']['large'], largeValue);
      expect(responseJson['data']['nested']['items'], hasLength(100));
      expect(output.join('\n'), isNot(contains('\x1B')));
    },
  );

  test(
    'error logging includes method, status, and complete response body',
    () async {
      await initializeWith([
        jsonStep({
          'message': 'invalid',
          'details': {
            'password': 'server-secret',
            'fields': ['email', 'name'],
          },
        }, statusCode: 422),
      ]);

      await DioRequestHandler.post(
        '/validate',
        data: {'name': 'Ada'},
        requestOptions: const RequestOptionsModel(
          logModel: LogModel(defaultLog: true),
          retryOptions: RetryOptions(maxAttempts: 1),
        ),
      );

      final errorLog = output.singleWhere(
        (line) => line.startsWith('[DioFlow][ERROR]'),
      );
      expect(errorLog, contains('Method: POST'));
      expect(errorLog, contains('Status Code: 422'));
      expect(errorLog, contains('"fields": ['));
      expect(errorLog, contains('"password": "********"'));
      expect(errorLog, isNot(contains('server-secret')));
    },
  );

  test('upload and download logs contain metadata, not file bytes', () async {
    await initializeWith([
      jsonStep({'uploaded': true}),
      bytesStep([9, 8, 7]),
    ]);
    const enabled = LogModel(defaultLog: true);

    await FileHandler.uploadFile<Uint8List>(
      '/upload',
      {
        'file': Uint8List.fromList([1, 2, 3]),
      },
      UploadMethodsEnum.post,
      requestOptions: const RequestOptionsModel(logModel: enabled),
    );
    await FileHandler.downloadBytes(
      '/download',
      UploadMethodsEnum.post,
      requestOptions: const RequestOptionsModel(
        logModel: enabled,
        responseType: ResponseType.bytes,
      ),
    );

    final uploadLog = output.singleWhere(
      (line) =>
          line.startsWith('[DioFlow][REQUEST]') &&
          line.contains('Operation: upload'),
    );
    final downloadLog = output.singleWhere(
      (line) =>
          line.startsWith('[DioFlow][RESPONSE]') &&
          line.contains('Operation: download'),
    );
    expect(uploadLog, contains('"length": 3'));
    expect(uploadLog, contains('UPLOAD'));
    expect(uploadLog, isNot(contains('[1, 2, 3]')));
    expect(downloadLog, contains('length: 3 bytes'));
    expect(downloadLog, contains('DOWNLOAD'));
    expect(downloadLog, isNot(contains('[9, 8, 7]')));
  });
}

String _extractFramedField(String log, String field) {
  final lines = log.split('\n');
  final start = lines.indexWhere(
    (line) => _stripAnsi(line).startsWith('│ $field:'),
  );
  if (start < 0) {
    throw StateError('Missing $field field in log output');
  }

  final firstLine = _stripAnsi(lines[start]);
  final inlineValue = firstLine.substring('│ $field:'.length).trimLeft();
  final extracted = <String>[if (inlineValue.isNotEmpty) inlineValue];
  for (final line in lines.skip(start + 1)) {
    final plainLine = _stripAnsi(line);
    if (!plainLine.startsWith('│ ')) {
      break;
    }
    final content = plainLine.substring(2);
    if (RegExp(r'^[A-Za-z][A-Za-z ]*:').hasMatch(content)) {
      break;
    }
    extracted.add(content);
  }
  return extracted.join('\n');
}

String _extractCopy(String log, String marker) {
  final start = log.indexOf('$marker\n');
  if (start < 0) {
    throw StateError('Missing $marker in log output');
  }
  return log.substring(start + marker.length + 1).trim();
}

String _stripAnsi(String value) =>
    value.replaceAll(RegExp(r'\x1B\[[0-9;]*m'), '');
