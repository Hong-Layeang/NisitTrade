import 'dart:async';

import 'package:flutter/material.dart';
import '../../core/constants/colors.dart';
import '../../core/navigation/app_routes.dart';

class AppAppBar extends StatefulWidget implements PreferredSizeWidget {
  final int chatBadgeCount;
  final int pendingPurchaseBadgeCount;
  final VoidCallback? onFavoriteTap;
  final VoidCallback? onChatTap;
  final List<Widget>? additionalActions;
  final bool showFavorite;
  final bool showChat;

  const AppAppBar({
    super.key,
    this.chatBadgeCount = 0,
    this.pendingPurchaseBadgeCount = 0,
    this.onFavoriteTap,
    this.onChatTap,
    this.additionalActions,
    this.showFavorite = true,
    this.showChat = true,
  });

  @override
  Size get preferredSize => const Size.fromHeight(56);

  @override
  State<AppAppBar> createState() => _AppAppBarState();
}

class _AppAppBarState extends State<AppAppBar> {
  bool _showMessageBadge = true;
  Timer? _switchTimer;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void didUpdateWidget(AppAppBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.chatBadgeCount != widget.chatBadgeCount ||
        oldWidget.pendingPurchaseBadgeCount != widget.pendingPurchaseBadgeCount) {
      _resetBadgeState();
    }
  }

  void _resetBadgeState() {
    final hasBoth = widget.chatBadgeCount > 0 && widget.pendingPurchaseBadgeCount > 0;
    if (!hasBoth) {
      _switchTimer?.cancel();
      _switchTimer = null;
      setState(() {
        _showMessageBadge = widget.chatBadgeCount > 0 || widget.pendingPurchaseBadgeCount == 0;
      });
    } else if (_switchTimer == null) {
      _startTimer();
    }
  }

  void _startTimer() {
    _switchTimer?.cancel();
    _switchTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!mounted) return;
      if (widget.chatBadgeCount > 0 && widget.pendingPurchaseBadgeCount > 0) {
        setState(() => _showMessageBadge = !_showMessageBadge);
      }
    });
  }

  @override
  void dispose() {
    _switchTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final onPrimary = Theme.of(context).colorScheme.onPrimary;
    return AppBar(
      backgroundColor: AppColors.primary,
      elevation: 0,
      automaticallyImplyLeading: false,
      title: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Image.asset(
              'assets/images/NisitTradeLogo.png',
              width: 32,
              height: 32,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            'NisitTrade',
            style: TextStyle(
              color: onPrimary,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      actions: [
        if (widget.showFavorite)
          IconButton(
            onPressed: widget.onFavoriteTap,
            icon: Icon(
              Icons.bookmark_border,
              color: onPrimary,
              size: 26,
            ),
          ),
        if (widget.showChat)
          Stack(
            children: [
              IconButton(
                onPressed: widget.onChatTap ?? () {
                  Navigator.of(context).pushNamed(AppRoutes.chat);
                },
                icon: Icon(
                  Icons.chat_bubble_outline,
                  color: onPrimary,
                  size: 26,
                ),
              ),
              if (widget.chatBadgeCount > 0 || widget.pendingPurchaseBadgeCount > 0)
                Positioned(
                  right: 6,
                  top: 6,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    transitionBuilder: (child, animation) => FadeTransition(
                      opacity: animation,
                      child: ScaleTransition(scale: animation, child: child),
                    ),
                    child: _buildActiveBadge(onPrimary),
                  ),
                ),
            ],
          ),
        if (widget.additionalActions != null) ...widget.additionalActions!,
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildActiveBadge(Color onPrimary) {
    final hasBoth = widget.chatBadgeCount > 0 && widget.pendingPurchaseBadgeCount > 0;
    final showMessage = !hasBoth
        ? widget.chatBadgeCount > 0  
        : _showMessageBadge;  

    if (showMessage) {
      final label = widget.chatBadgeCount > 99
          ? '99+'
          : widget.chatBadgeCount.toString();
      return _Badge(
        key: const ValueKey('msg'),
        color: Colors.red,
        label: label,
        textColor: onPrimary,
        fontSize: 10,
        minSize: 18,
      );
    } else {
      final label = widget.pendingPurchaseBadgeCount > 9
          ? '9+'
          : widget.pendingPurchaseBadgeCount.toString();
      return _Badge(
        key: const ValueKey('purchase'),
        color: const Color(0xFFFF9800),
        label: label,
        textColor: onPrimary,
        fontSize: 10,
        minSize: 18,
      );
    }
  }
}

class _Badge extends StatelessWidget {
  final Color color;
  final String label;
  final Color textColor;
  final double fontSize;
  final double minSize;

  const _Badge({
    super.key,
    required this.color,
    required this.label,
    required this.textColor,
    required this.fontSize,
    required this.minSize,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
      constraints: BoxConstraints(
        minWidth: minSize,
        minHeight: minSize,
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
