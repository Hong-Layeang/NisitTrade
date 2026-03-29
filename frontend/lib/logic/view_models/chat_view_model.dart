import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/auth/auth_token_store.dart';
import '../../data/dtos/product_dto.dart';
import '../../data/dtos/conversation_dto.dart';
import '../../data/repository_interfaces/i_chat_repository.dart';
import '../../logic/services/chat_websocket_service.dart';

const purchaseDuration = Duration(days: 2);

class AttachedProduct {
  final ProductDto product;
  final DateTime? countdownStartedAt;

  const AttachedProduct({required this.product, this.countdownStartedAt});

  AttachedProduct copyWith({DateTime? countdownStartedAt}) {
    return AttachedProduct(
      product: product,
      countdownStartedAt: countdownStartedAt ?? this.countdownStartedAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'product': product.toJson(),
    if (countdownStartedAt != null)
      'countdownStartedAt': countdownStartedAt!.toIso8601String(),
  };

  factory AttachedProduct.fromJson(Map<String, dynamic> json) {
    return AttachedProduct(
      product: ProductDto.fromJson(json['product'] as Map<String, dynamic>),
      countdownStartedAt: json['countdownStartedAt'] != null
          ? DateTime.parse(json['countdownStartedAt'] as String)
          : null,
    );
  }
}

class ChatRoomViewModel extends ChangeNotifier with WidgetsBindingObserver {
  ChatRoomViewModel({
    required IChatRepository chatRepository,
    required ChatWebSocketService chatWebSocket,
    AuthTokenStore? tokenStore,
  }) : _chatRepository = chatRepository,
       _chatWebSocket = chatWebSocket,
       _tokenStore = tokenStore ?? AuthTokenStore.instance {
    WidgetsBinding.instance.addObserver(this);
    _attachWebSocketListeners();
    unawaited(ensureWebSocketConnected());
  }

  final IChatRepository _chatRepository;
  final AuthTokenStore _tokenStore;

  int? _currentUserId;
  void setCurrentUserId(int? id) => _currentUserId = id;

  // Conversations list state
  List<ConversationDto> _conversations = [];
  bool _isLoadingConversations = false;
  String? _conversationsError;
  int _conversationOffset = 0;
  bool _hasMoreConversations = true;
  static const int _conversationPageSize = 20;

  // Current conversation state
  ConversationDto? _currentConversation;
  bool _isLoadingCurrentConversation = false;
  String? _currentConversationError;

  // Messages state
  List<MessageDto> _messages = [];
  bool _isLoadingMessages = false;
  String? _messagesError;
  int _messageOffset = 0;
  bool _hasMoreMessages = true;
  static const int _messagesPageSize = 50;

  // Sending message state
  bool _isSendingMessage = false;
  String? _sendMessageError;
  final Set<int> _messagesWithProductAttachment = <int>{};

  final Map<int, List<AttachedProduct>> _attachedProductsByConversation = {};

  final Map<int, Set<int>> _resolvedProductsByConversation = {};

  // Multi-select state
  final Set<int> _selectedMessageIds = {};
  bool _isSelectionMode = false;

  final Set<int> _notifiedMessageIds = {};

  // WebSocket subscriptions
  final List<StreamSubscription> _wsSubscriptions = [];
  final ChatWebSocketService _chatWebSocket;
  bool _isConnecting = false;

  final _unreadCountController = StreamController<int>.broadcast();
  Stream<int> get onUnreadCountChanged => _unreadCountController.stream;

  int _lastEmittedUnreadCount = -1;

  void _attachWebSocketListeners() {
    _wsSubscriptions.add(
      _chatWebSocket.onMessageReceived.listen(_onWsMessageReceived),
    );
    _wsSubscriptions.add(
      _chatWebSocket.onMessageNotify.listen(_onWsMessageNotify),
    );
    _wsSubscriptions.add(
      _chatWebSocket.onMessageUpdated.listen(_onWsMessageUpdated),
    );
    _wsSubscriptions.add(
      _chatWebSocket.onMessageDeleted.listen(_onWsMessageDeleted),
    );
    _wsSubscriptions.add(_chatWebSocket.onMessageRead.listen(_onWsMessageRead));
    _wsSubscriptions.add(
      _chatWebSocket.onConnectionChanged.listen(_onWsConnectionChanged),
    );
  }

