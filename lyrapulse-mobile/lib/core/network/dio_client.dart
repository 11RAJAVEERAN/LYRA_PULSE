import 'package:dio/dio.dart';
import '../../app/config/app_config.dart';
import '../storage/secure_storage_service.dart';

class DioClient {
  DioClient({Dio? dio, required SecureStorageService secureStorage})
    : dio = dio ?? Dio(BaseOptions(
        baseUrl: '${AppConfig.apiBaseUrl.replaceFirst(RegExp(r'/+$'), '')}/',
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 20),
        headers: const {'Accept': 'application/json'},
      )) {
    this.dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await secureStorage.readAccessToken();
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (error, handler) async {
        final options = error.requestOptions;
        if (error.response?.statusCode != 401 || options.extra['authRetry'] == true) {
          handler.next(error);
          return;
        }
        final refreshToken = await secureStorage.readRefreshToken();
        if (refreshToken == null || refreshToken.isEmpty) {
          handler.next(error);
          return;
        }
        try {
          final refreshResponse = await this.dio.post<dynamic>(
            'auth/token/refresh/',
            data: {'refresh': refreshToken},
            options: Options(extra: {'authRetry': true}),
          );
          final responseBody = refreshResponse.data;
          final envelope = responseBody is Map ? responseBody : <String, dynamic>{};
          final payload = envelope['data'] is Map ? envelope['data'] as Map : envelope;
          final accessToken = payload['access']?.toString();
          if (accessToken == null || accessToken.isEmpty) {
            throw const FormatException('The refresh response did not contain an access token.');
          }
          await secureStorage.saveTokens(access: accessToken, refresh: refreshToken);
          options
            ..headers['Authorization'] = 'Bearer $accessToken'
            ..extra['authRetry'] = true;
          final retriedResponse = await this.dio.fetch<dynamic>(options);
          handler.resolve(retriedResponse);
        } catch (_) {
          await secureStorage.clearTokens();
          handler.next(error);
        }
      },
    ));
  }

  final Dio dio;
}
