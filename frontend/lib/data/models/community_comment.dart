import '../dtos/community_comment_dto.dart';
import 'seller.dart';

class CommunityComment {
  final int id;
  final int userId;
  final int communityPostId;
  final String content;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Seller? user;

  const CommunityComment({
    required this.id,
    required this.userId,
    required this.communityPostId,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
    this.user,
  });

  factory CommunityComment.fromDto(CommunityCommentDto dto) {
    return CommunityComment(
      id: dto.id,
      userId: dto.userId,
      communityPostId: dto.communityPostId,
      content: dto.content,
      createdAt: dto.createdAt,
      updatedAt: dto.updatedAt,
      user: dto.user != null ? Seller.fromDto(dto.user!) : null,
    );
  }

  CommunityComment copyWith({
    int? id,
    int? userId,
    int? communityPostId,
    String? content,
    DateTime? createdAt,
    DateTime? updatedAt,
    Seller? user,
  }) {
    return CommunityComment(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      communityPostId: communityPostId ?? this.communityPostId,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      user: user ?? this.user,
    );
  }
}