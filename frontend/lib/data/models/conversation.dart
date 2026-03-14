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
    final productJson = json['Product'] ?? json['product'];
    final participantsJson = json['ConversationParticipants'] ?? json['participants'] ?? [];
    
    return Conversation(
      id: _toInt(json['id']),
      productId: json['product_id'] != null ? _toInt(json['product_id']) : null,
      createdAt: DateTime.parse(json['createdAt'] ?? json['created_at'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updatedAt'] ?? json['updated_at'] ?? DateTime.now().toIso8601String()),
      unreadCount: _toInt(json['unread_count'] ?? json['unreadCount'], fallback: 0),
      product: productJson != null ? Product.fromJson(productJson as Map<String, dynamic>) : null,
      participants: participantsJson is List
          ? participantsJson
              .map((p) => ConversationParticipant.fromJson(p as Map<String, dynamic>))
              .toList()
          : null,
      lastMessage: json['lastMessage'] != null 
          ? Message.fromJson(json['lastMessage'] as Map<String, dynamic>)
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

  // Associated data
  final Student? sender;

  const Message({
    required this.id,
    required this.messageText,
    required this.senderId,
    required this.conversationId,
    required this.sentAt,
    this.readBy = const [],
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

    return Message(
      id: _toInt(json['id']),
      messageText: (json['message_text'] ?? json['messageText'] ?? '') as String,
      senderId: _toInt(json['sender_id'] ?? json['senderId']),
      conversationId: _toInt(json['conversation_id'] ?? json['conversationId']),
      sentAt: DateTime.parse(json['sent_at'] ?? json['sentAt'] ?? DateTime.now().toIso8601String()),
      readBy: readByList,
      sender: senderJson != null ? Student.fromJson(senderJson as Map<String, dynamic>) : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'message_text': messageText,
    'sender_id': senderId,
    'conversation_id': conversationId,
    'sent_at': sentAt.toIso8601String(),
  };
}
