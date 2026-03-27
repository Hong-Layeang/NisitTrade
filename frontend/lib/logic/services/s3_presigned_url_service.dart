import 'package:dio/dio.dart';

class S3PresignedUrlService {
  S3PresignedUrlService(this._dio);

  final Dio _dio;
  final Map<String, _CachedUrl> _urlCache = {};

  static const String s3BaseUrl =
      'https://nisittrade-images.s3.ap-northeast-1.amazonaws.com';
  static const String _baseUrl = '/presigned-url/';
  static const int _defaultExpirationSeconds = 3600;
  static const int _refreshThresholdSeconds = 300;

  Future<String> getPresignedUrl(String s3Key) async {
    if (_urlCache.containsKey(s3Key)) {
      final cached = _urlCache[s3Key]!;
      if (!_isExpiringSoon(cached.expiresAt)) {
        return cached.url;
      }
    }
    return _fetchPresignedUrl(s3Key, _defaultExpirationSeconds);
  }

  Future<String> _fetchPresignedUrl(String s3Key, int expirationSeconds) async {
    try {
      final response = await _dio.post(
        _baseUrl,
        data: {'s3Key': s3Key, 'expirationSeconds': expirationSeconds},
      );

      if (response.statusCode == 200) {
        final presignedUrl =
            response.data['presignedUrl'] as String? ??
                response.data['presigned_url'] as String?;
        final expiresIn =
            (response.data['expiresIn'] as int?) ??
                (response.data['expires_in'] as int?) ??
                expirationSeconds;

        if (presignedUrl == null || presignedUrl.isEmpty) {
          throw Exception('Presigned URL response missing presignedUrl. Response: ${response.data}');
        }

        _urlCache[s3Key] = _CachedUrl(
          url: presignedUrl,
          expiresAt: DateTime.now().add(Duration(seconds: expiresIn)),
        );

        return presignedUrl;
      }

      throw Exception('Failed to get presigned URL: ${response.statusCode}');
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        final cleanKey = s3Key.startsWith('/') ? s3Key.substring(1) : s3Key;
        final directUrl = '$s3BaseUrl/$cleanKey';

        _urlCache[s3Key] = _CachedUrl(
          url: directUrl,
          expiresAt: DateTime.now().add(const Duration(hours: 24)),
        );

        return directUrl;
      }
      final errorMessage = _extractErrorMessage(e);
      final statusCode = e.response?.statusCode ?? 'N/A';
      throw Exception('Error fetching presigned URL (status: $statusCode): $errorMessage');
    } catch (e) {
      throw Exception('Unexpected error fetching presigned URL: $e');
    }
  }

  String _extractErrorMessage(DioException e) {
    if (e.response?.data != null) {
      final data = e.response!.data;
      if (data is Map<String, dynamic>) {
        return data['message'] ?? data['error'] ?? e.message ?? 'Unknown error';
      }
      return data.toString();
    }
    return e.message ?? 'Unknown error';
  }

  String? getCachedUrl(String s3Key) {
    final cached = _urlCache[s3Key];
    if (cached != null && !_isExpiringSoon(cached.expiresAt)) {
      return cached.url;
    }
    return null;
  }

  void invalidateCache(String s3Key) {
    _urlCache.remove(s3Key);
  }

  void clearCache() {
    _urlCache.clear();
  }

  bool _isExpiringSoon(DateTime expiresAt) {
    return DateTime.now()
        .add(const Duration(seconds: _refreshThresholdSeconds))
        .isAfter(expiresAt);
  }
}

class _CachedUrl {
  _CachedUrl({required this.url, required this.expiresAt});

  final String url;
  final DateTime expiresAt;
}
