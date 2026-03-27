import '../dtos/product_dto.dart';
import 'category.dart';
import 'comment.dart';
import 'like.dart';
import 'seller.dart';

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
  final Seller? user;
  final Category? category;
  final List<ProductImage>? productImages;
  final List<Like> likes;
  final List<Comment> comments;
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

  factory Product.fromDto(ProductDto dto) {
    return Product(
      id: dto.id,
      title: dto.title,
      description: dto.description,
      price: dto.price,
      status: dto.status,
      userId: dto.userId,
      categoryId: dto.categoryId,
      createdAt: dto.createdAt,
      updatedAt: dto.updatedAt,
      user: dto.user != null ? Seller.fromDto(dto.user!) : null,
      category: dto.category != null ? Category.fromDto(dto.category!) : null,
      productImages: dto.productImages?.map(ProductImage.fromDto).toList(growable: false),
      likes: dto.likes.map(Like.fromDto).toList(growable: false),
      comments: dto.comments.map(Comment.fromDto).toList(growable: false),
      commentCount: dto.commentCount,
    );
  }

  List<String> get imageUrls => productImages?.map((img) => img.imageUrl).toList() ?? [];
  bool get hasImages => productImages != null && productImages!.isNotEmpty;
  String? get firstImageUrl => imageUrls.isNotEmpty ? imageUrls.first : null;
  String? get primaryImageUrl => firstImageUrl;
  int get likesCount => likes.length;
  int get commentsCount => commentCount > comments.length ? commentCount : comments.length;
  List<String> get commentTexts => comments.map((c) => c.content).toList();
  bool get isAvailable => status == 'available';
  bool get isReserved => status == 'reserved';
  bool get isSold => status == 'sold';
  bool get isHidden => status == 'hidden';

  bool isLikedByUser(int? userId) {
    if (userId == null) return false;
    return likes.any((l) => l.userId == userId);
  }

  Like? findUserLike(int? userId) {
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
    return truncated == price ? '\$${price.toStringAsFixed(0)}' : '\$${price.toStringAsFixed(2)}';
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

  factory ProductImage.fromDto(ProductImageDto dto) {
    return ProductImage(
      id: dto.id,
      imageUrl: dto.imageUrl,
      productId: dto.productId,
      createdAt: dto.createdAt,
      updatedAt: dto.updatedAt,
    );
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