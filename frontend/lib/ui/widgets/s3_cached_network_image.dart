import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../../logic/services/s3_presigned_url_service.dart';

/// Widget to display S3 images with automatic presigned URL refresh on 403 errors
class S3CachedNetworkImage extends StatefulWidget {
  final String imageUrl;
  final String? s3Key; // Required if imageUrl is a presigned URL that might expire
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget Function(BuildContext, String, Object)? errorWidget;
  final ProgressIndicatorBuilder? progressIndicatorBuilder;
  final bool useOldImageOnUrlChange;
  final Duration fadeInDuration;
  final Duration fadeOutDuration;
  final Color? backgroundColor;
  final int maxRetries;

  const S3CachedNetworkImage({
    super.key,
    required this.imageUrl,
    this.s3Key,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.errorWidget,
    this.progressIndicatorBuilder,
    this.useOldImageOnUrlChange = true,
    this.fadeInDuration = const Duration(milliseconds: 500),
    this.fadeOutDuration = const Duration(milliseconds: 500),
    this.backgroundColor,
    this.maxRetries = 2,
  });

  @override
  State<S3CachedNetworkImage> createState() => _S3CachedNetworkImageState();
}

class _S3CachedNetworkImageState extends State<S3CachedNetworkImage> {
  late String _currentImageUrl;
  int _retryCount = 0;
  bool _isLoading = false;

  bool _isValidNetworkUrl(String? url) {
    final value = url?.trim() ?? '';
    if (value.isEmpty) return false;

    final uri = Uri.tryParse(value);
    return uri != null &&
        (uri.scheme == 'http' || uri.scheme == 'https') &&
        (uri.host.isNotEmpty);
  }

  @override
  void initState() {
    super.initState();
    _currentImageUrl = widget.imageUrl;
    if (_shouldFetchPresignedUrl(widget.imageUrl, widget.s3Key)) {
      // Try to resolve from cache synchronously first to avoid flicker
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final s3Key = widget.s3Key ?? _extractS3KeyFromUrl(widget.imageUrl);
        if (s3Key != null) {
          final cached = context.read<S3PresignedUrlService>().getCachedUrl(s3Key);
          if (cached != null) {
            setState(() => _currentImageUrl = cached);
            return;
          }
        }
        _refreshPresignedUrl(forceRefresh: false);
      });
    }
  }

  @override
  void didUpdateWidget(S3CachedNetworkImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrl != widget.imageUrl || oldWidget.s3Key != widget.s3Key) {
      _currentImageUrl = widget.imageUrl;
      _retryCount = 0;
      if (_shouldFetchPresignedUrl(widget.imageUrl, widget.s3Key)) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          final s3Key = widget.s3Key ?? _extractS3KeyFromUrl(widget.imageUrl);
          if (s3Key != null) {
            final cached = context.read<S3PresignedUrlService>().getCachedUrl(s3Key);
            if (cached != null) {
              setState(() => _currentImageUrl = cached);
              return;
            }
          }
          _refreshPresignedUrl(forceRefresh: false);
        });
      }
    }
  }

  Future<void> _refreshPresignedUrl({bool forceRefresh = true}) async {
    // Extract S3 key from URL if not provided
    String? s3Key = widget.s3Key;
    if (s3Key == null) {
      s3Key = _extractS3KeyFromUrl(widget.imageUrl);
      if (s3Key == null) {
        debugPrint('[S3Image] Could not extract S3 key from URL: ${widget.imageUrl}');
        return;
      }
    }

    if (!mounted) return;

    try {
      setState(() => _isLoading = true);

      final presignedUrlService = context.read<S3PresignedUrlService>();
      debugPrint('[S3Image] Attempting to fetch presigned URL for key: $s3Key');
      
      if (forceRefresh) {
        presignedUrlService.invalidateCache(s3Key); // Force refresh
      }
      
      final newUrl = await presignedUrlService.getPresignedUrl(s3Key);
      debugPrint('[S3Image] Successfully fetched presigned URL');

      if (mounted) {
        setState(() {
          _currentImageUrl = newUrl;
          _isLoading = false;
          _retryCount = 0;
        });
        final hasQueryParams = newUrl.contains('?');
        debugPrint('[S3Image] Updated _currentImageUrl (has query params: $hasQueryParams)');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        debugPrint('[S3Image] Error refreshing presigned URL: $e');
        debugPrint('[S3Image] Stack trace: ${StackTrace.current}');
      }
    }
  }

  String? _extractS3KeyFromUrl(String url) {
    try {
      final uri = Uri.tryParse(url);
      if (uri == null) return null;

      if (uri.host.contains('s3') && uri.host.contains('amazonaws.com')) {
        // Extract path and remove leading slash
        String path = uri.path.startsWith('/') ? uri.path.substring(1) : uri.path;
        return path;
      }
    } catch (e) {
      debugPrint('[S3Image] Error parsing URL: $e');
    }
    return null;
  }

  bool _shouldFetchPresignedUrl(String imageUrl, String? s3Key) {
    final uri = Uri.tryParse(imageUrl);
    if ((s3Key ?? '').trim().isNotEmpty) {
      return uri == null || !uri.hasQuery;
    }
    if (uri == null) return false;

    return uri.host.contains('s3') &&
        uri.host.contains('amazonaws.com') &&
        !uri.hasQuery;
  }

  void _handleImageError(Object error) {
    debugPrint('[S3Image] Image load error: $error');

    // Check if this is a 403/permission denied error
    if (error.toString().contains('403') || error.toString().contains('Forbidden')) {
      if (_retryCount < widget.maxRetries) {
        _retryCount++;
        debugPrint('[S3Image] Got 403 error, attempting to refresh presigned URL (attempt $_retryCount/${widget.maxRetries})');
        // Schedule the refresh after the current frame to avoid setState during build
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _refreshPresignedUrl();
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isValidNetworkUrl(_currentImageUrl)) {
      return Container(
        width: widget.width,
        height: widget.height,
        color: widget.backgroundColor ?? Colors.grey.shade200,
        child: const Icon(
          Icons.image_not_supported,
          color: Colors.grey,
        ),
      );
    }

    if (_isLoading) {
      return Container(
        width: widget.width,
        height: widget.height,
        color: widget.backgroundColor,
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    return CachedNetworkImage(
      imageUrl: _currentImageUrl,
      width: widget.width,
      height: widget.height,
      fit: widget.fit,
      useOldImageOnUrlChange: widget.useOldImageOnUrlChange,
      fadeInDuration: widget.fadeInDuration,
      fadeOutDuration: widget.fadeOutDuration,
      progressIndicatorBuilder: widget.progressIndicatorBuilder ??
          (context, url, progress) {
            return Container(
              width: widget.width,
              height: widget.height,
              color: widget.backgroundColor,
            );
          },
      errorWidget: (context, url, error) {
        final hasQueryParams = _currentImageUrl.contains('?');
        debugPrint('[S3Image] Error loading URL (has query params: $hasQueryParams): $_currentImageUrl');
        _handleImageError(error);

        return widget.errorWidget?.call(context, url, error) ??
            Container(
              width: widget.width,
              height: widget.height,
              color: widget.backgroundColor ?? Colors.grey.shade200,
              child: const Icon(
                Icons.image_not_supported,
                color: Colors.grey,
              ),
            );
      },
    );
  }
}
