import 'product_dto.dart';
import 'student_dto.dart';

class ConversationDto {
  final int id;
  final int? productId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int unreadCount;
  final bool isBlockedByMe;
  final bool hasBlockedMe;
  final ProductDto? product;
  final List<ConversationParticipantDto>? participants;
  final MessageDto? lastMessage;

  const ConversationDto({
    required this.id,
    this.productId,
    required this.createdAt,
    required this.updatedAt,
    this.unreadCount = 0,
    this.isBlockedByMe = false,
    this.hasBlockedMe = false,
    this.product,
    this.participants,
    this.lastMessage,
  });

  bool get isMessagingBlocked => isBlockedByMe || hasBlockedMe;

  ConversationDto copyWith({
    int? unreadCount,
    DateTime? updatedAt,
    ProductDto? product,
    List<ConversationParticipantDto>? participants,
    MessageDto? lastMessage,
    bool clearLastMessage = false,
    bool? isBlockedByMe,
    bool? hasBlockedMe,
  }) {
    return ConversationDto(
      id: id,
      productId: productId,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      unreadCount: unreadCount ?? this.unreadCount,
      isBlockedByMe: isBlockedByMe ?? this.isBlockedByMe,
      hasBlockedMe: hasBlockedMe ?? this.hasBlockedMe,
      product: product ?? this.product,
      participants: participants ?? this.participants,
      lastMessage: clearLastMessage ? null : lastMessage ?? this.lastMessage,
    );
  }

  static int _toInt(dynamic value, {int fallback = 0}) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? fallback;
    return fallback;
  }

  factory ConversationDto.fromJson(Map<String, dynamic> json) {
    final baseConversation = (json['Conversation'] is Map<String, dynamic>)
        ? json['Conversation'] as Map<String, dynamic>
        : json;
    final productJson = baseConversation['Product'] ??
        baseConversation['product'] ??
        json['Product'] ??
        json['product'];
    final participantsJson = json['ConversationParticipants'] ??
        baseConversation['ConversationParticipants'] ??
        json['participants'] ??
        [];
    final lastMessageJson = json['last_message'] ??
        json['lastMessage'] ??
        baseConversation['last_message'] ??
        baseConversation['lastMessage'];

    return ConversationDto(
      id: _toInt(baseConversation['id'] ?? json['conversation_id'] ?? json['id']),
      productId: (baseConversation['product_id'] ?? json['product_id']) != null
          ? _toInt(baseConversation['product_id'] ?? json['product_id'])
          : null,
      createdAt: DateTime.parse(
        baseConversation['createdAt'] ??
            baseConversation['created_at'] ??
            json['createdAt'] ??
            json['created_at'] ??
            DateTime.now().toIso8601String(),
      ),
      updatedAt: DateTime.parse(
        baseConversation['updatedAt'] ??
            baseConversation['updated_at'] ??
            json['updatedAt'] ??
            json['updated_at'] ??
            DateTime.now().toIso8601String(),
      ),
      unreadCount: _toInt(
        json['unread_count'] ??
            json['unreadCount'] ??
            baseConversation['unread_count'] ??
            baseConversation['unreadCount'],
        fallback: 0,
      ),
      isBlockedByMe: (json['is_blocked_by_me'] ??
              json['isBlockedByMe'] ??
              baseConversation['is_blocked_by_me'] ??
              baseConversation['isBlockedByMe'] ??
              false) ==
          true,
      hasBlockedMe: (json['has_blocked_me'] ??
              json['hasBlockedMe'] ??
              baseConversation['has_blocked_me'] ??
              baseConversation['hasBlockedMe'] ??
              false) ==
          true,
      product: productJson != null
          ? ProductDto.fromJson(productJson as Map<String, dynamic>)
          : null,
      participants: participantsJson is List
          ? participantsJson
              .map((p) => ConversationParticipantDto.fromJson(
                  p as Map<String, dynamic>))
              .toList()
          : null,
      lastMessage: lastMessageJson != null
          ? MessageDto.fromJson(lastMessageJson as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'product_id': productId,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'unread_count': unreadCount,
        'is_blocked_by_me': isBlockedByMe,
        'has_blocked_me': hasBlockedMe,
      };
}

class ConversationParticipantDto {
  final int id;
  final int conversationId;
  final int userId;
  final DateTime joinedAt;
  final StudentDto? user;

  const ConversationParticipantDto({
    required this.id,
    required this.conversationId,
    required this.userId,
    required this.joinedAt,
    this.user,
  });

  static int _toInt(dynamic value, {int fallback = 0}) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? fallback;
    return fallback;
  }

  factory ConversationParticipantDto.fromJson(Map<String, dynamic> json) {
    final userJson = json['User'] ?? json['user'];

    return ConversationParticipantDto(
      id: _toInt(json['id']),
      conversationId: _toInt(json['conversation_id'] ?? json['conversationId']),
      userId: _toInt(json['user_id'] ?? json['userId']),
      joinedAt: DateTime.parse(
          json['joined_at'] ?? json['joinedAt'] ?? DateTime.now().toIso8601String()),
      user: userJson != null
          ? StudentDto.fromJson(userJson as Map<String, dynamic>)
          : null,
    );
  }
}

