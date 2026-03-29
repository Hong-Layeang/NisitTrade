import 'package:dio/dio.dart';

import '../../core/errors/api_exception.dart';
import '../../core/errors/api_response.dart';
import '../../core/network/api_client.dart';
import '../dtos/conversation_dto.dart';
import '../repository_interfaces/i_chat_repository.dart';

class ChatRepository implements IChatRepository {
  ChatRepository._() : _dio = ApiClient.instance.dio;

  static final ChatRepository instance = ChatRepository._();

  final Dio _dio;

  @override
  Future<ApiResponse<List<ConversationDto>>> getConversations({
    int offset = 0,
    int limit = 20,
  }) async {
    try {
      final response = await _dio.get(
        '/conversations',
        queryParameters: {'offset': offset, 'limit': limit},
      );
      final data = response.data as Map<String, dynamic>;
      final items = data['items'] as List;
      return ApiResponse.success(
        items
            .map((item) => ConversationDto.fromJson(item as Map<String, dynamic>))
            .toList(),
      );
    } on DioException catch (e) {
      return ApiResponse.error(ApiException.fromDioException(e));
    } catch (e) {
      return ApiResponse.error(ApiException(message: 'Failed to load conversations: $e'));
    }
  }

  @override
  Future<ApiResponse<ConversationDto>> getConversation(int conversationId) async {
    try {
      final response = await _dio.get('/conversations/$conversationId');
      return ApiResponse.success(
        ConversationDto.fromJson(response.data as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      return ApiResponse.error(ApiException.fromDioException(e));
    } catch (e) {
      return ApiResponse.error(ApiException(message: 'Failed to load conversation: $e'));
    }
  }

  @override
  Future<ApiResponse<ConversationDto>> createConversation(int productId) async {
    try {
      final response = await _dio.post('/conversations', data: {'product_id': productId});
      return ApiResponse.success(
        ConversationDto.fromJson(response.data as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      return ApiResponse.error(ApiException.fromDioException(e));
    } catch (e) {
      return ApiResponse.error(ApiException(message: 'Failed to create conversation: $e'));
    }
  }

  @override
  Future<ApiResponse<ConversationDto>> createConversationWithUser(int userId) async {
    try {
      final response = await _dio.post(
        '/conversations',
        data: {'participant_user_id': userId},
      );
      return ApiResponse.success(
        ConversationDto.fromJson(response.data as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      return ApiResponse.error(ApiException.fromDioException(e));
    } catch (e) {
      return ApiResponse.error(ApiException(message: 'Failed to create conversation: $e'));
    }
  }

  @override
  Future<ApiResponse<List<MessageDto>>> getMessages({
    required int conversationId,
    int offset = 0,
    int limit = 50,
  }) async {
    try {
      final response = await _dio.get(
        '/messages/conversation/$conversationId',
        queryParameters: {'offset': offset, 'limit': limit},
      );
      final data = response.data as Map<String, dynamic>;
      final items = data['items'] as List;
      return ApiResponse.success(
        items
            .map((item) => MessageDto.fromJson(item as Map<String, dynamic>))
            .toList(),
      );
    } on DioException catch (e) {
      return ApiResponse.error(ApiException.fromDioException(e));
    } catch (e) {
      return ApiResponse.error(ApiException(message: 'Failed to load messages: $e'));
    }
  }

  @override
  Future<ApiResponse<MessageDto>> sendMessage({
    required int conversationId,
    required String messageText,
    int? attachedProductId,
    List<String> imagePaths = const [],
  }) async {
    try {
      final hasImages = imagePaths.isNotEmpty;
      final payload = {
        'message_text': messageText,
        if (attachedProductId != null) 'attached_product_id': attachedProductId,
      };

      final response = hasImages
          ? await _sendMultipartMessage(conversationId, payload, imagePaths)
          : await _dio.post(
              '/messages/conversation/$conversationId',
              data: payload,
            );
      return ApiResponse.success(
        MessageDto.fromJson(response.data as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      return ApiResponse.error(ApiException.fromDioException(e));
    } catch (e) {
      return ApiResponse.error(ApiException(message: 'Failed to send message: $e'));
    }
  }

  Future<Response<dynamic>> _sendMultipartMessage(
    int conversationId,
    Map<String, dynamic> payload,
    List<String> imagePaths,
  ) async {
    final formData = FormData.fromMap(payload);
    for (final imagePath in imagePaths) {
      formData.files.add(
        MapEntry('images', await MultipartFile.fromFile(imagePath)),
      );
    }

    return _dio.post(
      '/messages/conversation/$conversationId',
      data: formData,
      options: Options(contentType: 'multipart/form-data'),
    );
  }

  @override
  Future<ApiResponse<void>> markMessageAsRead(int messageId) async {
    return _voidCall(
      () => _dio.post('/messages/$messageId/read'),
      'Failed to mark message as read',
    );
  }

  @override
  Future<ApiResponse<void>> deleteConversation(int conversationId) async {
    return _voidCall(
      () => _dio.delete('/conversations/$conversationId'),
      'Failed to delete conversation',
    );
  }

  @override
  Future<ApiResponse<List<ConversationParticipantDto>>> getConversationParticipants(
    int conversationId,
  ) async {
    try {
      final response = await _dio.get('/conversations/$conversationId/participants');
      final items = response.data as List;
      return ApiResponse.success(
        items
            .map((item) => ConversationParticipantDto.fromJson(item as Map<String, dynamic>))
            .toList(),
      );
    } on DioException catch (e) {
      return ApiResponse.error(ApiException.fromDioException(e));
    } catch (e) {
      return ApiResponse.error(ApiException(message: 'Failed to load participants: $e'));
    }
  }

  @override
  Future<ApiResponse<Map<String, dynamic>>> editMessage({
    required int messageId,
    required String messageText,
  }) async {
    try {
      final response = await _dio.patch(
        '/messages/$messageId',
        data: {'message_text': messageText},
      );
      return ApiResponse.success(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      return ApiResponse.error(ApiException.fromDioException(e));
    } catch (e) {
      return ApiResponse.error(ApiException(message: 'Failed to edit message: $e'));
    }
  }

  @override
  Future<ApiResponse<List<int>>> deleteMessages(List<int> messageIds) async {
    try {
      final response = await _dio.post('/messages/delete', data: {'message_ids': messageIds});
      final deleted = (response.data as Map<String, dynamic>)['deleted'] as List? ?? [];
      final ids = deleted
          .map((id) => id is int ? id : int.tryParse('$id') ?? 0)
          .where((id) => id > 0)
          .toList();
      return ApiResponse.success(ids);
    } on DioException catch (e) {
      return ApiResponse.error(ApiException.fromDioException(e));
    } catch (e) {
      return ApiResponse.error(ApiException(message: 'Failed to delete messages: $e'));
    }
  }

  Future<ApiResponse<void>> _voidCall(
    Future<dynamic> Function() fn,
    String errorMessage,
  ) async {
    try {
      await fn();
      return ApiResponse.success(null);
    } on DioException catch (e) {
      return ApiResponse.error(ApiException.fromDioException(e));
    } catch (e) {
      return ApiResponse.error(ApiException(message: '$errorMessage: $e'));
    }
  }
}

