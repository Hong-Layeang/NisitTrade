import '../../models/product.dart';
import '../../models/user_profile.dart';
import '../../services/api/api_response.dart';
import '../../services/api/user_api_service.dart';

abstract class UserRepository {
  Future<ApiResponse<UserProfile>> getCurrentUser();

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
}
