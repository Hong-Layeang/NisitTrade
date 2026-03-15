import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/navigation/app_routes.dart';
import '../../../logic/view_models/chat_view_model.dart';
import '../../../logic/view_models/user_view_model.dart';
import '../../../data/models/conversation.dart';
import '../../../ui/widgets/app_app_bar.dart';
import '../../../ui/widgets/app_snack_bar.dart';
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
      _loadConversation();
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
    final chatBadgeCount = context.select<ChatRoomViewModel, int>(
      (viewModel) => viewModel.totalUnreadCount,
    );

    return Scaffold(
      appBar: AppAppBar(
        chatBadgeCount: chatBadgeCount,
        onFavoriteTap: () {
          Navigator.pushNamed(context, AppRoutes.saved);
        },
        onChatTap: () {
          Navigator.pushReplacementNamed(context, AppRoutes.chat);
        },
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

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      color: Colors.white,
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.arrow_back, color: Colors.black87),
          ),
          CircleAvatar(
            radius: 18,
            backgroundImage: avatarUrl != null && avatarUrl.isNotEmpty
              ? NetworkImage(avatarUrl)
                : null,
            child: avatarUrl == null || avatarUrl.isEmpty
                ? const Icon(Icons.person)
                : null,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  displayName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (productTitle.isNotEmpty)
                  Text(
                    productTitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.more_vert),
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
