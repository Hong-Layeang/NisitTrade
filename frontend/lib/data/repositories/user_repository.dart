import '../models/product.dart';
import '../models/user_profile.dart';
import '../../core/errors/api_response.dart';
import '../providers/user_api_service.dart';

abstract class UserRepository {
  Future<ApiResponse<UserProfile>> getCurrentUser();

  Future<ApiResponse<UserProfile>> getUserById(int userId);

  Future<ApiResponse<List<Product>>> getUserProducts({
    required int userId,
    int? limit,
    int? offset,
  });

  Future<ApiResponse<List<Product>>> getUserSavedListings({
    required int userId,
    int? limit,
    int? offset,
  });

  Future<ApiResponse<List<UserProfile>>> getAllUsers({
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

class UserRepositoryImpl implements UserRepository {
  UserRepositoryImpl({UserApiService? apiService})
      : _apiService = apiService ?? UserApiService.instance;

  final UserApiService _apiService;

  @override
  Future<ApiResponse<UserProfile>> getCurrentUser() async {
    return _apiService.getCurrentUser();
  }

  @override
  Future<ApiResponse<UserProfile>> getUserById(int userId) async {
    return _apiService.getUserById(userId);
  }

  @override
  Future<ApiResponse<List<Product>>> getUserProducts({
    required int userId,
    int? limit,
    int? offset,
  }) async {
    return _apiService.getUserProducts(
      userId: userId,
      limit: limit,
      offset: offset,
    );
  }

  @override
  Future<ApiResponse<List<Product>>> getUserSavedListings({
    required int userId,
    int? limit,
    int? offset,
  }) async {
    return _apiService.getUserSavedListings(
      userId: userId,
      limit: limit,
      offset: offset,
    );
  }

  @override
  Future<ApiResponse<List<UserProfile>>> getAllUsers({
    String? search,
    int? limit,
    int? offset,
  }) async {
    return _apiService.getAllUsers(
      search: search,
      limit: limit,
      offset: offset,
    );
  }

  @override
  Future<ApiResponse<bool>> followUser(int userId) async {
    return _apiService.followUser(userId);
  }

  @override
  Future<ApiResponse<bool>> unfollowUser(int userId) async {
    return _apiService.unfollowUser(userId);
  }

  @override
  Future<ApiResponse<String>> updateCoverImage({
    required int userId,
    required String filePath,
  }) async {
    return _apiService.updateCoverImage(userId: userId, filePath: filePath);
  }

  @override
  Future<ApiResponse<String>> updateAvatarImage({
    required int userId,
    required String filePath,
  }) async {
    return _apiService.updateAvatarImage(userId: userId, filePath: filePath);
  }
}
