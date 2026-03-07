import 'package:flutter/material.dart';
import 'app.dart';
import 'core/di/service_locator.dart';

void main() async {
  // Ensure Flutter bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();
  
  // Setup dependency injection
  await setupServiceLocator();
  
  runApp(const NisitTradeApp());
}
