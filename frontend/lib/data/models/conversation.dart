import '../dtos/conversation_dto.dart';
import 'product.dart';
import 'student.dart';

class Conversation {
  final int id;
  final int? productId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int unreadCount;
  final bool isBlockedByMe;
  final bool hasBlockedMe;
  final Product? product;
  final List<ConversationParticipant>? participants;
  final Message? lastMessage;

  const Conversation({
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

  factory Conversation.fromDto(ConversationDto dto) {
    return Conversation(
      id: dto.id,
      productId: dto.productId,
      createdAt: dto.createdAt,
      updatedAt: dto.updatedAt,
      unreadCount: dto.unreadCount,
      isBlockedByMe: dto.isBlockedByMe,
      hasBlockedMe: dto.hasBlockedMe,
      product: dto.product != null ? Product.fromDto(dto.product!) : null,
      participants: dto.participants?.map(ConversationParticipant.fromDto).toList(growable: false),
      lastMessage: dto.lastMessage != null ? Message.fromDto(dto.lastMessage!) : null,
    );
  }

  Conversation copyWith({
    int? unreadCount,
    DateTime? updatedAt,
    Product? product,
    List<ConversationParticipant>? participants,
    Message? lastMessage,
    bool clearLastMessage = false,
    bool? isBlockedByMe,
    bool? hasBlockedMe,
  }) {
    return Conversation(
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
}

class ConversationParticipant {
  final int id;
  final int conversationId;
  final int userId;
  final DateTime joinedAt;
  final Student? user;

  const ConversationParticipant({
    required this.id,
    required this.conversationId,
    required this.userId,
    required this.joinedAt,
    this.user,
  });

  factory ConversationParticipant.fromDto(ConversationParticipantDto dto) {
    return ConversationParticipant(
      id: dto.id,
      conversationId: dto.conversationId,
      userId: dto.userId,
      joinedAt: dto.joinedAt,
      user: dto.user != null ? Student.fromDto(dto.user!) : null,
    );
  }
}

class Message {
  final int id;
  final String messageText;
  final int senderId;
  final int conversationId;
  final DateTime sentAt;
  final DateTime? editedAt;
  final List<int> readBy;
  final List<String> imageUrls;
  final Product? attachedProduct;
  final Student? sender;

  const Message({
    required this.id,
    required this.messageText,
    required this.senderId,
    required this.conversationId,
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

  factory Message.fromDto(MessageDto dto) {
    return Message(
      id: dto.id,
      messageText: dto.messageText,
      senderId: dto.senderId,
      conversationId: dto.conversationId,
      sentAt: dto.sentAt,
      editedAt: dto.editedAt,
      readBy: dto.readBy,
      imageUrls: dto.imageUrls,
      attachedProduct: dto.attachedProduct != null ? Product.fromDto(dto.attachedProduct!) : null,
      sender: dto.sender != null ? Student.fromDto(dto.sender!) : null,
    );
  }

  Message copyWith({
    String? messageText,
    DateTime? editedAt,
    List<int>? readBy,
  }) {
    return Message(
      id: id,
      messageText: messageText ?? this.messageText,
      senderId: senderId,
      conversationId: conversationId,
      sentAt: sentAt,
      editedAt: editedAt ?? this.editedAt,
      readBy: readBy ?? this.readBy,
      imageUrls: imageUrls,
      attachedProduct: attachedProduct,
      sender: sender,
    );
  }
}