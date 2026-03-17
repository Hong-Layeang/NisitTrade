import '../models/conversation.dart';
import '../providers/chat_api_service.dart';
import '../../core/errors/api_response.dart';

class ChatRepository {
  ChatRepository._() : _apiService = ChatApiService.instance;

  static final ChatRepository instance = ChatRepository._();

  final ChatApiService _apiService;

  /// Get all conversations for the current user
  Future<ApiResponse<List<Conversation>>> getConversations({
    int page = 1,
    int limit = 20,
  }) async {
    return _apiService.getConversations(page: page, limit: limit);
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
    int page = 1,
    int limit = 50,
  }) async {
    return _apiService.getMessages(
      conversationId: conversationId,
      page: page,
      limit: limit,
    );
  }

  /// Send a message
  Future<ApiResponse<Message>> sendMessage({
    required int conversationId,
    required String messageText,
    int? attachedProductId,
  }) async {
    return _apiService.sendMessage(
      conversationId: conversationId,
      messageText: messageText,
      attachedProductId: attachedProductId,
    );
  }

  /// Mark message as read
  Future<ApiResponse<void>> markMessageAsRead(int messageId) async {
    return _apiService.markMessageAsRead(messageId);
  }

  /// Get conversation participants
  Future<ApiResponse<List<ConversationParticipant>>> getConversationParticipants(
    int conversationId,
  ) async {
    return _apiService.getConversationParticipants(conversationId);
  }
}
