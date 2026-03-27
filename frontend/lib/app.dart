import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/di/service_locator.dart';
import 'logic/services/s3_presigned_url_service.dart';
import 'logic/view_models/chat_view_model.dart';
import 'logic/view_models/community_view_model.dart';
import 'logic/view_models/marketplace_view_model.dart';
import 'logic/view_models/presence_view_model.dart';
import 'logic/view_models/product_feed_view_model.dart';
import 'logic/view_models/saved_listings_view_model.dart';
import 'logic/view_models/search_view_model.dart';
import 'logic/view_models/user_view_model.dart';
import 'ui/themes/app_theme.dart';
import 'core/navigation/app_navigator.dart';
import 'core/navigation/app_routes.dart';
import 'core/navigation/route_controller.dart';

// Global RouteObserver for tracking route changes
final routeObserver = RouteObserver<PageRoute>();

class NisitTradeApp extends StatelessWidget {
  const NisitTradeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // S3 Presigned URL Service
        Provider<S3PresignedUrlService>(
          create: (_) => getIt<S3PresignedUrlService>(),
        ),
        // Get ViewModels from dependency injection container
        ChangeNotifierProvider<UserViewModel>(
          create: (_) => getIt<UserViewModel>(),
        ),
        ChangeNotifierProvider<ProductFeedViewModel>(
          create: (_) => getIt<ProductFeedViewModel>(),
        ),
        ChangeNotifierProvider<SavedListingsViewModel>(
          create: (_) => getIt<SavedListingsViewModel>(),
        ),
        ChangeNotifierProvider<MarketplaceViewModel>(
          create: (_) => getIt<MarketplaceViewModel>(),
        ),
        ChangeNotifierProvider<SearchViewModel>(
          create: (_) => getIt<SearchViewModel>(),
        ),
        ChangeNotifierProvider<CommunityViewModel>(
          create: (_) => getIt<CommunityViewModel>(),
        ),
        ChangeNotifierProvider<PresenceViewModel>(
          create: (_) => getIt<PresenceViewModel>(),
        ),
        ChangeNotifierProvider<ChatRoomViewModel>(
          create: (_) => getIt<ChatRoomViewModel>()..loadPersistedAttachments(),
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        navigatorKey: appNavigatorKey,
        navigatorObservers: [routeObserver],
        theme: AppTheme.lightTheme,
        initialRoute: AppRoutes.splash,
        onGenerateRoute: controlRoute,
        builder: (context, child) => GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () => FocusScope.of(context).unfocus(),
          child: child,
        ),
      ),
    );
  }
}
