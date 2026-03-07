import 'package:dio/dio.dart';

import '../../data/providers/api_client.dart';

class MicrosoftAuthApiResponse {
  final bool isValid;
  final String? token;
  final bool needsPasswordSetup;
  final Map<String, dynamic>? user;
  final String? message;

  const MicrosoftAuthApiResponse({
    required this.isValid,
    required this.token,
    required this.needsPasswordSetup,
    required this.user,
    required this.message,
  });

  factory MicrosoftAuthApiResponse.fromResponse(
    Response<Map<String, dynamic>> response,
  ) {
    final data = response.data ?? const <String, dynamic>{};
    final validFromPayload = data['valid'];
    // Fallback to HTTP status if backend omits the `valid` flag.
    final isValid = validFromPayload is bool
        ? validFromPayload
        : (response.statusCode != null &&
            response.statusCode! >= 200 &&
            response.statusCode! < 300);

    final needsPasswordSetup = data['needsPasswordSetup'] == true;
    final token = data['token'];
    final user = data['user'];

    return MicrosoftAuthApiResponse(
      isValid: isValid,
      token: token is String ? token : null,
      needsPasswordSetup: needsPasswordSetup,
      user: user is Map<String, dynamic> ? user : null,
      message: _readMessage(data),
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

class MicrosoftAuthApi {
  MicrosoftAuthApi({Dio? dio}) : _dio = dio ?? ApiClient.instance.dio;

  static const String _microsoftLoginPath = '/auth/microsoft';
  static const String _setPasswordPath = '/auth/set-password';

  final Dio _dio;

  Future<MicrosoftAuthApiResponse> signInWithMicrosoft(String idToken) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        _microsoftLoginPath,
        data: <String, dynamic>{
          'idToken': idToken,
        },
      );

      return MicrosoftAuthApiResponse.fromResponse(response);
    } on DioException catch (error) {
      return MicrosoftAuthApiResponse(
        isValid: false,
        token: null,
        needsPasswordSetup: false,
        user: null,
        message: _extractMessage(error),
      );
    } catch (_) {
      return const MicrosoftAuthApiResponse(
        isValid: false,
        token: null,
        needsPasswordSetup: false,
        user: null,
        message: null,
      );
    }
  }

  Future<MicrosoftAuthApiResponse> setPassword({
    required String accessToken,
    required String password,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        _setPasswordPath,
        data: <String, dynamic>{
          'password': password,
        },
        options: Options(
          headers: <String, dynamic>{
            'Authorization': 'Bearer $accessToken',
          },
        ),
      );

      return MicrosoftAuthApiResponse.fromResponse(response);
    } on DioException catch (error) {
      return MicrosoftAuthApiResponse(
        isValid: false,
        token: null,
        needsPasswordSetup: false,
        user: null,
        message: _extractMessage(error),
      );
    } catch (_) {
      return const MicrosoftAuthApiResponse(
        isValid: false,
        token: null,
        needsPasswordSetup: false,
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
