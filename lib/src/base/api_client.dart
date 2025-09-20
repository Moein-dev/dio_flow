// ApiClient singleton: configures Dio instances and interceptors.
import 'package:dio/dio.dart';
import 'package:dio_flow/src/config/dio_flow_config.dart';
import 'package:dio_flow/src/interceptors/cache_interceptor.dart';
import 'package:dio_flow/src/interceptors/metrics_interceptor.dart';
import 'package:dio_flow/src/interceptors/rate_limit_interceptor.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiClient {
  static Dio? _dio;
  static Dio? _refreshDio;
  static SharedPreferences? _sharedPreferences;

  static Dio get dio {
    _dio ??= _createDio();
    return _dio!;
  }

  static Dio get refreshDio {
    _refreshDio ??= _createRefreshDio();
    return _refreshDio!;
  }

  static Future<void> initialize() async {
    DioFlowConfig.instance;

    _sharedPreferences = await SharedPreferences.getInstance();
  }

  static Dio _createDio() {
    if (_sharedPreferences == null) {
      throw StateError(
        'ApiClient must be initialized before use. Call ApiClient.initialize() first.',
      );
    }

    final config = DioFlowConfig.instance;

    final dio = Dio(
      BaseOptions(
        baseUrl: config.baseUrl,
        connectTimeout: config.connectTimeout,
        receiveTimeout: config.receiveTimeout,
        sendTimeout: config.sendTimeout,
        validateStatus: (status) => true,
      ),
    );

    dio.interceptors.addAll([
      MetricsInterceptor(),
      CacheInterceptor(prefs: _sharedPreferences!),
      RateLimitInterceptor(
        maxRequests: 30,
        interval: const Duration(minutes: 1),
      ),
    ]);

    return dio;
  }

  static Dio _createRefreshDio() {
    final config = DioFlowConfig.instance;

    final dio = Dio(
      BaseOptions(
        baseUrl: config.baseUrl,
        connectTimeout: config.connectTimeout,
        receiveTimeout: config.receiveTimeout,
        sendTimeout: config.sendTimeout,
        validateStatus: (status) => true,
      ),
    );

    return dio;
  }

  static Future<void> clearCache() async {
    _sharedPreferences ??= await SharedPreferences.getInstance();
    await _sharedPreferences!.clear();
  }

  static void reset() {
    _dio?.close();
    _dio = null;
  }
}
