import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';

import '../../../core/constants/colors.dart';
import '../../../core/di/service_locator.dart';
import '../../../core/navigation/app_routes.dart';
import '../../../core/utils/chat_timestamp_formatter.dart';
import '../../../core/utils/school_short_name.dart';
import '../../../core/utils/user_presence_formatter.dart';
import '../../../data/dtos/conversation_dto.dart';
import '../../../data/dtos/product_dto.dart';
import '../../../data/repository_interfaces/i_product_repository.dart';
import '../../../data/repository_interfaces/i_user_repository.dart';
import '../../../logic/services/profile_content_change_notifier.dart';
import '../../../logic/view_models/chat_view_model.dart';
import '../../../logic/view_models/presence_view_model.dart';
import '../../../logic/view_models/product_feed_view_model.dart';
import '../../../logic/view_models/user_view_model.dart';
import '../../../ui/screens/marketplace/product_detail_page.dart' hide getIt;
import '../../../ui/screens/profile/other_profile_page.dart' hide getIt;
import '../../../ui/widgets/app_action_sheet.dart';
import '../../../ui/widgets/app_loading.dart';
import '../../../ui/widgets/app_snack_bar.dart';
import '../../../ui/widgets/loading_error_builder.dart';
import '../../../ui/widgets/user_widgets.dart';
import 'widgets/attachment_carousel.dart';
import 'widgets/chat_bubble.dart';
import 'widgets/chat_input.dart';
import 'widgets/chat_menu_helpers.dart';
import 'purchase_confirmation_message.dart';
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
  final IUserRepository _userRepository = getIt<IUserRepository>();
  final IProductRepository _productRepository = getIt<IProductRepository>();
  bool _hasInitialized = false;
  Timer? _countdownTimer;
  DateTime _now = DateTime.now();
  final Set<int> _expiredPromptedProductIds = {};
  final Set<int> _autoPromptedPurchaseConfirmationMessageIds = {};
  final Set<int> _processedSellerDecisionMessageIds = {};
  int? _lastSeenBottomMessageId;
  bool _hasPositionedLatestMessage = false;
  bool _isShowingPurchaseConfirmationPrompt = false;
  bool _isShowingBuyerRatingPrompt = false;
  bool _hasPrimedSellerDecisionHistory = false;

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
    if (_viewModel.currentConversation?.id == widget.conversationId) {
      _viewModel.clearCurrentConversation(notify: false);
    }
    _countdownTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed && _hasInitialized) {
      _ensureWebSocketAndJoin();
    }
  }

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

    _maybePromptSellerForConfirmedPurchase();
    _applySellerDecisionSignals();
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
    _hasPositionedLatestMessage = false;
    _lastSeenBottomMessageId = null;
    _hasPrimedSellerDecisionHistory = false;
    _processedSellerDecisionMessageIds.clear();

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
      await _viewModel.loadMessages(refresh: true, preserveExisting: false);
    }

    _primeSellerDecisionHistory();

    _watchCurrentParticipantPresence();
    _scrollToBottom(animated: false);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      _checkForNewlyExpiredAttachments();
      _maybePromptSellerForConfirmedPurchase();
    });
  }

  void _maybePromptSellerForConfirmedPurchase() {
    if (!mounted || _isShowingPurchaseConfirmationPrompt) {
      return;
    }

    final conversation = _viewModel.currentConversation;
    if (conversation == null || conversation.id != widget.conversationId) {
      return;
    }

    final currentUserId = _getCurrentUserId();
    if (currentUserId == 0) {
      return;
    }

    for (final message in _viewModel.messages.reversed) {
      final confirmedProductId = PurchaseConfirmationMessage.tryParseProductId(
        message.messageText,
      );
      if (confirmedProductId == null) {
        continue;
      }
      if (_autoPromptedPurchaseConfirmationMessageIds.contains(message.id)) {
        continue;
      }

      _autoPromptedPurchaseConfirmationMessageIds.add(message.id);

      if (!_isBuyerMessageForCurrentConversation(message, conversation)) {
        continue;
      }

      if (message.senderId == currentUserId) {
        continue;
      }

      AttachedProduct? confirmedProduct;
      for (final attachedProduct in _viewModel.attachedProducts) {
        if (attachedProduct.product.id == confirmedProductId) {
          confirmedProduct = attachedProduct;
          break;
        }
      }

      if (confirmedProduct == null) {
        continue;
      }
      if (confirmedProduct.product.isSold || confirmedProduct.product.isHidden) {
        _viewModel.removeAttachedProduct(confirmedProduct.product.id);
        continue;
      }
      if (!_isProductOwnerForConversation(confirmedProduct.product, conversation)) {
        continue;
      }

      _isShowingPurchaseConfirmationPrompt = true;
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) {
          _isShowingPurchaseConfirmationPrompt = false;
          return;
        }

        await _handleMarkAsSold(confirmedProduct!.product);
        if (mounted) {
          _isShowingPurchaseConfirmationPrompt = false;
        }
      });
      break;
    }
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

  bool _requiresConversationHydration(ConversationDto? conversation) {
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

  void _scrollToBottom({bool animated = true, int retryFrames = 8}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      if (!_scrollController.hasClients) {
        if (retryFrames > 0) {
          _scrollToBottom(animated: animated, retryFrames: retryFrames - 1);
        }
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

      _hasPositionedLatestMessage = true;
    });
  }

  void _onScroll() {
    if (!_scrollController.hasClients) {
      return;
    }

    if (!_hasPositionedLatestMessage) {
      return;
    }

    if (_scrollController.position.pixels <= 120) {
      _viewModel.loadMoreMessages();
    }
  }

  Future<bool> _handleSendMessage(
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
      return true;
    }

    if (!mounted) {
      return false;
    }

    AppSnackBar.error(
      context,
      _viewModel.sendMessageError ?? 'Failed to send message',
    );
    return false;
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

    return LoadingErrorBuilder(
      isLoading:
          viewModel.isLoadingCurrentConversation &&
          !isShowingRequestedConversation,
      error: isShowingRequestedConversation
          ? null
          : viewModel.currentConversationError,
      onRetry: _loadConversation,
      child: conversation == null
          ? const Center(child: Text('No conversation found'))
          : Container(
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
                          final isOwner = _isProductOwnerForConversation(
                            ap.product,
                            conversation,
                          );
                          return _buildProductCountdownLabel(
                            ap,
                            isOwner: isOwner,
                          );
                        },
                        isExpiredBuilder: _isProductCountdownExpired,
                        isOwnerBuilder: (product) =>
                            _isProductOwnerForConversation(
                              product,
                              conversation,
                            ),
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
            ),
    );
  }

  Future<void> _editSelectedMessage(ChatRoomViewModel viewModel) async {
    final messageId = viewModel.selectedMessageIds.first;
    final message = viewModel.messages.firstWhere(
      (m) => m.id == messageId,
      orElse: () => MessageDto(
        id: 0,
        messageText: '',
        senderId: 0,
        conversationId: 0,
        sentAt: DateTime.now(),
      ),
    );
    if (message.id == 0) return;

    final result = await showDialog<String>(
      context: context,
      builder: (context) =>
          _EditMessageDialog(initialText: message.messageText),
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
      AppSnackBar.success(
        context,
        '$count message${count > 1 ? 's' : ''} deleted',
      );
    } else {
      AppSnackBar.error(context, 'Failed to delete messages');
    }
  }

  Widget _buildAppBarTitle(
    ConversationDto? conversation,
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

  void _navigateToProduct(ProductDto product) {
    Navigator.of(context).pushNamed(
      AppRoutes.productDetail,
      arguments: ProductDetailArgs(productId: product.id),
    );
  }

  void _checkForNewlyExpiredAttachments() {
    final currentUserId = _getCurrentUserId();
    final conversation = _viewModel.currentConversation;
    for (final ap in List.of(_viewModel.attachedProducts)) {
      if (!_isProductCountdownExpired(ap)) continue;
      if (_expiredPromptedProductIds.contains(ap.product.id)) continue;

      _expiredPromptedProductIds.add(ap.product.id);
      final ownerId = _resolveProductOwnerId(ap.product, conversation);
      final isOwner = currentUserId != 0 && ownerId == currentUserId;
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

  Future<void> _promptDidBuy(ProductDto product) async {
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

  Future<void> _promptSaleCompleteAsSeller(ProductDto product) async {
    final didSell = await showDidYouSellPrompt(
      context,
      productTitle: product.title,
    );
    if (!mounted) return;

    if (didSell == true) {
      await _handleMarkAsSold(product);
    } else {
      _completePurchaseAttachmentCycle(product.id);
      await _sendSellerDecisionSignal(
        product,
        action: SellerPurchaseDecisionMessage.actionNotSold,
      );
    }
  }

  Future<void> _handleMarkAsSold(ProductDto product) async {
    final choice = await _showUpdateListingStatusDialog(product);
    if (!mounted) return;

    if (choice == null) {
      return;
    }

    if (choice == _ListingStatusChoice.keepActive) {
      _completePurchaseAttachmentCycle(product.id);
      await _sendSellerDecisionSignal(
        product,
        action: SellerPurchaseDecisionMessage.actionKeepActive,
      );
      return;
    }

    if (choice == _ListingStatusChoice.markAsSold) {
      final response = await _productRepository.updateProductStatus(
        id: product.id,
        status: 'sold',
      );
      if (!mounted) return;
      if (response.isSuccess) {
        _viewModel.removeAttachedProduct(product.id);
        await _sendSellerDecisionSignal(
          product,
          action: SellerPurchaseDecisionMessage.actionSold,
        );
        if (!mounted) return;
        final updatedProduct = response.data;
        if (updatedProduct != null) {
          context.read<ProductFeedViewModel>().applyExternalProductUpdate(
            updatedProduct,
          );
          getIt<ProfileContentChangeNotifier>().markProductChanged(
            ownerUserId: updatedProduct.userId,
          );
        }
      } else {
        AppSnackBar.error(
          context,
          response.error?.message ?? 'Could not update listing status',
        );
      }
    }
  }

  bool _isBuyerMessageForCurrentConversation(
    MessageDto message,
    ConversationDto conversation,
  ) {
    final participant = _otherParticipant(conversation);
    if (participant == null || participant.userId <= 0) {
      return false;
    }
    return message.senderId == participant.userId;
  }

  Future<_ListingStatusChoice?> _showUpdateListingStatusDialog(
    ProductDto product,
  ) {
    return showModalBottomSheet<_ListingStatusChoice>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (_) => _UpdateListingStatusSheet(product: product),
    );
  }

  Future<void> _handleConfirmPurchase(ProductDto product) async {
    final conversation = _viewModel.currentConversation;
    final sellerParticipant = conversation != null
        ? _sellerParticipant(conversation, product)
        : null;
    final sellerName = sellerParticipant?.user?.name ?? 'Seller';

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

    final sellerId = _resolveProductOwnerId(product, conversation);
    final currentUserId = _getCurrentUserId();

    if (sellerId == 0) {
      _viewModel.removeAttachedProduct(product.id);
      AppSnackBar.error(context, 'Could not identify seller to rate');
      return;
    }

    if (currentUserId != 0 && sellerId == currentUserId) {
      _viewModel.removeAttachedProduct(product.id);
      AppSnackBar.error(context, 'You cannot rate your own listing');
      return;
    }

    final response = await _userRepository.submitRating(
      sellerId: sellerId,
      productId: product.id,
      rating: result.rating,
      feedback: result.feedback,
    );

    if (!mounted) return;

    if (response.isSuccess) {
      _completePurchaseAttachmentCycle(product.id);
      final notifiedSeller = await _sendPurchaseConfirmationSignal(product);
      if (!mounted) return;

      AppSnackBar.success(
        context,
        notifiedSeller
            ? 'Review submitted. Seller can now update the listing.'
            : 'Review submitted - thank you!',
      );
    } else {
      AppSnackBar.error(
        context,
        response.error?.message ?? 'Failed to submit review',
      );
    }
  }

  Future<void> _promptBuyerToRateAfterSellerMarkedSold(
    ProductDto product,
  ) async {
    final conversation = _viewModel.currentConversation;
    final sellerParticipant = conversation != null
        ? _sellerParticipant(conversation, product)
        : null;
    final sellerName = sellerParticipant?.user?.name ?? 'Seller';

    final result = await showPurchaseRatingDialog(
      context,
      sellerName: sellerName,
      productTitle: product.title,
    );

    if (!mounted) return;

    if (result == null) {
      _completePurchaseAttachmentCycle(product.id);
      return;
    }

    final sellerId = _resolveProductOwnerId(product, conversation);
    final currentUserId = _getCurrentUserId();

    if (sellerId == 0) {
      _completePurchaseAttachmentCycle(product.id);
      AppSnackBar.error(context, 'Could not identify seller to rate');
      return;
    }

    if (currentUserId != 0 && sellerId == currentUserId) {
      _completePurchaseAttachmentCycle(product.id);
      AppSnackBar.error(context, 'You cannot rate your own listing');
      return;
    }

    final response = await _userRepository.submitRating(
      sellerId: sellerId,
      productId: product.id,
      rating: result.rating,
      feedback: result.feedback,
    );

    if (!mounted) return;

    _completePurchaseAttachmentCycle(product.id);

    if (response.isSuccess) {
      AppSnackBar.success(context, 'Thanks for rating your purchase.');
    } else {
      AppSnackBar.error(
        context,
        response.error?.message ?? 'Failed to submit review',
      );
    }
  }

  void _completePurchaseAttachmentCycle(int productId) {
    _expiredPromptedProductIds.remove(productId);
    _viewModel.completeAttachedProductCycle(productId);
  }

  Future<bool> _sendPurchaseConfirmationSignal(ProductDto product) async {
    return _viewModel.sendMessage(
      PurchaseConfirmationMessage.build(productId: product.id),
      attachConversationProduct: false,
    );
  }

  Future<void> _sendSellerDecisionSignal(
    ProductDto product, {
    required String action,
  }) async {
    await _viewModel.sendMessage(
      SellerPurchaseDecisionMessage.build(productId: product.id, action: action),
      attachedProductId: product.id,
      attachConversationProduct: false,
    );
  }

  void _primeSellerDecisionHistory() {
    for (final message in _viewModel.messages) {
      final decision = SellerPurchaseDecisionMessage.tryParse(message.messageText);
      if (decision != null) {
        _processedSellerDecisionMessageIds.add(message.id);
        _completePurchaseAttachmentCycle(decision.productId);
      }
    }
    _hasPrimedSellerDecisionHistory = true;
  }

  void _applySellerDecisionSignals() {
    if (!mounted || _isShowingBuyerRatingPrompt || !_hasPrimedSellerDecisionHistory) return;

    final conversation = _viewModel.currentConversation;
    if (conversation == null || conversation.id != widget.conversationId) {
      return;
    }

    final currentUserId = _getCurrentUserId();
    if (currentUserId == 0) {
      return;
    }

    for (final message in _viewModel.messages.reversed) {
      final decision = SellerPurchaseDecisionMessage.tryParse(message.messageText);
      if (decision == null) continue;
      if (_processedSellerDecisionMessageIds.contains(message.id)) continue;

      _processedSellerDecisionMessageIds.add(message.id);

      final product = _findProductForDecision(decision.productId, conversation);
      if (product == null) {
        continue;
      }

      final sellerId = _resolveProductOwnerId(product, conversation);
      if (sellerId <= 0) {
        continue;
      }

      final isMessageFromSeller = message.senderId == sellerId;
      final isCurrentUserSeller = currentUserId == sellerId;
      if (!isMessageFromSeller || isCurrentUserSeller) {
        continue;
      }

      if (decision.isMarkedSold) {
        if (_hasCurrentUserPurchaseConfirmation(decision.productId)) {
          _completePurchaseAttachmentCycle(decision.productId);
          if (!mounted) return;
          AppSnackBar.info(context, 'Seller marked this listing as sold.');
          continue;
        }

        final resolvedProduct = product;
        _isShowingBuyerRatingPrompt = true;
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          if (!mounted) {
            _isShowingBuyerRatingPrompt = false;
            return;
          }
          await _promptBuyerToRateAfterSellerMarkedSold(resolvedProduct);
          if (mounted) {
            _isShowingBuyerRatingPrompt = false;
          }
        });
        continue;
      }

      _completePurchaseAttachmentCycle(decision.productId);
      if (!mounted) return;

      final label = decision.isKeptActive
          ? 'Seller kept this listing active.'
          : 'Seller marked this purchase as not sold.';
      AppSnackBar.info(context, label);
    }
  }

  ProductDto? _findProductForDecision(
    int productId,
    ConversationDto? conversation,
  ) {
    for (final attachedProduct in _viewModel.attachedProducts) {
      if (attachedProduct.product.id == productId) {
        return attachedProduct.product;
      }
    }

    for (final message in _viewModel.messages.reversed) {
      final attachedProduct = message.attachedProduct;
      if (attachedProduct != null && attachedProduct.id == productId) {
        return attachedProduct;
      }
    }

    final conversationProduct = conversation?.product;
    if (conversationProduct != null && conversationProduct.id == productId) {
      return conversationProduct;
    }

    return null;
  }

  bool _hasCurrentUserPurchaseConfirmation(int productId) {
    final currentUserId = _getCurrentUserId();
    if (currentUserId == 0) {
      return false;
    }

    for (final message in _viewModel.messages) {
      if (message.senderId != currentUserId) {
        continue;
      }
      final confirmedProductId = PurchaseConfirmationMessage.tryParseProductId(
        message.messageText,
      );
      if (confirmedProductId == productId) {
        return true;
      }
    }

    return false;
  }

  String _buildProductCountdownLabel(
    AttachedProduct ap, {
    bool isOwner = false,
  }) {
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
    if (viewModel.messages.isEmpty) {
      final emptyState = LayoutBuilder(
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

      return LoadingErrorBuilder(
        isLoading: viewModel.isLoadingMessages,
        error: viewModel.messagesError,
        onRetry: () => viewModel.loadMessages(refresh: true),
        child: emptyState,
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
            child: Center(
              child: AppLoadingIndicator(size: 22, strokeWidth: 2.2),
            ),
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
          showAttachedProductCard:
              PurchaseConfirmationMessage.isPurchaseConfirmation(
                message.messageText,
              ) ||
              SellerPurchaseDecisionMessage.isSellerDecision(
                message.messageText,
              ),
          onTapAttachedProduct: _navigateToProduct,
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

  Widget _buildBlockedComposerState(ConversationDto conversation) {
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

  Future<void> _showChatActions(ConversationDto conversation) async {
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

  Future<void> _cancelPendingPurchase(ConversationDto conversation) async {
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
    final reportInput = await showUserReportSheet(
      context,
      title: 'Report $displayName',
    );
    if (!mounted || reportInput == null) return;

    final response = await _userRepository.reportUser(
      userId: userId,
      reason: reportInput.reason,
      details: reportInput.details,
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
    required ConversationDto conversation,
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

    final response = await _userRepository.blockUser(userId);
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
    required ConversationDto conversation,
    required int userId,
    required String displayName,
  }) async {
    final response = await _userRepository.unblockUser(userId);
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

  Future<void> _deleteConversation(ConversationDto conversation) async {
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
      Navigator.of(context).pushReplacementNamed(AppRoutes.chat);
      return;
    }

    AppSnackBar.error(
      context,
      _viewModel.conversationsError ?? 'Failed to delete conversation',
    );
  }

  ConversationParticipantDto? _otherParticipant(ConversationDto conversation) {
    final currentUserId = _getCurrentUserId();
    return conversation.participants?.firstWhere(
          (participant) =>
              participant.user != null &&
              participant.userId > 0 &&
              participant.userId != currentUserId,
          orElse: () => ConversationParticipantDto(
            id: 0,
            conversationId: conversation.id,
            userId: 0,
            joinedAt: DateTime.now(),
          ),
        ) ??
        conversation.participants?.firstWhere(
          (participant) => participant.user != null && participant.userId > 0,
          orElse: () => ConversationParticipantDto(
            id: 0,
            conversationId: conversation.id,
            userId: 0,
            joinedAt: DateTime.now(),
          ),
        );
  }

  ConversationParticipantDto? _sellerParticipant(
    ConversationDto conversation,
    ProductDto product,
  ) {
    final ownerId = _resolveProductOwnerId(product, conversation);
    if (ownerId > 0) {
      final matchingParticipant = conversation.participants
          ?.cast<ConversationParticipantDto?>()
          .firstWhere(
            (participant) => participant?.userId == ownerId,
            orElse: () => null,
          );
      if (matchingParticipant != null) {
        return matchingParticipant;
      }
    }
    return _otherParticipant(conversation);
  }

  bool _isProductOwnerForConversation(
    ProductDto product,
    ConversationDto? conversation,
  ) {
    final currentUserId = _getCurrentUserId();
    if (currentUserId == 0) {
      return false;
    }
    return _resolveProductOwnerId(product, conversation) == currentUserId;
  }

  int _resolveProductOwnerId(
    ProductDto product,
    ConversationDto? conversation,
  ) {
    if (product.userId > 0) {
      return product.userId;
    }

    final conversationProduct = conversation?.product;
    if (conversationProduct != null && conversationProduct.id == product.id) {
      return conversationProduct.userId;
    }

    return 0;
  }

  int _getCurrentUserId() {
    final userViewModel = Provider.of<UserViewModel>(context, listen: false);
    return userViewModel.userId ?? 0;
  }
}

class _ChatTimelineItem {
  final String? dateLabel;
  final MessageDto? message;

  const _ChatTimelineItem._({this.dateLabel, this.message});

  factory _ChatTimelineItem.dateDivider(String label) {
    return _ChatTimelineItem._(dateLabel: label);
  }

  factory _ChatTimelineItem.message(MessageDto message) {
    return _ChatTimelineItem._(message: message);
  }

  bool get isDateDivider => dateLabel != null;
}

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
  final ProductDto product;

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
                    child: const Icon(
                      Icons.check_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Sale Complete!',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.sell_outlined,
                        size: 13,
                        color: AppColors.primary,
                      ),
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
                    onPressed: () => Navigator.of(
                      context,
                    ).pop(_ListingStatusChoice.markAsSold),
                    icon: const Icon(
                      Icons.remove_shopping_cart_outlined,
                      size: 18,
                    ),
                    label: const Text('Mark as Sold'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(52),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.of(
                      context,
                    ).pop(_ListingStatusChoice.keepActive),
                    icon: const Icon(Icons.layers_outlined, size: 18),
                    label: const Text('Keep Product Active'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(52),
                    ),
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
