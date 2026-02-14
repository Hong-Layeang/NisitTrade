import 'package:flutter/material.dart';
import 'utils/navigation/app_navigator.dart';
import 'utils/routes/app_routes.dart';
import 'utils/routes/route_controller.dart';

class NisitTradeApp extends StatelessWidget {
  const NisitTradeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      navigatorKey: appNavigatorKey,
      initialRoute: AppRoutes.splash,
      onGenerateRoute: controlRoute,
    );
  }
}
