class LogModel {
  final bool defaultLog;
  final bool isRequestEnabled;
  final bool isResponseEnabled;
  final bool isErrorEnabled;
  final bool isRetryEnabled;

  const LogModel({
    this.defaultLog = true,
    this.isRequestEnabled = true,
    this.isResponseEnabled = true,
    this.isErrorEnabled = true,
    this.isRetryEnabled = true,
  });

  static const LogModel defaultLogModel = LogModel(
    defaultLog: true,
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
