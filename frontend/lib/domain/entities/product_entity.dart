import 'package:equatable/equatable.dart';
import 'category_entity.dart';
import 'seller_entity.dart';

class ProductLikeEntity extends Equatable {
  final int id;
  final int userId;

  const ProductLikeEntity({
    required this.id,
    required this.userId,
  });

  @override
  List<Object?> get props => [id, userId];
}

class ProductCommentEntity extends Equatable {
  final int id;
  final String content;
  final int userId;
  final int productId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final SellerEntity? user;

  const ProductCommentEntity({
    required this.id,
    required this.content,
    required this.userId,
    required this.productId,
    required this.createdAt,
    required this.updatedAt,
    this.user,
  });

  @override
  List<Object?> get props => [id, content, userId, productId, createdAt, updatedAt, user];
}

/// Domain entity representing a product
class ProductEntity extends Equatable {
  final int id;
  final String title;
  final String? description;
  final double price;
  final ProductStatus status;
  final int userId;
  final int categoryId;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  // Associated data
  final SellerEntity? seller;
  final CategoryEntity? category;
  final List<String> imageUrls;
  final List<ProductLikeEntity> likes;
  final List<ProductCommentEntity> comments;
  final int likeCount;
  final int commentCount;
  final bool isLiked;

  const ProductEntity({
    required this.id,
    required this.title,
    this.description,
    required this.price,
    required this.status,
    required this.userId,
    required this.categoryId,
    required this.createdAt,
    required this.updatedAt,
    this.seller,
    this.category,
    this.imageUrls = const [],
    this.likes = const [],
    this.comments = const [],
    this.likeCount = 0,
    this.commentCount = 0,
    this.isLiked = false,
  });

  /// Returns the first image URL if available
  String? get primaryImageUrl => imageUrls.isNotEmpty ? imageUrls.first : null;

  /// Alias for primaryImageUrl for backward compatibility
  String? get firstImageUrl => primaryImageUrl;

  /// Returns true if the product has images
  bool get hasImages => imageUrls.isNotEmpty;

  /// Returns true if the product is available for purchase
  bool get isAvailable => status == ProductStatus.available;

  /// Returns true if the product is sold
  bool get isSold => status == ProductStatus.sold;

  /// Returns true if the product is hidden
  bool get isHidden => status == ProductStatus.hidden;

  /// Returns formatted price with currency
  String get formattedPrice => '\$${price.toStringAsFixed(2)}';

  /// Returns a short description (first 100 characters)
  String? get shortDescription {
    if (description == null || description!.isEmpty) return null;
    return description!.length > 100 
        ? '${description!.substring(0, 100)}...' 
        : description;
  }

  /// Returns time ago from creation
  String get timeAgo {
    final difference = DateTime.now().difference(createdAt);
    if (difference.inDays > 365) {
      return '${(difference.inDays / 365).floor()}y ago';
    } else if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()}mo ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  /// Returns number of likes (alias for compatibility)
  int get likesCount => likeCount;

  /// Returns number of comments (alias for compatibility)
  int get commentsCount => commentCount;

  @override
  List<Object?> get props => [
    id, title, description, price, status, userId, categoryId,
    createdAt, updatedAt, seller, category, imageUrls, 
    likes, comments, likeCount, commentCount, isLiked
  ];
}

/// Enum representing product status
enum ProductStatus {
  available,
  sold,
  pending,
  hidden;

  static ProductStatus fromString(String status) {
    switch (status.toLowerCase()) {
      case 'available':
        return ProductStatus.available;
      case 'sold':
        return ProductStatus.sold;
      case 'pending':
        return ProductStatus.pending;
      case 'hidden':
        return ProductStatus.hidden;
      default:
        return ProductStatus.available;
    }
  }

  String toValue() {
    switch (this) {
      case ProductStatus.available:
        return 'available';
      case ProductStatus.sold:
        return 'sold';
      case ProductStatus.pending:
        return 'pending';
      case ProductStatus.hidden:
        return 'hidden';
    }
  }
}
