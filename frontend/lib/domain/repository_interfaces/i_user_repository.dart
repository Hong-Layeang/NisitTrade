import '../entities/user_entity.dart';
import '../entities/product_entity.dart';
import '../../core/errors/api_response.dart';

/// Repository interface for managing user data
/// This belongs in the domain layer and defines the contract
abstract class IUserRepository {
  Future<ApiResponse<UserEntity>> getCurrentUser();

  Future<ApiResponse<UserEntity>> getUserById(int userId);

  Future<ApiResponse<List<ProductEntity>>> getUserProducts({
    required int userId,
    int? limit,
    int? offset,
  });

  Future<ApiResponse<List<ProductEntity>>> getUserSavedListings({
    required int userId,
    int? limit,
    int? offset,
  });

  Future<ApiResponse<List<UserEntity>>> getAllUsers({
    String? search,
    int? limit,
    int? offset,
  });

  Future<ApiResponse<bool>> followUser(int userId);

  Future<ApiResponse<bool>> unfollowUser(int userId);

  Future<ApiResponse<String>> updateCoverImage({
    required int userId,
    required String filePath,
  });

  Future<ApiResponse<String>> updateAvatarImage({
    required int userId,
    required String filePath,
  });
}
