import 'package:dio/dio.dart';

/// Service to handle presigned URL generation and refresh
class S3PresignedUrlService {
  final Dio _dio;

  // Cache to avoid excessive requests for the same key
  final Map<String, _CachedUrl> _urlCache = {};

  // S3 base URL for direct access (fallback when presigned URL service is unavailable)
  static const String s3BaseUrl = 'https://nisittrade-images.s3.ap-northeast-1.amazonaws.com';
  static const String _baseUrl = '/presigned-url';
  static const int _defaultExpirationSeconds = 3600; // 1 hour
  static const int _refreshThresholdSeconds = 300; // Refresh if expires in < 5 minutes

  S3PresignedUrlService(this._dio);

  Future<String> getPresignedUrl(String s3Key) async {
    // Check if we have a valid cached URL
    if (_urlCache.containsKey(s3Key)) {
      final cached = _urlCache[s3Key]!;
      if (!_isExpiringSoon(cached.expiresAt)) {
        return cached.url;
      }
    }

    // Fetch a fresh presigned URL
    return _fetchPresignedUrl(s3Key, _defaultExpirationSeconds);
  }

  Future<String> _fetchPresignedUrl(String s3Key, int expirationSeconds) async {
    try {
      final response = await _dio.post(
        _baseUrl,
        data: {
          's3Key': s3Key,
          'expirationSeconds': expirationSeconds,
        },
      );

      if (response.statusCode == 200) {
        final presignedUrl = response.data['presignedUrl'] as String? ??
            response.data['presigned_url'] as String?;
        final expiresIn = (response.data['expiresIn'] as int?) ??
            (response.data['expires_in'] as int?) ??
            expirationSeconds;

        if (presignedUrl == null || presignedUrl.isEmpty) {
          throw Exception('Presigned URL response missing presignedUrl');
        }

        // Cache the URL with expiration time
        _urlCache[s3Key] = _CachedUrl(
          url: presignedUrl,
          expiresAt: DateTime.now().add(Duration(seconds: expiresIn)),
        );

        return presignedUrl;
      }

      throw Exception('Failed to get presigned URL: ${response.statusCode}');
    } on DioException catch (e) {
      // If presigned URL service is not available (404), fall back to direct S3 URL
      if (e.response?.statusCode == 404) {
        // Remove leading slash if present
        final cleanKey = s3Key.startsWith('/') ? s3Key.substring(1) : s3Key;
        final directUrl = '$s3BaseUrl/$cleanKey';

        // Cache the direct URL (with shorter expiration since it's not presigned)
        _urlCache[s3Key] = _CachedUrl(
          url: directUrl,
          expiresAt: DateTime.now().add(const Duration(hours: 24)),
        );

        return directUrl;
      }

      throw Exception('Error fetching presigned URL: ${e.message}');
    }
  }

  /// Clear cache for a specific key
  void invalidateCache(String s3Key) {
    _urlCache.remove(s3Key);
  }

  /// Clear all cached URLs
  void clearCache() {
    _urlCache.clear();
  }

  bool _isExpiringSoon(DateTime expiresAt) {
    return DateTime.now().add(const Duration(seconds: _refreshThresholdSeconds)).isAfter(expiresAt);
  }
}

class _CachedUrl {
  final String url;
  final DateTime expiresAt;

  _CachedUrl({required this.url, required this.expiresAt});
}
