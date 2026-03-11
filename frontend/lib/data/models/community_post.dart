import 'seller.dart';
import 'community_comment.dart';

class CommunityPost {
  final int id;
  final Seller author;
  final String content;
  final String? imageUrl;
  final List<String> imageUrls;
  final int likesCount;
  final int commentsCount;
  final bool isLikedByMe;
  final int? myLikeId;
  final List<CommunityComment> comments;
  final DateTime createdAt;

  const CommunityPost({
    required this.id,
    required this.author,
    required this.content,
    this.imageUrl,
    this.imageUrls = const [],
    required this.likesCount,
    required this.commentsCount,
    this.isLikedByMe = false,
    this.myLikeId,
    this.comments = const [],
    required this.createdAt,
  });

  List<String> get orderedImages {
    if (imageUrls.isNotEmpty) return imageUrls;
    if (imageUrl != null && imageUrl!.isNotEmpty) return [imageUrl!];
    return const [];
  }

  factory CommunityPost.fromJson(Map<String, dynamic> json) {
    final userJson = json['User'] as Map<String, dynamic>? ?? {};
    final rawList = json['image_urls'];
    final parsedImages = rawList is List
        ? rawList
            .map((item) => item?.toString() ?? '')
            .where((item) => item.isNotEmpty)
            .toList()
        : <String>[];
    final parsedComments = json['comments'] is List
      ? (json['comments'] as List)
        .whereType<Map<String, dynamic>>()
        .map(CommunityComment.fromJson)
        .toList()
      : <CommunityComment>[];

    return CommunityPost(
      id: json['id'] as int? ?? 0,
      author: Seller.fromJson(userJson),
      content: (json['content'] ?? '') as String,
      imageUrl: json['image_url'] as String?,
      imageUrls: parsedImages,
      likesCount: json['likes_count'] as int? ?? 0,
      commentsCount: json['comments_count'] as int? ?? 0,
      isLikedByMe: json['is_liked_by_me'] == true,
      myLikeId: json['my_like_id'] as int?,
      comments: parsedComments,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  CommunityPost copyWith({
    int? id,
    Seller? author,
    String? content,
    String? imageUrl,
    List<String>? imageUrls,
    int? likesCount,
    int? commentsCount,
    bool? isLikedByMe,
    int? myLikeId,
    List<CommunityComment>? comments,
    DateTime? createdAt,
  }) {
    return CommunityPost(
      id: id ?? this.id,
      author: author ?? this.author,
      content: content ?? this.content,
      imageUrl: imageUrl ?? this.imageUrl,
      imageUrls: imageUrls ?? this.imageUrls,
      likesCount: likesCount ?? this.likesCount,
      commentsCount: commentsCount ?? this.commentsCount,
      isLikedByMe: isLikedByMe ?? this.isLikedByMe,
      myLikeId: myLikeId ?? this.myLikeId,
      comments: comments ?? this.comments,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
