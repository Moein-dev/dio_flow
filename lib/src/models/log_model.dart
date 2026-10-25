typedef DioFlowLogSink = void Function(DioFlowRawLog log);

class DioFlowRawLog {
  final String type;
  final String plainText;
  final String? curl;
  final String? responseJson;

  const DioFlowRawLog({
    required this.type,
    required this.plainText,
    this.curl,
    this.responseJson,
  });
}

class LogModel {
  final bool defaultLog;
  final bool isRequestEnabled;
  final bool isResponseEnabled;
  final bool isErrorEnabled;
  final bool isRetryEnabled;
  final bool includeSensitiveDataInCopyLogs;
  final DioFlowLogSink? logSink;

  const LogModel({
    this.defaultLog = false,
    this.isRequestEnabled = true,
    this.isResponseEnabled = true,
    this.isErrorEnabled = true,
    this.isRetryEnabled = true,
    this.includeSensitiveDataInCopyLogs = false,
    this.logSink,
  });

  static const LogModel defaultLogModel = LogModel(
    defaultLog: false,
    isRequestEnabled: true,
    isResponseEnabled: true,
    isErrorEnabled: true,
    isRetryEnabled: true,
  );

  static const LogModel disabledAllLog = LogModel(
    defaultLog: false,
    isRequestEnabled: false,
    isResponseEnabled: false,
    isErrorEnabled: false,
    isRetryEnabled: false,
  );
}
