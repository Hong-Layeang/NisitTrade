import '../../data/dtos/user_profile_dto.dart';
import '../../data/dtos/product_dto.dart';
import '../../data/dtos/community_post_dto.dart';
import '../../core/errors/api_response.dart';

abstract class IUserRepository {
  Future<ApiResponse<UserProfileDto>> getCurrentUser();

  Future<ApiResponse<UserProfileDto>> getUserById(int userId);

  Future<ApiResponse<List<ProductDto>>> getUserProducts({
    required int userId,
    int? limit,
    int? offset,
  });

  Future<ApiResponse<List<ProductDto>>> getUserSavedListings({
    required int userId,
    int? limit,
    int? offset,
  });

  Future<ApiResponse<List<UserProfileDto>>> getAllUsers({
    String? search,
    int? limit,
    int? offset,
  });

  Future<ApiResponse<List<CommunityPostDto>>> getUserSavedPosts({
    required int userId,
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

  Future<ApiResponse<UserProfileDto>> updateProfile({
    required int userId,
    required String fullName,
    String? bio,
    String? major,
  });

  Future<ApiResponse<void>> reportUser({
    required int userId,
    required String reason,
    String? details,
  });

  Future<ApiResponse<bool>> blockUser(int userId);

  Future<ApiResponse<bool>> unblockUser(int userId);

  Future<ApiResponse<bool>> submitRating({
    required int sellerId,
    required int productId,
    required int rating,
    String? feedback,
  });
}

