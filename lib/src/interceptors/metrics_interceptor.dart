import 'package:dio/dio.dart';
import 'package:dio_flow/src/utils/request_metrics.dart';

/// Interceptor for collecting metrics and performance data about API requests.
/// 
/// This interceptor tracks timing, status codes, and other metrics for all requests,
/// allowing for analysis of API performance and monitoring of request patterns.
class MetricsInterceptor extends Interceptor {
  /// Intercepts outgoing requests to record the start time.
  /// 
  /// This method attaches a timestamp to the request options so that the
  /// total request duration can be calculated when the response or error is received.
  /// 
  /// Parameters:
  ///   options - The original request options
  ///   handler - The request handler used to continue the request
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.extra['startTime'] = DateTime.now();
    handler.next(options);
  }

  /// Intercepts successful responses to record metrics.
  /// 
  /// This method calculates the duration of the request and records various
  /// metrics about the successful response, such as status code and response size.
  /// 
  /// Parameters:
  ///   response - The response from the server
  ///   handler - The response handler used to continue the response processing
  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    _recordMetric(response.requestOptions, response);
    handler.next(response);
  }

  /// Intercepts errors to record metrics even when requests fail.
  /// 
  /// This method calculates the duration of the request and records various
  /// metrics about the failed response, ensuring that we track performance
  /// data for both successful and failed requests.
  /// 
  /// Parameters:
  ///   err - The error that occurred during the request
  ///   handler - The error handler used to continue error processing
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    _recordMetric(err.requestOptions, err.response);
    handler.next(err);
  }

  /// Records a metric for the given request and response.
  /// 
  /// This private method creates a RequestMetric object with data from the
  /// request and response, and adds it to the metrics collection for later analysis.
  /// 
  /// Parameters:
  ///   options - The request options containing the start time and request details
  ///   response - The response (which may be null if the request failed)
  void _recordMetric(RequestOptions options, Response? response) {
    final startTime = options.extra['startTime'] as DateTime;
    final endTime = DateTime.now();

    final metric = RequestMetric(
      path: options.path,
      method: options.method,
      timestamp: startTime,
      duration: endTime.difference(startTime),
      statusCode: response?.statusCode ?? -1,
      responseSize: response?.data?.toString().length,
      isSuccess: response?.statusCode != null && 
                 response!.statusCode! >= 200 && 
                 response.statusCode! < 300,
    );

    RequestMetrics.addMetric(metric);
  }
} 