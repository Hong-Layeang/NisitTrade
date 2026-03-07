import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'logic/state_managers/product_feed_provider.dart';
import 'logic/state_managers/user_provider.dart';
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
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => ProductFeedProvider()),
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
