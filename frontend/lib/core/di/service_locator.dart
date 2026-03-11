import 'package:get_it/get_it.dart';

// Data layer
import '../../data/providers/category_api_service.dart';
import '../../data/providers/community_api_service.dart';
import '../../data/providers/product_api_service.dart';
import '../../data/providers/user_api_service.dart';
import '../../data/repositories/category_repository_impl.dart';
import '../../data/repositories/community_repository_impl.dart';
import '../../data/repositories/product_repository_impl.dart';
import '../../data/repositories/product_image_repository_impl.dart';
import '../../data/repositories/product_like_repository_impl.dart';
import '../../data/repositories/product_save_repository_impl.dart';
import '../../data/repositories/product_report_repository_impl.dart';
import '../../data/repositories/product_comment_repository_impl.dart';
import '../../data/repositories/user_repository_impl.dart';

// Domain layer
import '../../domain/repository_interfaces/i_category_repository.dart';
import '../../domain/repository_interfaces/i_product_repository.dart';
import '../../domain/repository_interfaces/i_product_image_repository.dart';
import '../../domain/repository_interfaces/i_product_like_repository.dart';
import '../../domain/repository_interfaces/i_product_save_repository.dart';
import '../../domain/repository_interfaces/i_product_report_repository.dart';
import '../../domain/repository_interfaces/i_product_comment_repository.dart';
import '../../domain/repository_interfaces/i_user_repository.dart';

// Logic layer (ViewModels)
import '../../logic/view_models/community_view_model.dart';
import '../../logic/view_models/product_feed_view_model.dart';
import '../../logic/view_models/saved_listings_view_model.dart';
import '../../logic/view_models/search_view_model.dart';
import '../../logic/view_models/marketplace_view_model.dart';
import '../../logic/view_models/user_view_model.dart';

/// Global service locator instance
final getIt = GetIt.instance;

/// Setup all dependency injection bindings
/// This should be called in main() before runApp()
Future<void> setupServiceLocator() async {
  // ============================================================================
  // API SERVICES (Singletons)
  // ============================================================================
  
  // API services are already singletons, just register them
  getIt.registerLazySingleton<CategoryApiService>(
    () => CategoryApiService.instance,
  );

  getIt.registerLazySingleton<CommunityApiService>(
    () => CommunityApiService.instance,
  );
  
  getIt.registerLazySingleton<ProductApiService>(
    () => ProductApiService.instance,
  );
  
  getIt.registerLazySingleton<UserApiService>(
    () => UserApiService.instance,
  );

  // ============================================================================
  // REPOSITORIES (Singletons)
  // ============================================================================
  
  // Category Repository
  getIt.registerLazySingleton<ICategoryRepository>(
    () => CategoryRepositoryImpl(
      apiService: getIt<CategoryApiService>(),
    ),
  );

  // Community Repository
  getIt.registerLazySingleton<CommunityRepository>(
    () => CommunityRepositoryImpl(
      apiService: getIt<CommunityApiService>(),
    ),
  );
  
  // Product Repository (core CRUD only)
  getIt.registerLazySingleton<IProductRepository>(
    () => ProductRepositoryImpl(
      apiService: getIt<ProductApiService>(),
    ),
  );
  
  // Product-related repositories (separated concerns)
  getIt.registerLazySingleton<IProductImageRepository>(
    () => ProductImageRepositoryImpl(
      apiService: getIt<ProductApiService>(),
    ),
  );
  
  getIt.registerLazySingleton<IProductLikeRepository>(
    () => ProductLikeRepositoryImpl(
      apiService: getIt<ProductApiService>(),
    ),
  );
  
  getIt.registerLazySingleton<IProductSaveRepository>(
    () => ProductSaveRepositoryImpl(
      apiService: getIt<ProductApiService>(),
    ),
  );
  
  getIt.registerLazySingleton<IProductReportRepository>(
    () => ProductReportRepositoryImpl(
      apiService: getIt<ProductApiService>(),
    ),
  );
  
  getIt.registerLazySingleton<IProductCommentRepository>(
    () => ProductCommentRepositoryImpl(
      apiService: getIt<ProductApiService>(),
    ),
  );
  
  // User Repository
  getIt.registerLazySingleton<IUserRepository>(
    () => UserRepositoryImpl(
      apiService: getIt<UserApiService>(),
    ),
  );

  // ============================================================================
  // VIEW MODELS (Factories)
  // ============================================================================
  
  getIt.registerFactory<ProductFeedViewModel>(
    () => ProductFeedViewModel(
      productRepository: getIt<IProductRepository>(),
      likeRepository: getIt<IProductLikeRepository>(),
      saveRepository: getIt<IProductSaveRepository>(),
      commentRepository: getIt<IProductCommentRepository>(),
      reportRepository: getIt<IProductReportRepository>(),
    ),
  );
  
  getIt.registerFactory<UserViewModel>(
    () => UserViewModel(
      userRepository: getIt<IUserRepository>(),
    ),
  );

  getIt.registerFactory<SavedListingsViewModel>(
    () => SavedListingsViewModel(
      userRepository: getIt<IUserRepository>(),
      productRepository: getIt<IProductRepository>(),
      productSaveRepository: getIt<IProductSaveRepository>(),
      communityRepository: getIt<CommunityRepository>(),
    ),
  );

  getIt.registerFactory<SearchViewModel>(
    () => SearchViewModel(
      categoryRepository: getIt<ICategoryRepository>(),
      userRepository: getIt<IUserRepository>(),
    ),
  );

  getIt.registerFactory<CommunityViewModel>(
    () => CommunityViewModel(
      communityRepository: getIt<CommunityRepository>(),
    ),
  );

  getIt.registerFactory<MarketplaceViewModel>(
    () => MarketplaceViewModel(
      categoryRepository: getIt<ICategoryRepository>(),
    ),
  );
}

/// Reset the service locator (useful for testing)
Future<void> resetServiceLocator() async {
  await getIt.reset();
}
