import 'package:get_it/get_it.dart';

// Data layer
import '../../logic/services/s3_presigned_url_service.dart';
import '../network/api_client.dart';
import '../../data/repositories/category_repository_impl.dart';
import '../../data/repositories/chat_repository_impl.dart';
import '../../data/repositories/community_repository_impl.dart';
import '../../data/repositories/product_repository_impl.dart';
import '../../data/repositories/product_image_repository_impl.dart';
import '../../data/repositories/product_like_repository_impl.dart';
import '../../data/repositories/product_save_repository_impl.dart';
import '../../data/repositories/product_report_repository_impl.dart';
import '../../data/repositories/product_comment_repository_impl.dart';
import '../../data/repositories/user_repository_impl.dart';

// Domain layer
import '../../data/repository_interfaces/i_category_repository.dart';
import '../../data/repository_interfaces/i_product_repository.dart';
import '../../data/repository_interfaces/i_product_image_repository.dart';
import '../../data/repository_interfaces/i_product_like_repository.dart';
import '../../data/repository_interfaces/i_product_save_repository.dart';
import '../../data/repository_interfaces/i_product_report_repository.dart';
import '../../data/repository_interfaces/i_product_comment_repository.dart';
import '../../data/repository_interfaces/i_user_repository.dart';
import '../../data/repository_interfaces/i_community_repository.dart';
import '../../data/repository_interfaces/i_chat_repository.dart';

// Logic layer (ViewModels)
import '../../logic/view_models/chat_view_model.dart';
import '../../logic/view_models/community_view_model.dart';
import '../../logic/view_models/product_feed_view_model.dart';
import '../../logic/view_models/presence_view_model.dart';
import '../../logic/view_models/saved_listings_view_model.dart';
import '../../logic/view_models/search_view_model.dart';
import '../../logic/view_models/marketplace_view_model.dart';
import '../../logic/view_models/user_view_model.dart';
import '../../logic/services/presence_websocket_service.dart';
import '../../logic/services/chat_websocket_service.dart';
import '../../logic/services/profile_content_change_notifier.dart';

final getIt = GetIt.instance;

/// Setup all dependency injection bindings
Future<void> setupServiceLocator() async {
  getIt.registerLazySingleton<S3PresignedUrlService>(
    () => S3PresignedUrlService(ApiClient.instance.dio),
  );

  getIt.registerLazySingleton<ICategoryRepository>(
    () => CategoryRepositoryImpl(),
  );

  getIt.registerLazySingleton<ICommunityRepository>(
    () => CommunityRepositoryImpl(),
  );

  getIt.registerLazySingleton<IProductRepository>(
    () => ProductRepositoryImpl(),
  );

  getIt.registerLazySingleton<IProductImageRepository>(
    () => ProductImageRepositoryImpl(),
  );

  getIt.registerLazySingleton<IProductLikeRepository>(
    () => ProductLikeRepositoryImpl(),
  );

  getIt.registerLazySingleton<IProductSaveRepository>(
    () => ProductSaveRepositoryImpl(),
  );

  getIt.registerLazySingleton<IProductReportRepository>(
    () => ProductReportRepositoryImpl(),
  );

  getIt.registerLazySingleton<IProductCommentRepository>(
    () => ProductCommentRepositoryImpl(),
  );

  getIt.registerLazySingleton<IUserRepository>(
    () => UserRepositoryImpl(),
  );

  getIt.registerLazySingleton<IChatRepository>(
    () => ChatRepository.instance,
  );

  getIt.registerLazySingleton<PresenceWebSocketService>(
    () => PresenceWebSocketService(),
  );

  getIt.registerLazySingleton<ChatWebSocketService>(
    () => ChatWebSocketService(),
  );

  getIt.registerLazySingleton<ProfileContentChangeNotifier>(
    () => ProfileContentChangeNotifier(),
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
      communityRepository: getIt<ICommunityRepository>(),
      profileContentChangeNotifier: getIt<ProfileContentChangeNotifier>(),
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
      communityRepository: getIt<ICommunityRepository>(),
      profileContentChangeNotifier: getIt<ProfileContentChangeNotifier>(),
    ),
  );

  getIt.registerFactory<MarketplaceViewModel>(
    () => MarketplaceViewModel(
      categoryRepository: getIt<ICategoryRepository>(),
    ),
  );

  getIt.registerFactory<ChatRoomViewModel>(
    () => ChatRoomViewModel(
      chatRepository: getIt<IChatRepository>(),
      chatWebSocket: getIt<ChatWebSocketService>(),
    ),
  );

  getIt.registerFactory<PresenceViewModel>(
    () => PresenceViewModel(
      presenceService: getIt<PresenceWebSocketService>(),
    ),
  );
}

/// Reset the service locator
Future<void> resetServiceLocator() async {
  await getIt.reset();
}