class MessageDto {
  final int id;
  final String messageText;
  final int senderId;
  final int conversationId;
  final int? attachedProductId;
  final DateTime sentAt;
  final DateTime? editedAt;
  final List<int> readBy;
  final List<String> imageUrls;
  final ProductDto? attachedProduct;
  final StudentDto? sender;

  const MessageDto({
    required this.id,
    required this.messageText,
    required this.senderId,
    required this.conversationId,
    this.attachedProductId,
    required this.sentAt,
    this.editedAt,
    this.readBy = const [],
    this.imageUrls = const [],
    this.attachedProduct,
    this.sender,
  });

  bool isReadBy(int userId) => readBy.contains(userId);
  bool get isEdited => editedAt != null;
  bool get hasImages => imageUrls.isNotEmpty;

  MessageDto copyWith({
    String? messageText,
    DateTime? editedAt,
    List<int>? readBy,
    int? attachedProductId,
  }) {
    return MessageDto(
      id: id,
      messageText: messageText ?? this.messageText,
      senderId: senderId,
      conversationId: conversationId,
      attachedProductId: attachedProductId ?? this.attachedProductId,
      sentAt: sentAt,
      editedAt: editedAt ?? this.editedAt,
      readBy: readBy ?? this.readBy,
      imageUrls: imageUrls,
      attachedProduct: attachedProduct,
      sender: sender,
    );
  }

  static int _toInt(dynamic value, {int fallback = 0}) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? fallback;
    return fallback;
  }

  factory MessageDto.fromJson(Map<String, dynamic> json) {
    final senderJson = json['User'] ?? json['user'];
    final attachedProductJson =
        json['AttachedProduct'] ?? json['attached_product'];
    final readByData = json['MessageReads'] ?? json['message_reads'] ?? [];

    List<int> readByList = [];
    if (readByData is List) {
      readByList = readByData
          .map((read) {
            final userId = read is Map ? read['user_id'] ?? read['userId'] : read;
            return _toInt(userId);
          })
          .where((id) => id > 0)
          .toList();
    }

    final imageUrlsData = json['image_urls'] ?? json['imageUrls'] ?? [];
    final parsedImageUrls = imageUrlsData is List
        ? imageUrlsData
            .map((item) => item?.toString() ?? '')
            .where((item) => item.trim().isNotEmpty)
            .toList(growable: false)
        : const <String>[];

    final rawEditedAt = json['edited_at'] ?? json['editedAt'];

    return MessageDto(
      id: _toInt(json['id']),
      messageText: (json['message_text'] ?? json['messageText'] ?? '') as String,
      senderId: _toInt(json['sender_id'] ?? json['senderId']),
      conversationId: _toInt(json['conversation_id'] ?? json['conversationId']),
      attachedProductId: (json['attached_product_id'] ?? json['attachedProductId']) != null
        ? _toInt(json['attached_product_id'] ?? json['attachedProductId'])
        : (attachedProductJson is Map<String, dynamic>
          ? _toInt(attachedProductJson['id'], fallback: 0)
          : 0) > 0
        ? _toInt((attachedProductJson as Map<String, dynamic>)['id'])
        : null,
      sentAt: DateTime.parse(
          json['sent_at'] ?? json['sentAt'] ?? DateTime.now().toIso8601String()),
      editedAt: rawEditedAt is String && rawEditedAt.isNotEmpty
          ? DateTime.tryParse(rawEditedAt)
          : null,
      readBy: readByList,
      imageUrls: parsedImageUrls,
      attachedProduct: attachedProductJson != null
          ? ProductDto.fromJson(attachedProductJson as Map<String, dynamic>)
          : null,
      sender: senderJson != null
          ? StudentDto.fromJson(senderJson as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'message_text': messageText,
        'sender_id': senderId,
        'conversation_id': conversationId,
        'attached_product_id': attachedProductId,
        'sent_at': sentAt.toIso8601String(),
        'edited_at': editedAt?.toIso8601String(),
        'image_urls': imageUrls,
      };
}
