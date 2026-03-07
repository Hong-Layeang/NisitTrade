import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../logic/view_models/product_feed_view_model.dart';
import '../../../logic/view_models/user_view_model.dart';
import '../../../core/auth/auth_service.dart';
import '../../../core/auth/microsoft_auth_service.dart';
import '../../../core/constants/colors.dart';
import '../../../core/navigation/app_routes.dart';
import 'widgets/auth_back_link.dart';
import 'widgets/auth_footer_links.dart';
import 'widgets/microsoft_signin_button.dart';
import 'widgets/white_blur_gradient.dart';
import '../../widgets/app_buttons.dart';
import '../../widgets/app_form_fields.dart';
import 'set_password_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isMicrosoftLoading = false;
  bool _isEmailLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleMicrosoftLogin() async {
    if (_isMicrosoftLoading) {
      return;
    }

    setState(() {
      _isMicrosoftLoading = true;
    });

    final result = await MicrosoftAuthService.instance.signIn();

    if (!mounted) {
      return;
    }

    setState(() {
      _isMicrosoftLoading = false;
    });

    if (result.needsPasswordSetup && result.token != null) {
      Navigator.pushNamed(
        context,
        AppRoutes.setPassword,
        arguments: SetPasswordArgs(
          accessToken: result.token!,
          email: result.email,
        ),
      );
      return;
    }

    if (result.isAuthenticated) {
      // Clear stale product data from any previous user session
      if (mounted) {
        context.read<ProductFeedViewModel>().clear();
        context.read<UserViewModel>().load();
      }
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.marketplace,
        (route) => false,
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(result.message)),
    );
  }

  Future<void> _handleEmailLogin() async {
    if (_isEmailLoading) {
      return;
    }

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Email and password are required.')),
      );
      return;
    }

    setState(() {
      _isEmailLoading = true;
    });

    final result = await AuthService.instance.login(
      email: email,
      password: password,
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _isEmailLoading = false;
    });

    if (result.isAuthenticated) {
      // Clear stale product data from any previous user session
      if (mounted) {
        context.read<ProductFeedViewModel>().clear();
        context.read<UserViewModel>().load();
      }
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.marketplace,
        (route) => false,
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(result.message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Banner Image with white blur at bottom
            SizedBox(
              width: double.infinity,
              height: MediaQuery.of(context).size.height * 0.25,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    'assets/images/onboarding/banner.png',
                    fit: BoxFit.cover,
                  ),
                  // White blur gradient at bottom
                  const WhiteBlurGradient(),
                ],
              ),
            ),

            // Back to Welcome page
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: AuthBackLink(
                label: 'Back to Welcome page',
                onTap: () => Navigator.pop(context),
              ),
            ),

            const Divider(height: 1, color: AppColors.border),

            // Content Section
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 24),

                      // Sign In Now Title
                      Center(
                        child: Text('Sign In Now', style: textTheme.titleLarge),
                      ),
                      const SizedBox(height: 24),

                      // University Email Field
                      const AppRequiredLabel(label: 'University Email'),
                      const SizedBox(height: 8),
                      AppTextField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        hintText: 'lastname.fistname@university.com',
                        textInputAction: TextInputAction.next,
                        autofillHints: const [AutofillHints.email],
                      ),
                      const SizedBox(height: 20),

                      // Password Field
                      const AppRequiredLabel(label: 'Password'),
                      const SizedBox(height: 8),
                      AppTextField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        hintText: '****************',
                        textInputAction: TextInputAction.done,
                        autofillHints: const [AutofillHints.password],
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                            color: AppColors.textSecondary,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Forgot Password Link
                      Align(
                        alignment: Alignment.centerRight,
                        child: GestureDetector(
                          onTap: () {
                            Navigator.pushNamed(context, AppRoutes.forgotPassword);
                          },
                          child: const Text(
                            'Forgot Password?',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      AppPrimaryButton(
                        label: 'LOGIN',
                        isLoading: _isEmailLoading,
                        onPressed: _isEmailLoading ? null : _handleEmailLogin,
                      ),
                      const SizedBox(height: 16),

                      Row(
                        children: [
                          const Expanded(
                            child: Divider(color: AppColors.border),
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 12),
                            child: Text(
                              'OR',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 1,
                              ),
                            ),
                          ),
                          const Expanded(
                            child: Divider(color: AppColors.border),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      MicrosoftSignInButton(
                        isLoading: _isMicrosoftLoading,
                        onPressed: _handleMicrosoftLogin,
                      ),
                      const SizedBox(height: 16),

                      // Sign Up Link
                      Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              "Don't have an account?",
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: () {
                                Navigator.pushNamed(context, AppRoutes.signup);
                              },
                              child: const Text(
                                'Sign Up',
                                style: TextStyle(
                                  color: AppColors.primary,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Footer Links
            Padding(
              padding: const EdgeInsets.only(bottom: 24, top: 16),
              child: AuthFooterLinks(
                onTermsTap: () {
                  // TODO: Open terms of use
                },
                onPrivacyTap: () {
                  // TODO: Open privacy policy
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

