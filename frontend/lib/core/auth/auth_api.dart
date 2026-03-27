import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../network/api_client.dart';

class AuthApiResponse {
  const AuthApiResponse({
    required this.isValid,
    required this.token,
    required this.user,
    required this.message,
  });

  final bool isValid;
  final String? token;
  final Map<String, dynamic>? user;
  final String? message;

  factory AuthApiResponse.fromResponse(Response<Map<String, dynamic>> response) {
    final data = response.data ?? const <String, dynamic>{};
    final validFromPayload = data['valid'];
    final isValid = validFromPayload is bool
        ? validFromPayload
        : (response.statusCode != null &&
            response.statusCode! >= 200 &&
            response.statusCode! < 300);

    final token = data['token'];
    final user = data['user'];
    final message = _readMessage(data);

    return AuthApiResponse(
      isValid: isValid,
      token: token is String ? token : null,
      user: user is Map<String, dynamic> ? user : null,
      message: message,
    );
  }

  static String? _readMessage(Map<String, dynamic> data) {
    if (data['msg'] is String) {
      return data['msg'] as String;
    }
    if (data['message'] is String) {
      return data['message'] as String;
    }
    return null;
  }
}

class AuthApi {
  AuthApi({Dio? dio}) : _dio = dio ?? ApiClient.instance.dio;

  static const String _loginPath = '/auth/login';

  final Dio _dio;

  Future<AuthApiResponse> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        _loginPath,
        data: <String, dynamic>{
          'email': email,
          'password': password,
        },
      );

      return AuthApiResponse.fromResponse(response);
    } on DioException catch (error) {
      return AuthApiResponse(
        isValid: false,
        token: null,
        user: null,
        message: _extractMessage(error),
      );
    } catch (e, st) {
      debugPrint('AuthApi.login unexpected error: $e\n$st');
      return const AuthApiResponse(
        isValid: false,
        token: null,
        user: null,
        message: null,
      );
    }
  }

  static String? _extractMessage(DioException error) {
    final data = error.response?.data;
    if (data is Map<String, dynamic>) {
      if (data['msg'] is String) {
        return data['msg'] as String;
      }
      if (data['message'] is String) {
        return data['message'] as String;
      }
    }
    return null;
  }
}
