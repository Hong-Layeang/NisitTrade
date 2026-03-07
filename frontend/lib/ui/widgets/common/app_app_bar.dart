import 'package:flutter/material.dart';
import '../../../core/constants/colors.dart';

class AppAppBar extends StatelessWidget implements PreferredSizeWidget {
  final int chatBadgeCount;
  final VoidCallback? onFavoriteTap;
  final VoidCallback? onChatTap;
  final List<Widget>? additionalActions;
  final bool showFavorite;
  final bool showChat;

  const AppAppBar({
    super.key,
    this.chatBadgeCount = 0,
    this.onFavoriteTap,
    this.onChatTap,
    this.additionalActions,
    this.showFavorite = true,
    this.showChat = true,
  });

  @override
  Size get preferredSize => const Size.fromHeight(56);

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
        if (showFavorite)
          IconButton(
            onPressed: onFavoriteTap,
            icon: Icon(
              Icons.favorite_border,
              color: onPrimary,
              size: 26,
            ),
          ),
        if (showChat)
          Stack(
            children: [
              IconButton(
                onPressed: onChatTap,
                icon: Icon(
                  Icons.chat_bubble_outline,
                  color: onPrimary,
                  size: 26,
                ),
              ),
              if (chatBadgeCount > 0)
                Positioned(
                  right: 6,
                  top: 6,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 18,
                      minHeight: 18,
                    ),
                    child: Text(
                      chatBadgeCount > 99 ? '99+' : chatBadgeCount.toString(),
                      style: TextStyle(
                        color: onPrimary,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        if (additionalActions != null) ...additionalActions!,
        const SizedBox(width: 8),
      ],
    );
  }
}
