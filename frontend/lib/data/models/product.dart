import 'category.dart';
import 'seller.dart';
import 'like.dart';
import 'comment.dart';
import '../../domain/entities/product_entity.dart';

class Product {
  final int id;
  final String title;
  final String? description;
  final double price;
  final String status;
  final int userId;
  final int categoryId;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  // Associated data
  final Seller? user;
  final Category? category;
  final List<ProductImage>? productImages;
  final List<Like> likes; // Never null, initialized as empty list
  final List<Comment> comments; // Never null, initialized as empty list
  final int commentCount;

  const Product({
    required this.id,
    required this.title,
    this.description,
    required this.price,
    required this.status,
    required this.userId,
    required this.categoryId,
    required this.createdAt,
    required this.updatedAt,
    this.user,
    this.category,
    this.productImages,
    List<Like>? likes,
    List<Comment>? comments,
    int? commentCount,
  })  : likes = likes ?? const [],
        comments = comments ?? const [],
        commentCount = commentCount ?? (comments?.length ?? 0);

  static int _toInt(dynamic value, {int fallback = 0}) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) {
      return int.tryParse(value) ?? fallback;
    }
    return fallback;
  }

  factory Product.fromJson(Map<String, dynamic> json) {
    final parsedComments = json['Comments'] != null
        ? (json['Comments'] as List)
            .map((comment) => Comment.fromJson(comment as Map<String, dynamic>))
            .toList()
        : <Comment>[];
    final parsedCommentCount = _toInt(
      json['comment_count'] ??
          json['comments_count'] ??
          json['commentCount'] ??
          json['commentsCount'],
      fallback: parsedComments.length,
    );

    return Product(
      id: json['id'] as int? ?? 0,
      title: (json['title'] ?? '') as String,
      description: json['description'] as String?,
      price: json['price'] != null ? double.parse(json['price'].toString()) : 0.0,
      status: (json['status'] ?? 'available') as String,
      userId: json['user_id'] as int? ?? 0,
      categoryId: json['category_id'] as int? ?? 0,
      createdAt: (json['createdAt'] ?? json['created_at']) != null 
          ? DateTime.parse((json['createdAt'] ?? json['created_at']) as String)
          : DateTime.now(),
      updatedAt: (json['updatedAt'] ?? json['updated_at']) != null 
          ? DateTime.parse((json['updatedAt'] ?? json['updated_at']) as String)
          : DateTime.now(),
      user: json['User'] != null ? Seller.fromJson(json['User'] as Map<String, dynamic>) : null,
      category: json['Category'] != null ? Category.fromJson(json['Category'] as Map<String, dynamic>) : null,
      productImages: json['ProductImages'] != null
          ? (json['ProductImages'] as List).map((img) => ProductImage.fromJson(img as Map<String, dynamic>)).toList()
          : null,
      likes: json['Likes'] != null
          ? (json['Likes'] as List).map((like) => Like.fromJson(like as Map<String, dynamic>)).toList()
          : [], // Initialize as empty list instead of null
        comments: parsedComments,
        commentCount: parsedCommentCount,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'price': price,
      'status': status,
      'user_id': userId,
      'category_id': categoryId,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      if (user != null) 'User': user!.toJson(),
      if (category != null) 'Category': category!.toJson(),
      if (productImages != null) 'ProductImages': productImages!.map((img) => img.toJson()).toList(),
      if (likes.isNotEmpty) 'Likes': likes.map((like) => like.toJson()).toList(),
      if (comments.isNotEmpty) 'Comments': comments.map((comment) => comment.toJson()).toList(),
      'comment_count': commentsCount,
    };
  }

  Product copyWith({
    int? id,
    String? title,
    String? description,
    double? price,
    String? status,
    int? userId,
    int? categoryId,
    DateTime? createdAt,
    DateTime? updatedAt,
    Seller? user,
    Category? category,
    List<ProductImage>? productImages,
    List<Like>? likes,
    List<Comment>? comments,
    int? commentCount,
  }) {
    return Product(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      price: price ?? this.price,
      status: status ?? this.status,
      userId: userId ?? this.userId,
      categoryId: categoryId ?? this.categoryId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      user: user ?? this.user,
      category: category ?? this.category,
      productImages: productImages ?? this.productImages,
      likes: likes ?? this.likes,
      comments: comments ?? this.comments,
      commentCount: commentCount ?? this.commentCount,
    );
  }

  // ============================================================================
  // CONVENIENCE GETTERS FOR FRONTEND USE
  // ============================================================================

  /// Get list of image URLs from product images
  List<String> get imageUrls => productImages?.map((img) => img.imageUrl).toList() ?? [];

  /// Check if product has images
  bool get hasImages => productImages != null && productImages!.isNotEmpty;

  /// Get the first image URL or null
  String? get firstImageUrl => imageUrls.isNotEmpty ? imageUrls.first : null;

  /// Get number of likes
  int get likesCount => likes.length;

  /// Get number of comments
  int get commentsCount => commentCount > comments.length ? commentCount : comments.length;

  /// Get list of comment texts
  List<String> get commentTexts => comments.map((c) => c.content).toList();

  /// Check if product is available for purchase
  bool get isAvailable => status == 'available';

  /// Check if product is reserved
  bool get isReserved => status == 'reserved';

  /// Check if product is sold
  bool get isSold => status == 'sold';

  /// Check if product is hidden
  bool get isHidden => status == 'hidden';

  /// Get human-readable status
  String get statusLabel {
    switch (status) {
      case 'available':
        return 'Available';
      case 'reserved':
        return 'Reserved';
      case 'sold':
        return 'Sold';
      case 'hidden':
        return 'Hidden';
      default:
        return status;
    }
  }

  /// Get seller name
  String get sellerName => user?.fullName ?? 'Unknown Seller';

  /// Get seller profile image URL
  String? get sellerProfileImage => user?.profileImage;

  /// Get category name
  String get categoryName => category?.name ?? 'Uncategorized';

  /// Format price for display — decimals only when non-zero
  String get formattedPrice {
    final truncated = price.truncateToDouble();
    return truncated == price
        ? '\$${price.toStringAsFixed(0)}'
        : '\$${price.toStringAsFixed(2)}';
  }

  /// Get time ago from creation
  String get timeAgo => _formatTimeAgo(createdAt);

  /// Calculate days since creation
  int get daysSinceCreated => DateTime.now().difference(createdAt).inDays;

  /// Check if product is brand new (created within 24 hours)
  bool get isBrandNew => daysSinceCreated == 0;

  /// Check if product is from the current or last week
  bool get isRecent => daysSinceCreated <= 7;

  /// Private helper to format time ago
  static String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) {
      return 'just now';
    } else if (difference.inMinutes < 60) {
      final minutes = difference.inMinutes;
      return '$minutes ${minutes == 1 ? 'minute' : 'minutes'} ago';
    } else if (difference.inHours < 24) {
      final hours = difference.inHours;
      return '$hours ${hours == 1 ? 'hour' : 'hours'} ago';
    } else if (difference.inDays < 7) {
      final days = difference.inDays;
      return '$days ${days == 1 ? 'day' : 'days'} ago';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return '$weeks ${weeks == 1 ? 'week' : 'weeks'} ago';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return '$months ${months == 1 ? 'month' : 'months'} ago';
    } else {
      final years = (difference.inDays / 365).floor();
      return '$years ${years == 1 ? 'year' : 'years'} ago';
    }
  }

  /// Convert to domain entity
  ProductEntity toEntity() {
    return ProductEntity(
      id: id,
      title: title,
      description: description,
      price: price,
      status: ProductStatus.fromString(status),
      userId: userId,
      categoryId: categoryId,
      createdAt: createdAt,
      updatedAt: updatedAt,
      seller: user?.toEntity(),
      category: category?.toEntity(),
      imageUrls: imageUrls,
      likes: likes
          .map((like) => ProductLikeEntity(id: like.id, userId: like.userId))
          .toList(),
      likeCount: likes.length,
      comments: comments
          .map(
            (comment) => ProductCommentEntity(
              id: comment.id,
              content: comment.content,
              userId: comment.userId,
              productId: comment.productId,
              createdAt: comment.createdAt,
              updatedAt: comment.updatedAt,
              user: comment.user?.toEntity(),
            ),
          )
          .toList(),
      commentCount: commentsCount,
      isLiked: false,
    );
  }

  /// Create from domain entity
  factory Product.fromEntity(ProductEntity entity) {
    final mappedImages = entity.imageUrls
        .where((url) => url.trim().isNotEmpty)
        .toList(growable: false);
    final mappedLikes = entity.likes
        .map(
          (like) => Like(
            id: like.id,
            userId: like.userId,
            productId: entity.id,
            createdAt: entity.updatedAt,
            updatedAt: entity.updatedAt,
          ),
        )
        .toList(growable: false);

    return Product(
      id: entity.id,
      title: entity.title,
      description: entity.description,
      price: entity.price,
      status: entity.status.toValue(),
      userId: entity.userId,
      categoryId: entity.categoryId,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      user: entity.seller != null ? Seller.fromEntity(entity.seller!) : null,
      category: entity.category != null ? Category.fromEntity(entity.category!) : null,
      productImages: mappedImages.isEmpty
          ? null
          : List<ProductImage>.generate(
              mappedImages.length,
              (index) {
                final now = DateTime.now();
                return ProductImage(
                  id: index + 1,
                  imageUrl: mappedImages[index],
                  productId: entity.id,
                  createdAt: now,
                  updatedAt: now,
                );
              },
            ),
      likes: mappedLikes,
      comments: entity.comments
          .map(
            (comment) => Comment(
              id: comment.id,
              content: comment.content,
              userId: comment.userId,
              productId: comment.productId,
              createdAt: comment.createdAt,
              updatedAt: comment.updatedAt,
              user: comment.user != null ? Seller.fromEntity(comment.user!) : null,
            ),
          )
          .toList(growable: false),
      commentCount: entity.commentCount,
    );
  }
}

