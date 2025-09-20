import 'package:dio/dio.dart';
import 'package:dio_flow/src/utils/token_manager.dart';

class DioInterceptor extends Interceptor {
  final Dio dio;

  DioInterceptor({required this.dio});

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) async {
    final requestOptions = response.requestOptions;

    if (response.statusCode == 401) {
      try {
        await TokenManager.refreshAccessToken();
        final newToken = await TokenManager.getAccessToken();

        if (newToken == null || newToken.isEmpty) {
          await TokenManager.clearTokens();
          return handler.next(response);
        }

        final newOptions = requestOptions.copyWith(
          headers: {
            ...requestOptions.headers,
            'Authorization': 'Bearer $newToken',
          },
          extra: {
            ...requestOptions.extra,
            'isRefreshTokenUsed': true,
          },
        );

        final Response retriedResponse = await dio.fetch(newOptions);
        return handler.resolve(retriedResponse);
      } catch (e) {
        await TokenManager.clearTokens();
        return handler.next(response);
      }
    }

    return handler.next(response);
  }
}
