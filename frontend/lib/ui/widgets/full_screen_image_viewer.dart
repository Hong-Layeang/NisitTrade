import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class FullScreenImageViewer {
  FullScreenImageViewer._();

  static void show(
    BuildContext context,
    String imageUrl, {
    List<String>? allImages,
    int initialIndex = 0,
  }) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierDismissible: true,
        barrierColor: Colors.transparent,
        transitionDuration: const Duration(milliseconds: 380),
        reverseTransitionDuration: const Duration(milliseconds: 260),
        pageBuilder: (_, _, _) => _FullScreenImagePage(
          imageUrl: imageUrl,
          allImages: allImages,
          initialIndex: initialIndex,
        ),
        transitionsBuilder: (_, animation, _, child) {
          final curved = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutQuint,
            reverseCurve: Curves.easeInCubic,
          );
          return FadeTransition(
            opacity: curved,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.06),
                end: Offset.zero,
              ).animate(curved),
              child: child,
            ),
          );
        },
      ),
    );
  }
}

// Internal implementation
class _FullScreenImagePage extends StatefulWidget {
  const _FullScreenImagePage({
    required this.imageUrl,
    this.allImages,
    this.initialIndex = 0,
  });

  final String imageUrl;
  final List<String>? allImages;
  final int initialIndex;

  @override
  State<_FullScreenImagePage> createState() => _FullScreenImagePageState();
}

class _FullScreenImagePageState extends State<_FullScreenImagePage>
    with TickerProviderStateMixin {
  // page controller (multi-image mode)
  late final PageController _pageCtrl =
      PageController(initialPage: widget.initialIndex);
  late int _pageIndex = widget.initialIndex;

  // drag state
  Offset _drag = Offset.zero;
  bool _isDragging = false;

  // spring snap-back controller
  late final AnimationController _snapCtrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
  );
  late Animation<Offset> _snapAnim;

  //derived values
  double get _progress => (_drag.dy.abs() / 320).clamp(0.0, 1.0);
  double get _bgOpacity => 1.0 - _progress * 0.95;
  double get _blurSigma => 18.0 * (1.0 - _progress);

  @override
  void dispose() {
    _snapCtrl.dispose();
    _pageCtrl.dispose();
    super.dispose();
  }

  // gesture handlers
  void _onDragStart(DragStartDetails _) {
    _snapCtrl.stop();
    setState(() => _isDragging = true);
  }

  void _onDragUpdate(DragUpdateDetails d) {
    setState(() => _drag += d.delta);
  }

  void _onDragEnd(DragEndDetails d) {
    final vy = d.velocity.pixelsPerSecond.dy;
    if (_drag.dy.abs() > 110 || vy.abs() > 700) {
      Navigator.of(context).pop();
      return;
    }
    // Spring snap-back
    final from = _drag;
    _snapAnim = Tween<Offset>(begin: from, end: Offset.zero).animate(
      CurvedAnimation(parent: _snapCtrl, curve: Curves.elasticOut),
    );
    _snapCtrl
      ..reset()
      ..forward();
    _snapCtrl.addListener(() {
      if (mounted) setState(() => _drag = _snapAnim.value);
    });
    setState(() => _isDragging = false);
  }

  // build
  @override
  Widget build(BuildContext context) {
    final images = widget.allImages;
    final isMulti = images != null && images.length > 1;

    return GestureDetector(
      onVerticalDragStart: _onDragStart,
      onVerticalDragUpdate: _onDragUpdate,
      onVerticalDragEnd: _onDragEnd,
      child: Stack(
        children: [
          // Blurred & dimmed background
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(
                sigmaX: _blurSigma,
                sigmaY: _blurSigma,
              ),
              child: AnimatedOpacity(
                opacity: _bgOpacity,
                duration: _isDragging
                    ? Duration.zero
                    : const Duration(milliseconds: 180),
                child: const ColoredBox(color: Colors.black),
              ),
            ),
          ),

          // Scaffold with close button
          Scaffold(
            backgroundColor: Colors.transparent,
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              automaticallyImplyLeading: false,
              leading: IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.45),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white24, width: 0.5),
                  ),
                  child: const Icon(Icons.close, color: Colors.white, size: 18),
                ),
              ),
              // Page counter for multi-image mode
              title: isMulti
                  ? Text(
                      '${_pageIndex + 1} / ${images.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    )
                  : null,
              centerTitle: true,
            ),
            body: Transform.translate(
              offset: Offset(_drag.dx * 0.35, _drag.dy),
              child: Transform.scale(
                alignment: Alignment.center,
                scale: 1.0 - _progress * 0.08,
                child: isMulti
                    ? PageView.builder(
                        controller: _pageCtrl,
                        itemCount: images.length,
                        onPageChanged: (i) => setState(() => _pageIndex = i),
                        itemBuilder: (_, i) => _buildZoomableImage(images[i]),
                      )
                    : _buildZoomableImage(widget.imageUrl),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildZoomableImage(String url) {
    return InteractiveViewer(
      minScale: 0.5,
      maxScale: 5.0,
      child: Center(
        child: CachedNetworkImage(
          key: ValueKey('fullscreen_$url'),
          imageUrl: url,
          fit: BoxFit.contain,
          useOldImageOnUrlChange: true,
          fadeInDuration: Duration.zero,
          fadeOutDuration: Duration.zero,
          progressIndicatorBuilder: (context, url, progress) => SizedBox(
            height: 240,
            child: Center(
              child: CircularProgressIndicator(
                value: progress.progress,
                color: Colors.white,
                strokeWidth: 2,
              ),
            ),
          ),
          errorWidget: (context, url, error) => const Center(
            child: Icon(Icons.broken_image, color: Colors.white38, size: 72),
          ),
        ),
      ),
    );
  }
}
