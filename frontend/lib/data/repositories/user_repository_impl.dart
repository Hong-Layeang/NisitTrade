import '../../core/errors/api_response.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/entities/product_entity.dart';
import '../../domain/repository_interfaces/i_user_repository.dart';
import '../providers/user_api_service.dart';

/// Implementation of IUserRepository using the API service
class UserRepositoryImpl implements IUserRepository {
  UserRepositoryImpl({UserApiService? apiService})
      : _apiService = apiService ?? UserApiService.instance;

  final UserApiService _apiService;

  @override
  Future<ApiResponse<UserEntity>> getCurrentUser() async {
    final response = await _apiService.getCurrentUser();
    if (response.isSuccess && response.data != null) {
      return ApiResponse.success(response.data!.toEntity());
    }
    return ApiResponse.error(response.error!);
  }

  @override
  Future<ApiResponse<UserEntity>> getUserById(int userId) async {
    final response = await _apiService.getUserById(userId);
    if (response.isSuccess && response.data != null) {
      return ApiResponse.success(response.data!.toEntity());
    }
    return ApiResponse.error(response.error!);
  }

  @override
  Future<ApiResponse<List<ProductEntity>>> getUserProducts({
    required int userId,
    int? limit,
    int? offset,
  }) async {
    final response = await _apiService.getUserProducts(
      userId: userId,
      limit: limit,
      offset: offset,
    );
    if (response.isSuccess && response.data != null) {
      final entities = response.data!.map((model) => model.toEntity()).toList();
      return ApiResponse.success(entities);
    }
    return ApiResponse.error(response.error!);
  }

  @override
  Future<ApiResponse<List<ProductEntity>>> getUserSavedListings({
    required int userId,
    int? limit,
    int? offset,
  }) async {
    final response = await _apiService.getUserSavedListings(
      userId: userId,
      limit: limit,
      offset: offset,
    );
    if (response.isSuccess && response.data != null) {
      final entities = response.data!.map((model) => model.toEntity()).toList();
      return ApiResponse.success(entities);
    }
    return ApiResponse.error(response.error!);
  }

  @override
  Future<ApiResponse<List<UserEntity>>> getAllUsers({
    String? search,
    int? limit,
    int? offset,
  }) async {
    final response = await _apiService.getAllUsers(
      search: search,
      limit: limit,
      offset: offset,
    );
    if (response.isSuccess && response.data != null) {
      final entities = response.data!.map((model) => model.toEntity()).toList();
      return ApiResponse.success(entities);
    }
    return ApiResponse.error(response.error!);
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

  @override
  Future<ApiResponse<UserEntity>> updateProfile({
    required int userId,
    required String fullName,
    String? bio,
    String? major,
  }) async {
    final response = await _apiService.updateProfile(
      userId: userId,
      fullName: fullName,
      bio: bio,
      major: major,
    );

    if (response.isSuccess && response.data != null) {
      return ApiResponse.success(response.data!.toEntity());
    }

    return ApiResponse.error(response.error!);
  }
}
