import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/colors.dart';
import '../../../core/navigation/app_routes.dart';
import '../../../core/utils/school_short_name.dart';
import '../../../core/utils/chat_timestamp_formatter.dart';
import '../../../core/utils/user_presence_formatter.dart';
import '../../../data/models/conversation.dart';
import '../../../data/models/user_profile.dart';
import '../../../data/providers/user_api_service.dart';
import '../../../logic/view_models/chat_view_model.dart';
import '../../../logic/view_models/presence_view_model.dart';
import '../../../logic/view_models/user_view_model.dart';
import '../marketplace/product_detail_page.dart';
import '../../../ui/widgets/app_action_sheet.dart';
import '../../../ui/widgets/app_snack_bar.dart';
import '../../../ui/widgets/user_widgets.dart';
import '../profile/other_profile_page.dart';
import 'widgets/chat_menu_helpers.dart';

class ConversationsListScreen extends StatefulWidget {
  static const routeName = '/conversations';

  const ConversationsListScreen({super.key});

  @override
  State<ConversationsListScreen> createState() =>
      _ConversationsListScreenState();
}

class _ConversationsListScreenState extends State<ConversationsListScreen> {
  static const int _pageSize = 100;
  static const Duration _purchaseWindow = purchaseDuration;

  bool _hasInitialized = false;
  bool _isLoadingUsers = false;
  String? _usersError;
  int? _openingUserId;
  List<UserProfile> _allUsers = [];
  String _searchQuery = '';
  Timer? _countdownTimer;
  DateTime _now = DateTime.now();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_hasInitialized) return;

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _now = DateTime.now());
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refresh();
    });
    _hasInitialized = true;
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  Future<void> _refresh() async {
    final chatVm = context.read<ChatRoomViewModel>();
    await Future.wait<void>([
      chatVm.ensureWebSocketConnected(),
      _loadUsers(),
      chatVm.loadConversations(refresh: true),
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
      ..sort((a, b) {
        final aHasRecentActivity = a.lastMessage != null;
        final bHasRecentActivity = b.lastMessage != null;
        if (aHasRecentActivity != bHasRecentActivity) {
          return bHasRecentActivity ? 1 : -1;
        }
        return b.updatedAt.compareTo(a.updatedAt);
      });

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
          schoolShortName: buildSchoolShortName(
            email: user.username,
            fallback: '',
          ),
          subtitle: _conversationSubtitle(conversation, 'Start a conversation'),
          avatarUrl: user.avatarUrl,
          conversation: conversation,
          isBlockedByMe: conversation.isBlockedByMe,
          hasBlockedMe: conversation.hasBlockedMe,
          isOnline: user.isOnline,
          lastSeenAt: user.lastSeenAt,
        ),
      );
    }

    final sortedUsers = [..._allUsers]
      ..sort(
        (a, b) => a.fullName.toLowerCase().compareTo(b.fullName.toLowerCase()),
      );

    for (final user in sortedUsers) {
      if (user.id <= 0 ||
          user.id == currentUserId ||
          seenUserIds.contains(user.id)) {
        continue;
      }

      entries.add(
        _ChatListEntry(
          userId: user.id,
          title: user.fullName.trim().isNotEmpty ? user.fullName : 'User',
          schoolShortName: buildSchoolShortName(
            universityName: user.university?.name,
            universityDomain: user.emailDomain,
            email: user.email,
            fallback: '',
          ),
          subtitle: user.isBlockedByMe
              ? 'You blocked this account'
              : user.hasBlockedMe
              ? 'Messaging unavailable'
              : 'Start a conversation',
          avatarUrl: user.profileImage,
          isBlockedByMe: user.isBlockedByMe,
          hasBlockedMe: user.hasBlockedMe,
          isOnline: user.isOnline,
          lastSeenAt: user.lastSeenAt,
        ),
      );
    }

    return entries;
  }

  String _conversationSubtitle(Conversation conversation, String fallback) {
    if (conversation.isBlockedByMe) {
      return 'You blocked this account';
    }
    if (conversation.hasBlockedMe) {
      return 'Messaging unavailable';
    }

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

  Widget? _buildConversationStatusChip(_ChatListEntry entry) {
    if (!entry.isMessagingBlocked) {
      return null;
    }

    final isBlockedByMe = entry.isBlockedByMe;
    final backgroundColor = isBlockedByMe
        ? AppColors.warningBackground
        : AppColors.warningBackground;
    final textColor = isBlockedByMe
        ? AppColors.textSecondary
        : AppColors.textSecondary;
    final icon = isBlockedByMe
        ? Icons.block_rounded
        : Icons.lock_outline_rounded;
    final label = isBlockedByMe ? 'Blocked' : 'Unavailable';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: textColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openChat(_ChatListEntry entry) async {
    if (_openingUserId != null) return;

    final chatRoomViewModel = context.read<ChatRoomViewModel>();

    final existingConversation = entry.conversation;
    if (existingConversation != null) {
      chatRoomViewModel.selectConversation(existingConversation);
      Navigator.of(
        context,
      ).pushNamed(AppRoutes.chatRoom, arguments: existingConversation.id);
      return;
    }

    if (entry.isMessagingBlocked) {
      await _showEntryActions(entry);
      return;
    }

    setState(() {
      _openingUserId = entry.userId;
    });

    try {
      final conversation = await chatRoomViewModel.createConversationWithUser(
        entry.userId,
      );

      if (!mounted) return;

      if (conversation == null) {
        AppSnackBar.error(
          context,
          chatRoomViewModel.currentConversationError ??
              'Failed to start conversation',
        );
        return;
      }

      // Chat list selection: open with no attachment
      Navigator.of(
        context,
      ).pushNamed(AppRoutes.chatRoom, arguments: conversation.id);
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
    final hasAttachments = conversation != null &&
        context
            .read<ChatRoomViewModel>()
            .attachedProductsForConversation(conversation.id)
            .isNotEmpty;

    await AppActionSheet.show(
      context,
      items: [
        if (conversation == null && !entry.isMessagingBlocked)
          AppActionSheetItem(
            label: 'Start chat',
            icon: Icons.chat_bubble_outline_rounded,
            isDisabled: _openingUserId == entry.userId,
            onTap: () => _openChat(entry),
          ),
        AppActionSheetItem(
          label: 'View profile',
          icon: Icons.person_outline_rounded,
          onTap: () => Navigator.of(context).pushNamed(
            AppRoutes.userProfile,
            arguments: OtherProfileArgs(userId: entry.userId),
          ),
        ),
        if (conversation?.product != null && hasAttachments)
          AppActionSheetItem(
            label: 'Open listing',
            icon: Icons.open_in_new_rounded,
            onTap: () => Navigator.of(context).pushNamed(
              AppRoutes.productDetail,
              arguments: ProductDetailArgs(
                productId: conversation!.product!.id,
              ),
            ),
          ),
        AppActionSheetItem(
          label: entry.isBlockedByMe ? 'Unblock user' : 'Block user',
          icon: entry.isBlockedByMe
              ? Icons.lock_open_rounded
              : Icons.block_rounded,
          isDestructive: true,
          onTap: () => entry.isBlockedByMe
              ? _unblockUser(
                  userId: entry.userId,
                  displayName: entry.title,
                  conversation: conversation,
                )
              : _blockUser(
                  userId: entry.userId,
                  displayName: entry.title,
                  conversation: conversation,
                ),
        ),
        AppActionSheetItem(
          label: 'Report user',
          icon: Icons.flag_outlined,
          isDestructive: true,
          onTap: () =>
              _reportUser(userId: entry.userId, displayName: entry.title),
        ),
        if (conversation != null)
          AppActionSheetItem(
            label: 'Delete chat',
            icon: Icons.delete_outline_rounded,
            isDestructive: true,
            onTap: () => _deleteConversation(conversation),
          ),
      ],
    );
  }

  void _updateUserBlockState(
    int userId, {
    required bool isBlockedByMe,
    bool? hasBlockedMe,
  }) {
    setState(() {
      _allUsers = _allUsers
          .map(
            (user) => user.id == userId
                ? user.copyWith(
                    isBlockedByMe: isBlockedByMe,
                    hasBlockedMe: hasBlockedMe,
                  )
                : user,
          )
          .toList(growable: false);
    });
  }

  /// Returns the first active (non-expired) attached product for a conversation,
  /// or null if there is none.
  AttachedProduct? _activeAttachedProduct(int conversationId) {
    final chatVm = context.read<ChatRoomViewModel>();
    final products = chatVm.attachedProductsForConversation(conversationId);
    for (final ap in products) {
      if (ap.countdownStartedAt == null) return ap; // awaiting
      final expiresAt = ap.countdownStartedAt!.add(_purchaseWindow);
      if (_now.isBefore(expiresAt)) return ap; // still active
    }
    return null;
  }

  String _countdownLabel(AttachedProduct ap) {
    final startedAt = ap.countdownStartedAt;
    if (startedAt == null) return 'Pending';

    final remaining = startedAt.add(_purchaseWindow).difference(_now);
    if (remaining.isNegative || remaining.inSeconds <= 0) return 'Expired';

    final hours = remaining.inHours;
    final minutes = remaining.inMinutes % 60;
    if (hours >= 24) {
      final days = hours ~/ 24;
      final h = hours % 24;
      return '${days}d ${h}h ${minutes}m left';
    }
    return '${hours}h ${minutes}m left';
  }

  Widget _buildPurchaseIndicator(AttachedProduct ap) {
    final label = _countdownLabel(ap);
    final isAwaiting = ap.countdownStartedAt == null;
    final color = isAwaiting
        ? AppColors.textSecondary
        : const Color(0xFFE67E22);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          isAwaiting
              ? Icons.hourglass_empty_rounded
              : Icons.timer_outlined,
          size: 13,
          color: color,
        ),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            isAwaiting ? 'Purchase pending' : label,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: color,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildEntryTrailing({
    required _ChatListEntry entry,
    required Conversation? conversation,
    required bool isOpening,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (conversation != null && conversation.unreadCount > 0)
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: CircleAvatar(
              radius: 11,
              backgroundColor: AppColors.primary,
              child: Text(
                conversation.unreadCount > 99
                    ? '99+'
                    : conversation.unreadCount.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        SizedBox(
          width: 32,
          height: 32,
          child: IconButton(
            padding: EdgeInsets.zero,
            icon: Icon(
              Icons.more_vert_rounded,
              color: isOpening
                  ? AppColors.textSecondary.withValues(alpha: 0.4)
                  : AppColors.textSecondary,
              size: 22,
            ),
            onPressed: isOpening ? null : () => _showEntryActions(entry),
          ),
        ),
      ],
    );
  }

  Future<void> _blockUser({
    required int userId,
    required String displayName,
    Conversation? conversation,
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
      _updateUserBlockState(userId, isBlockedByMe: true);
      if (conversation != null) {
        context.read<ChatRoomViewModel>().setConversationBlockState(
          conversation.id,
          isBlockedByMe: true,
          hasBlockedMe: conversation.hasBlockedMe,
        );
      }
    } else {
      AppSnackBar.error(
        context,
        response.error?.message ?? 'Failed to block user',
      );
    }
  }

  Future<void> _unblockUser({
    required int userId,
    required String displayName,
    Conversation? conversation,
  }) async {
    final response = await UserApiService.instance.unblockUser(userId);
    if (!mounted) return;

    if (response.isSuccess) {
      AppSnackBar.success(context, '$displayName unblocked');
      _updateUserBlockState(userId, isBlockedByMe: false);
      if (conversation != null) {
        context.read<ChatRoomViewModel>().setConversationBlockState(
          conversation.id,
          isBlockedByMe: false,
          hasBlockedMe: conversation.hasBlockedMe,
        );
      }
      return;
    }

    AppSnackBar.error(
      context,
      response.error?.message ?? 'Failed to unblock user',
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

    return Consumer2<ChatRoomViewModel, PresenceViewModel>(
      builder: (context, chatViewModel, presenceViewModel, child) {
        final entries =
            _buildEntries(chatViewModel.conversations, currentUserId).where((
              entry,
            ) {
              final query = _searchQuery.trim().toLowerCase();
              if (query.isEmpty) return true;
              return entry.title.toLowerCase().contains(query) ||
                  entry.subtitle.toLowerCase().contains(query);
            }).toList();

        final userIdsToWatch = entries.map((entry) => entry.userId).where((id) => id > 0);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          presenceViewModel.watchUserIds(userIdsToWatch);
        });

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
                    prefixIcon: const Icon(
                      Icons.search,
                      color: AppColors.textSecondary,
                    ),
                    hintText: 'Search chats',
                    filled: true,
                    fillColor: Colors.grey[100],
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 0,
                      horizontal: 16,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(
                              Icons.cancel,
                              color: AppColors.textSecondary,
                            ),
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
                    isLoadingConversations:
                        chatViewModel.isLoadingConversations,
                    conversationsError: chatViewModel.conversationsError,
                    presenceViewModel: presenceViewModel,
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
    required PresenceViewModel presenceViewModel,
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
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(combinedError, textAlign: TextAlign.center),
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
        final conversation = entry.conversation;
        final isBlocked = entry.isMessagingBlocked;
        final hasUnread = conversation != null && conversation.unreadCount > 0;
        final unreadCount = conversation?.unreadCount ?? 0;
        final statusChip = _buildConversationStatusChip(entry);
        final timestamp = conversation?.lastMessage?.sentAt;
        final timestampLabel = timestamp != null
            ? formatChatTimestamp(timestamp)
            : null;
        final realtimePresence = presenceViewModel.presenceForUser(entry.userId);
        final isOnline = realtimePresence?.isOnline ?? entry.isOnline;
        final presenceDotColor = presenceColor(isOnline: isOnline);
        // override subtitle for multiple unread
        final subtitleText = (hasUnread && unreadCount > 1)
          ? '$unreadCount new messages'
          : entry.subtitle;

        // Active purchase countdown for this conversation
        final activeAp = conversation != null
            ? _activeAttachedProduct(conversation.id)
            : null;

        return Column(
          key: ValueKey('chat_user_${entry.userId}'),
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 6,
              ),
              leading: UserAvatar(
                imageUrl: entry.avatarUrl ?? '',
                displayName: entry.title,
                radius: 26,
                showStatusDot: true,
                statusDotColor: presenceDotColor,
                statusDotSize: 14,
                statusDotBorderWidth: 2.5,
              ),
              title: Row(
                children: [
                  Expanded(
                    child: Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: entry.title,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: hasUnread
                                  ? FontWeight.w800
                                  : FontWeight.w600,
                              color: hasUnread
                                  ? const Color(0xFF0D0D0D)
                                  : AppColors.textPrimary,
                            ),
                          ),
                          if (entry.schoolShortName?.isNotEmpty == true)
                            TextSpan(
                              text: ' @${entry.schoolShortName}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: hasUnread
                                    ? AppColors.textPrimary.withValues(
                                        alpha: 0.72,
                                      )
                                    : AppColors.textSecondary,
                              ),
                            ),
                        ],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (statusChip != null) ...[
                    const SizedBox(width: 8),
                    statusChip,
                  ],
                ],
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Flexible(
                        fit: FlexFit.loose,
                        child: Text(
                          subtitleText,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: hasUnread
                                ? FontWeight.w700
                                : FontWeight.w400,
                            color: isBlocked
                                ? AppColors.textSecondary
                                : hasUnread
                                ? const Color(0xFF1A1A1A)
                                : AppColors.textSecondary,
                          ),
                        ),
                      ),
                      if (timestampLabel != null) ...[
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                              child: Text(
                                '·',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: hasUnread
                                      ? const Color(0xFF1A1A1A)
                                      : AppColors.textSecondary.withValues(
                                          alpha: 0.5,
                                        ),
                                ),
                              ),
                            ),
                            Text(
                              timestampLabel,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: hasUnread
                                    ? FontWeight.w700
                                    : FontWeight.w400,
                                color: hasUnread
                                    ? AppColors.primary
                                    : AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                  if (activeAp != null) ...[
                    const SizedBox(height: 3),
                    _buildPurchaseIndicator(activeAp),
                  ],
                ],
              ),
              trailing: _buildEntryTrailing(
                entry: entry,
                conversation: conversation,
                isOpening: isOpening,
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
                  color: AppColors.textSecondary.withValues(alpha: 0.15),
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
    this.schoolShortName,
    this.avatarUrl,
    this.conversation,
    this.isBlockedByMe = false,
    this.hasBlockedMe = false,
    this.isOnline = false,
    this.lastSeenAt,
  });

  final int userId;
  final String title;
  final String subtitle;
  final String? schoolShortName;
  final String? avatarUrl;
  final Conversation? conversation;
  final bool isBlockedByMe;
  final bool hasBlockedMe;
  final bool isOnline;
  final DateTime? lastSeenAt;

  bool get isMessagingBlocked => isBlockedByMe || hasBlockedMe;
}
