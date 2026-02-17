import 'package:flutter/material.dart';
import '../../../utils/constants/colors.dart';
import '../../widgets/common/app_buttons.dart';
import '../../widgets/common/app_form_fields.dart';

class JoinWaitlistDialog extends StatefulWidget {
  const JoinWaitlistDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => const JoinWaitlistDialog(),
    );
  }

  @override
  State<JoinWaitlistDialog> createState() => _JoinWaitlistDialogState();
}

class _JoinWaitlistDialogState extends State<JoinWaitlistDialog> {
  final _schoolNameController = TextEditingController();
  final _emailController = TextEditingController();

  @override
  void dispose() {
    _schoolNameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Close Button
            Align(
              alignment: Alignment.topRight,
              child: GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: const Icon(
                  Icons.close,
                  size: 28,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            const SizedBox(height: 8),

            // Title
            Text(
              'Join the Waitlist',
              textAlign: TextAlign.center,
              style: textTheme.titleLarge?.copyWith(color: AppColors.primary),
            ),
            const SizedBox(height: 16),

            // Description
            Text(
              'Want Empor at your school? Join our waitlist and be the first to know when we expand to your campus!',
              textAlign: TextAlign.center,
              style: textTheme.bodyMedium?.copyWith(
                color: AppColors.textPrimary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),

            // School Name Label
            Text('School Name', style: textTheme.labelLarge),
            const SizedBox(height: 8),

            // School Name Input Field
            AppTextField(
              controller: _schoolNameController,
              hintText: 'Enter your school name',
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.organizationName],
            ),
            const SizedBox(height: 16),

            // Email Address Label
            Text('Email Address', style: textTheme.labelLarge),
            const SizedBox(height: 8),

            // Email Input Field
            AppTextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              hintText: 'Enter your student email',
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.email],
            ),
            const SizedBox(height: 24),

            // Register Button
            AppPrimaryButton(
              label: 'Register',
              onPressed: _onRegister,
            ),
          ],
        ),
      ),
    );
  }

  void _onRegister() {
    final schoolName = _schoolNameController.text.trim();
    final email = _emailController.text.trim();

    if (schoolName.isEmpty || email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all fields'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // TODO: Handle registration logic (API call)

    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Successfully joined the waitlist!'),
        backgroundColor: AppColors.primary,
      ),
    );
  }
}
