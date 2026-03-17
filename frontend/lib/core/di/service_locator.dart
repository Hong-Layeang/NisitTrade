import 'package:get_it/get_it.dart';

// Data layer
import '../../data/providers/category_api_service.dart';
import '../../data/providers/community_api_service.dart';
import '../../data/providers/product_api_service.dart';
import '../../data/providers/user_api_service.dart';
import '../../data/providers/s3_presigned_url_service.dart';
import '../../data/providers/api_client.dart';
import '../../data/repositories/category_repository_impl.dart';
import '../../data/repositories/chat_repository.dart';
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
import '../../logic/view_models/chat_view_model.dart';
import '../../logic/view_models/community_view_model.dart';
import '../../logic/view_models/product_feed_view_model.dart';
import '../../logic/view_models/saved_listings_view_model.dart';
import '../../logic/view_models/search_view_model.dart';
import '../../logic/view_models/marketplace_view_model.dart';
import '../../logic/view_models/user_view_model.dart';

final getIt = GetIt.instance;

/// Setup all dependency injection bindings
Future<void> setupServiceLocator() async {
  
  // S3 Presigned URL Service
  getIt.registerLazySingleton<S3PresignedUrlService>(
    () => S3PresignedUrlService(ApiClient.instance.dio),
  );
  
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
  
  // Product Repository
  getIt.registerLazySingleton<IProductRepository>(
    () => ProductRepositoryImpl(
      apiService: getIt<ProductApiService>(),
    ),
  );
  
  // Product-related repositories 
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
  
  getIt.registerLazySingleton<IUserRepository>(
    () => UserRepositoryImpl(
      apiService: getIt<UserApiService>(),
    ),
  );

  getIt.registerLazySingleton<ChatRepository>(
    () => ChatRepository.instance,
  );


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

  getIt.registerFactory<ChatRoomViewModel>(
    () => ChatRoomViewModel(
      chatRepository: getIt<ChatRepository>(),
    ),
  );
}

/// Reset the service locator
Future<void> resetServiceLocator() async {
  await getIt.reset();
}
