import 'dart:collection';

class RequestMetric {
  final String path;
  final String method;
  final DateTime timestamp;
  final Duration duration;
  final int statusCode;
  final int? responseSize;
  final bool isSuccess;

  RequestMetric({
    required this.path,
    required this.method,
    required this.timestamp,
    required this.duration,
    required this.statusCode,
    this.responseSize,
    required this.isSuccess,
  });
}

class RequestMetrics {
  static const int _maxStoredMetrics = 100;
  static final Queue<RequestMetric> _metrics = Queue();
  
  static void addMetric(RequestMetric metric) {
    _metrics.add(metric);
    if (_metrics.length > _maxStoredMetrics) {
      _metrics.removeFirst();
    }
  }

  static List<RequestMetric> getMetrics() => List.from(_metrics);

  static Map<String, dynamic> getAggregatedStats() {
    if (_metrics.isEmpty) {
      return {};
    }

    var totalDuration = Duration.zero;
    var successCount = 0;
    var failureCount = 0;
    final pathStats = <String, List<Duration>>{};

    for (final metric in _metrics) {
      totalDuration += metric.duration;
      metric.isSuccess ? successCount++ : failureCount++;
      
      pathStats.putIfAbsent(metric.path, () => []).add(metric.duration);
    }

    final avgDuration = totalDuration ~/ _metrics.length;
    final successRate = successCount / _metrics.length * 100;

    final pathAverages = pathStats.map((path, durations) {
      final avg = durations.reduce((a, b) => a + b) ~/ durations.length;
      return MapEntry(path, avg);
    });

    return {
      'totalRequests': _metrics.length,
      'averageDuration': avgDuration.inMilliseconds,
      'successRate': successRate,
      'successCount': successCount,
      'failureCount': failureCount,
      'pathAverages': pathAverages,
    };
  }

  static void clear() => _metrics.clear();
} 