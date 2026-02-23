import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/product_feed_provider.dart';
import 'ui/theme/app_theme.dart';
import 'utils/navigation/app_navigator.dart';
import 'utils/routes/app_routes.dart';
import 'utils/routes/route_controller.dart';

class NisitTradeApp extends StatelessWidget {
  const NisitTradeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ProductFeedProvider(),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        navigatorKey: appNavigatorKey,
        theme: AppTheme.lightTheme,
        initialRoute: AppRoutes.splash,
        onGenerateRoute: controlRoute,
      ),
    );
  }
}
