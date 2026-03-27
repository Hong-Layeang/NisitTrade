import '../dtos/community_post_dto.dart';
import 'community_comment.dart';
import 'seller.dart';

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
  final bool isSavedByMe;
  final int? mySavedId;
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
    this.isSavedByMe = false,
    this.mySavedId,
    this.comments = const [],
    required this.createdAt,
  });

  List<String> get orderedImages {
    if (imageUrls.isNotEmpty) return imageUrls;
    if (imageUrl != null && imageUrl!.isNotEmpty) return [imageUrl!];
    return const [];
  }

  factory CommunityPost.fromDto(CommunityPostDto dto) {
    return CommunityPost(
      id: dto.id,
      author: Seller.fromDto(dto.author),
      content: dto.content,
      imageUrl: dto.imageUrl,
      imageUrls: dto.imageUrls,
      likesCount: dto.likesCount,
      commentsCount: dto.commentsCount,
      isLikedByMe: dto.isLikedByMe,
      myLikeId: dto.myLikeId,
      isSavedByMe: dto.isSavedByMe,
      mySavedId: dto.mySavedId,
      comments: dto.comments.map(CommunityComment.fromDto).toList(growable: false),
      createdAt: dto.createdAt,
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
    bool? isSavedByMe,
    int? mySavedId,
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
      isSavedByMe: isSavedByMe ?? this.isSavedByMe,
      mySavedId: mySavedId ?? this.mySavedId,
      comments: comments ?? this.comments,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}