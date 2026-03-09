import '../../domain/entities/product_entity.dart';

/// Helper class for product like operations
class ProductLikeHelpers {
  const ProductLikeHelpers._();

  /// Finds a user's like in the product
  static ProductLikeEntity? findUserLike({
    required ProductEntity product,
    required int? userId,
  }) {
    if (userId == null) return null;

    for (final like in product.likes) {
      if (like.userId == userId) {
        return like;
      }
    }
    return null;
  }

  /// Finds the ID of a user's like
  static int? findUserLikeId({
    required ProductEntity product,
    required int? userId,
  }) {
    return findUserLike(product: product, userId: userId)?.id;
  }

  /// Checks if a product is liked by a user
  static bool isLikedByUser({
    required ProductEntity product,
    required int? userId,
  }) {
    return findUserLike(product: product, userId: userId) != null;
  }
}
