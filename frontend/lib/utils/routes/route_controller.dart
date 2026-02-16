import 'package:flutter/material.dart';
import '../../ui/screens/auth/forgot_password_page.dart';
import '../../ui/screens/auth/login_page.dart';
import '../../ui/screens/auth/set_password_page.dart';
import '../../ui/screens/auth/signup_page.dart';
import '../../ui/screens/auth/welcome_page.dart';
import '../../ui/Screens/splash/splash_page.dart';
import '../../ui/layouts/main_shell.dart';
import 'app_routes.dart';
import 'auth_gate.dart';

Route<dynamic> controlRoute(RouteSettings settings) {
  switch (settings.name) {
    case AppRoutes.splash:
      return MaterialPageRoute(builder: (_) => const SplashPage());
    case AppRoutes.welcome:
      return MaterialPageRoute(builder: (_) => const WelcomePage());
    case AppRoutes.login:
      return MaterialPageRoute(builder: (_) => const LoginPage());

    case AppRoutes.signup:
      return MaterialPageRoute(builder: (_) => const SignupPage());

    case AppRoutes.forgotPassword:
      return MaterialPageRoute(builder: (_) => const ForgotPasswordPage());

    case AppRoutes.setPassword:
      final args = settings.arguments;
      if (args is SetPasswordArgs) {
        return MaterialPageRoute(
          builder: (_) => SetPasswordPage(args: args),
        );
      }
      return MaterialPageRoute(builder: (_) => const LoginPage());

    case AppRoutes.marketplace:
      return MaterialPageRoute(
        builder: (_) => const AuthGate(
          child: MainShell(initialIndex: 0),
        ),
      );

    case AppRoutes.search:
      return MaterialPageRoute(
        builder: (_) => const AuthGate(
          child: MainShell(initialIndex: 1),
        ),
      );

    case AppRoutes.sell:
      return MaterialPageRoute(
        builder: (_) => const AuthGate(
          child: MainShell(initialIndex: 2),
        ),
      );

    case AppRoutes.community:
      return MaterialPageRoute(
        builder: (_) => const AuthGate(
          child: MainShell(initialIndex: 3),
        ),
      );

    case AppRoutes.profile:
      return MaterialPageRoute(
        builder: (_) => const AuthGate(
          child: MainShell(initialIndex: 4),
        ),
      );

    default:
      return MaterialPageRoute(builder: (_) => const LoginPage());
  }
}
