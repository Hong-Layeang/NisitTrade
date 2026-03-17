/// Helper class for handling image URLs and S3 keys
class ImageUrlHelper {
  // S3 bucket base URL - update this to match your S3 bucket configuration
  static const String s3BaseUrl = 'https://nisittrade-images.s3.ap-northeast-1.amazonaws.com';

  /// Converts an S3 key or URL to a full URL
  /// If the input is already a full URL (starts with http/https), returns it as-is
  /// If it's an S3 key, prepends the S3 base URL
  static String getFullImageUrl(String imageUrlOrKey) {
    // If it's already a full URL, return as-is
    if (imageUrlOrKey.startsWith('http://') || imageUrlOrKey.startsWith('https://')) {
      return imageUrlOrKey;
    }

    // If it's empty, return empty
    if (imageUrlOrKey.isEmpty) {
      return '';
    }

    // Remove leading slash if present
    final key = imageUrlOrKey.startsWith('/')
        ? imageUrlOrKey.substring(1)
        : imageUrlOrKey;

    // Construct full S3 URL
    return '$s3BaseUrl/$key';
  }

  /// Extracts S3 key from a full S3 URL
  /// Returns null if the URL is not an S3 URL
  static String? extractS3KeyFromUrl(String url) {
    try {
      final uri = Uri.tryParse(url);
      if (uri == null) return null;

      // Check if it's an S3 URL
      if (uri.host.contains('s3') && uri.host.contains('amazonaws.com')) {
        // Extract path and remove leading slash
        String path = uri.path.startsWith('/') ? uri.path.substring(1) : uri.path;
        return path;
      }
    } catch (e) {
      return null;
    }
    return null;
  }

  /// Checks if a URL is valid
  static bool isValidUrl(String url) {
    if (url.isEmpty) return false;

    try {
      final uri = Uri.parse(url);
      return uri.hasScheme && (uri.scheme == 'http' || uri.scheme == 'https');
    } catch (e) {
      return false;
    }
  }

  /// Converts a list of image URLs/keys to full URLs
  static List<String> convertToFullUrls(List<String> imageUrlsOrKeys) {
    return imageUrlsOrKeys
        .map((url) => getFullImageUrl(url))
        .where((url) => url.isNotEmpty)
        .toList();
  }
}
