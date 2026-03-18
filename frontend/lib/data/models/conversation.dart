import 'product.dart';
import 'student.dart';

class Conversation {
  final int id;
  final int? productId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int unreadCount;
  
  // Associated data
  final Product? product;
  final List<ConversationParticipant>? participants;
  final Message? lastMessage;

  const Conversation({
    required this.id,
    this.productId,
    required this.createdAt,
    required this.updatedAt,
    this.unreadCount = 0,
    this.product,
    this.participants,
    this.lastMessage,
  });

  static int _toInt(dynamic value, {int fallback = 0}) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) {
      return int.tryParse(value) ?? fallback;
    }
    return fallback;
  }

  factory Conversation.fromJson(Map<String, dynamic> json) {
    final baseConversation =
      (json['Conversation'] is Map<String, dynamic>) ? json['Conversation'] as Map<String, dynamic> : json;
    final productJson =
      baseConversation['Product'] ?? baseConversation['product'] ?? json['Product'] ?? json['product'];
    final participantsJson =
      json['ConversationParticipants'] ?? baseConversation['ConversationParticipants'] ?? json['participants'] ?? [];
    final lastMessageJson =
      json['last_message'] ?? json['lastMessage'] ?? baseConversation['last_message'] ?? baseConversation['lastMessage'];
    
    return Conversation(
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
      product: productJson != null ? Product.fromJson(productJson as Map<String, dynamic>) : null,
      participants: participantsJson is List
          ? participantsJson
              .map((p) => ConversationParticipant.fromJson(p as Map<String, dynamic>))
              .toList()
          : null,
      lastMessage: lastMessageJson != null
          ? Message.fromJson(lastMessageJson as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'product_id': productId,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'unread_count': unreadCount,
  };
}

class ConversationParticipant {
  final int id;
  final int conversationId;
  final int userId;
  final DateTime joinedAt;
  
  // Associated data
  final Student? user;

  const ConversationParticipant({
    required this.id,
    required this.conversationId,
    required this.userId,
    required this.joinedAt,
    this.user,
  });

  static int _toInt(dynamic value, {int fallback = 0}) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) {
      return int.tryParse(value) ?? fallback;
    }
    return fallback;
  }

  factory ConversationParticipant.fromJson(Map<String, dynamic> json) {
    final userJson = json['User'] ?? json['user'];
    
    return ConversationParticipant(
      id: _toInt(json['id']),
      conversationId: _toInt(json['conversation_id'] ?? json['conversationId']),
      userId: _toInt(json['user_id'] ?? json['userId']),
      joinedAt: DateTime.parse(json['joined_at'] ?? json['joinedAt'] ?? DateTime.now().toIso8601String()),
      user: userJson != null ? Student.fromJson(userJson as Map<String, dynamic>) : null,
    );
  }
}

class Message {
  final int id;
  final String messageText;
  final int senderId;
  final int conversationId;
  final DateTime sentAt;
  final List<int> readBy; // List of user IDs who have read this message
  final List<String> imageUrls;
  final Product? attachedProduct;

  // Associated data
  final Student? sender;

  const Message({
    required this.id,
    required this.messageText,
    required this.senderId,
    required this.conversationId,
    required this.sentAt,
    this.readBy = const [],
    this.imageUrls = const [],
    this.attachedProduct,
    this.sender,
  });

  static int _toInt(dynamic value, {int fallback = 0}) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) {
      return int.tryParse(value) ?? fallback;
    }
    return fallback;
  }

  // Check if message is read by a specific user
  bool isReadBy(int userId) => readBy.contains(userId);

  factory Message.fromJson(Map<String, dynamic> json) {
    final senderJson = json['User'] ?? json['user'];
    final attachedProductJson = json['AttachedProduct'] ?? json['attached_product'];
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

    return Message(
      id: _toInt(json['id']),
      messageText: (json['message_text'] ?? json['messageText'] ?? '') as String,
      senderId: _toInt(json['sender_id'] ?? json['senderId']),
      conversationId: _toInt(json['conversation_id'] ?? json['conversationId']),
      sentAt: DateTime.parse(json['sent_at'] ?? json['sentAt'] ?? DateTime.now().toIso8601String()),
      readBy: readByList,
      imageUrls: parsedImageUrls,
      attachedProduct: attachedProductJson != null
          ? Product.fromJson(attachedProductJson as Map<String, dynamic>)
          : null,
      sender: senderJson != null ? Student.fromJson(senderJson as Map<String, dynamic>) : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'message_text': messageText,
    'sender_id': senderId,
    'conversation_id': conversationId,
    'sent_at': sentAt.toIso8601String(),
    'image_urls': imageUrls,
  };

  bool get hasImages => imageUrls.isNotEmpty;
}
