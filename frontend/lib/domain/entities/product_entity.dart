import 'package:equatable/equatable.dart';
import 'category_entity.dart';
import 'seller_entity.dart';

/// Domain entity representing a product
/// This is a pure business object with no framework dependencies
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

  /// Returns formatted price with currency
  String get formattedPrice => '฿${price.toStringAsFixed(2)}';

  /// Returns a short description (first 100 characters)
  String? get shortDescription {
    if (description == null || description!.isEmpty) return null;
    return description!.length > 100 
        ? '${description!.substring(0, 100)}...' 
        : description;
  }

  @override
  List<Object?> get props => [
    id, title, description, price, status, userId, categoryId,
    createdAt, updatedAt, seller, category, imageUrls, 
    likeCount, commentCount, isLiked
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
