import 'package:flutter/material.dart';
import '../../../utils/routes/app_routes.dart';
import '../../../services/auth/microsoft_auth_service.dart';
import '../../widgets/auth/white_blur_gradient.dart';
import '../../widgets/auth/microsoft_signin_button.dart';

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

    if (result.isSuccess) {
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
    return Scaffold(
      backgroundColor: Colors.white,
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
              child: GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                },
                child: const Row(
                  children: [
                    Icon(
                      Icons.arrow_back,
                      color: Colors.black87,
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Back to Welcome page',
                      style: TextStyle(
                        color: Colors.black87,
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            Divider(height: 1, color: Colors.grey.shade300),

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
                      const Center(
                        child: Text(
                          'Sign In Now',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // University Email Field
                      _buildRequiredLabel('University Email'),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          hintText: 'John.doe@university.com',
                          hintStyle: TextStyle(
                            color: Colors.grey.shade400,
                            fontSize: 16,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                              color: Color(0xFF00BCD4),
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Password Field
                      _buildRequiredLabel('Password'),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          hintText: '****************',
                          hintStyle: TextStyle(
                            color: Colors.grey.shade400,
                            fontSize: 16,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                              color: Color(0xFF00BCD4),
                              width: 2,
                            ),
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              color: Colors.grey,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
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
                              color: Color(0xFF00BCD4),
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Login Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            // Navigate to marketplace after login
                            Navigator.pushNamedAndRemoveUntil(
                              context,
                              AppRoutes.marketplace,
                              (route) => false,
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF00BCD4),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            elevation: 0,
                          ),
                          child: const Text(
                            'LOGIN',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
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
                                color: Colors.grey,
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
                                  color: Color(0xFF00BCD4),
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
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  GestureDetector(
                    onTap: () {
                      // TODO: Open terms of use
                    },
                    child: const Text(
                      'Terms of use',
                      style: TextStyle(
                        color: Color(0xFF00BCD4),
                        fontSize: 14,
                        decoration: TextDecoration.underline,
                        decorationColor: Color(0xFF00BCD4),
                      ),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      '|',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      // TODO: Open privacy policy
                    },
                    child: const Text(
                      'privacy policy',
                      style: TextStyle(
                        color: Color(0xFF00BCD4),
                        fontSize: 14,
                        decoration: TextDecoration.underline,
                        decorationColor: Color(0xFF00BCD4),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRequiredLabel(String label) {
    return Row(
      children: [
        const Text(
          '* ',
          style: TextStyle(
            color: Colors.red,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: Colors.black87,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
