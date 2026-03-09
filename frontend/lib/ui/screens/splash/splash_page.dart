import 'package:flutter/material.dart';
import '../../../core/auth/auth_session.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/app_durations.dart';
import '../../../core/navigation/app_routes.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _textFadeAnimation;
  late Animation<double> _versionFadeAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _navigateNext();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      vsync: this,
      duration: AppDurations.splash,
    );

    // Logo slide up animation
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOutCubic),
      ),
    );

    // Logo fade animation
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );

    // Logo scale animation with spring effect
    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.7, curve: Curves.elasticOut),
      ),
    );

    // Text fade animation (delayed)
    _textFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.3, 0.8, curve: Curves.easeIn),
      ),
    );

    // Version fade animation (most delayed)
    _versionFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.5, 1.0, curve: Curves.easeIn),
      ),
    );

    _animationController.forward();
  }

  Future<void> _navigateNext() async {
    await Future.delayed(AppDurations.splashDelay);
    final isAuthenticated = await AuthSession.instance.hasValidSession();
    if (mounted) {
      final nextRoute =
          isAuthenticated ? AppRoutes.marketplace : AppRoutes.welcome;
      Navigator.pushReplacementNamed(context, nextRoute);
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: SafeArea(
        child: Column(
          children: [
            // Logo centered with staggered animations
            Expanded(
              child: Center(
                child: SlideTransition(
                  position: _slideAnimation,
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: ScaleTransition(
                      scale: _scaleAnimation,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Logo with hero effect
                          Image.asset(
                            'assets/images/NisitTradeLogo.png',
                            width: 50,
                            fit: BoxFit.contain,
                          ),
                          const SizedBox(width: 10),
                          // Text with delayed fade
                          FadeTransition(
                            opacity: _textFadeAnimation,
                            child: const Text(
                              'NisitTrade',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Version text at bottom with delayed fade
            FadeTransition(
              opacity: _versionFadeAnimation,
              child: const Padding(
                padding: EdgeInsets.only(bottom: 48),
                child: Text(
                  'Version 1.0',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    fontWeight: FontWeight.w300,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}