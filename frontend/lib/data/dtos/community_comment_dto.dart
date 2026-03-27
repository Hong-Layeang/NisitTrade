import 'seller_dto.dart';

class CommunityCommentDto {
  final int id;
  final int userId;
  final int communityPostId;
  final String content;
  final DateTime createdAt;
  final DateTime updatedAt;
  final SellerDto? user;

  const CommunityCommentDto({
    required this.id,
    required this.userId,
    required this.communityPostId,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
    this.user,
  });

  static DateTime _parseDate(dynamic value) {
    if (value is DateTime) return value;
    if (value is String && value.isNotEmpty) return DateTime.tryParse(value) ?? DateTime.now();
    return DateTime.now();
  }

  factory CommunityCommentDto.fromJson(Map<String, dynamic> json) {
    return CommunityCommentDto(
      id: json['id'] as int? ?? 0,
      userId: (json['user_id'] ?? json['userId']) as int? ?? 0,
      communityPostId: (json['community_post_id'] ?? json['communityPostId']) as int? ?? 0,
      content: (json['content'] ?? '') as String,
      createdAt: _parseDate(json['created_at'] ?? json['createdAt']),
      updatedAt: _parseDate(json['updated_at'] ?? json['updatedAt']),
      user: json['User'] is Map<String, dynamic>
          ? SellerDto.fromJson(json['User'] as Map<String, dynamic>)
          : null,
    );
  }

  CommunityCommentDto copyWith({
    int? id,
    int? userId,
    int? communityPostId,
    String? content,
    DateTime? createdAt,
    DateTime? updatedAt,
    SellerDto? user,
  }) {
    return CommunityCommentDto(
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
