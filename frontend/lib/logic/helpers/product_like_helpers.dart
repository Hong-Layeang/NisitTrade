import '../../data/dtos/product_dto.dart';
import '../../data/dtos/like_dto.dart';

/// Helper class for product like operations
class ProductLikeHelpers {
  const ProductLikeHelpers._();

  /// Finds a user's like in the product
  static LikeDto? findUserLike({
    required ProductDto product,
    required int? userId,
  }) {
    return product.findUserLike(userId);
  }

  /// Finds the ID of a user's like
  static int? findUserLikeId({
    required ProductDto product,
    required int? userId,
  }) {
    return product.findUserLike(userId)?.id;
  }

  /// Checks if a product is liked by a user
  static bool isLikedByUser({
    required ProductDto product,
    required int? userId,
  }) {
    return product.isLikedByUser(userId);
  }
}

