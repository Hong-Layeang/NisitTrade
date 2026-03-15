import 'package:flutter/material.dart';
import '../../ui/screens/auth/forgot_password_page.dart';
import '../../ui/screens/auth/login_page.dart';
import '../../ui/screens/auth/set_password_page.dart';
import '../../ui/screens/auth/signup_page.dart';
import '../../ui/screens/auth/welcome_page.dart';
import '../../ui/screens/splash/splash_page.dart';
import '../../ui/screens/marketplace/product_detail_page.dart';
import '../../ui/screens/community/community_detail_page.dart';
import '../../ui/layouts/main_shell.dart';
import '../../ui/screens/profile/other_profile_page.dart';
import '../../ui/screens/saved/saved_page.dart';
import '../../ui/screens/chat/chat_room_screen.dart';
import '../../ui/screens/chat/conversations_list_screen.dart';
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
      final args = settings.arguments;
      final skipAuthCheck =
          args is MarketplaceRouteArgs && args.skipAuthCheck;

      if (skipAuthCheck) {
        return MaterialPageRoute(
          builder: (_) => const MainShell(initialIndex: 0),
        );
      }

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

    case AppRoutes.productDetail:
      final args = settings.arguments;
      if (args is ProductDetailArgs) {
        return MaterialPageRoute(
          builder: (_) => ProductDetailPage(
            productId: args.productId,
            focusComments: args.focusComments,
            initialProduct: args.initialProduct,
          ),
        );
      }
      return MaterialPageRoute(builder: (_) => const LoginPage());

    case AppRoutes.communityDetail:
      final args = settings.arguments;
      if (args is CommunityDetailArgs) {
        return MaterialPageRoute(
          builder: (_) => CommunityDetailPage(
            postId: args.postId,
            focusComments: args.focusComments,
            initialPost: args.initialPost,
          ),
        );
      }
      return MaterialPageRoute(builder: (_) => const LoginPage());

    case AppRoutes.saved:
      return MaterialPageRoute(
        builder: (_) => const AuthGate(
          child: SavedListingsPage(),
        ),
      );

    case AppRoutes.userProfile:
      final args = settings.arguments;
      if (args is OtherProfileArgs) {
        return MaterialPageRoute(
          builder: (_) => AuthGate(
            child: OtherProfilePage(userId: args.userId),
          ),
        );
      }
      return MaterialPageRoute(builder: (_) => const LoginPage());

    case AppRoutes.chat:
      return MaterialPageRoute(
        builder: (_) => const AuthGate(
          child: ConversationsListScreen(),
        ),
      );

    case AppRoutes.chatRoom:
      final args = settings.arguments;
      if (args is int) {
        return MaterialPageRoute(
          builder: (_) => AuthGate(
            child: ChatRoomScreen(conversationId: args),
          ),
        );
      }
      if (args is ChatRoomRouteArgs) {
        return MaterialPageRoute(
          builder: (_) => AuthGate(
            child: ChatRoomScreen(
              conversationId: args.conversationId,
              attachProductOnCompose: args.attachProductOnCompose,
            ),
          ),
        );
      }
      return MaterialPageRoute(builder: (_) => const LoginPage());

    default:
      return MaterialPageRoute(builder: (_) => const LoginPage());
  }
}
