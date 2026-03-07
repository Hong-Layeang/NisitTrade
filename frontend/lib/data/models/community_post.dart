import 'seller.dart';

class CommunityPost {
  final String id;
  final Seller author;
  final String content;
  final String? imageUrl;
  final int likes;
  final int comments;
  final String timeAgo;

  const CommunityPost({
    required this.id,
    required this.author,
    required this.content,
    this.imageUrl,
    required this.likes,
    required this.comments,
    required this.timeAgo,
  });
}
