import '../dtos/comment_dto.dart';
import 'seller.dart';

class Comment {
  final int id;
  final String content;
  final int? rating;
  final int userId;
  final int productId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Seller? user;

  const Comment({
    required this.id,
    required this.content,
    this.rating,
    required this.userId,
    required this.productId,
    required this.createdAt,
    required this.updatedAt,
    this.user,
  });

  factory Comment.fromDto(CommentDto dto) {
    return Comment(
      id: dto.id,
      content: dto.content,
      rating: dto.rating,
      userId: dto.userId,
      productId: dto.productId,
      createdAt: dto.createdAt,
      updatedAt: dto.updatedAt,
      user: dto.user != null ? Seller.fromDto(dto.user!) : null,
    );
  }

  Comment copyWith({
    int? id,
    String? content,
    int? rating,
    int? userId,
    int? productId,
    DateTime? createdAt,
    DateTime? updatedAt,
    Seller? user,
  }) {
    return Comment(
      id: id ?? this.id,
      content: content ?? this.content,
      rating: rating ?? this.rating,
      userId: userId ?? this.userId,
      productId: productId ?? this.productId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      user: user ?? this.user,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Comment && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}