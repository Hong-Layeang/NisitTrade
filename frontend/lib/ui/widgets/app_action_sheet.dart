import 'package:flutter/material.dart';
import '../../../core/constants/colors.dart';

class AppActionSheetItem {
  final String label;
  final IconData icon;
  final VoidCallback? onTap;
  final bool isDestructive;
  final bool isDisabled;

  const AppActionSheetItem({
    required this.label,
    required this.icon,
    this.onTap,
    this.isDestructive = false,
    this.isDisabled = false,
  });
}

class AppActionSheet extends StatelessWidget {
  final String? title;
  final List<AppActionSheetItem> items;

  const AppActionSheet({
    super.key,
    this.title,
    required this.items,
  });

  static Future<void> show(
    BuildContext context, {
    String? title,
    required List<AppActionSheetItem> items,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => AppActionSheet(
        title: title,
        items: items,
      ),
    );
  }

  Color _itemColor(AppActionSheetItem item) {
    if (item.isDisabled) return AppColors.textSecondary;
    if (item.isDestructive) return Colors.red;
    return AppColors.textPrimary;
  }

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.sizeOf(context).height * 0.8;

    return SafeArea(
      top: false,
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: double.infinity,
          constraints: BoxConstraints(maxHeight: maxHeight),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(24),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.14),
                blurRadius: 18,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 10),
              Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              if (title != null) ...[
                const SizedBox(height: 12),
                Text(
                  title!,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
              const SizedBox(height: 8),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const Divider(
                    height: 1,
                    color: AppColors.border,
                  ),
                  itemBuilder: (context, index) {
                    final item = items[index];
                    final color = _itemColor(item);
                    return InkWell(
                      onTap: item.isDisabled
                          ? null
                          : () {
                              Navigator.of(context).pop();
                              if (item.onTap != null) {
                                WidgetsBinding.instance.addPostFrameCallback((_) {
                                  item.onTap!.call();
                                });
                              }
                            },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 14,
                        ),
                        child: Row(
                          children: [
                            Icon(item.icon, color: color, size: 24),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Text(
                                item.label,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: color,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }
}