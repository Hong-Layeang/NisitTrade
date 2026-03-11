import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'app.dart';
import 'core/di/service_locator.dart';
import 'core/utils/timeago_messages.dart';

void main() async {
  // Ensure Flutter bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();

  timeago.setLocaleMessages('en', EnNumericMessages());
  
  // Setup dependency injection
  await setupServiceLocator();
  
  runApp(const NisitTradeApp());
}
