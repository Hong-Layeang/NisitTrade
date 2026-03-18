import 'package:flutter/material.dart';

import '../auth/auth_session.dart';
import 'app_routes.dart';
import '../../ui/widgets/app_loading.dart';

class AuthGate extends StatefulWidget {
  final Widget child;
  final String redirectRoute;

  const AuthGate({
    super.key,
    required this.child,
    this.redirectRoute = AppRoutes.welcome,
  });

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  late final Future<bool> _authFuture;

  @override
  void initState() {
    super.initState();
    _authFuture = AuthSession.instance.hasValidSession();
  }

  @override
  Widget build(BuildContext context) {
    final hasCachedValidSession = AuthSession.instance.hasCachedValidSession;

    return FutureBuilder<bool>(
      future: _authFuture,
      initialData: hasCachedValidSession ? true : null,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          if (hasCachedValidSession) {
            return widget.child;
          }
          return const AppPageLoading();
        }

        final isAuthenticated = snapshot.data == true;
        if (isAuthenticated) {
          return widget.child;
        }

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) {
            return;
          }
          Navigator.pushNamedAndRemoveUntil(
            context,
            widget.redirectRoute,
            (route) => false,
          );
        });

        return const Scaffold(body: SizedBox.shrink());
      },
    );
  }
}
