import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/di/service_locator.dart';
import 'logic/view_models/marketplace_view_model.dart';
import 'logic/view_models/product_feed_view_model.dart';
import 'logic/view_models/saved_listings_view_model.dart';
import 'logic/view_models/search_view_model.dart';
import 'logic/view_models/user_view_model.dart';
import 'ui/themes/app_theme.dart';
import 'core/navigation/app_navigator.dart';
import 'core/navigation/app_routes.dart';
import 'core/navigation/route_controller.dart';

class NisitTradeApp extends StatelessWidget {
  const NisitTradeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
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
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        navigatorKey: appNavigatorKey,
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
