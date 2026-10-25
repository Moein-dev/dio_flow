import 'dart:convert';

import 'package:dio_flow/dio_flow.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await setupDioFlow();
  runApp(const MyApp());
}

Future<void> setupDioFlow() async {
  DioFlowConfig.initialize(
    baseUrl: 'https://api.example.com',
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
    sendTimeout: const Duration(seconds: 10),
  );
  await ApiClient.initialize();
  registerMockResponses();
}

void registerMockResponses() {
  MockDioFlow.enableMockMode();

  MockDioFlow.mockResponse(
    '/users/1',
    MockResponse.success({
      'id': 1,
      'name': 'Sarah Connor',
      'email': 'sarah@example.com',
      'role': 'Administrator',
    }),
  );

  MockDioFlow.mockResponse(
    '/users',
    MockResponse.success({
      'id': 42,
      'name': 'John Doe',
      'role': 'Developer',
      'created': true,
    }, statusCode: 201),
    method: 'POST',
  );

  MockDioFlow.mockResponse(
    '/feed',
    MockResponse.success([
      {'id': 101, 'title': 'Welcome to DioFlow', 'author': 'Moein'},
      {'id': 102, 'title': 'Seamless Flutter Networking', 'author': 'Team'},
    ]),
  );

  MockDioFlow.mockResponse(
    '/upload',
    MockResponse.success({
      'fileId': 'upl_2026',
      'status': 'uploaded',
      'bytesReceived': 2048,
    }),
    method: 'POST',
  );

  MockDioFlow.mockResponse(
    '/not-found',
    MockResponse.failure('User resource does not exist', statusCode: 404),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DioFlow Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: const DemoHomePage(),
    );
  }
}

class DemoHomePage extends StatefulWidget {
  const DemoHomePage({super.key});

  @override
  State<DemoHomePage> createState() => _DemoHomePageState();
}

class _DemoHomePageState extends State<DemoHomePage> {
  bool _mockMode = true;
  bool _enableLogs = true;
  bool _isLoading = false;
  double? _uploadProgress;

  int? _lastStatusCode;
  Duration? _lastDuration;
  bool _lastFromCache = false;
  String _lastResponseJson = 'Tap any button above to make an API request.';
  String? _lastCurl;

  LogModel get _logModel =>
      _enableLogs ? const LogModel(defaultLog: true) : LogModel.disabledAllLog;

