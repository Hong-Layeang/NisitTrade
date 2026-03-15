import '../models/conversation.dart';
import '../../core/errors/api_response.dart';
import 'api_client.dart';
import 'base_api_service.dart';

class ChatApiService extends BaseApiService {
  ChatApiService._() : super(ApiClient.instance.dio);

  static final ChatApiService instance = ChatApiService._();

  static const String _baseRoute = '/conversations';
  static const String _messagesRoute = '/messages';

  /// Get all conversations for the current user with pagination
  Future<ApiResponse<List<Conversation>>> getConversations({
    int page = 1,
    int limit = 20,
  }) async {
    return executeApiCall(
      call: () => dio.get(
        _baseRoute,
        queryParameters: {
          'page': page,
          'limit': limit,
        },
      ),
      parser: (data) {
        if (data is! Map<String, dynamic>) {
          throw FormatException('Expected object response, got ${data.runtimeType}');
        }
        final items = data['items'] as List?;
        if (items == null) {
          throw FormatException('Expected "items" field in response');
        }
        return items
            .map((item) => Conversation.fromJson(item as Map<String, dynamic>))
            .toList();
      },
      errorMessage: 'Failed to load conversations',
    );
  }

  /// Get a single conversation with its details
  Future<ApiResponse<Conversation>> getConversation(int conversationId) async {
    return executeApiCall(
      call: () => dio.get('$_baseRoute/$conversationId'),
      parser: (data) => Conversation.fromJson(data as Map<String, dynamic>),
      errorMessage: 'Failed to load conversation',
    );
  }

  /// Create a new conversation for a product
  Future<ApiResponse<Conversation>> createConversation(int productId) async {
    return executeApiCall(
      call: () => dio.post(
        _baseRoute,
        data: {'product_id': productId},
      ),
      parser: (data) => Conversation.fromJson(data as Map<String, dynamic>),
      errorMessage: 'Failed to create conversation',
    );
  }

  /// Get messages for a conversation with pagination
  Future<ApiResponse<List<Message>>> getMessages({
    required int conversationId,
    int page = 1,
    int limit = 50,
  }) async {
    return executeApiCall(
      call: () => dio.get(
        '$_messagesRoute/conversation/$conversationId',
        queryParameters: {
          'page': page,
          'limit': limit,
        },
      ),
      parser: (data) {
        if (data is! Map<String, dynamic>) {
          throw FormatException('Expected object response, got ${data.runtimeType}');
        }
        final items = data['items'] as List?;
        if (items == null) {
          throw FormatException('Expected "items" field in response');
        }
        return items
            .map((item) => Message.fromJson(item as Map<String, dynamic>))
            .toList();
      },
      errorMessage: 'Failed to load messages',
    );
  }

  /// Send a message to a conversation
  Future<ApiResponse<Message>> sendMessage({
    required int conversationId,
    required String messageText,
    int? attachedProductId,
  }) async {
    return executeApiCall(
      call: () => dio.post(
        '$_messagesRoute/conversation/$conversationId',
        data: {
          'message_text': messageText,
          if (attachedProductId != null) 'attached_product_id': attachedProductId,
        },
      ),
      parser: (data) => Message.fromJson(data as Map<String, dynamic>),
      errorMessage: 'Failed to send message',
    );
  }

  /// Mark a message as read
  Future<ApiResponse<void>> markMessageAsRead(int messageId) async {
    return executeApiCall(
      call: () => dio.post('$_messagesRoute/$messageId/read'),
      parser: (data) {},
      errorMessage: 'Failed to mark message as read',
    );
  }

  /// Get conversation participants
  Future<ApiResponse<List<ConversationParticipant>>> getConversationParticipants(
    int conversationId,
  ) async {
    return executeListApiCall(
      call: () => dio.get('$_baseRoute/$conversationId/participants'),
      itemParser: (item) => ConversationParticipant.fromJson(item as Map<String, dynamic>),
      errorMessage: 'Failed to load participants',
    );
  }
}
