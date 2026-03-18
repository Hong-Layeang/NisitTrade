import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/models/conversation.dart';
import '../../data/models/product.dart';
import '../../data/repositories/chat_repository.dart';

class AttachedProduct {
  final Product product;
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
      product: Product.fromJson(json['product'] as Map<String, dynamic>),
      countdownStartedAt: json['countdownStartedAt'] != null
          ? DateTime.parse(json['countdownStartedAt'] as String)
          : null,
    );
  }
}

class ChatRoomViewModel extends ChangeNotifier {
  ChatRoomViewModel({required ChatRepository chatRepository})
      : _chatRepository = chatRepository;

  final ChatRepository _chatRepository;

  // Conversations list state
  List<Conversation> _conversations = [];
  bool _isLoadingConversations = false;
  String? _conversationsError;
  int _conversationOffset = 0;
  bool _hasMoreConversations = true;
  static const int _conversationPageSize = 20;

  // Current conversation state
  Conversation? _currentConversation;
  bool _isLoadingCurrentConversation = false;
  String? _currentConversationError;

  // Messages state
  List<Message> _messages = [];
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

  List<AttachedProduct> get attachedProducts {
    final convId = _currentConversation?.id;
    if (convId == null) return const [];
    return List.unmodifiable(_attachedProductsByConversation[convId] ?? []);
  }

  void addAttachedProduct(Product product) {
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
    _attachedProductsByConversation[convId]
        ?.removeWhere((ap) => ap.product.id == productId);
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

  Future<void> _saveAttachments() async {
    final prefs = await SharedPreferences.getInstance();
    final map = <String, dynamic>{};
    for (final entry in _attachedProductsByConversation.entries) {
      map[entry.key.toString()] =
          entry.value.map((ap) => ap.toJson()).toList();
    }
    await prefs.setString(_attachmentsKey, jsonEncode(map));
  }

  Future<void> loadPersistedAttachments() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_attachmentsKey);
    if (raw == null) return;
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
      // Corrupted data — ignore and start fresh
    }
  }

  // Getters
  List<Conversation> get conversations => _conversations;
  bool get isLoadingConversations => _isLoadingConversations;
  String? get conversationsError => _conversationsError;
  bool get hasMoreConversations => _hasMoreConversations;

  Conversation? get currentConversation => _currentConversation;
  bool get isLoadingCurrentConversation => _isLoadingCurrentConversation;
  String? get currentConversationError => _currentConversationError;

  List<Message> get messages => _messages;
  bool get isLoadingMessages => _isLoadingMessages;
  String? get messagesError => _messagesError;
  bool get hasMoreMessages => _hasMoreMessages;

  bool get isSendingMessage => _isSendingMessage;
  String? get sendMessageError => _sendMessageError;
  int get totalUnreadCount => _conversations.fold<int>(
        0,
        (sum, conversation) => sum + conversation.unreadCount,
      );

  bool hasProductAttachmentForMessage(int messageId) =>
      _messagesWithProductAttachment.contains(messageId);

  Conversation? findConversationWithUser(int userId) {
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

  Conversation? findConversationForProduct(int productId) {
    for (final conversation in _conversations) {
      if (conversation.productId == productId) {
        return conversation;
      }
    }

    return null;
  }

  // Load conversations list
  Future<void> loadConversations({bool refresh = false}) async {
    if (_isLoadingConversations) return;

    final previousConversations = List<Conversation>.from(_conversations);
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
        _conversationsError = response.error?.message ?? 'Failed to load conversations';
      }
    } catch (e) {
      if (refresh) {
        _conversations = previousConversations;
      }
      _conversationsError = 'Error: ${e.toString()}';
    } finally {
      _isLoadingConversations = false;
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
      } else {
        _currentConversationError = response.error?.message ?? 'Failed to load conversation';
      }
    } catch (e) {
      _currentConversationError = 'Error: ${e.toString()}';
    } finally {
      _isLoadingCurrentConversation = false;
      notifyListeners();
    }
  }

  // Create a conversation for a product
  Future<Conversation?> createConversation(int productId) async {
    _isLoadingCurrentConversation = true;
    _currentConversationError = null;
    notifyListeners();

    try {
      final response = await _chatRepository.createConversation(productId);
      if (response.isSuccess) {
        _currentConversation = response.data;
        if (response.data != null) {
          _upsertConversation(response.data!);
        }
        return response.data;
      } else {
        _currentConversationError = response.error?.message ?? 'Failed to create conversation';
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
  Future<Conversation?> createConversationWithUser(int userId) async {
    _isLoadingCurrentConversation = true;
    _currentConversationError = null;
    notifyListeners();

    try {
      final response = await _chatRepository.createConversationWithUser(userId);
      if (response.isSuccess) {
        _currentConversation = response.data;
        if (response.data != null) {
          _upsertConversation(response.data!);
        }
        return response.data;
      } else {
        _currentConversationError = response.error?.message ?? 'Failed to create conversation';
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
  Future<void> loadMessages({bool refresh = false}) async {
    if (_currentConversation == null) return;
    if (_isLoadingMessages) return;

    if (refresh) {
      _messageOffset = 0;
      _hasMoreMessages = true;
      _messages = [];
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
        if (refresh) {
          _messages = (response.data ?? []).reversed.toList();
        } else {
          _messages.insertAll(0, (response.data ?? []).reversed);
        }
        _messageOffset = refresh
            ? (response.data ?? []).length
            : _messageOffset + (response.data ?? []).length;
        if ((response.data ?? []).length < _messagesPageSize) {
          _hasMoreMessages = false;
        }
      } else {
        _messagesError = response.error?.message ?? 'Failed to load messages';
      }
    } catch (e) {
      _messagesError = 'Error: ${e.toString()}';
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

    if (
      normalizedMessageText.isEmpty &&
      imagePaths.isEmpty &&
      !attachConversationProduct
    ) {
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
        _messages.add(response.data!);
        if (attachConversationProduct) {
          _messagesWithProductAttachment.add(response.data!.id);
        }
        _stampPendingCountdowns(response.data!.sentAt);
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

  // Set current conversation (without fetching)
  void selectConversation(Conversation conversation) {
    _currentConversation = conversation;
    _messages = [];
    _messageOffset = 0;
    _hasMoreMessages = true;
    notifyListeners();
  }

  // Clear current conversation
  void clearCurrentConversation() {
    _currentConversation = null;
    _messages = [];
    _messagesWithProductAttachment.clear();
    _messageOffset = 0;
    _hasMoreMessages = true;
    _sendMessageError = null;
    notifyListeners();
  }

  // Add message to local list (for real-time updates)
  void addMessageToChat(Message message) {
    if (_currentConversation?.id == message.conversationId) {
      _messages.add(message);
      notifyListeners();
    }
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

      _conversations.removeWhere((conversation) => conversation.id == conversationId);
      if (_currentConversation?.id == conversationId) {
        clearCurrentConversation();
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

  void _upsertConversation(Conversation conversation) {
    _conversations.removeWhere((item) => item.id == conversation.id);
    _conversations.insert(0, conversation);
  }
}