  Future<void> _executeRequest(
    String label,
    Future<ResponseModel> Function() action,
  ) async {
    setState(() {
      _isLoading = true;
      _uploadProgress = null;
    });

    final stopwatch = Stopwatch()..start();
    try {
      final response = await action();
      stopwatch.stop();

      setState(() {
        _lastStatusCode = response.statusCode;
        _lastDuration = stopwatch.elapsed;
        _lastFromCache = response.isFromCache;
        _lastCurl = response.logCurl;

        final rawData = response.data;
        if (rawData is Map || rawData is List) {
          _lastResponseJson = const JsonEncoder.withIndent('  ').convert(rawData);
        } else if (rawData != null) {
          _lastResponseJson = rawData.toString();
        } else {
          _lastResponseJson = response.message ?? 'No data returned';
        }
      });
    } catch (e) {
      stopwatch.stop();
      setState(() {
        _lastStatusCode = 500;
        _lastDuration = stopwatch.elapsed;
        _lastResponseJson = 'Unexpected error: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _onGetUser() {
    _executeRequest('GET /users/1', () {
      return DioRequestHandler.get(
        '/users/1',
        requestOptions: RequestOptionsModel(logModel: _logModel),
      );
    });
  }

  void _onPostUser() {
    _executeRequest('POST /users', () {
      return DioRequestHandler.post(
        '/users',
        data: {'name': 'John Doe', 'role': 'Developer'},
        requestOptions: RequestOptionsModel(logModel: _logModel),
      );
    });
  }

  void _onGetCachedFeed() {
    _executeRequest('GET /feed (Cached)', () {
      return DioRequestHandler.get(
        '/feed',
        requestOptions: RequestOptionsModel(
          logModel: _logModel,
          cacheOptions: const CacheOptions(
            shouldCache: true,
            cacheDuration: Duration(minutes: 2),
          ),
        ),
      );
    });
  }

  void _onSimulateUpload() {
    _executeRequest('Upload File', () async {
      final sampleBytes = Uint8List.fromList(List.generate(2048, (i) => i % 256));
      return FileHandler.uploadFile(
        '/upload',
        {'document': sampleBytes},
        UploadMethodsEnum.post,
        requestOptions: RequestOptionsModel(logModel: _logModel),
        onProgress: (sent, total) {
          setState(() {
            _uploadProgress = total > 0 ? sent / total : 1.0;
          });
        },
      );
    });
  }

  void _onSimulateError() {
    _executeRequest('Simulate 404', () {
      return DioRequestHandler.get(
        '/not-found',
        requestOptions: RequestOptionsModel(logModel: _logModel),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('DioFlow Demo'),
        centerTitle: true,
        backgroundColor: theme.colorScheme.inversePrimary,
        elevation: 2,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Control Panel Card
          Card(
            elevation: 1,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Column(
                children: [
                  SwitchListTile(
                    title: const Text('Mock Mode'),
                    subtitle: Text(
                      _mockMode
                          ? 'Requests return instant mock responses (offline-ready)'
                          : 'Requests contact real server at https://api.example.com',
                      style: theme.textTheme.bodySmall,
                    ),
                    value: _mockMode,
                    activeThumbColor: theme.colorScheme.primary,
                    onChanged: (val) {
                      setState(() {
                        _mockMode = val;
                        if (val) {
                          MockDioFlow.enableMockMode();
                        } else {
                          MockDioFlow.disableMockMode();
                        }
                      });
                    },
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    title: const Text('Debug Logging'),
                    subtitle: Text(
                      _enableLogs
                          ? 'Prints formatted, masked cURL and summaries to console'
                          : 'Console output stays completely silent',
                      style: theme.textTheme.bodySmall,
                    ),
                    value: _enableLogs,
                    activeThumbColor: theme.colorScheme.primary,
                    onChanged: (val) {
                      setState(() {
                        _enableLogs = val;
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Action Buttons Card
          Card(
            elevation: 1,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Network Operations',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ElevatedButton.icon(
                        key: const Key('get-user-button'),
                        onPressed: _isLoading ? null : _onGetUser,
                        icon: const Icon(Icons.download, size: 18),
                        label: const Text('GET User'),
                      ),
                      ElevatedButton.icon(
                        key: const Key('post-user-button'),
                        onPressed: _isLoading ? null : _onPostUser,
                        icon: const Icon(Icons.upload, size: 18),
                        label: const Text('POST User'),
                      ),
                      ElevatedButton.icon(
                        key: const Key('cached-feed-button'),
                        onPressed: _isLoading ? null : _onGetCachedFeed,
                        icon: const Icon(Icons.cached, size: 18),
                        label: const Text('Cached Feed'),
                      ),
                      ElevatedButton.icon(
                        key: const Key('upload-file-button'),
                        onPressed: _isLoading ? null : _onSimulateUpload,
                        icon: const Icon(Icons.attach_file, size: 18),
                        label: const Text('Upload File'),
                      ),
                      OutlinedButton.icon(
                        key: const Key('error-button'),
                        onPressed: _isLoading ? null : _onSimulateError,
                        icon: const Icon(Icons.error_outline, size: 18),
                        label: const Text('Test 404 Error'),
                      ),
                    ],
                  ),
                  if (_isLoading) ...[
                    const SizedBox(height: 14),
                    LinearProgressIndicator(value: _uploadProgress),
                    if (_uploadProgress != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          'Upload Progress: ${(_uploadProgress! * 100).toInt()}%',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodySmall,
                        ),
                      ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Response Details Card
          Card(
            elevation: 1,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Response Inspector',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (_lastStatusCode != null)
                        Chip(
                          avatar: Icon(
                            _lastStatusCode! < 400
                                ? Icons.check_circle
                                : Icons.cancel,
                            size: 16,
                            color: _lastStatusCode! < 400
                                ? Colors.green
                                : Colors.red,
                          ),
                          label: Text(
                            'Status $_lastStatusCode',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: _lastStatusCode! < 400
                                  ? Colors.green.shade800
                                  : Colors.red.shade800,
                            ),
                          ),
                          backgroundColor: _lastStatusCode! < 400
                              ? Colors.green.shade50
                              : Colors.red.shade50,
                          padding: EdgeInsets.zero,
                        ),
                    ],
                  ),
                  if (_lastDuration != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4, bottom: 8),
                      child: Row(
                        children: [
                          Icon(Icons.timer_outlined, size: 16, color: theme.hintColor),
                          const SizedBox(width: 4),
                          Text(
                            'Duration: ${_lastDuration!.inMilliseconds} ms',
                            style: theme.textTheme.bodySmall,
                          ),
                          if (_lastFromCache) ...[
                            const SizedBox(width: 12),
                            const Icon(Icons.flash_on, size: 16, color: Colors.amber),
                            Text(
                              'Served from Cache',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: Colors.amber.shade900,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  const SizedBox(height: 6),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: theme.dividerColor,
                      ),
                    ),
                    child: SelectableText(
                      _lastResponseJson,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 13,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (_lastCurl != null && _lastCurl!.isNotEmpty)
                        TextButton.icon(
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: _lastCurl!));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('cURL command copied to clipboard!'),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          },
                          icon: const Icon(Icons.terminal, size: 16),
                          label: const Text('Copy cURL'),
                        ),
                      TextButton.icon(
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: _lastResponseJson));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Response JSON copied to clipboard!'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        },
                        icon: const Icon(Icons.copy, size: 16),
                        label: const Text('Copy JSON'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
