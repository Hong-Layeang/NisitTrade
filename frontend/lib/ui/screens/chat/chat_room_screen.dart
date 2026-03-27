import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';

import '../../../core/constants/colors.dart';
import '../../../core/navigation/app_routes.dart';
import '../../../core/utils/chat_timestamp_formatter.dart';
import '../../../core/utils/school_short_name.dart';
import '../../../core/utils/user_presence_formatter.dart';
import '../../../data/models/conversation.dart';
import '../../../data/models/product.dart';
import '../../../logic/view_models/chat_view_model.dart';
import '../../../logic/view_models/presence_view_model.dart';
import '../../../logic/view_models/user_view_model.dart';
import '../../../ui/screens/marketplace/product_detail_page.dart';
import '../../../ui/screens/profile/other_profile_page.dart' hide getIt;
import '../../../ui/widgets/app_action_sheet.dart';
import '../../../ui/widgets/app_snack_bar.dart';
import '../../../ui/widgets/user_widgets.dart';
import 'widgets/attachment_carousel.dart';
import 'widgets/chat_bubble.dart';
import 'widgets/chat_input.dart';
import '../../../data/providers/user_api_service.dart';
import '../../../data/providers/product_api_service.dart';
import 'widgets/chat_menu_helpers.dart';
import 'widgets/purchase_rating_dialog.dart';

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

