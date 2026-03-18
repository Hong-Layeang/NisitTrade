import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/colors.dart';
import '../../../core/navigation/app_routes.dart';
import '../../../data/models/conversation.dart';
import '../../../data/models/user_profile.dart';
import '../../../data/providers/user_api_service.dart';
import '../../../logic/view_models/chat_view_model.dart';
import '../../../logic/view_models/user_view_model.dart';
import '../../../ui/widgets/app_action_sheet.dart';
import '../../../ui/widgets/app_snack_bar.dart';
import '../../../ui/widgets/user_widgets.dart';
import '../profile/other_profile_page.dart';
import 'widgets/chat_menu_helpers.dart';

class ConversationsListScreen extends StatefulWidget {
  static const routeName = '/conversations';

  const ConversationsListScreen({super.key});

  @override
  State<ConversationsListScreen> createState() => _ConversationsListScreenState();
}

class _ConversationsListScreenState extends State<ConversationsListScreen> {
  static const int _pageSize = 100;

  bool _hasInitialized = false;
  bool _isLoadingUsers = false;
  String? _usersError;
  int? _openingUserId;
  List<UserProfile> _allUsers = [];
  String _searchQuery = '';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_hasInitialized) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refresh();
    });
    _hasInitialized = true;
  }

  Future<void> _refresh() async {
    await Future.wait<void>([
      _loadUsers(),
      context.read<ChatRoomViewModel>().loadConversations(refresh: true),
    ]);
  }

  Future<void> _loadUsers() async {
    if (_isLoadingUsers) return;

    setState(() {
      _isLoadingUsers = true;
      _usersError = null;
    });

    try {
      final loadedUsers = <UserProfile>[];
      final seenIds = <int>{};
      var offset = 0;

      while (true) {
        final response = await UserApiService.instance.getAllUsers(
          limit: _pageSize,
          offset: offset,
        );

        if (!response.isSuccess) {
          if (!mounted) return;
          setState(() {
            _usersError = response.error?.message ?? 'Failed to load users';
            _isLoadingUsers = false;
          });
          return;
        }

        final batch = response.data ?? const <UserProfile>[];
        for (final user in batch) {
          if (user.id <= 0 || seenIds.contains(user.id)) continue;
          seenIds.add(user.id);
          loadedUsers.add(user);
        }

        if (batch.length < _pageSize) {
          break;
        }

        offset += _pageSize;
      }

      if (!mounted) return;
      setState(() {
        _allUsers = loadedUsers;
        _isLoadingUsers = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _usersError = 'Error: ${e.toString()}';
        _isLoadingUsers = false;
      });
    }
  }

  ConversationParticipant? _otherParticipant(
    Conversation conversation,
    int currentUserId,
  ) {
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

  List<_ChatListEntry> _buildEntries(
    List<Conversation> conversations,
    int currentUserId,
  ) {
    final entries = <_ChatListEntry>[];
    final seenUserIds = <int>{};

    final sortedConversations = [...conversations]
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

    for (final conversation in sortedConversations) {
      final participant = _otherParticipant(conversation, currentUserId);
      final user = participant?.user;
      final userId = participant?.userId ?? 0;

      if (user == null || userId <= 0 || userId == currentUserId) {
        continue;
      }
      if (!seenUserIds.add(userId)) {
        continue;
      }

      entries.add(
        _ChatListEntry(
          userId: userId,
          title: user.name.trim().isNotEmpty ? user.name : 'User',
          subtitle: _conversationSubtitle(
            conversation,
            'Start a conversation',
          ),
          avatarUrl: user.avatarUrl,
          conversation: conversation,
        ),
      );
    }

    final sortedUsers = [..._allUsers]
      ..sort(
        (a, b) => a.fullName.toLowerCase().compareTo(b.fullName.toLowerCase()),
      );

    for (final user in sortedUsers) {
      if (user.id <= 0 || user.id == currentUserId || seenUserIds.contains(user.id)) {
        continue;
      }

      entries.add(
        _ChatListEntry(
          userId: user.id,
          title: user.fullName.trim().isNotEmpty ? user.fullName : 'User',
          subtitle: 'Start a conversation',
          avatarUrl: user.profileImage,
        ),
      );
    }

    return entries;
  }

  String _conversationSubtitle(Conversation conversation, String fallback) {
    final lastMessage = conversation.lastMessage;
    final messageText = (lastMessage?.messageText ?? '').trim();
    if (messageText.isNotEmpty) {
      return messageText;
    }
    if ((lastMessage?.imageUrls ?? const <String>[]).isNotEmpty) {
      return 'Shared photos';
    }
    if (lastMessage?.attachedProduct != null) {
      return 'Shared a listing';
    }
    return fallback;
  }

  Future<void> _openChat(_ChatListEntry entry) async {
    if (_openingUserId != null) return;

    final chatRoomViewModel = context.read<ChatRoomViewModel>();

    final existingConversation = entry.conversation;
    if (existingConversation != null) {
      chatRoomViewModel.selectConversation(existingConversation);
      Navigator.of(context).pushNamed(
        AppRoutes.chatRoom,
        arguments: existingConversation.id,
      );
      return;
    }

    setState(() {
      _openingUserId = entry.userId;
    });

    try {
      final conversation = await chatRoomViewModel.createConversationWithUser(entry.userId);

      if (!mounted) return;

      if (conversation == null) {
        AppSnackBar.error(context, 'Failed to start conversation');
        return;
      }

      // Chat list selection: open with no attachment
      Navigator.of(context).pushNamed(
        AppRoutes.chatRoom,
        arguments: conversation.id,
      );
    } finally {
      if (mounted) {
        setState(() {
          _openingUserId = null;
        });
      }
    }
  }

  Future<void> _showEntryActions(_ChatListEntry entry) async {
    final conversation = entry.conversation;
    if (conversation == null) return;

    await AppActionSheet.show(
      context,
      items: [
        AppActionSheetItem(
          label: 'View profile',
          icon: Icons.person_outline_rounded,
          onTap: () => Navigator.of(context).pushNamed(
            AppRoutes.userProfile,
            arguments: OtherProfileArgs(userId: entry.userId),
          ),
        ),
        AppActionSheetItem(
          label: 'Block user',
          icon: Icons.block_rounded,
          isDestructive: true,
          onTap: () => _blockUser(
            userId: entry.userId,
            displayName: entry.title,
          ),
        ),
        AppActionSheetItem(
          label: 'Report user',
          icon: Icons.flag_outlined,
          isDestructive: true,
          onTap: () => _reportUser(
            userId: entry.userId,
            displayName: entry.title,
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
    } else {
      AppSnackBar.error(
        context,
        response.error?.message ?? 'Failed to submit report',
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

    final chatViewModel = context.read<ChatRoomViewModel>();
    final success = await chatViewModel.deleteConversation(conversation.id);
    if (!mounted) return;

    if (success) {
      AppSnackBar.success(context, 'Chat deleted');
    } else {
      AppSnackBar.error(
        context,
        chatViewModel.conversationsError ?? 'Failed to delete conversation',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = context.read<UserViewModel>().userId ?? 0;

    return Consumer<ChatRoomViewModel>(
      builder: (context, chatViewModel, child) {
        final entries = _buildEntries(chatViewModel.conversations, currentUserId)
            .where((entry) {
          final query = _searchQuery.trim().toLowerCase();
          if (query.isEmpty) return true;
          return entry.title.toLowerCase().contains(query) ||
              entry.subtitle.toLowerCase().contains(query);
        }).toList();

        return Scaffold(
          appBar: AppBar(
            backgroundColor: AppColors.primary,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.of(context).maybePop(),
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
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: TextField(
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
                    hintText: 'Search chats',
                    filled: true,
                    fillColor: Colors.grey[100],
                    contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.cancel, color: AppColors.textSecondary),
                            onPressed: () {
                              setState(() {
                                _searchQuery = '';
                              });
                            },
                          )
                        : null,
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                ),
              ),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _refresh,
                  child: _buildBody(
                    entries: entries,
                    isLoadingConversations: chatViewModel.isLoadingConversations,
                    conversationsError: chatViewModel.conversationsError,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBody({
    required List<_ChatListEntry> entries,
    required bool isLoadingConversations,
    required String? conversationsError,
  }) {
    if (_isLoadingUsers && entries.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(height: 180),
          Center(child: CircularProgressIndicator()),
        ],
      );
    }

    final combinedError = conversationsError ?? _usersError;
    if (combinedError != null && entries.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.7,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Error loading chats',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      combinedError,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _refresh,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      );
    }

    if (entries.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(height: 180),
          Center(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  Icon(
                    Icons.chat_bubble_outline_rounded,
                    size: 48,
                    color: AppColors.textSecondary,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'No users available yet',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: entries.length + (isLoadingConversations ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == entries.length) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final entry = entries[index];
        final isOpening = _openingUserId == entry.userId;

        return Column(
          key: ValueKey('chat_user_${entry.userId}'),
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              leading: UserAvatar(
                imageUrl: entry.avatarUrl ?? '',
                radius: 26,
              ),
              title: Text(
                entry.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              subtitle: Text(
                entry.subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
              trailing: isOpening
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (entry.conversation != null &&
                            entry.conversation!.unreadCount > 0)
                          Padding(
                            padding: const EdgeInsets.only(right: 4),
                            child: CircleAvatar(
                              radius: 11,
                              backgroundColor: AppColors.primary,
                              child: Text(
                                entry.conversation!.unreadCount > 99
                                    ? '99+'
                                    : entry.conversation!.unreadCount.toString(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        if (entry.conversation != null)
                          SizedBox(
                            width: 32,
                            height: 32,
                            child: IconButton(
                              padding: EdgeInsets.zero,
                              icon: const Icon(
                                Icons.more_horiz_rounded,
                                color: AppColors.textSecondary,
                                size: 22,
                              ),
                              onPressed: () => _showEntryActions(entry),
                            ),
                          ),
                      ],
                    ),
              onTap: isOpening ? null : () => _openChat(entry),
            ),
            if (index < entries.length - 1)
              // Divider now spans full width
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Divider(
                  height: 1,
                  thickness: 0.7,
                  color: AppColors.textSecondary.withOpacity(0.15),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _ChatListEntry {
  const _ChatListEntry({
    required this.userId,
    required this.title,
    required this.subtitle,
    this.avatarUrl,
    this.conversation,
  });

  final int userId;
  final String title;
  final String subtitle;
  final String? avatarUrl;
  final Conversation? conversation;
}
