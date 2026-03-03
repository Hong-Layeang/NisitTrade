import 'package:flutter/material.dart';
import '../../../utils/constants/colors.dart';
import '../../../utils/routes/app_routes.dart';
import '../../widgets/auth/auth_back_link.dart';
import '../../widgets/auth/auth_footer_links.dart';
import '../../widgets/auth/white_blur_gradient.dart';
import '../../widgets/common/app_buttons.dart';
import '../../widgets/common/app_form_fields.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _agreedToTerms = false;

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
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
              height: MediaQuery.of(context).size.height * 0.22,
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

                      // Sign Up Now Title
                      Center(
                        child: Text('Sign Up Now', style: textTheme.titleLarge),
                      ),
                      const SizedBox(height: 24),

                      // Full Name Field
                      const AppRequiredLabel(label: 'Full Name'),
                      const SizedBox(height: 8),
                      AppTextField(
                        controller: _fullNameController,
                        keyboardType: TextInputType.name,
                        textCapitalization: TextCapitalization.words,
                        hintText: 'Virak Dara',
                        textInputAction: TextInputAction.next,
                        autofillHints: const [AutofillHints.name],
                      ),
                      const SizedBox(height: 20),

                      // University Email Field
                      const AppRequiredLabel(label: 'University Email'),
                      const SizedBox(height: 8),
                      AppTextField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        hintText: 'lastname.firstname@university.com',
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
                        autofillHints: const [AutofillHints.newPassword],
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
                      const SizedBox(height: 16),

                      // Terms and Conditions Checkbox
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 24,
                            height: 24,
                            child: Checkbox(
                              value: _agreedToTerms,
                              onChanged: (value) {
                                setState(() {
                                  _agreedToTerms = value ?? false;
                                });
                              },
                              activeColor: AppColors.primary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4),
                              ),
                              side: BorderSide(
                                color: AppColors.textSecondary,
                                width: 1.5,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _agreedToTerms = !_agreedToTerms;
                                });
                              },
                              child: RichText(
                                text: TextSpan(
                                  style: const TextStyle(
                                    color: AppColors.textPrimary,
                                    fontSize: 14,
                                  ),
                                  children: [
                                    const TextSpan(
                                      text: 'By signing up you agree to our ',
                                    ),
                                    WidgetSpan(
                                      child: GestureDetector(
                                        onTap: () {
                                          // TODO: Open Terms of Service
                                        },
                                        child: const Text(
                                          'Terms of Service',
                                          style: TextStyle(
                                            color: AppColors.primary,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                            decoration:
                                                TextDecoration.underline,
                                            decorationColor: AppColors.primary,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Sign Up Button
                      AppPrimaryButton(
                        label: 'Sign up',
                        onPressed: _agreedToTerms
                            ? () {
                                Navigator.pushNamedAndRemoveUntil(
                                  context,
                                  AppRoutes.marketplace,
                                  (route) => false,
                                );
                              }
                            : null,
                      ),
                      const SizedBox(height: 16),

                      // Sign In Link
                      Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              'Already have an account?',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: () {
                                Navigator.pushReplacementNamed(context, AppRoutes.login);
                              },
                              child: const Text(
                                'Sign In',
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