class ProductImage {
  final int id;
  final String imageUrl;
  final int productId;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ProductImage({
    required this.id,
    required this.imageUrl,
    required this.productId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ProductImage.fromJson(Map<String, dynamic> json) {
    return ProductImage(
      id: json['id'] as int? ?? 0,
      imageUrl: (json['image_url'] ?? '') as String,
      productId: json['product_id'] as int? ?? 0,
      createdAt: (json['createdAt'] ?? json['created_at']) != null
          ? DateTime.parse((json['createdAt'] ?? json['created_at']) as String)
          : DateTime.now(),
      updatedAt: (json['updatedAt'] ?? json['updated_at']) != null
          ? DateTime.parse((json['updatedAt'] ?? json['updated_at']) as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'image_url': imageUrl,
      'product_id': productId,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  ProductImage copyWith({
    int? id,
    String? imageUrl,
    int? productId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ProductImage(
      id: id ?? this.id,
      imageUrl: imageUrl ?? this.imageUrl,
      productId: productId ?? this.productId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

extension ProductEntityToModelX on ProductEntity {
  Product toModel() => Product.fromEntity(this);
}

extension ProductEntityIterableToModelX on Iterable<ProductEntity> {
  List<Product> toModels() => map((entity) => entity.toModel()).toList();
}
