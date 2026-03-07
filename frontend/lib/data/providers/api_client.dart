import 'dart:io';

import 'package:dio/dio.dart';

import '../../core/config/app_config.dart';
import '../../core/navigation/app_navigator.dart';
import '../../core/navigation/app_routes.dart';
import '../../core/auth/auth_token_store.dart';

class ApiClient {
  ApiClient._() {
    _dio = Dio(
      BaseOptions(
        baseUrl: AppConfig.apiBaseUrl,
        connectTimeout: AppConfig.connectTimeout,
        receiveTimeout: AppConfig.receiveTimeout,
        contentType: 'application/json',
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          if (options.data is FormData) {
            options.headers.remove(Headers.contentTypeHeader); // 'content-type'
            options.headers.remove('Content-Type'); // mixed-case variant
          }
          if (!options.headers.containsKey('Authorization')) {
            final token = await _tokenStore.readToken();
            if (token != null && token.isNotEmpty) {
              options.headers['Authorization'] = 'Bearer $token';
            }
          }
          handler.next(options);
        },
        onError: (error, handler) async {
          final requestOptions = error.requestOptions;
          final hasRetried = requestOptions.extra[_fallbackKey] == true;

          if (Platform.isAndroid && !hasRetried && _shouldFallback(error)) {
            final fallbackBaseUrl = AppConfig.fallbackApiBaseUrl;
            final nextOptions = requestOptions.copyWith(
              baseUrl: fallbackBaseUrl,
              extra: <String, dynamic>{
                ...requestOptions.extra,
                _fallbackKey: true,
              },
            );

            try {
              final response = await _dio.fetch(nextOptions);
              return handler.resolve(response);
            } catch (fallbackError) {
              if (fallbackError is DioException) {
                return handler.reject(fallbackError);
              }
              return handler.reject(
                DioException(
                  requestOptions: nextOptions,
                  error: fallbackError,
                ),
              );
            }
          }

          // Auto-logout on 401 (stale/invalid token)
          if (error.response?.statusCode == 401) {
            await _tokenStore.clearToken();
            final nav = appNavigatorKey.currentState;
            if (nav != null) {
              nav.pushNamedAndRemoveUntil(
                AppRoutes.welcome,
                (route) => false,
              );
            }
            return handler.reject(error);
          }

          handler.next(error);
        },
      ),
    );
  }

  static final ApiClient instance = ApiClient._();

  late final Dio _dio;
  final AuthTokenStore _tokenStore = AuthTokenStore.instance;
  static const String _fallbackKey = 'apiFallbackAttempted';

  Dio get dio => _dio;

  bool _shouldFallback(DioException error) {
    return error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.connectionError;
  }
}
