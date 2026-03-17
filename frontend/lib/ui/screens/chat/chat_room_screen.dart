import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/colors.dart';
import '../../../core/navigation/app_routes.dart';
import '../../../logic/view_models/chat_view_model.dart';
import '../../../logic/view_models/user_view_model.dart';
import '../../../data/models/conversation.dart';
import '../../../ui/widgets/app_snack_bar.dart';
import '../../../ui/widgets/user_widgets.dart';
import 'widgets/chat_bubble.dart';
import 'widgets/chat_input.dart';

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
  late bool _attachConversationProductOnNextSend;

  @override
  void initState() {
    super.initState();
    _attachConversationProductOnNextSend = widget.attachProductOnCompose;
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_hasInitialized) {
      _viewModel = Provider.of<ChatRoomViewModel>(context, listen: false);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadConversation();
      });
      _hasInitialized = true;
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadConversation() async {
    await _viewModel.loadConversation(widget.conversationId);
    await _viewModel.loadMessages(refresh: true);
    _scrollToBottom();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      Future.delayed(const Duration(milliseconds: 100), () {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels <=
        _scrollController.position.maxScrollExtent * 0.2) {
      _viewModel.loadMoreMessages();
    }
  }

  Future<void> _handleSendMessage(
    String messageText,
    bool includeAttachedProduct,
  ) async {
    final success = await _viewModel.sendMessage(
      messageText,
      attachConversationProduct: includeAttachedProduct,
    );
    if (success) {
      if (includeAttachedProduct && mounted) {
        setState(() {
          _attachConversationProductOnNextSend = false;
        });
      }
      _scrollToBottom();
    } else {
      AppSnackBar.error(
        context,
        _viewModel.sendMessageError ?? 'Failed to send message',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Messages',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Consumer<ChatRoomViewModel>(
        builder: (context, viewModel, child) {
          if (viewModel.isLoadingCurrentConversation) {
            return const Center(child: CircularProgressIndicator());
          }

          if (viewModel.currentConversationError != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Error loading conversation',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(viewModel.currentConversationError ?? ''),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadConversation,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final conversation = viewModel.currentConversation;
          if (conversation == null) {
            return const Center(child: Text('No conversation found'));
          }

          return Column(
            children: [
              // Header with conversation info
              _buildConversationHeader(conversation),
              const Divider(height: 1),
              // Messages list
              Expanded(
                child: _buildMessagesList(viewModel),
              ),
              // Input area
              ChatInput(
                onSendMessage: _handleSendMessage,
                isLoading: viewModel.isLoadingCurrentConversation,
                isSendingMessage: viewModel.isSendingMessage,
                attachedProduct: conversation.product,
                attachProductOnCompose: _attachConversationProductOnNextSend,
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildConversationHeader(Conversation conversation) {
    final currentUserId = _getCurrentUserId();
    final participant = conversation.participants?.firstWhere(
      (p) => p.user != null && p.userId != currentUserId,
      orElse: () => ConversationParticipant(
        id: 0,
        conversationId: conversation.id,
        userId: 0,
        joinedAt: DateTime.now(),
      ),
    ) ?? conversation.participants?.firstWhere(
      (p) => p.user != null,
      orElse: () => ConversationParticipant(
        id: 0,
        conversationId: conversation.id,
        userId: 0,
        joinedAt: DateTime.now(),
      ),
    );

    final productTitle = conversation.product?.title ?? '';
    final displayName = participant?.user?.name ?? 'User';
    final avatarUrl = participant?.user?.avatarUrl;
    final participantUserId = participant?.userId;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: const BoxDecoration(
        color: AppColors.background,
        border: Border(
          bottom: BorderSide(color: AppColors.border, width: 1),
        ),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: participantUserId != null && participantUserId > 0
                ? () => Navigator.of(context).pushNamed(
                      AppRoutes.userProfile,
                      arguments: participantUserId,
                    )
                : null,
            child: UserAvatar(
              imageUrl: avatarUrl ?? '',
              radius: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: GestureDetector(
              onTap: participantUserId != null && participantUserId > 0
                  ? () => Navigator.of(context).pushNamed(
                        AppRoutes.userProfile,
                        arguments: participantUserId,
                      )
                  : null,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    displayName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (productTitle.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      productTitle,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessagesList(ChatRoomViewModel viewModel) {
    if (viewModel.isLoadingMessages && viewModel.messages.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (viewModel.messages.isEmpty) {
      return Center(
        child: Text(
          'No messages yet. Start the conversation!',
          style: TextStyle(color: Colors.grey[600]),
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      itemCount: viewModel.messages.length +
          (viewModel.isLoadingMessages ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == 0 && viewModel.isLoadingMessages) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final messageIndex =
            viewModel.isLoadingMessages ? index - 1 : index;
        if (messageIndex < 0 || messageIndex >= viewModel.messages.length) {
          return const SizedBox.shrink();
        }

        final message = viewModel.messages[messageIndex];
        final isCurrentUser = message.senderId == _getCurrentUserId();

        // Mark message as read if not current user
        if (!isCurrentUser && !message.isReadBy(_getCurrentUserId())) {
          Future.microtask(() => viewModel.markMessageAsRead(message.id));
        }

        return ChatBubble(
          message: message,
          isCurrentUser: isCurrentUser,
          attachedProduct: message.attachedProduct ??
              (viewModel.hasProductAttachmentForMessage(message.id)
                  ? viewModel.currentConversation?.product
                  : null),
        );
      },
    );
  }

  int _getCurrentUserId() {
    final userViewModel = Provider.of<UserViewModel>(context, listen: false);
    return userViewModel.userId ?? 0;
  }
}
