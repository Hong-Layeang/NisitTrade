import '../models/conversation.dart';
import '../providers/chat_api_service.dart';
import '../../core/errors/api_response.dart';

class ChatRepository {
  ChatRepository._() : _apiService = ChatApiService.instance;

  static final ChatRepository instance = ChatRepository._();

  final ChatApiService _apiService;

  /// Get all conversations for the current user
  Future<ApiResponse<List<Conversation>>> getConversations({
    int offset = 0,
    int limit = 20,
  }) async {
    return _apiService.getConversations(offset: offset, limit: limit);
  }

  /// Get a single conversation
  Future<ApiResponse<Conversation>> getConversation(int conversationId) async {
    return _apiService.getConversation(conversationId);
  }

  /// Create a new conversation
  Future<ApiResponse<Conversation>> createConversation(int productId) async {
    return _apiService.createConversation(productId);
  }

  /// Create a new conversation with a user
  Future<ApiResponse<Conversation>> createConversationWithUser(int userId) async {
    return _apiService.createConversationWithUser(userId);
  }

  /// Get messages for a conversation
  Future<ApiResponse<List<Message>>> getMessages({
    required int conversationId,
    int offset = 0,
    int limit = 50,
  }) async {
    return _apiService.getMessages(
      conversationId: conversationId,
      offset: offset,
      limit: limit,
    );
  }

  /// Send a message
  Future<ApiResponse<Message>> sendMessage({
    required int conversationId,
    required String messageText,
    int? attachedProductId,
    List<String> imagePaths = const [],
  }) async {
    return _apiService.sendMessage(
      conversationId: conversationId,
      messageText: messageText,
      attachedProductId: attachedProductId,
      imagePaths: imagePaths,
    );
  }

  /// Mark message as read
  Future<ApiResponse<void>> markMessageAsRead(int messageId) async {
    return _apiService.markMessageAsRead(messageId);
  }

  Future<ApiResponse<void>> deleteConversation(int conversationId) async {
    return _apiService.deleteConversation(conversationId);
  }

  /// Get conversation participants
  Future<ApiResponse<List<ConversationParticipant>>> getConversationParticipants(
    int conversationId,
  ) async {
    return _apiService.getConversationParticipants(conversationId);
  }

  /// Edit a message
  Future<ApiResponse<Map<String, dynamic>>> editMessage({
    required int messageId,
    required String messageText,
  }) async {
    return _apiService.editMessage(messageId: messageId, messageText: messageText);
  }

  /// Delete multiple messages
  Future<ApiResponse<List<int>>> deleteMessages(List<int> messageIds) async {
    return _apiService.deleteMessages(messageIds);
  }
}
