import 'package:flutter/material.dart';
import '../../../../domain/entities/product_entity.dart';
import '../../../widgets/app_action_sheet.dart';
import '../../../widgets/app_snack_bar.dart';

/// Helper class to generate and manage product action sheet items.
class ProductCardActionHandler {
  final BuildContext context;
  final ProductEntity product;
  final bool isOwner;
  final Future<void> Function() onEditListing;
  final Future<void> Function() onDeleteListing;
  final Future<void> Function() onSaveListing;
  final Future<void> Function() onHideToggle;
  final Future<void> Function() onShareListing;
  final Future<void> Function() onReportListing;

  ProductCardActionHandler({
    required this.context,
    required this.product,
    required this.isOwner,
    required this.onEditListing,
    required this.onDeleteListing,
    required this.onSaveListing,
    required this.onHideToggle,
    required this.onShareListing,
    required this.onReportListing,
  });

  /// Build action items based on user role and product state.
  List<AppActionSheetItem> _buildActionItems() {
    return <AppActionSheetItem>[
      if (isOwner)
        AppActionSheetItem(
          label: 'Edit listing',
          icon: Icons.edit_outlined,
          onTap: onEditListing,
        ),
      if (isOwner)
        AppActionSheetItem(
          label: 'Delete listing',
          icon: Icons.delete_outline,
          isDestructive: true,
          onTap: onDeleteListing,
        ),
      AppActionSheetItem(
        label: 'Save listing',
        icon: Icons.bookmark_border,
        onTap: onSaveListing,
      ),
      if (isOwner)
        AppActionSheetItem(
          label: product.isHidden ? 'Unhide listing' : 'Hide listing',
          icon: Icons.visibility_off_outlined,
          onTap: onHideToggle,
        ),
      AppActionSheetItem(
        label: 'Share',
        icon: Icons.share_outlined,
        onTap: onShareListing,
      ),
      AppActionSheetItem(
        label: 'Report',
        icon: Icons.flag_outlined,
        isDestructive: true,
        onTap: onReportListing,
      ),
    ];
  }

  /// Show the action sheet with generated items.
  void showActionSheet() {
    AppActionSheet.show(
      context,
      title: 'Listing options',
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