  void _onWsConnectionChanged(bool isConnected) {
    if (!isConnected) {
      return;
    }

    _syncConversationRoomSubscriptions();
    if (_conversations.isNotEmpty && !_isLoadingConversations) {
      unawaited(loadConversations(refresh: true));
    }

    if (_currentConversation != null && !_isLoadingMessages) {
      joinConversationRoom(_currentConversation!.id);
      unawaited(loadMessages(refresh: true, preserveExisting: true));
    }
  }

  Future<void> ensureWebSocketConnected() async {
    if (_isConnecting || _chatWebSocket.isConnected) return;
    _isConnecting = true;
    try {
      final token = await _tokenStore.readToken();
      if (token != null && token.isNotEmpty) {
        await _chatWebSocket.connect(token: token);
      }
    } catch (e) {
      debugPrint('ChatRoomViewModel: WS connect error: $e');
    } finally {
      _isConnecting = false;
    }
  }

  void joinConversationRoom(int conversationId) {
    if (conversationId <= 0) {
      return;
    }
    _chatWebSocket.joinConversation(conversationId);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        unawaited(ensureWebSocketConnected());
        unawaited(loadConversations(refresh: true));
        break;
      case AppLifecycleState.detached:
        unawaited(_chatWebSocket.disconnect());
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
        break;
    }
  }

  void _onWsMessageReceived(MessageDto message) {
    addMessageToChat(message);
  }

  void _onWsMessageNotify(MessageDto message) {
    // Ignore own messages
    if (_currentUserId != null && message.senderId == _currentUserId) return;

    _syncAttachedProductsFromMessages(
      message.conversationId,
      [message],
      save: true,
    );

    // Deduplicate with chat:receive
    if (!_notifiedMessageIds.add(message.id)) return;

    // Keep set bounded
    if (_notifiedMessageIds.length > 200) {
      final toRemove = _notifiedMessageIds.take(100).toList();
      _notifiedMessageIds.removeAll(toRemove);
    }

    final conversationId = message.conversationId;

    if (_currentConversation?.id == conversationId) {
      joinConversationRoom(conversationId);
      addMessageToChat(message);
      return;
    }

    final index = _conversations.indexWhere((c) => c.id == conversationId);
    if (index != -1) {
      _upsertConversationLastMessage(message, incrementUnread: true);
      joinConversationRoom(conversationId);
      notifyListeners();
    } else {
      joinConversationRoom(conversationId);
      unawaited(loadConversations(refresh: true));
    }
  }

  void _onWsMessageUpdated(MessageUpdateEvent event) {
    final idx = _messages.indexWhere((m) => m.id == event.messageId);
    if (idx != -1) {
      _messages[idx] = _messages[idx].copyWith(
        messageText: event.messageText,
        editedAt: event.editedAt,
      );
      notifyListeners();
    }
  }

  void _onWsMessageDeleted(MessageDeleteEvent event) {
    _messages.removeWhere((m) => event.messageIds.contains(m.id));
    _selectedMessageIds.removeAll(event.messageIds);
    if (_selectedMessageIds.isEmpty) _isSelectionMode = false;
    notifyListeners();
  }

  void _onWsMessageRead(MessageReadEvent event) {
    final idx = _messages.indexWhere((m) => m.id == event.messageId);
    if (idx != -1) {
      final current = _messages[idx];
      if (!current.readBy.contains(event.userId)) {
        _messages[idx] = current.copyWith(
          readBy: [...current.readBy, event.userId],
        );
        notifyListeners();
      }
    }
  }

  // Selection getters
  bool get isSelectionMode => _isSelectionMode;
  Set<int> get selectedMessageIds => Set.unmodifiable(_selectedMessageIds);
  int get selectedCount => _selectedMessageIds.length;

  bool isMessageSelected(int messageId) =>
      _selectedMessageIds.contains(messageId);

  void toggleMessageSelection(int messageId) {
    if (_selectedMessageIds.contains(messageId)) {
      _selectedMessageIds.remove(messageId);
      if (_selectedMessageIds.isEmpty) _isSelectionMode = false;
    } else {
      _selectedMessageIds.add(messageId);
      _isSelectionMode = true;
    }
    notifyListeners();
  }

  void startSelection(int messageId) {
    _isSelectionMode = true;
    _selectedMessageIds.add(messageId);
    notifyListeners();
  }

  void clearSelection() {
    _selectedMessageIds.clear();
    _isSelectionMode = false;
    notifyListeners();
  }

