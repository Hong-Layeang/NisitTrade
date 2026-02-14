import 'package:dio/dio.dart';

class MicrosoftAuthApi {
  MicrosoftAuthApi({Dio? dio}) : _dio = dio ?? _defaultDio();

  static const String _baseUrl = 'https://api.example.com';
  static const String _validatePath = '/auth/microsoft/validate';

  final Dio _dio;

  Future<bool> validateToken(String idToken) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        _validatePath,
        data: <String, dynamic>{
          'idToken': idToken,
        },
        options: Options(
          headers: <String, dynamic>{
            'Authorization': 'Bearer $idToken',
          },
        ),
      );

      final data = response.data;
      if (data is Map<String, dynamic>) {
        final valid = data['valid'];
        if (valid is bool) {
          return valid;
        }
      }

      return response.statusCode == 200;
    } on DioException {
      return false;
    } catch (_) {
      return false;
    }
  }

  static Dio _defaultDio() {
    return Dio(
      BaseOptions(
        baseUrl: _baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        headers: const {
          'Content-Type': 'application/json',
        },
      ),
    );
  }
}
