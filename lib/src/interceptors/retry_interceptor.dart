import 'dart:async';
import 'package:dio/dio.dart';

/// Interceptor that automatically retries failed network requests.
///
/// This interceptor handles transient network errors by retrying the request
/// after a specified delay, up to a maximum number of attempts. This improves
/// reliability for operations over unreliable networks.
class RetryInterceptor extends Interceptor {
  final Dio dio;

  RetryInterceptor({required this.dio});

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final Map<String, dynamic> extra = Map<String, dynamic>.from(
      err.requestOptions.extra,
    );
    
    // خواندن مقادیر پیکربندی
    final int maxAttempts = extra['maxAttempts'] ?? 3; // مقدار پیش‌فرض ۳
    final Duration retryInterval = extra['retryInterval'] ?? Duration(seconds: 1);
    final int currentRetryCount = extra['retryCount'] ?? 0;

    // بررسی آیا باید retry شود
    if (_shouldRetry(err, currentRetryCount, maxAttempts)) {
      final int newRetryCount = currentRetryCount + 1;
      
      // ایجاد کپی جدید از extra با شمارشگر به‌روزرسانی شده
      final Map<String, dynamic> newExtra = {
        ...extra,
        'retryCount': newRetryCount,
      };

      // ایجاد درخواست جدید با تنظیمات به‌روزرسانی شده
      final RequestOptions newOptions = err.requestOptions.copyWith(
        extra: newExtra,
      );

      // انتظار برای بازه زمانی مشخص
      await Future.delayed(retryInterval);

      try {
        // اجرای مجدد درخواست با عبور از تمامی اینترسپتورها
        final Response response = await dio.fetch(newOptions);
        handler.resolve(response);
      } catch (e) {
        // اگر retry نیز شکست خورد، خطا را به handler بعدی منتقل کن
        handler.reject(e as DioException);
      }
    } else {
      // عدم retry و رد خطا
      handler.reject(err);
    }
  }

  bool _shouldRetry(DioException error, int retryCount, int maxAttempts) {
    return retryCount < maxAttempts &&
        error.type != DioExceptionType.cancel &&
        (error.type == DioExceptionType.connectionTimeout ||
            error.type == DioExceptionType.receiveTimeout ||
            error.type == DioExceptionType.sendTimeout ||
            error.type == DioExceptionType.connectionError);
  }
}