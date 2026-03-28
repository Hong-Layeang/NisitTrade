import 'category_dto.dart';
import 'seller_dto.dart';
import 'like_dto.dart';
import 'comment_dto.dart';

class ProductDto {
  final int id;
  final String title;
  final String? description;
  final double price;
  final String status;
  final int userId;
  final int categoryId;
  final DateTime createdAt;
  final DateTime updatedAt;

  final SellerDto? user;
  final CategoryDto? category;
  final List<ProductImageDto>? productImages;
  final List<LikeDto> likes;
  final List<CommentDto> comments;
  final int commentCount;

  const ProductDto({
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
    List<LikeDto>? likes,
    List<CommentDto>? comments,
    int? commentCount,
  }) : likes = likes ?? const [],
       comments = comments ?? const [],
       commentCount = commentCount ?? (comments?.length ?? 0);

  static int _toInt(dynamic value, {int fallback = 0}) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? fallback;
    return fallback;
  }

  factory ProductDto.fromJson(Map<String, dynamic> json) {
    final parsedComments = json['Comments'] != null
        ? (json['Comments'] as List)
              .map(
                (comment) =>
                    CommentDto.fromJson(comment as Map<String, dynamic>),
              )
              .toList()
        : <CommentDto>[];
    final parsedCommentCount = _toInt(
      json['comment_count'] ??
          json['comments_count'] ??
          json['commentCount'] ??
          json['commentsCount'],
      fallback: parsedComments.length,
    );

    return ProductDto(
      id: _toInt(json['id']),
      title: (json['title'] ?? '') as String,
      description: json['description'] as String?,
      price: json['price'] != null
          ? double.parse(json['price'].toString())
          : 0.0,
      status: (json['status'] ?? 'available') as String,
      userId: _toInt(json['user_id'] ?? json['userId']),
      categoryId: _toInt(json['category_id'] ?? json['categoryId']),
      createdAt: (json['createdAt'] ?? json['created_at']) != null
          ? DateTime.parse((json['createdAt'] ?? json['created_at']) as String)
          : DateTime.now(),
      updatedAt: (json['updatedAt'] ?? json['updated_at']) != null
          ? DateTime.parse((json['updatedAt'] ?? json['updated_at']) as String)
          : DateTime.now(),
      user: json['User'] != null
          ? SellerDto.fromJson(json['User'] as Map<String, dynamic>)
          : null,
      category: json['Category'] != null
          ? CategoryDto.fromJson(json['Category'] as Map<String, dynamic>)
          : null,
      productImages: json['ProductImages'] != null
          ? (json['ProductImages'] as List)
                .map(
                  (img) =>
                      ProductImageDto.fromJson(img as Map<String, dynamic>),
                )
                .toList()
          : null,
      likes: json['Likes'] != null
          ? (json['Likes'] as List)
                .map((like) => LikeDto.fromJson(like as Map<String, dynamic>))
                .toList()
          : [],
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
      if (productImages != null)
        'ProductImages': productImages!.map((img) => img.toJson()).toList(),
      if (likes.isNotEmpty)
        'Likes': likes.map((like) => like.toJson()).toList(),
      if (comments.isNotEmpty)
        'Comments': comments.map((comment) => comment.toJson()).toList(),
      'comment_count': commentsCount,
    };
  }

  ProductDto copyWith({
    int? id,
    String? title,
    String? description,
    double? price,
    String? status,
    int? userId,
    int? categoryId,
    DateTime? createdAt,
    DateTime? updatedAt,
    SellerDto? user,
    CategoryDto? category,
    List<ProductImageDto>? productImages,
    List<LikeDto>? likes,
    List<CommentDto>? comments,
    int? commentCount,
  }) {
    return ProductDto(
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

  List<String> get imageUrls =>
      productImages?.map((img) => img.imageUrl).toList() ?? [];
  bool get hasImages => productImages != null && productImages!.isNotEmpty;
  String? get firstImageUrl => imageUrls.isNotEmpty ? imageUrls.first : null;
  String? get primaryImageUrl => firstImageUrl;
  int get likesCount => likes.length;
  int get commentsCount =>
      commentCount > comments.length ? commentCount : comments.length;
  List<String> get commentTexts => comments.map((c) => c.content).toList();
  bool get isAvailable => status == 'available';
  bool get isReserved => status == 'reserved';
  bool get isSold => status == 'sold';
  bool get isHidden => status == 'hidden';

  bool isLikedByUser(int? userId) {
    if (userId == null) return false;
    return likes.any((l) => l.userId == userId);
  }

  LikeDto? findUserLike(int? userId) {
    if (userId == null) return null;
    for (final like in likes) {
      if (like.userId == userId) return like;
    }
    return null;
  }

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

  String get sellerName => user?.fullName ?? 'Unknown Seller';
  String? get sellerProfileImage => user?.profileImage;
  String get categoryName => category?.name ?? 'Uncategorized';

  String get formattedPrice {
    final truncated = price.truncateToDouble();
    return truncated == price
        ? '\$${price.toStringAsFixed(0)}'
        : '\$${price.toStringAsFixed(2)}';
  }
}

class ProductImageDto {
  final int id;
  final String imageUrl;
  final int productId;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ProductImageDto({
    required this.id,
    required this.imageUrl,
    required this.productId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ProductImageDto.fromJson(Map<String, dynamic> json) {
    return ProductImageDto(
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

  ProductImageDto copyWith({
    int? id,
    String? imageUrl,
    int? productId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ProductImageDto(
      id: id ?? this.id,
      imageUrl: imageUrl ?? this.imageUrl,
      productId: productId ?? this.productId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