  /// Returns true if all selected messages belong to [userId].
  bool canEditSelectedMessages(int userId) {
    if (_selectedMessageIds.length != 1) return false;
    final msg = _messages.firstWhere(
      (m) => m.id == _selectedMessageIds.first,
      orElse: () => MessageDto(
        id: 0,
        messageText: '',
        senderId: 0,
        conversationId: 0,
        sentAt: DateTime.now(),
      ),
    );
    return msg.senderId == userId && msg.imageUrls.isEmpty;
  }

  bool canDeleteSelectedMessages(int userId) {
    if (_selectedMessageIds.isEmpty) return false;
    return _messages
        .where((m) => _selectedMessageIds.contains(m.id))
        .every((m) => m.senderId == userId);
  }

  /// Edit a single message
  Future<bool> editMessage(int messageId, String newText) async {
    try {
      final response = await _chatRepository.editMessage(
        messageId: messageId,
        messageText: newText,
      );
      if (response.isSuccess && response.data != null) {
        final idx = _messages.indexWhere((m) => m.id == messageId);
        if (idx != -1) {
          final editedAt = response.data!['editedAt'] != null
              ? DateTime.tryParse(response.data!['editedAt'] as String)
              : DateTime.now();
          _messages[idx] = _messages[idx].copyWith(
            messageText: newText,
            editedAt: editedAt,
          );
        }
        clearSelection();
        notifyListeners();
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  /// Delete selected messages
  Future<bool> deleteSelectedMessages() async {
    if (_selectedMessageIds.isEmpty) return false;
    try {
      final ids = _selectedMessageIds.toList();
      final response = await _chatRepository.deleteMessages(ids);
      if (response.isSuccess) {
        final deleted = response.data ?? ids;
        _messages.removeWhere((m) => deleted.contains(m.id));
        clearSelection();
        notifyListeners();
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  List<AttachedProduct> get attachedProducts {
    final convId = _currentConversation?.id;
    if (convId == null) return const [];
    return List.unmodifiable(_attachedProductsByConversation[convId] ?? []);
  }

  /// Returns attached products for a specific conversation (used by list screen).
  List<AttachedProduct> attachedProductsForConversation(int conversationId) {
    return List.unmodifiable(
      _attachedProductsByConversation[conversationId] ?? [],
    );
  }

  void addAttachedProduct(ProductDto product) {
    final convId = _currentConversation?.id;
    if (convId == null) return;
    final list = _attachedProductsByConversation.putIfAbsent(convId, () => []);
    if (list.any((ap) => ap.product.id == product.id)) return;
    list.insert(0, AttachedProduct(product: product));
    _saveAttachments();
    notifyListeners();
  }

  void removeAttachedProduct(int productId) {
    final convId = _currentConversation?.id;
    if (convId == null) return;
    _attachedProductsByConversation[convId]?.removeWhere(
      (ap) => ap.product.id == productId,
    );
    _resolvedProductsByConversation
        .putIfAbsent(convId, () => {})
        .add(productId);
    _saveAttachments();
    notifyListeners();
  }

  void clearAttachedProducts() {
    final convId = _currentConversation?.id;
    if (convId == null) return;
    _attachedProductsByConversation.remove(convId);
    _saveAttachments();
    notifyListeners();
  }

  void clearAttachedProductsForConversation(int conversationId) {
    final ids = (_attachedProductsByConversation[conversationId] ?? [])
        .map((ap) => ap.product.id)
        .toSet();
    _attachedProductsByConversation.remove(conversationId);
    if (ids.isNotEmpty) {
      _resolvedProductsByConversation[conversationId] = ids;
    }
    _saveAttachments();
    notifyListeners();
  }

  void _stampPendingCountdowns(DateTime sentAt) {
    final convId = _currentConversation?.id;
    if (convId == null) return;
    final list = _attachedProductsByConversation[convId];
    if (list == null) return;
    for (var i = 0; i < list.length; i++) {
      if (list[i].countdownStartedAt == null) {
        list[i] = list[i].copyWith(countdownStartedAt: sentAt);
      }
    }
  }

  void stampPendingCountdownsFromMessages(DateTime sentAt) {
    _stampPendingCountdowns(sentAt);
    _saveAttachments();
    notifyListeners();
  }

  static const _attachmentsKey = 'attached_products_v1';
  static const _resolvedKey = 'resolved_products_v1';

  Future<void> _saveAttachments() async {
    final prefs = await SharedPreferences.getInstance();
    final map = <String, dynamic>{};
    for (final entry in _attachedProductsByConversation.entries) {
      map[entry.key.toString()] = entry.value.map((ap) => ap.toJson()).toList();
    }
    await prefs.setString(_attachmentsKey, jsonEncode(map));

    final resolvedMap = <String, dynamic>{};
    for (final entry in _resolvedProductsByConversation.entries) {
      resolvedMap[entry.key.toString()] = entry.value.toList();
    }
    await prefs.setString(_resolvedKey, jsonEncode(resolvedMap));
  }

  Future<void> loadPersistedAttachments() async {
    final prefs = await SharedPreferences.getInstance();

    final raw = prefs.getString(_attachmentsKey);
    if (raw != null) {
      try {
        final map = jsonDecode(raw) as Map<String, dynamic>;
        for (final entry in map.entries) {
          final convId = int.tryParse(entry.key);
          if (convId == null) continue;
          final list = (entry.value as List)
              .map((e) => AttachedProduct.fromJson(e as Map<String, dynamic>))
              .toList();
          _attachedProductsByConversation[convId] = list;
        }
      } catch (_) {
        // Corrupted data - ignore and start fresh
      }
    }

    final resolvedRaw = prefs.getString(_resolvedKey);
    if (resolvedRaw != null) {
      try {
        final resolvedMap = jsonDecode(resolvedRaw) as Map<String, dynamic>;
        for (final entry in resolvedMap.entries) {
          final convId = int.tryParse(entry.key);
          if (convId == null) continue;
          final ids = (entry.value as List)
              .map((e) => e is int ? e : int.tryParse(e.toString()) ?? 0)
              .where((id) => id > 0)
              .toSet();
          _resolvedProductsByConversation[convId] = ids;
        }
      } catch (_) {
        // Ignore corrupted resolved data
      }
    }

    _pruneStaleAttachmentState();
  }

  Set<int> _knownConversationIds() {
    final ids = _conversations.map((conversation) => conversation.id).toSet();
    final currentConversationId = _currentConversation?.id;
    if (currentConversationId != null) {
      ids.add(currentConversationId);
    }
    return ids;
  }

  void _pruneStaleAttachmentState({bool save = false}) {
    final knownConversationIds = _knownConversationIds();
    if (knownConversationIds.isEmpty) {
      return;
    }

    bool changed = false;

    final staleAttachmentIds = _attachedProductsByConversation.keys
        .where((conversationId) => !knownConversationIds.contains(conversationId))
        .toList(growable: false);
    for (final conversationId in staleAttachmentIds) {
      _attachedProductsByConversation.remove(conversationId);
      changed = true;
    }

    final staleResolvedIds = _resolvedProductsByConversation.keys
        .where((conversationId) => !knownConversationIds.contains(conversationId))
        .toList(growable: false);
    for (final conversationId in staleResolvedIds) {
      _resolvedProductsByConversation.remove(conversationId);
      changed = true;
    }

    if (changed && save) {
      _saveAttachments();
    }
  }

  void _syncAttachedProductsFromMessages(
    int conversationId,
    List<MessageDto> messages, {
    bool save = false,
  }) {
    final resolved = _resolvedProductsByConversation[conversationId] ?? {};
    bool changed = false;

    for (final message in messages) {
      final product = _resolveAttachmentProductFromMessage(
        conversationId,
        message,
      );
      if (product == null) continue;
      final resolvedProduct = _resolveAttachmentProduct(
        conversationId,
        product,
      );
      if (resolved.contains(resolvedProduct.id)) continue;

      final list = _attachedProductsByConversation.putIfAbsent(
        conversationId,
        () => [],
      );
      final existingIndex = list.indexWhere(
        (ap) => ap.product.id == resolvedProduct.id,
      );

      if (existingIndex == -1) {
        list.add(
          AttachedProduct(
            product: resolvedProduct,
            countdownStartedAt: message.sentAt,
          ),
        );
        changed = true;
      } else if (list[existingIndex].countdownStartedAt == null) {
        list[existingIndex] = list[existingIndex].copyWith(
          countdownStartedAt: message.sentAt,
        );
        changed = true;
      }
    }

    if (changed && save) {
      _saveAttachments();
    }
  }

  ProductDto? _resolveAttachmentProductFromMessage(
    int conversationId,
    MessageDto message,
  ) {
    if (message.attachedProduct != null) {
      return message.attachedProduct;
    }

    final attachedProductId = message.attachedProductId;
    if (attachedProductId == null || attachedProductId <= 0) {
      return null;
    }

    final currentConversationProduct =
        _currentConversation?.id == conversationId
        ? _currentConversation?.product
        : null;
    if (currentConversationProduct?.id == attachedProductId) {
      return currentConversationProduct;
    }

    final listedConversation = _conversations
        .cast<ConversationDto?>()
        .firstWhere(
          (conversation) => conversation?.id == conversationId,
          orElse: () => null,
        );
    if (listedConversation?.product?.id == attachedProductId) {
      return listedConversation?.product;
    }

    return null;
  }

  ProductDto _resolveAttachmentProduct(
    int conversationId,
    ProductDto fallback,
  ) {
    final currentConversationProduct =
        _currentConversation?.id == conversationId
        ? _currentConversation?.product
        : null;
    if (currentConversationProduct?.id == fallback.id) {
      return currentConversationProduct!;
    }

    final listedConversation = _conversations
        .cast<ConversationDto?>()
        .firstWhere(
          (conversation) => conversation?.id == conversationId,
          orElse: () => null,
        );
    final listedConversationProduct = listedConversation?.product;
    if (listedConversationProduct?.id == fallback.id) {
      return listedConversationProduct!;
    }

    return fallback;
  }

  // Getters
  List<ConversationDto> get conversations => _conversations;
  bool get isLoadingConversations => _isLoadingConversations;
  String? get conversationsError => _conversationsError;
  bool get hasMoreConversations => _hasMoreConversations;

  ConversationDto? get currentConversation => _currentConversation;
  bool get isLoadingCurrentConversation => _isLoadingCurrentConversation;
  String? get currentConversationError => _currentConversationError;

  List<MessageDto> get messages => _messages;
  bool get isLoadingMessages => _isLoadingMessages;
  String? get messagesError => _messagesError;
  bool get hasMoreMessages => _hasMoreMessages;

  bool get isSendingMessage => _isSendingMessage;
  String? get sendMessageError => _sendMessageError;
  int get totalUnreadCount => _conversations.fold<int>(
    0,
    (sum, conversation) => sum + conversation.unreadCount,
  );

  int get pendingPurchaseCount {
    final knownConversationIds = _knownConversationIds();
    final now = DateTime.now();
    int count = 0;
    for (final entry in _attachedProductsByConversation.entries) {
      if (!knownConversationIds.contains(entry.key)) {
        continue;
      }

      final list = entry.value;
      final hasPending = list.any((ap) {
        if (ap.countdownStartedAt == null) return false;
        return now.isBefore(ap.countdownStartedAt!.add(purchaseDuration));
      });
      if (hasPending) count++;
    }
    return count;
  }

  bool hasProductAttachmentForMessage(int messageId) =>
      _messagesWithProductAttachment.contains(messageId);

  ConversationDto? findConversationWithUser(int userId) {
    for (final conversation in _conversations) {
      final participants = conversation.participants;
      if (participants == null) {
        continue;
      }

      final matchesUser = participants.any(
        (participant) => participant.userId == userId,
      );
      if (matchesUser) {
        return conversation;
      }
    }

    return null;
  }

  ConversationDto? findConversationForProduct(int productId) {
    for (final conversation in _conversations) {
      if (conversation.productId == productId) {
        return conversation;
      }
    }

    return null;
  }

  void setConversationBlockState(
    int conversationId, {
    required bool isBlockedByMe,
    required bool hasBlockedMe,
  }) {
    if (_currentConversation?.id == conversationId) {
      _currentConversation = _currentConversation?.copyWith(
        isBlockedByMe: isBlockedByMe,
        hasBlockedMe: hasBlockedMe,
      );
    }

    final index = _conversations.indexWhere(
      (conversation) => conversation.id == conversationId,
    );
    if (index != -1) {
      _conversations[index] = _conversations[index].copyWith(
        isBlockedByMe: isBlockedByMe,
        hasBlockedMe: hasBlockedMe,
      );
    }

    notifyListeners();
  }

  // Load conversations list
  Future<void> loadConversations({bool refresh = false}) async {
    if (_isLoadingConversations) return;

    final previousConversations = List<ConversationDto>.from(_conversations);
    if (refresh) {
      _hasMoreConversations = true;
      _conversationOffset = 0;
    }

    _isLoadingConversations = true;
    _conversationsError = null;
    notifyListeners();

    try {
      final response = await _chatRepository.getConversations(
        offset: _conversationOffset,
        limit: _conversationPageSize,
      );

      if (response.isSuccess) {
        final fetchedConversations = response.data ?? [];
        if (refresh) {
          _conversations = fetchedConversations;
        } else {
          _conversations.addAll(fetchedConversations);
        }

        for (final conversation in fetchedConversations) {
          final lastMessage = conversation.lastMessage;
          if (lastMessage != null) {
            _syncAttachedProductsFromMessages(
              conversation.id,
              [lastMessage!],
              save: true,
            );
          }
        }

        _syncConversationRoomSubscriptions();
        _pruneStaleAttachmentState(save: refresh);
        _conversationOffset = refresh
            ? fetchedConversations.length
            : _conversationOffset + fetchedConversations.length;
        if (fetchedConversations.length < _conversationPageSize) {
          _hasMoreConversations = false;
        }
      } else {
        if (refresh) {
          _conversations = previousConversations;
        }
        _conversationsError =
            response.error?.message ?? 'Failed to load conversations';
      }
    } catch (e) {
      if (refresh) {
        _conversations = previousConversations;
      }
      _conversationsError = 'Error: ${e.toString()}';
    } finally {
      _isLoadingConversations = false;
      final newTotal = totalUnreadCount;
      if (newTotal != _lastEmittedUnreadCount) {
        _lastEmittedUnreadCount = newTotal;
        _unreadCountController.add(newTotal);
      }
      notifyListeners();
    }
  }

  // Load more conversations
  Future<void> loadMoreConversations() async {
    if (!_hasMoreConversations || _isLoadingConversations) return;
    await loadConversations();
  }

  // Load a specific conversation
  Future<void> loadConversation(int conversationId) async {
    if (_isLoadingCurrentConversation) return;

    _isLoadingCurrentConversation = true;
    _currentConversationError = null;
    notifyListeners();

    try {
      final response = await _chatRepository.getConversation(conversationId);
      if (response.isSuccess) {
        _currentConversation = response.data;
        _messagesWithProductAttachment.clear();
        if (response.data != null) {
          joinConversationRoom(response.data!.id);
        }
        if (response.data != null) {
          final existingIndex = _conversations.indexWhere(
            (conversation) => conversation.id == response.data!.id,
          );
          if (existingIndex != -1) {
            _conversations[existingIndex] = _conversations[existingIndex]
                .copyWith(
                  participants: response.data!.participants,
                  product: response.data!.product,
                  isBlockedByMe: response.data!.isBlockedByMe,
                  hasBlockedMe: response.data!.hasBlockedMe,
                );
          }
        }
      } else {
        _currentConversationError =
            response.error?.message ?? 'Failed to load conversation';
      }
    } catch (e) {
      _currentConversationError = 'Error: ${e.toString()}';
    } finally {
      _isLoadingCurrentConversation = false;
      notifyListeners();
    }
  }

  // Create a conversation for a product
  Future<ConversationDto?> createConversation(int productId) async {
    _isLoadingCurrentConversation = true;
    _currentConversationError = null;
    notifyListeners();

    try {
      final response = await _chatRepository.createConversation(productId);
      if (response.isSuccess) {
        _currentConversation = response.data;
        if (response.data != null) {
          _upsertConversation(response.data!);
          joinConversationRoom(response.data!.id);
        }
        return response.data;
      } else {
        _currentConversationError =
            response.error?.message ?? 'Failed to create conversation';
        return null;
      }
    } catch (e) {
      _currentConversationError = 'Error: ${e.toString()}';
      return null;
    } finally {
      _isLoadingCurrentConversation = false;
      notifyListeners();
    }
  }

  // Create a conversation with a user
  Future<ConversationDto?> createConversationWithUser(int userId) async {
    _isLoadingCurrentConversation = true;
    _currentConversationError = null;
    notifyListeners();

    try {
      final response = await _chatRepository.createConversationWithUser(userId);
      if (response.isSuccess) {
        _currentConversation = response.data;
        if (response.data != null) {
          _upsertConversation(response.data!);
          joinConversationRoom(response.data!.id);
        }
        return response.data;
      } else {
        _currentConversationError =
            response.error?.message ?? 'Failed to create conversation';
        return null;
      }
    } catch (e) {
      _currentConversationError = 'Error: ${e.toString()}';
      return null;
    } finally {
      _isLoadingCurrentConversation = false;
      notifyListeners();
    }
  }

  // Load messages for current conversation
  Future<void> loadMessages({
    bool refresh = false,
    bool preserveExisting = true,
  }) async {
    if (_currentConversation == null) return;
    if (_isLoadingMessages) return;

    final hadExistingMessages = _messages.isNotEmpty;
    if (refresh) {
      _messageOffset = 0;
      _hasMoreMessages = true;
      if (!preserveExisting) {
        _messages = [];
      }
    }

    _isLoadingMessages = true;
    _messagesError = null;
    notifyListeners();

    try {
      final response = await _chatRepository.getMessages(
        conversationId: _currentConversation!.id,
        offset: _messageOffset,
        limit: _messagesPageSize,
      );

      if (response.isSuccess) {
        final fetchedMessages = (response.data ?? []).reversed.toList();
        if (refresh) {
          _messages = fetchedMessages;
        } else {
          _messages.insertAll(0, fetchedMessages);
        }
        _messageOffset = refresh
            ? fetchedMessages.length
            : _messageOffset + fetchedMessages.length;
        if (fetchedMessages.length < _messagesPageSize) {
          _hasMoreMessages = false;
        }
        _syncAttachedProductsFromMessages(
          _currentConversation!.id,
          _messages,
          save: refresh,
        );
      } else {
        _messagesError = response.error?.message ?? 'Failed to load messages';
        if (refresh && preserveExisting && hadExistingMessages) {
          _hasMoreMessages = true;
        }
      }
    } catch (e) {
      _messagesError = 'Error: ${e.toString()}';
      if (refresh && preserveExisting && hadExistingMessages) {
        _hasMoreMessages = true;
      }
    } finally {
      _isLoadingMessages = false;
      notifyListeners();
    }
  }

  // Load more messages (older)
  Future<void> loadMoreMessages() async {
    if (!_hasMoreMessages || _isLoadingMessages) return;
    await loadMessages();
  }

  // Send a message
  Future<bool> sendMessage(
    String messageText, {
    bool attachConversationProduct = false,
    List<String> imagePaths = const [],
  }) async {
    final normalizedMessageText = messageText.trim();

    if (_currentConversation == null) {
      return false;
    }

    if (normalizedMessageText.isEmpty &&
        imagePaths.isEmpty &&
        !attachConversationProduct) {
      return false;
    }

    _isSendingMessage = true;
    _sendMessageError = null;
    notifyListeners();

    try {
      final response = await _chatRepository.sendMessage(
        conversationId: _currentConversation!.id,
        messageText: normalizedMessageText,
        attachedProductId: attachConversationProduct
            ? _currentConversation?.product?.id
            : null,
        imagePaths: imagePaths,
      );

      if (response.isSuccess && response.data != null) {
        final msg = response.data!;
        // Guard against duplicate from WebSocket race
        if (!_messages.any((m) => m.id == msg.id)) {
          _messages.add(msg);
        }
        _upsertConversationLastMessage(msg, unreadCount: 0);
        if (attachConversationProduct) {
          _messagesWithProductAttachment.add(msg.id);
        }
        _stampPendingCountdowns(msg.sentAt);
        _saveAttachments();
        _sendMessageError = null;
        notifyListeners();
        return true;
      } else {
        _sendMessageError = response.error?.message ?? 'Failed to send message';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _sendMessageError = 'Error: ${e.toString()}';
      notifyListeners();
      return false;
    } finally {
      _isSendingMessage = false;
      notifyListeners();
    }
  }

  // Mark message as read
  Future<void> markMessageAsRead(int messageId) async {
    try {
      _chatWebSocket.markMessageRead(messageId);
      final response = await _chatRepository.markMessageAsRead(messageId);
      if (response.isSuccess) {
        // Update message in local cache
        final messageIndex = _messages.indexWhere((m) => m.id == messageId);
        if (messageIndex != -1) {
          notifyListeners();
        }
      }
    } catch (e) {
      // Silently fail for read receipts
    }
  }

  // Set current conversation
  void selectConversation(ConversationDto conversation) {
    _currentConversation = conversation.copyWith(unreadCount: 0);
    joinConversationRoom(conversation.id);

    final index = _conversations.indexWhere(
      (item) => item.id == conversation.id,
    );
    if (index != -1) {
      _conversations[index] = _conversations[index].copyWith(unreadCount: 0);
    }

    _messages = [];
    _messageOffset = 0;
    _hasMoreMessages = true;
    notifyListeners();
  }

  // Clear current conversation
  void clearCurrentConversation({bool notify = true}) {
    final conversationId = _currentConversation?.id;
    if (conversationId != null) {
      _chatWebSocket.leaveConversation(conversationId);
    }
    _currentConversation = null;
    _messages = [];
    _messagesWithProductAttachment.clear();
    _messageOffset = 0;
    _hasMoreMessages = true;
    _sendMessageError = null;
    if (notify) {
      notifyListeners();
    }
  }

  // Add message to local list
  void addMessageToChat(MessageDto message) {
    _syncAttachedProductsFromMessages(
      message.conversationId,
      [message],
      save: true,
    );

    // If user is viewing this conversation, add message to thread
    if (_currentConversation?.id == message.conversationId) {
      final alreadyInThread = _messages.any((item) => item.id == message.id);
      if (!alreadyInThread) {
        _messages.add(message);
      }
      _upsertConversationLastMessage(message, unreadCount: 0);
      notifyListeners();
      return;
    }

    // For other conversations, skip own messages (avoid self-incrementing unread)
    if (_currentUserId != null && message.senderId == _currentUserId) {
      _upsertConversationLastMessage(message);
      notifyListeners();
      return;
    }

    // If chat:notify already handled this message, skip incrementing again
    if (_notifiedMessageIds.contains(message.id)) {
      _upsertConversationLastMessage(message);
      notifyListeners();
      return;
    }

    // Increment unread for messages from others in non-active conversations
    _notifiedMessageIds.add(message.id);
    _upsertConversationLastMessage(message, incrementUnread: true);
    notifyListeners();
  }

  Future<bool> deleteConversation(int conversationId) async {
    try {
      final response = await _chatRepository.deleteConversation(conversationId);
      if (!response.isSuccess) {
        _conversationsError =
            response.error?.message ?? 'Failed to delete conversation';
        notifyListeners();
        return false;
      }

      final now = DateTime.now();
      final index = _conversations.indexWhere(
        (conversation) => conversation.id == conversationId,
      );
      if (index != -1) {
        final existing = _conversations[index];
        _conversations[index] = existing.copyWith(
          unreadCount: 0,
          updatedAt: now,
          clearLastMessage: true,
        );
      }

      _attachedProductsByConversation.remove(conversationId);
      await _saveAttachments();

      if (_currentConversation?.id == conversationId) {
        _currentConversation = _currentConversation?.copyWith(
          unreadCount: 0,
          updatedAt: now,
          clearLastMessage: true,
        );
        _messages = [];
        _messagesWithProductAttachment.clear();
        _messageOffset = 0;
        _hasMoreMessages = true;
        _sendMessageError = null;
        _currentConversationError = null;
        notifyListeners();
      } else {
        notifyListeners();
      }
      return true;
    } catch (e) {
      _conversationsError = 'Error: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  void _upsertConversation(ConversationDto conversation) {
    _conversations.removeWhere((item) => item.id == conversation.id);
    _conversations.insert(0, conversation);
    joinConversationRoom(conversation.id);
  }

  void _upsertConversationLastMessage(
    MessageDto message, {
    int? unreadCount,
    bool incrementUnread = false,
  }) {
    final conversationId = message.conversationId;
    final index = _conversations.indexWhere(
      (item) => item.id == conversationId,
    );
    if (index == -1) {
      return;
    }

    final existing = _conversations[index];
    final nextUnreadCount =
        unreadCount ??
        (incrementUnread ? existing.unreadCount + 1 : existing.unreadCount);
    final updatedConversation = existing.copyWith(
      lastMessage: message,
      unreadCount: nextUnreadCount,
      updatedAt: message.sentAt,
    );

    _conversations.removeAt(index);
    _conversations.insert(0, updatedConversation);

    if (_currentConversation?.id == conversationId) {
      _currentConversation = _currentConversation?.copyWith(
        lastMessage: message,
        unreadCount: nextUnreadCount,
        updatedAt: message.sentAt,
      );
    }

    // Emit unread count if it changed
    final newTotal = totalUnreadCount;
    if (newTotal != _lastEmittedUnreadCount) {
      _lastEmittedUnreadCount = newTotal;
      _unreadCountController.add(newTotal);
    }
  }

  void _syncConversationRoomSubscriptions() {
    for (final conversation in _conversations) {
      joinConversationRoom(conversation.id);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    for (final sub in _wsSubscriptions) {
      sub.cancel();
    }
    _wsSubscriptions.clear();
    _unreadCountController.close();
    super.dispose();
  }
}
