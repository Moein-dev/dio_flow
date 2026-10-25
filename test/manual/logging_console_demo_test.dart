import 'dart:convert';

import 'package:dio_flow/dio_flow.dart';
import 'package:dio_flow/src/handlers/dio_flow_log.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/scripted_adapter.dart';

const _enabledLog = LogModel(defaultLog: true);
const _singleAttempt = RetryOptions(maxAttempts: 1);
const _runDemo = bool.fromEnvironment('DIO_FLOW_RUN_LOG_DEMO');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'prints real deterministic logging scenarios',
    () async {
      final originalDebugPrint = debugPrint;
      final logsByScenario = <String, List<String>>{};
      List<String>? activeLogs;

      debugPrint = (message, {wrapWidth}) {
        if (message == null) return;
        activeLogs?.add(message);
        debugPrintSynchronously(message, wrapWidth: null);
      };

      const ansiMode = String.fromEnvironment(
        'DIO_FLOW_DEMO_ANSI',
        defaultValue: 'auto',
      );
      DioFlowLog.ansiColorsEnabledOverride = switch (ansiMode) {
        'on' => true,
        'off' => false,
        _ => null,
      };
      DioFlowLog.resetSensitiveCopyWarningForTesting();

      Future<List<String>> scenario(
        String id,
        String title,
        Future<void> Function() action,
      ) async {
        final logs = <String>[];
        logsByScenario[id] = logs;
        activeLogs = logs;
        debugPrintSynchronously('\n===== $id · $title =====', wrapWidth: null);
        await action();
        activeLogs = null;
        debugPrintSynchronously(
          '===== END $id · DioFlow log entries: ${logs.length} =====',
          wrapWidth: null,
        );
        return logs;
      }

      SharedPreferences.setMockInitialValues({});
      DioFlowConfig.initialize(baseUrl: 'https://api.example.com');
      await ApiClient.initialize();
      final adapter = ScriptedAdapter([
        jsonStep({
          'data': {
            'user': {
              'id': 7,
              'profile': {
                'name': 'Ada',
                'roles': ['admin', 'editor'],
              },
            },
            'items': [
              {
                'id': 1,
                'meta': {'active': true},
              },
              {
                'id': 2,
                'meta': {'active': false},
              },
            ],
          },
          'meta': {
            'page': 1,
            'flags': {'complete': true},
          },
        }),
        jsonStep({'created': true, 'id': 101}, statusCode: 201),
        jsonStep({
          'message': 'invalid request',
          'details': {'field': 'email', 'reason': 'malformed'},
        }, statusCode: 400),
        jsonStep({'message': 'temporarily unavailable'}, statusCode: 503),
        jsonStep({
          'data': {'recovered': true},
        }),
        jsonStep({
          'data': {'value': 'cached-once'},
        }),
        jsonStep({'uploaded': true}),
        jsonStep({'access_token': 'demo-access-token-123', 'masked': true}),
        jsonStep({'access_token': 'demo-access-token-123', 'accepted': true}),
        jsonStep({'silent': true}),
      ]);
      ApiClient.dio.httpClientAdapter = adapter;

      try {
        final getLogs = await scenario(
          '01',
          'successful GET with nested JSON response',
          () async {
            final response = await DioRequestHandler.get(
              '/nested',
              parameters: {'page': 1},
              requestOptions: const RequestOptionsModel(
                logModel: _enabledLog,
                retryOptions: _singleAttempt,
              ),
            );
            expect(response.isSuccess, isTrue);
          },
        );

        final nestedResponseLog = getLogs.singleWhere(
          (log) => log.startsWith('[DioFlow][RESPONSE]'),
        );
        final nestedJson = _extractCopy(nestedResponseLog, 'RESPONSE COPY >>');
        expect(jsonDecode(nestedJson), isA<Map<String, dynamic>>());
        debugPrintSynchronously(
          '\n===== COPYABLE JSON EXTRACTED FROM SCENARIO 01 =====\n$nestedJson\n'
          '===== END COPYABLE JSON =====',
          wrapWidth: null,
        );

        await scenario('02', 'POST with request body', () async {
          final response = await DioRequestHandler.post(
            '/reports',
            data: {
              'title': 'Weekly report',
              'filters': {
                'active': true,
                'tags': ['alpha', 'beta'],
              },
            },
            requestOptions: const RequestOptionsModel(
              logModel: _enabledLog,
              retryOptions: _singleAttempt,
            ),
          );
          expect(response.isSuccess, isTrue);
        });

        await scenario('03', 'HTTP 400 error response', () async {
          final response = await DioRequestHandler.post(
            '/validate',
            data: {'email': 'not-an-email'},
            requestOptions: const RequestOptionsModel(
              logModel: _enabledLog,
              retryOptions: _singleAttempt,
            ),
          );
          expect(response.isSuccess, isFalse);
          expect(response.statusCode, 400);
        });

        await scenario('04', 'retry after HTTP 503', () async {
          final response = await DioRequestHandler.get(
            '/retry',
            requestOptions: const RequestOptionsModel(
              logModel: _enabledLog,
              retryOptions: RetryOptions(
                maxAttempts: 2,
                retryInterval: Duration.zero,
              ),
            ),
          );
          expect(response.isSuccess, isTrue);
        });

        final cacheLogs = await scenario(
          '05',
          'cache miss followed by cache hit',
          () async {
            const options = RequestOptionsModel(
              logModel: _enabledLog,
              retryOptions: _singleAttempt,
              cacheOptions: CacheOptions(
                shouldCache: true,
                cacheDuration: Duration(minutes: 1),
              ),
            );
            final first = await DioRequestHandler.get(
              '/cache-demo',
              requestOptions: options,
            );
            final second = await DioRequestHandler.get(
              '/cache-demo',
              requestOptions: options,
            );
            expect(first.isSuccess, isTrue);
            expect(second.isSuccess, isTrue);
          },
        );
        expect(cacheLogs.join('\n'), contains('CACHE MISS'));
        expect(cacheLogs.join('\n'), contains('CACHE HIT'));

        await scenario('06', 'mock response', () async {
          MockDioFlow.enableMockMode();
          MockDioFlow.mockResponse(
            '/mock-profile',
            MockResponse.success({
              'profile': {'id': 42, 'name': 'Mock User'},
            }),
          );
          final response = await DioRequestHandler.get(
            '/mock-profile',
            requestOptions: const RequestOptionsModel(logModel: _enabledLog),
          );
          expect(response.isSuccess, isTrue);
          MockDioFlow.disableMockMode();
        });

        await scenario('07', 'FormData upload', () async {
          final response = await FileHandler.uploadFile<Uint8List>(
            '/upload',
            {
              'attachment': Uint8List.fromList([1, 2, 3, 4, 5]),
            },
            UploadMethodsEnum.post,
            additionalData: {
              'title': 'demo.txt',
              'password': 'sample-upload-password',
            },
            requestOptions: const RequestOptionsModel(
              logModel: _enabledLog,
              retryOptions: _singleAttempt,
            ),
          );
          expect(response.isSuccess, isTrue);
        });

        const demoToken = 'demo-access-token-123';
        final maskedLogs = await scenario('08', 'masked copy logs', () async {
          final response = await DioRequestHandler.post(
            '/secure-masked',
            parameters: {'access_token': demoToken},
            data: {
              'password': 'demo-password',
              'profile': {'email': 'demo@example.com'},
            },
            requestOptions: const RequestOptionsModel(
              logModel: _enabledLog,
              retryOptions: _singleAttempt,
              customHeaders: {
                'Authorization': 'Bearer demo-access-token-123',
                'Cookie': 'session=demo-cookie',
                'X-API-Key': 'demo-api-key',
              },
            ),
          );
          expect(response.isSuccess, isTrue);
        });
        final maskedRequestLog = maskedLogs.singleWhere(
          (log) => log.startsWith('[DioFlow][REQUEST]'),
        );
        final maskedResponseLog = maskedLogs.singleWhere(
          (log) => log.startsWith('[DioFlow][RESPONSE]'),
        );
        final maskedCurl = _extractCopy(maskedRequestLog, 'CURL COPY >>');
        final maskedResponse = _extractCopy(
          maskedResponseLog,
          'RESPONSE COPY >>',
        );
        expect(maskedCurl, isNot(contains(demoToken)));
        expect(maskedResponse, isNot(contains(demoToken)));
        expect(maskedCurl, isNot(contains('\x1B')));
        expect(maskedResponse, isNot(contains('\x1B')));
        expect(jsonDecode(maskedResponse), isA<Map<String, dynamic>>());
        debugPrintSynchronously(
          '\n===== MASKED CURL COPY EXTRACTED FROM SCENARIO 08 =====\n'
          '$maskedCurl\n'
          '===== END MASKED CURL COPY =====',
          wrapWidth: null,
        );

        final rawEvents = <DioFlowRawLog>[];
        final explicitLogs = await scenario(
          '09',
          'explicit sensitive copy logs and raw callback',
          () async {
            final response = await DioRequestHandler.post(
              '/secure-explicit',
              parameters: {'access_token': demoToken},
              data: {
                'password': 'demo-password',
                'profile': {'email': 'demo@example.com'},
              },
              requestOptions: RequestOptionsModel(
                logModel: LogModel(
                  defaultLog: true,
                  includeSensitiveDataInCopyLogs: true,
                  logSink: rawEvents.add,
                ),
                retryOptions: const RetryOptions(maxAttempts: 1),
                customHeaders: {
                  'Authorization': 'Bearer $demoToken',
                  'Cookie': 'session=demo-cookie',
                  'X-API-Key': 'demo-api-key',
                },
              ),
            );
            expect(response.isSuccess, isTrue);
          },
        );
        final explicitRequestLog = explicitLogs.singleWhere(
          (log) => log.startsWith('[DioFlow][REQUEST]'),
        );
        final explicitResponseLog = explicitLogs.singleWhere(
          (log) => log.startsWith('[DioFlow][RESPONSE]'),
        );
        final explicitCurl = _extractCopy(explicitRequestLog, 'CURL COPY >>');
        final explicitResponse = _extractCopy(
          explicitResponseLog,
          'RESPONSE COPY >>',
        );
        expect(explicitCurl, contains(demoToken));
        expect(explicitResponse, contains(demoToken));
        expect(explicitCurl, isNot(contains('\x1B')));
        expect(explicitResponse, isNot(contains('\x1B')));
        expect(jsonDecode(explicitResponse), isA<Map<String, dynamic>>());
        expect(rawEvents, hasLength(2));
        final responseEvent = rawEvents.last;
        expect(responseEvent.type, 'RESPONSE');
        expect(responseEvent.curl, contains(demoToken));
        expect(responseEvent.responseJson, contains(demoToken));
        expect(responseEvent.plainText, isNot(contains('I/flutter')));
        expect(responseEvent.plainText, isNot(contains('\x1B')));
        expect(responseEvent.plainText, isNot(contains('╭')));

        debugPrintSynchronously(
          '\n===== EXPLICIT CURL COPY EXTRACTED FROM SCENARIO 09 =====\n'
          '$explicitCurl\n'
          '===== END EXPLICIT CURL COPY =====\n'
          '\n===== RAW CALLBACK SAMPLE FROM SCENARIO 09 =====\n'
          '${responseEvent.plainText}\n'
          'cURL: ${responseEvent.curl}\n'
          'Response JSON:\n${responseEvent.responseJson}\n'
          '===== END RAW CALLBACK SAMPLE =====',
          wrapWidth: null,
        );

        final beforeSilentRequest = adapter.requests.length;
        final silentLogs = await scenario('10', 'logging disabled', () async {
          final response = await DioRequestHandler.get(
            '/silent',
            requestOptions: const RequestOptionsModel(
              retryOptions: _singleAttempt,
            ),
          );
          expect(response.isSuccess, isTrue);
        });
        expect(adapter.requests.length, beforeSilentRequest + 1);
        expect(silentLogs, isEmpty);

        debugPrintSynchronously(
          '\n===== EXECUTION SUMMARY =====\n'
          'ANSI mode: $ansiMode\n'
          'Platform: ${kIsWeb ? 'Web' : 'VM'}\n'
          'Adapter network dispatches: ${adapter.requests.length}\n'
          'Scenario 10 DioFlow log entries: ${silentLogs.length}\n'
          'Masked copy contains demo token: ${maskedCurl.contains(demoToken)}\n'
          'Explicit copy contains demo token: '
          '${explicitCurl.contains(demoToken)}\n'
          '===== END EXECUTION SUMMARY =====',
          wrapWidth: null,
        );
      } finally {
        MockDioFlow.disableMockMode();
        DioFlowLog.ansiColorsEnabledOverride = null;
        DioFlowLog.resetSensitiveCopyWarningForTesting();
        debugPrint = originalDebugPrint;
        ApiClient.reset();
      }
    },
    skip: _runDemo ? false : 'Run explicitly with DIO_FLOW_RUN_LOG_DEMO=true.',
  );
}

String _extractCopy(String log, String marker) {
  final start = log.indexOf('$marker\n');
  if (start < 0) {
    throw StateError('Missing $marker in log output');
  }
  return log.substring(start + marker.length + 1).trim();
}
