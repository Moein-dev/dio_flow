class ApiException implements Exception {
  final String message;
  final int statusCode;
  final dynamic data;

  ApiException(this.message, {this.statusCode = 500, this.data});

  @override
  String toString() => 'ApiException: $message (Status: $statusCode)';
}
