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

  static DateTime _parseDate(dynamic value) {
    if (value is DateTime) return value;
    if (value is String && value.isNotEmpty) {
      return DateTime.tryParse(value) ?? DateTime.now();
    }
    return DateTime.now();
  }

  factory CommunityComment.fromJson(Map<String, dynamic> json) {
    return CommunityComment(
      id: json['id'] as int? ?? 0,
      userId: (json['user_id'] ?? json['userId']) as int? ?? 0,
      communityPostId:
          (json['community_post_id'] ?? json['communityPostId']) as int? ?? 0,
      content: (json['content'] ?? '') as String,
      createdAt: _parseDate(json['created_at'] ?? json['createdAt']),
      updatedAt: _parseDate(json['updated_at'] ?? json['updatedAt']),
      user: json['User'] is Map<String, dynamic>
          ? Seller.fromJson(json['User'] as Map<String, dynamic>)
          : null,
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