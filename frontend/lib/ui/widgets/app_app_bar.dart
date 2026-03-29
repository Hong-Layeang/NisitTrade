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
  static const Duration _badgeSwitchInterval = Duration(seconds: 3);

  Timer? _badgeSwitchTimer;
  bool _showChatBadge = true;

  @override
  void initState() {
    super.initState();
    _configureBadgeRotation();
  }

  @override
  void didUpdateWidget(covariant AppAppBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.chatBadgeCount != widget.chatBadgeCount ||
        oldWidget.pendingPurchaseBadgeCount !=
            widget.pendingPurchaseBadgeCount) {
      _configureBadgeRotation();
    }
  }

  void _configureBadgeRotation() {
    _badgeSwitchTimer?.cancel();

    final hasChat = widget.chatBadgeCount > 0;
    final hasPurchase = widget.pendingPurchaseBadgeCount > 0;

    if (hasChat && hasPurchase) {
      _badgeSwitchTimer = Timer.periodic(_badgeSwitchInterval, (_) {
        if (!mounted) {
          return;
        }
        setState(() {
          _showChatBadge = !_showChatBadge;
        });
      });
      return;
    }

    _showChatBadge = hasChat;
  }

  @override
  void dispose() {
    _badgeSwitchTimer?.cancel();
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
            icon: Icon(Icons.bookmark_border, color: onPrimary, size: 26),
          ),
        if (widget.showChat)
          Stack(
            children: [
              IconButton(
                onPressed:
                    widget.onChatTap ??
                    () {
                      Navigator.of(context).pushNamed(AppRoutes.chat);
                    },
                icon: Icon(
                  Icons.chat_bubble_outline,
                  color: onPrimary,
                  size: 26,
                ),
              ),
              if (widget.chatBadgeCount > 0 ||
                  widget.pendingPurchaseBadgeCount > 0)
                Positioned(
                  right: 4,
                  top: 4,
                  child: _buildActiveBadge(onPrimary),
                ),
            ],
          ),
        if (widget.additionalActions != null) ...widget.additionalActions!,
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildActiveBadge(Color onPrimary) {
    final showChat = widget.chatBadgeCount > 0;
    final showPurchase = widget.pendingPurchaseBadgeCount > 0;

    if (showChat && showPurchase) {
      return _showChatBadge
          ? _buildChatBadge(onPrimary)
          : _buildPurchaseBadge(onPrimary);
    }

    return showChat ? _buildChatBadge(onPrimary) : _buildPurchaseBadge(onPrimary);
  }

  Widget _buildChatBadge(Color onPrimary) {
    final label = widget.chatBadgeCount > 99
        ? '99+'
        : widget.chatBadgeCount.toString();
    return _Badge(
      color: Colors.red,
      label: label,
      textColor: onPrimary,
      fontSize: 10,
      minSize: 18,
    );
  }

  Widget _buildPurchaseBadge(Color onPrimary) {
    final label = widget.pendingPurchaseBadgeCount > 9
        ? '9+'
        : widget.pendingPurchaseBadgeCount.toString();
    return _Badge(
      color: const Color(0xFFFF9800),
      label: label,
      textColor: onPrimary,
      fontSize: 10,
      minSize: 18,
    );
  }
}

class _Badge extends StatelessWidget {
  final Color color;
  final String label;
  final Color textColor;
  final double fontSize;
  final double minSize;

  const _Badge({
    required this.color,
    required this.label,
    required this.textColor,
    required this.fontSize,
    required this.minSize,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      constraints: BoxConstraints(minWidth: minSize, minHeight: minSize),
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
