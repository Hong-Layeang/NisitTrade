import 'package:flutter/material.dart';
import '../../data/models/conversation.dart';
import '../../data/repositories/chat_repository.dart';

class ChatRoomViewModel extends ChangeNotifier {
  ChatRoomViewModel({required ChatRepository chatRepository})
      : _chatRepository = chatRepository;

  final ChatRepository _chatRepository;

  // Conversations list state
  List<Conversation> _conversations = [];
  bool _isLoadingConversations = false;
  String? _conversationsError;
  int _conversationPage = 1;
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
  int _messagePage = 1;
  bool _hasMoreMessages = true;
  static const int _messagesPageSize = 50;

  // Sending message state
  bool _isSendingMessage = false;
  String? _sendMessageError;
  final Set<int> _messagesWithProductAttachment = <int>{};

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

  // Load conversations list
  Future<void> loadConversations({bool refresh = false}) async {
    if (_isLoadingConversations) return;

    if (refresh) {
      _conversationPage = 1;
      _hasMoreConversations = true;
      _conversations = [];
    }

    _isLoadingConversations = true;
    _conversationsError = null;
    notifyListeners();

    try {
      final response = await _chatRepository.getConversations(
        page: _conversationPage,
        limit: _conversationPageSize,
      );

      if (response.isSuccess) {
        if (refresh) {
          _conversations = response.data ?? [];
        } else {
          _conversations.addAll(response.data ?? []);
        }
        _conversationPage++;
        if ((response.data ?? []).length < _conversationPageSize) {
          _hasMoreConversations = false;
        }
      } else {
        _conversationsError = response.error?.message ?? 'Failed to load conversations';
      }
    } catch (e) {
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
        // Add to conversations list
        if (response.data != null) {
          _conversations.insert(0, response.data!);
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
      _messagePage = 1;
      _hasMoreMessages = true;
      _messages = [];
    }

    _isLoadingMessages = true;
    _messagesError = null;
    notifyListeners();

    try {
      final response = await _chatRepository.getMessages(
        conversationId: _currentConversation!.id,
        page: _messagePage,
        limit: _messagesPageSize,
      );

      if (response.isSuccess) {
        if (refresh) {
          _messages = (response.data ?? []).reversed.toList();
        } else {
          _messages.insertAll(0, (response.data ?? []).reversed);
        }
        _messagePage++;
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
  }) async {
    if (_currentConversation == null || messageText.trim().isEmpty) {
      return false;
    }

    _isSendingMessage = true;
    _sendMessageError = null;
    notifyListeners();

    try {
      final response = await _chatRepository.sendMessage(
        conversationId: _currentConversation!.id,
        messageText: messageText.trim(),
        attachedProductId: attachConversationProduct
            ? _currentConversation?.product?.id
            : null,
      );

      if (response.isSuccess && response.data != null) {
        _messages.add(response.data!);
        if (attachConversationProduct) {
          _messagesWithProductAttachment.add(response.data!.id);
        }
        // For real-time updates, we would emit via WebSocket here
        // For now, the message will be included in the sent response
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
    _messagePage = 1;
    _hasMoreMessages = true;
    notifyListeners();
  }

  // Clear current conversation
  void clearCurrentConversation() {
    _currentConversation = null;
    _messages = [];
    _messagesWithProductAttachment.clear();
    _messagePage = 1;
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
}
