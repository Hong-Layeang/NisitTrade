import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../logic/view_models/chat_view_model.dart';
import '../../../data/models/conversation.dart';
import '../../../ui/widgets/app_app_bar.dart';
import '../../../ui/screens/chat/chat_room_screen.dart';

class ConversationsListScreen extends StatefulWidget {
  static const routeName = '/conversations';

  const ConversationsListScreen({super.key});

  @override
  State<ConversationsListScreen> createState() =>
      _ConversationsListScreenState();
}

class _ConversationsListScreenState extends State<ConversationsListScreen> {
  late ChatRoomViewModel _viewModel;
  late ScrollController _scrollController;
  bool _hasInitialized = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_hasInitialized) {
      _viewModel = Provider.of<ChatRoomViewModel>(context, listen: false);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _viewModel.loadConversations(refresh: true);
      });
      _hasInitialized = true;
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 500) {
      _viewModel.loadMoreConversations();
    }
  }

  void _handleConversationTap(Conversation conversation) {
    _viewModel.selectConversation(conversation);
    Navigator.of(context).pushNamed(
      ChatRoomScreen.routeName,
      arguments: conversation.id,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppAppBar(showFavorite: false),
      body: Consumer<ChatRoomViewModel>(
        builder: (context, viewModel, child) {
          if (viewModel.conversationsError != null &&
              viewModel.conversations.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Error loading conversations',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(viewModel.conversationsError ?? ''),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () =>
                        viewModel.loadConversations(refresh: true),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (viewModel.conversations.isEmpty &&
              viewModel.isLoadingConversations) {
            return const Center(child: CircularProgressIndicator());
          }

          if (viewModel.conversations.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.mail_outline, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(
                    'No messages yet',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Start a conversation by contacting a seller',
                    style: TextStyle(color: Colors.grey[600]),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            controller: _scrollController,
            itemCount: viewModel.conversations.length +
                (viewModel.isLoadingConversations ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == viewModel.conversations.length) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: CircularProgressIndicator(),
                  ),
                );
              }

              final conversation = viewModel.conversations[index];
              return _buildConversationTile(conversation);
            },
          );
        },
      ),
    );
  }

  Widget _buildConversationTile(Conversation conversation) {
    final participant = conversation.participants?.firstWhere(
      (p) => p.user != null,
      orElse: () => ConversationParticipant(
        id: 0,
        conversationId: conversation.id,
        userId: 0,
        joinedAt: DateTime.now(),
      ),
    );

    final lastMessage = conversation.lastMessage;
    final userName = participant?.user?.name ?? 'Unknown User';
    final userAvatar = participant?.user?.profileImage;
    final messagePreview =
        lastMessage?.messageText ?? 'Start a conversation';

    return ListTile(
      onTap: () => _handleConversationTap(conversation),
      leading: CircleAvatar(
        radius: 24,
        backgroundImage: userAvatar != null ? NetworkImage(userAvatar) : null,
        child: userAvatar == null ? const Icon(Icons.person) : null,
      ),
      title: Text(
        userName,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Text(
        messagePreview,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(color: Colors.grey[600]),
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (conversation.unreadCount > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                conversation.unreadCount.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
