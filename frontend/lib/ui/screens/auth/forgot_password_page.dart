import 'package:flutter/material.dart';
import '../../widgets/app_buttons.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Spacer(flex: 2),

              // Title
              Text(
                'Request Password Reset',
                style: textTheme.titleLarge,
              ),
              const SizedBox(height: 24),

              // Email Input Field
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.done,
                autofillHints: const [AutofillHints.email],
                decoration: const InputDecoration(
                  hintText: 'Enter your email',
                ),
              ),
              const SizedBox(height: 16),

              // Send Password Request Email Button
              AppPrimaryButton(
                label: 'Send Password Request Email',
                onPressed: () {
                  // TODO: Handle send password reset email
                },
              ),
              const SizedBox(height: 12),

              // Go Back to Log In Button
              AppSecondaryButton(
                label: 'Go Back to Log In',
                onPressed: () => Navigator.pop(context),
              ),

              const Spacer(flex: 3),
            ],
          ),
        ),
      ),
    );
  }
}