class _ChatRoomScreenState extends State<ChatRoomScreen>
    with WidgetsBindingObserver {
  late ChatRoomViewModel _viewModel;
  late ScrollController _scrollController;
  bool _hasInitialized = false;
  Timer? _countdownTimer;
  DateTime _now = DateTime.now();
  final Set<int> _expiredPromptedProductIds = {};
  int? _lastSeenBottomMessageId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || !_hasInitialized) return;
      _checkForNewlyExpiredAttachments();
      if (_viewModel.attachedProducts.isNotEmpty) {
        setState(() {
          _now = DateTime.now();
        });
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_hasInitialized) {
      return;
    }

    _viewModel = Provider.of<ChatRoomViewModel>(context, listen: false);
    _viewModel.addListener(_onViewModelChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _ensureWebSocketAndJoin();
      _loadConversation();
    });
    _hasInitialized = true;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _viewModel.removeListener(_onViewModelChanged);
    _countdownTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed && _hasInitialized) {
      // Reconnect WS and rejoin room to catch any missed messages
      _ensureWebSocketAndJoin();
      // Reload messages to get anything sent while the app was backgrounded
      _refreshMessages();
    }
  }

  Future<void> _refreshMessages() async {
    if (!mounted) return;
    await _viewModel.loadMessages(refresh: true);
    if (mounted) _scrollToBottom(animated: false);
  }

  /// Scrolls to the bottom whenever a new message is appended at the end
  /// of the list (e.g. incoming WebSocket message). Only auto-scrolls when
  /// the user is already near the bottom so we don't interrupt reading.
  void _onViewModelChanged() {
    final messages = _viewModel.messages;
    if (messages.isEmpty) return;
    final lastId = messages.last.id;
    if (lastId != _lastSeenBottomMessageId) {
      _lastSeenBottomMessageId = lastId;
      if (_isNearBottom()) {
        _scrollToBottom();
      }
    }
  }

  bool _isNearBottom() {
    if (!_scrollController.hasClients) return true;
    try {
      final pos = _scrollController.position;
      return (pos.maxScrollExtent - pos.pixels) < 200;
    } catch (_) {
      return true;
    }
  }

  Future<void> _ensureWebSocketAndJoin() async {
    await _viewModel.ensureWebSocketConnected();
    _viewModel.joinConversationRoom(widget.conversationId);
  }

  Future<void> _loadConversation() async {
    final currentConversation = _viewModel.currentConversation;
    final hasMatchingConversation =
        currentConversation?.id == widget.conversationId;
    final needsHydration =
        !hasMatchingConversation ||
        _requiresConversationHydration(currentConversation);

    if (needsHydration) {
      await _viewModel.loadConversation(widget.conversationId);
    }

    if (_viewModel.currentConversation?.id == widget.conversationId) {
      await _viewModel.loadMessages(refresh: true);
    }

    _watchCurrentParticipantPresence();
    _scrollToBottom(animated: false);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _checkForNewlyExpiredAttachments();
    });
  }

  void _watchCurrentParticipantPresence() {
    final conversation = _viewModel.currentConversation;
    if (conversation == null) {
      return;
    }

    final participant = _otherParticipant(conversation);
    if (participant == null || participant.userId <= 0) {
      return;
    }

    final presenceViewModel = Provider.of<PresenceViewModel>(
      context,
      listen: false,
    );
    presenceViewModel.watchUserIds([participant.userId]);
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
    final hasPendingAttachments = _viewModel.attachedProducts.any(
      (ap) => ap.countdownStartedAt == null,
    );

    final success = await _viewModel.sendMessage(
      messageText,
      imagePaths: imagePaths,
      attachConversationProduct: hasPendingAttachments,
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
    return Consumer<ChatRoomViewModel>(
      builder: (context, viewModel, _) {
        final isSelectionMode = viewModel.isSelectionMode;

        return PopScope(
          canPop: !isSelectionMode,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop && isSelectionMode) {
              viewModel.clearSelection();
            }
          },
          child: Scaffold(
            backgroundColor: AppColors.surface,
            appBar: isSelectionMode
                ? _buildSelectionAppBar(viewModel)
                : _buildNormalAppBar(),
            body: _buildBody(viewModel),
          ),
        );
      },
    );
  }

  PreferredSizeWidget _buildSelectionAppBar(ChatRoomViewModel viewModel) {
    final currentUserId = _getCurrentUserId();
    final canEdit = viewModel.canEditSelectedMessages(currentUserId);
    final canDelete = viewModel.canDeleteSelectedMessages(currentUserId);

    return AppBar(
      elevation: 0,
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      leading: IconButton(
        icon: const Icon(Icons.close_rounded),
        onPressed: viewModel.clearSelection,
      ),
      title: Text(
        '${viewModel.selectedCount} selected',
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
      actions: [
        if (canEdit)
          IconButton(
            icon: const Icon(Icons.edit_rounded),
            tooltip: 'Edit',
            onPressed: () => _editSelectedMessage(viewModel),
          ),
        if (canDelete)
          IconButton(
            icon: const Icon(Icons.delete_rounded),
            tooltip: 'Delete',
            onPressed: () => _deleteSelectedMessages(viewModel),
          ),
      ],
    );
  }

  PreferredSizeWidget _buildNormalAppBar() {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.white,
      foregroundColor: AppColors.textPrimary,
      titleSpacing: 0,
      title: Consumer2<ChatRoomViewModel, PresenceViewModel>(
        builder: (context, viewModel, presenceViewModel, _) {
          final conversation = viewModel.currentConversation;
          return _buildAppBarTitle(conversation, presenceViewModel);
        },
      ),
      actions: [
        Consumer<ChatRoomViewModel>(
          builder: (context, viewModel, _) {
            final conversation = viewModel.currentConversation;
            return IconButton(
              icon: const Icon(Icons.more_vert_rounded),
              onPressed: conversation == null
                  ? null
                  : () => _showChatActions(conversation),
            );
          },
        ),
      ],
    );
  }

  Widget _buildBody(ChatRoomViewModel viewModel) {
    final conversation = viewModel.currentConversation;
    final isMessagingBlocked = conversation?.isMessagingBlocked ?? false;
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
                countdownLabelBuilder: (ap) {
                  final isOwner =
                      ap.product.userId == _getCurrentUserId();
                  return _buildProductCountdownLabel(ap, isOwner: isOwner);
                },
                isExpiredBuilder: _isProductCountdownExpired,
                isOwnerBuilder: (product) =>
                    product.userId == _getCurrentUserId(),
                onTapProduct: (product) => _navigateToProduct(product),
                onConfirmPurchase: (product) =>
                    _handleConfirmPurchase(product),
                onMarkAsSold: (product) => _handleMarkAsSold(product),
                onRemove: (product) =>
                    vm.removeAttachedProduct(product.id),
              );
            },
          ),
          Expanded(child: _buildMessagesList(viewModel)),
          if (viewModel.isSelectionMode)
            const SizedBox.shrink()
          else if (isMessagingBlocked)
            _buildBlockedComposerState(conversation)
          else
            ChatInput(
              onSendMessage: _handleSendMessage,
              isLoading: viewModel.isLoadingCurrentConversation,
              isSendingMessage: viewModel.isSendingMessage,
            ),
        ],
      ),
    );
  }

  Future<void> _editSelectedMessage(ChatRoomViewModel viewModel) async {
    final messageId = viewModel.selectedMessageIds.first;
    final message = viewModel.messages.firstWhere(
      (m) => m.id == messageId,
      orElse: () => Message(id: 0, messageText: '', senderId: 0, conversationId: 0, sentAt: DateTime.now()),
    );
    if (message.id == 0) return;

    final result = await showDialog<String>(
      context: context,
      builder: (context) => _EditMessageDialog(initialText: message.messageText),
    );

    if (!mounted || result == null) return;
    final success = await viewModel.editMessage(messageId, result);
    if (!mounted) return;
    if (success) {
      AppSnackBar.success(context, 'Message edited');
    } else {
      AppSnackBar.error(context, 'Failed to edit message');
    }
  }

  Future<void> _deleteSelectedMessages(ChatRoomViewModel viewModel) async {
    final count = viewModel.selectedCount;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete $count message${count > 1 ? 's' : ''}?'),
        content: const Text('This action cannot be undone.'),
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
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (!mounted || confirmed != true) return;

    final success = await viewModel.deleteSelectedMessages();
    if (!mounted) return;
    if (success) {
      AppSnackBar.success(context, '$count message${count > 1 ? 's' : ''} deleted');
    } else {
      AppSnackBar.error(context, 'Failed to delete messages');
    }
  }

  Widget _buildAppBarTitle(
    Conversation? conversation,
    PresenceViewModel presenceViewModel,
  ) {
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
    final participantUserId = participant?.userId ?? 0;
    final realtimePresence = participantUserId > 0
      ? presenceViewModel.presenceForUser(participantUserId)
      : null;
    final isOnline =
      realtimePresence?.isOnline ?? participant?.user?.isOnline ?? false;
    final lastSeenAt =
      realtimePresence?.lastSeenAt ?? participant?.user?.lastSeenAt;
    final statusInfo = buildPresenceLabel(
      isOnline: isOnline,
      lastSeenAt: lastSeenAt,
    );

    return GestureDetector(
      onTap: participantUserId > 0
          ? () => Navigator.of(context).pushNamed(
                AppRoutes.userProfile,
                arguments: OtherProfileArgs(userId: participantUserId),
              )
          : null,
      child: Row(
        children: [
          UserAvatar(imageUrl: avatarUrl, displayName: displayName, radius: 18),
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
                      color: presenceColor(isOnline: isOnline),
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
      ),
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

  void _checkForNewlyExpiredAttachments() {
    final currentUserId = _getCurrentUserId();
    for (final ap in List.of(_viewModel.attachedProducts)) {
      if (!_isProductCountdownExpired(ap)) continue;
      if (_expiredPromptedProductIds.contains(ap.product.id)) continue;

      _expiredPromptedProductIds.add(ap.product.id);
      final isOwner =
          currentUserId != 0 && ap.product.userId == currentUserId;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          if (isOwner) {
            _promptSaleCompleteAsSeller(ap.product);
          } else {
            _promptDidBuy(ap.product);
          }
        }
      });
    }
  }

  Future<void> _promptDidBuy(Product product) async {
    final didBuy = await showDidYouBuyPrompt(
      context,
      productTitle: product.title,
    );
    if (!mounted) return;

    if (didBuy == true) {
      await _handleConfirmPurchase(product);
    } else {
      _viewModel.removeAttachedProduct(product.id);
    }
  }

  Future<void> _promptSaleCompleteAsSeller(Product product) async {
    final didSell = await showDidYouSellPrompt(
      context,
      productTitle: product.title,
    );
    if (!mounted) return;

    if (didSell == true) {
      await _handleMarkAsSold(product);
    } else {
      _viewModel.removeAttachedProduct(product.id);
    }
  }

  Future<void> _handleMarkAsSold(Product product) async {
    final choice = await _showUpdateListingStatusDialog(product);
    if (!mounted) return;

    _viewModel.removeAttachedProduct(product.id);

    if (choice == _ListingStatusChoice.markAsSold) {
      final response = await ProductApiService.instance.updateProductStatus(
        id: product.id,
        status: 'sold',
      );
      if (!mounted) return;
      if (response.isSuccess) {
        AppSnackBar.success(context, 'Listing marked as sold and removed from feed');
      } else {
        AppSnackBar.error(
          context,
          response.error?.message ?? 'Could not update listing status',
        );
      }
    }
    // _ListingStatusChoice.keepActive: do nothing — listing stays on feed
  }

  Future<_ListingStatusChoice?> _showUpdateListingStatusDialog(
      Product product) {
    return showModalBottomSheet<_ListingStatusChoice>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (_) => _UpdateListingStatusSheet(product: product),
    );
  }

  Future<void> _handleConfirmPurchase(Product product) async {
    final conversation = _viewModel.currentConversation;
    final sellerParticipant = conversation != null
        ? _otherParticipant(conversation)
        : null;
    final sellerName = sellerParticipant?.user?.name ??
        'Seller';

    final result = await showPurchaseRatingDialog(
      context,
      sellerName: sellerName,
      productTitle: product.title,
    );

    if (!mounted) return;

    if (result == null) {
      _viewModel.removeAttachedProduct(product.id);
      return;
    }

    final sellerId = product.userId != 0
        ? product.userId
        : (sellerParticipant?.userId ?? 0);

    if (sellerId == 0) {
      _viewModel.removeAttachedProduct(product.id);
      AppSnackBar.error(context, 'Could not identify seller to rate');
      return;
    }

    final response = await UserApiService.instance.submitRating(
      sellerId: sellerId,
      productId: product.id,
      rating: result.rating,
      feedback: result.feedback,
    );

    if (!mounted) return;

    _viewModel.removeAttachedProduct(product.id);

    if (response.isSuccess) {
      AppSnackBar.success(context, 'Review submitted — thank you!');
    } else {
      AppSnackBar.error(context, response.error?.message ?? 'Failed to submit review');
    }
  }

  String _buildProductCountdownLabel(AttachedProduct ap,
      {bool isOwner = false}) {
    final startedAt = ap.countdownStartedAt;
    if (startedAt == null) {
      return isOwner ? 'Awaiting buyer' : 'Awaiting purchase message';
    }

    final expiresAt = startedAt.add(purchaseDuration);
    final remaining = expiresAt.difference(_now);
    if (remaining.isNegative || remaining.inSeconds <= 0) {
      return isOwner ? 'Sale window closed' : 'Purchase window expired';
    }

    final hours = remaining.inHours;
    final minutes = remaining.inMinutes % 60;
    final seconds = remaining.inSeconds % 60;

    if (hours >= 24) {
      final days = hours ~/ 24;
      final h = hours % 24;
      return '${days}d ${h}h ${minutes}m left';
    }
    return '${hours}h ${minutes}m ${seconds}s left';
  }

  bool _isProductCountdownExpired(AttachedProduct ap) {
    final startedAt = ap.countdownStartedAt;
    if (startedAt == null) return false;
    final expiresAt = startedAt.add(purchaseDuration);
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

        final isSelected = viewModel.isMessageSelected(message.id);
        final isSelectionMode = viewModel.isSelectionMode;

        return ChatBubble(
          message: message,
          isCurrentUser: isCurrentUser,
          attachedProduct: message.attachedProduct,
          isSelected: isSelected,
          isSelectionMode: isSelectionMode,
          onLongPress: () {
            if (isCurrentUser) {
              viewModel.startSelection(message.id);
            }
          },
          onTap: isSelectionMode && isCurrentUser
              ? () => viewModel.toggleMessageSelection(message.id)
              : null,
        );
      },
    );
  }

  List<_ChatTimelineItem> _buildTimelineItems(ChatRoomViewModel viewModel) {
    final items = <_ChatTimelineItem>[];
    String? activeDateLabel;

    for (final message in viewModel.messages) {
      final dateLabel = formatChatDateLabel(message.sentAt);
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

  Widget _buildBlockedComposerState(Conversation conversation) {
    final title = conversation.isBlockedByMe
        ? 'Messaging paused'
        : 'Messaging unavailable';
    final message = conversation.isBlockedByMe
        ? 'You blocked this account. Conversation history stays available, and messaging will resume after you unblock them.'
        : 'This account is not available for new messages right now. Your conversation history remains available below.';

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(top: BorderSide(color: AppColors.border)),
        boxShadow: [
          BoxShadow(
            color: AppColors.textPrimary.withValues(alpha: 0.05),
            blurRadius: 18,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: AppColors.warningBackground,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.border),
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    conversation.isBlockedByMe
                        ? Icons.block_flipped
                        : Icons.shield_outlined,
                    size: 18,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        message,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                          height: 1.4,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showChatActions(Conversation conversation) async {
    final participant = _otherParticipant(conversation);
    final hasAttachments = _viewModel
        .attachedProductsForConversation(conversation.id)
        .isNotEmpty;
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
        if (conversation.product != null && hasAttachments)
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
            label: conversation.isBlockedByMe ? 'Unblock user' : 'Block user',
            icon: conversation.isBlockedByMe
                ? Icons.lock_open_rounded
                : Icons.block_rounded,
            isDestructive: true,
            onTap: () => conversation.isBlockedByMe
                ? _unblockUser(
                    conversation: conversation,
                    userId: participant.userId,
                    displayName: participant.user?.name ?? 'user',
                  )
                : _blockUser(
                    conversation: conversation,
                    userId: participant.userId,
                    displayName: participant.user?.name ?? 'user',
                  ),
          ),
        if (hasAttachments)
          AppActionSheetItem(
            label: 'Cancel pending purchase',
            icon: Icons.shopping_bag_outlined,
            isDestructive: true,
            onTap: () => _cancelPendingPurchase(conversation),
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

  Future<void> _cancelPendingPurchase(Conversation conversation) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel pending purchase?'),
        content: const Text(
          'This will remove all pending products from this conversation. You can always re-attach them from the product listing.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Keep'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFD64545),
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Cancel purchase'),
          ),
        ],
      ),
    );
    if (!mounted || confirmed != true) return;
    _viewModel.clearAttachedProductsForConversation(conversation.id);
    AppSnackBar.show(context, 'Pending purchase removed');
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
    required Conversation conversation,
    required int userId,
    required String displayName,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Block $displayName?'),
        content: const Text(
          'You will both stop being able to message each other, but your previous messages will stay visible until you unblock them.',
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
      _viewModel.setConversationBlockState(
        conversation.id,
        isBlockedByMe: true,
        hasBlockedMe: conversation.hasBlockedMe,
      );
      _viewModel.clearAttachedProductsForConversation(conversation.id);
    } else {
      AppSnackBar.error(
        context,
        response.error?.message ?? 'Failed to block user',
      );
    }
  }

  Future<void> _unblockUser({
    required Conversation conversation,
    required int userId,
    required String displayName,
  }) async {
    final response = await UserApiService.instance.unblockUser(userId);
    if (!mounted) return;

    if (response.isSuccess) {
      AppSnackBar.success(context, '$displayName unblocked');
      _viewModel.setConversationBlockState(
        conversation.id,
        isBlockedByMe: false,
        hasBlockedMe: conversation.hasBlockedMe,
      );
      return;
    }

    AppSnackBar.error(
      context,
      response.error?.message ?? 'Failed to unblock user',
    );
  }

  Future<void> _deleteConversation(Conversation conversation) async {
    final confirmed = await showDeleteChatConfirmation(
      context,
      title: 'Delete chat',
      message: 'This clears the conversation history for this chat.',
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

  int _getCurrentUserId() {
    final userViewModel = Provider.of<UserViewModel>(context, listen: false);
    return userViewModel.userId ?? 0;
  }

}

class _ChatTimelineItem {
  final String? dateLabel;
  final Message? message;

  const _ChatTimelineItem._({this.dateLabel, this.message});

  factory _ChatTimelineItem.dateDivider(String label) {
    return _ChatTimelineItem._(dateLabel: label);
  }

  factory _ChatTimelineItem.message(Message message) {
    return _ChatTimelineItem._(message: message);
  }

  bool get isDateDivider => dateLabel != null;
}

// Dialog that owns its TextEditingController so it is disposed at the correct
// point in the widget lifecycle — avoiding the "used after dispose" crash that
// occurs when the controller is disposed synchronously after showDialog returns.
class _EditMessageDialog extends StatefulWidget {
  final String initialText;

  const _EditMessageDialog({required this.initialText});

  @override
  State<_EditMessageDialog> createState() => _EditMessageDialogState();
}

class _EditMessageDialogState extends State<_EditMessageDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialText);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit message'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        maxLines: 5,
        minLines: 1,
        decoration: const InputDecoration(
          hintText: 'Enter new message text',
          border: OutlineInputBorder(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            final text = _controller.text.trim();
            if (text.isNotEmpty) {
              Navigator.of(context).pop(text);
            }
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------

enum _ListingStatusChoice { markAsSold, keepActive }

class _UpdateListingStatusSheet extends StatelessWidget {
  final Product product;

  const _UpdateListingStatusSheet({required this.product});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(context).bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(top: 12, bottom: 20),
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
            child: Column(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0FBA81).withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: const BoxDecoration(
                      color: Color(0xFF0FBA81),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: const Icon(Icons.check_rounded,
                        color: Colors.white, size: 24),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Sale Complete! 🎉',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  "Would you like to update this listing's status on the feed?",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.sell_outlined,
                          size: 13, color: AppColors.primary),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          product.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.of(context)
                        .pop(_ListingStatusChoice.markAsSold),
                    icon: const Icon(Icons.remove_shopping_cart_outlined,
                        size: 18),
                    label: const Text('Mark as Sold — Remove from Feed'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(52),
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.of(context)
                        .pop(_ListingStatusChoice.keepActive),
                    icon: const Icon(Icons.layers_outlined, size: 18),
                    label: const Text('Keep Listing Active'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(52),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      side: const BorderSide(color: AppColors.border),
                      foregroundColor: AppColors.textSecondary,
                      textStyle: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Choose "Keep Listing Active" if you have more of this item to sell.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary.withValues(alpha: 0.7),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
