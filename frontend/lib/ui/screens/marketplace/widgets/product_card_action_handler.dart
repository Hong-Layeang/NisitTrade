import 'package:flutter/material.dart';
import '../../../../data/dtos/product_dto.dart';
import '../../../widgets/app_action_sheet.dart';
import '../../../widgets/app_snack_bar.dart';

/// Helper class to generate and manage product action sheet items.
class ProductCardActionHandler {
  final BuildContext context;
  final ProductDto product;
  final bool isOwner;
  final bool isSaved;
  final Future<void> Function() onEditProduct;
  final Future<void> Function() onDeleteProduct;
  final Future<void> Function() onToggleSaveProduct;
  final Future<void> Function() onHideToggle;
  final Future<void> Function() onRecoverToFeed;
  final Future<void> Function() onShareProduct;
  final Future<void> Function() onReportProduct;

  ProductCardActionHandler({
    required this.context,
    required this.product,
    required this.isOwner,
    required this.isSaved,
    required this.onEditProduct,
    required this.onDeleteProduct,
    required this.onToggleSaveProduct,
    required this.onHideToggle,
    required this.onRecoverToFeed,
    required this.onShareProduct,
    required this.onReportProduct,
  });

  /// Build action items based on user role and product state.
  List<AppActionSheetItem> _buildActionItems() {
    return <AppActionSheetItem>[
      if (isOwner)
        AppActionSheetItem(
          label: 'Edit product',
          icon: Icons.edit_outlined,
          onTap: onEditProduct,
        ),
      if (isOwner)
        AppActionSheetItem(
          label: 'Delete product',
          icon: Icons.delete_outline,
          isDestructive: true,
          onTap: onDeleteProduct,
        ),
      AppActionSheetItem(
        label: isSaved ? 'Unsave product' : 'Save product',
        icon: isSaved ? Icons.bookmark_remove_outlined : Icons.bookmark_border,
        onTap: onToggleSaveProduct,
      ),
      if (isOwner && product.isSold)
        AppActionSheetItem(
          label: 'Recover to feed',
          icon: Icons.restore_outlined,
          onTap: onRecoverToFeed,
        ),
      if (isOwner)
        AppActionSheetItem(
          label: product.isHidden ? 'Unhide product' : 'Hide product',
          icon: Icons.visibility_off_outlined,
          onTap: onHideToggle,
        ),
      AppActionSheetItem(
        label: 'Share',
        icon: Icons.share_outlined,
        onTap: onShareProduct,
      ),
      AppActionSheetItem(
        label: 'Report product',
        icon: Icons.flag_outlined,
        isDestructive: true,
        onTap: onReportProduct,
      ),
    ];
  }

  /// Show the action sheet with generated items.
  void showActionSheet() {
    AppActionSheet.show(
      context,
      title: 'Product options',
      items: _buildActionItems(),
    );
  }
}

/// Extension to wrap action handlers with common error/loading/success feedback.
extension ActionHandlerExtension on State {
  /// Execute an action with loading state and error feedback.
  Future<void> executeAction(
    Future<void> Function() action, {
    void Function(bool)? onLoadingChanged,
    String successMessage = '',
    String errorMessage = 'Action failed. Please try again.',
  }) async {
    onLoadingChanged?.call(true);

    try {
      await action();
      if (successMessage.isNotEmpty && mounted) {
        AppSnackBar.show(context, successMessage);
      }
    } catch (e) {
      debugPrint('Action execution error: $e');
      if (mounted) {
        AppSnackBar.error(context, errorMessage);
      }
    } finally {
      onLoadingChanged?.call(false);
    }
  }
}

