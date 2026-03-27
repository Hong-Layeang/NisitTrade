import '../../core/errors/api_response.dart';
import '../../data/dtos/conversation_dto.dart';

abstract class IChatRepository {
  Future<ApiResponse<List<ConversationDto>>> getConversations({
    int offset,
    int limit,
  });
  Future<ApiResponse<ConversationDto>> getConversation(int conversationId);
  Future<ApiResponse<ConversationDto>> createConversation(int productId);
  Future<ApiResponse<ConversationDto>> createConversationWithUser(int userId);
  Future<ApiResponse<List<MessageDto>>> getMessages({
    required int conversationId,
    int offset,
    int limit,
  });
  Future<ApiResponse<MessageDto>> sendMessage({
    required int conversationId,
    required String messageText,
    int? attachedProductId,
    List<String> imagePaths,
  });
  Future<ApiResponse<void>> markMessageAsRead(int messageId);
  Future<ApiResponse<void>> deleteConversation(int conversationId);
  Future<ApiResponse<List<ConversationParticipantDto>>>
      getConversationParticipants(int conversationId);
  Future<ApiResponse<Map<String, dynamic>>> editMessage({
    required int messageId,
    required String messageText,
  });
  Future<ApiResponse<List<int>>> deleteMessages(List<int> messageIds);
}

