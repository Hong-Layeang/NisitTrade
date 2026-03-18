import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';

import '../../../core/constants/colors.dart';
import '../../../core/navigation/app_routes.dart';
import '../../../core/utils/school_short_name.dart';
import '../../../data/models/conversation.dart';
import '../../../data/models/product.dart';
import '../../../logic/view_models/chat_view_model.dart';
import '../../../logic/view_models/user_view_model.dart';
import '../../../ui/screens/marketplace/product_detail_page.dart';
import '../../../ui/screens/profile/other_profile_page.dart';
import '../../../ui/widgets/app_action_sheet.dart';
import '../../../ui/widgets/app_snack_bar.dart';
import '../../../ui/widgets/user_widgets.dart';
import 'widgets/attachment_carousel.dart';
import 'widgets/chat_bubble.dart';
import 'widgets/chat_input.dart';
import '../../../data/providers/user_api_service.dart';
import 'widgets/chat_menu_helpers.dart';

class ChatRoomScreen extends StatefulWidget {
  static const routeName = '/chat-room';

  final int conversationId;
  final bool attachProductOnCompose;

  const ChatRoomScreen({
    super.key,
    required this.conversationId,
    this.attachProductOnCompose = false,
  });

  @override
  State<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends State<ChatRoomScreen> {
  late ChatRoomViewModel _viewModel;
  late ScrollController _scrollController;
  bool _hasInitialized = false;
  Timer? _countdownTimer;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        _now = DateTime.now();
      });
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_hasInitialized) {
      return;
    }

    _viewModel = Provider.of<ChatRoomViewModel>(context, listen: false);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadConversation();
    });
    _hasInitialized = true;
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadConversation() async {
    final currentConversation = _viewModel.currentConversation;
    final hasMatchingConversation =
        currentConversation?.id == widget.conversationId;
    final needsHydration = !hasMatchingConversation ||
        _requiresConversationHydration(currentConversation);

    if (needsHydration) {
      await _viewModel.loadConversation(widget.conversationId);
    }

    if (_viewModel.currentConversation?.id == widget.conversationId) {
      await _viewModel.loadMessages(refresh: true);
    }

    _scrollToBottom(animated: false);
  }

  bool _requiresConversationHydration(Conversation? conversation) {
    if (conversation == null) return true;

    final participants = conversation.participants;
    if (participants == null || participants.isEmpty) {
      return true;
    }

    final product = conversation.product;
    if (conversation.productId != null && product == null) {
      return true;
    }

    return false;
  }

  void _scrollToBottom({bool animated = true}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) {
        return;
      }

      final target = _scrollController.position.maxScrollExtent;
      if (animated) {
        _scrollController.animateTo(
          target,
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutCubic,
        );
      } else {
        _scrollController.jumpTo(target);
      }
    });
  }

  void _onScroll() {
    if (!_scrollController.hasClients) {
      return;
    }

    if (_scrollController.position.pixels <= 120) {
      _viewModel.loadMoreMessages();
    }
  }

  Future<void> _handleSendMessage(
    String messageText,
    List<String> imagePaths,
  ) async {
    final success = await _viewModel.sendMessage(
      messageText,
      imagePaths: imagePaths,
    );

    if (success) {
      _scrollToBottom();
      return;
    }

    AppSnackBar.error(
      context,
      _viewModel.sendMessageError ?? 'Failed to send message',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        titleSpacing: 0,
        title: Consumer<ChatRoomViewModel>(
          builder: (context, viewModel, _) {
            final conversation = viewModel.currentConversation;
            return _buildAppBarTitle(conversation);
          },
        ),
        actions: [
          Consumer<ChatRoomViewModel>(
            builder: (context, viewModel, _) {
              final conversation = viewModel.currentConversation;
              return IconButton(
                icon: const Icon(Icons.more_horiz_rounded),
                onPressed: conversation == null
                    ? null
                    : () => _showChatActions(conversation),
              );
            },
          ),
        ],
      ),
      body: Consumer<ChatRoomViewModel>(
        builder: (context, viewModel, _) {
          final conversation = viewModel.currentConversation;
          final isShowingRequestedConversation =
              conversation?.id == widget.conversationId;

          if (viewModel.isLoadingCurrentConversation &&
              !isShowingRequestedConversation) {
            return const Center(child: CircularProgressIndicator());
          }

          if (viewModel.currentConversationError != null) {
            return _buildErrorState(viewModel.currentConversationError ?? '');
          }

          if (conversation == null) {
            return const Center(child: Text('No conversation found'));
          }

          return Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFF4FBFF), AppColors.surface],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: Column(
              children: [
                // Attachment carousel for attached products
                Consumer<ChatRoomViewModel>(
                  builder: (context, vm, _) {
                    if (vm.attachedProducts.isEmpty) {
                      return const SizedBox.shrink();
                    }
                    return AttachmentCarousel(
                      attachedProducts: vm.attachedProducts,
                      countdownLabelBuilder: _buildProductCountdownLabel,
                      isExpiredBuilder: _isProductCountdownExpired,
                      onTapProduct: (product) => _navigateToProduct(product),
                      onConfirmPurchase: (product) => _navigateToProduct(product),
                      onRemove: (product) => vm.removeAttachedProduct(product.id),
                    );
                  },
                ),
                Expanded(
                  child: _buildMessagesList(viewModel),
                ),
                ChatInput(
                  onSendMessage: _handleSendMessage,
                  isLoading: viewModel.isLoadingCurrentConversation,
                  isSendingMessage: viewModel.isSendingMessage,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildAppBarTitle(Conversation? conversation) {
    if (conversation == null) {
      return const Text(
        'Messages',
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
      );
    }

    final participant = _otherParticipant(conversation);
    final displayName = participant?.user?.name ?? 'Messages';
    final avatarUrl = participant?.user?.avatarUrl ?? '';
    final schoolShortName = buildSchoolShortName(
      email: participant?.user?.username,
      fallback: '',
    );
    final statusInfo = _buildPresenceLabel(conversation.updatedAt);

    return Row(
      children: [
        UserAvatar(imageUrl: avatarUrl, radius: 18),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  if (schoolShortName.isNotEmpty) ...[
                    const SizedBox(width: 6),
                    Text(
                      schoolShortName,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ],
              ),
              Row(
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: _presenceColor(conversation.updatedAt),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      statusInfo,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.chat_bubble_outline_rounded,
              size: 44,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: 16),
            const Text(
              'Could not load this conversation',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadConversation,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToProduct(Product product) {
    Navigator.of(context).pushNamed(
      AppRoutes.productDetail,
      arguments: ProductDetailArgs(productId: product.id),
    );
  }

  String _buildProductCountdownLabel(AttachedProduct ap) {
    final startedAt = ap.countdownStartedAt;
    if (startedAt == null) {
      return 'Awaiting purchase message';
    }

    final expiresAt = startedAt.add(const Duration(days: 2));
    final remaining = expiresAt.difference(_now);
    if (remaining.isNegative || remaining.inSeconds <= 0) {
      return 'Window ended';
    }

    final hours = remaining.inHours;
    final minutes = remaining.inMinutes % 60;
    final seconds = remaining.inSeconds % 60;

    if (hours >= 24) {
      final days = hours ~/ 24;
      final h = hours % 24;
      return '${days}d ${h}h ${minutes}m';
    }
    return '${hours}h ${minutes}m ${seconds}s';
  }

  bool _isProductCountdownExpired(AttachedProduct ap) {
    final startedAt = ap.countdownStartedAt;
    if (startedAt == null) return false;
    final expiresAt = startedAt.add(const Duration(days: 2));
    return _now.isAfter(expiresAt);
  }

  Widget _buildMessagesList(ChatRoomViewModel viewModel) {
    if (viewModel.isLoadingMessages && viewModel.messages.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (viewModel.messages.isEmpty) {
      return LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 74,
                      height: 74,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.forum_outlined,
                        color: AppColors.primary,
                        size: 34,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'No messages yet',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Share a quick update, ask a question, or send photos to get the conversation moving.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    }

    final timelineItems = _buildTimelineItems(viewModel);

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(0, 6, 0, 18),
      itemCount: timelineItems.length + (viewModel.isLoadingMessages ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == 0 && viewModel.isLoadingMessages) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final itemIndex = viewModel.isLoadingMessages ? index - 1 : index;
        if (itemIndex < 0 || itemIndex >= timelineItems.length) {
          return const SizedBox.shrink();
        }

        final item = timelineItems[itemIndex];
        if (item.isDateDivider) {
          return _buildDateDivider(item.dateLabel!);
        }

        final message = item.message!;
        final isCurrentUser = message.senderId == _getCurrentUserId();

        if (!isCurrentUser && !message.isReadBy(_getCurrentUserId())) {
          Future.microtask(() => viewModel.markMessageAsRead(message.id));
        }

        return ChatBubble(
          message: message,
          isCurrentUser: isCurrentUser,
          attachedProduct: null,
        );
      },
    );
  }

  List<_ChatTimelineItem> _buildTimelineItems(ChatRoomViewModel viewModel) {
    final items = <_ChatTimelineItem>[];
    String? activeDateLabel;

    for (final message in viewModel.messages) {
      final dateLabel = _formatDateDivider(message.sentAt);
      if (dateLabel != activeDateLabel) {
        activeDateLabel = dateLabel;
        items.add(_ChatTimelineItem.dateDivider(dateLabel));
      }
      items.add(_ChatTimelineItem.message(message));
    }

    return items;
  }

  Widget _buildDateDivider(String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: AppColors.border),
          ),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showChatActions(Conversation conversation) async {
    final participant = _otherParticipant(conversation);
    await AppActionSheet.show(
      context,
      title: 'Conversation',
      items: [
        if (participant != null && participant.userId > 0)
          AppActionSheetItem(
            label: 'View profile',
            icon: Icons.person_outline_rounded,
            onTap: () => Navigator.of(context).pushNamed(
              AppRoutes.userProfile,
              arguments: OtherProfileArgs(userId: participant.userId),
            ),
          ),
        if (conversation.product != null)
          AppActionSheetItem(
            label: 'Open listing',
            icon: Icons.open_in_new_rounded,
            onTap: () => Navigator.of(context).pushNamed(
              AppRoutes.productDetail,
              arguments: ProductDetailArgs(productId: conversation.product!.id),
            ),
          ),
        if (participant != null && participant.userId > 0)
          AppActionSheetItem(
            label: 'Report user',
            icon: Icons.flag_outlined,
            isDestructive: true,
            onTap: () => _reportUser(
              userId: participant.userId,
              displayName: participant.user?.name ?? 'user',
            ),
          ),
        if (participant != null && participant.userId > 0)
          AppActionSheetItem(
            label: 'Block user',
            icon: Icons.block_rounded,
            isDestructive: true,
            onTap: () => _blockUser(
              userId: participant.userId,
              displayName: participant.user?.name ?? 'user',
            ),
          ),
        AppActionSheetItem(
          label: 'Delete chat',
          icon: Icons.delete_outline_rounded,
          isDestructive: true,
          onTap: () => _deleteConversation(conversation),
        ),
      ],
    );
  }

  Future<void> _reportUser({
    required int userId,
    required String displayName,
  }) async {
    final reason = await showUserReportReasonDialog(
      context,
      title: 'Report $displayName',
    );
    if (!mounted || reason == null) return;

    final response = await UserApiService.instance.reportUser(
      userId: userId,
      reason: reason,
    );

    if (!mounted) return;

    if (response.isSuccess) {
      AppSnackBar.success(context, 'Report submitted');
      return;
    }

    AppSnackBar.error(
      context,
      response.error?.message ?? 'Failed to submit report',
    );
  }

  Future<void> _blockUser({
    required int userId,
    required String displayName,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Block $displayName?'),
        content: const Text(
          'They won\'t be able to message you or see your listings.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFD64545),
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Block'),
          ),
        ],
      ),
    );
    if (!mounted || confirmed != true) return;

    final response = await UserApiService.instance.blockUser(userId);
    if (!mounted) return;

    if (response.isSuccess) {
      AppSnackBar.success(context, '$displayName blocked');
    } else {
      AppSnackBar.error(
        context,
        response.error?.message ?? 'Failed to block user',
      );
    }
  }

  Future<void> _deleteConversation(Conversation conversation) async {
    final confirmed = await showDeleteChatConfirmation(
      context,
      title: 'Delete chat',
      message: 'This removes the conversation from your chat list.',
    );
    if (!mounted || !confirmed) return;

    final success = await _viewModel.deleteConversation(conversation.id);
    if (!mounted) return;

    if (success) {
      AppSnackBar.success(context, 'Chat deleted');
      Navigator.of(context).maybePop();
      return;
    }

    AppSnackBar.error(
      context,
      _viewModel.conversationsError ?? 'Failed to delete conversation',
    );
  }

  ConversationParticipant? _otherParticipant(Conversation conversation) {
    final currentUserId = _getCurrentUserId();
    return conversation.participants?.firstWhere(
          (participant) =>
              participant.user != null &&
              participant.userId > 0 &&
              participant.userId != currentUserId,
          orElse: () => ConversationParticipant(
            id: 0,
            conversationId: conversation.id,
            userId: 0,
            joinedAt: DateTime.now(),
          ),
        ) ??
        conversation.participants?.firstWhere(
          (participant) => participant.user != null && participant.userId > 0,
          orElse: () => ConversationParticipant(
            id: 0,
            conversationId: conversation.id,
            userId: 0,
            joinedAt: DateTime.now(),
          ),
        );
  }

  String _formatDateDivider(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final target = DateTime(date.year, date.month, date.day);

    if (target == today) {
      return 'Today';
    }
    if (target == yesterday) {
      return 'Yesterday';
    }

    const months = <String>[
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    final month = months[date.month - 1];
    if (date.year == now.year) {
      return '$month ${date.day}';
    }
    return '$month ${date.day}, ${date.year}';
  }

  int _getCurrentUserId() {
    final userViewModel = Provider.of<UserViewModel>(context, listen: false);
    return userViewModel.userId ?? 0;
  }

  String _buildPresenceLabel(DateTime updatedAt) {
    final now = DateTime.now();
    final diff = now.difference(updatedAt);
    if (diff.inMinutes <= 5) {
      return 'Active now';
    }
    if (diff.inHours < 1) {
      return 'Recently active';
    }
    if (diff.inDays < 1) {
      return 'Active today';
    }
    return 'Offline';
  }

  Color _presenceColor(DateTime updatedAt) {
    final now = DateTime.now();
    final diff = now.difference(updatedAt);
    if (diff.inMinutes <= 5) {
      return const Color(0xFF34C759);
    }
    if (diff.inHours < 24) {
      return const Color(0xFFFFB020);
    }
    return AppColors.textSecondary;
  }
}

class _ChatTimelineItem {
  final String? dateLabel;
  final Message? message;

  const _ChatTimelineItem._({
    this.dateLabel,
    this.message,
  });

  factory _ChatTimelineItem.dateDivider(String label) {
    return _ChatTimelineItem._(dateLabel: label);
  }

  factory _ChatTimelineItem.message(Message message) {
    return _ChatTimelineItem._(message: message);
  }

  bool get isDateDivider => dateLabel != null;
}
