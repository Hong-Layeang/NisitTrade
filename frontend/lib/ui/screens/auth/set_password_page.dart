import 'package:flutter/material.dart';

import '../../../services/auth/microsoft_auth_service.dart';
import '../../../utils/constants/colors.dart';
import '../../../utils/routes/app_routes.dart';
import '../../widgets/common/app_buttons.dart';
import '../../widgets/common/app_form_fields.dart';

class SetPasswordArgs {
  final String accessToken;
  final String? email;

  const SetPasswordArgs({
    required this.accessToken,
    this.email,
  });
}

class SetPasswordPage extends StatefulWidget {
  final SetPasswordArgs args;

  const SetPasswordPage({super.key, required this.args});

  @override
  State<SetPasswordPage> createState() => _SetPasswordPageState();
}

class _SetPasswordPageState extends State<SetPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  final _passwordFocus = FocusNode();
  final _confirmFocus = FocusNode();
  bool _obscurePassword = true;
  bool _isSubmitting = false;
  bool _hasAttemptedSubmit = false;

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(_handlePasswordChange);
  }

  @override
  void dispose() {
    _passwordController.removeListener(_handlePasswordChange);
    _passwordController.dispose();
    _confirmController.dispose();
    _passwordFocus.dispose();
    _confirmFocus.dispose();
    super.dispose();
  }

  void _handlePasswordChange() {
    if (!_hasAttemptedSubmit && _confirmController.text.isEmpty) {
      return;
    }
    _formKey.currentState?.validate();
  }

  String? _validatePassword(String? value) {
    // Keep client-side validation lightweight; backend enforces full policy.
    final password = value?.trim() ?? '';

    if (password.isEmpty) {
      return 'Please enter your password.';
    }

    if (password.length < 8) {
      return 'Password must be at least 8 characters.';
    }

    return null;
  }

  String? _validateConfirmation(String? value) {
    final confirm = value?.trim() ?? '';
    if (confirm.isEmpty) {
      return 'Please confirm your password.';
    }

    if (confirm != _passwordController.text.trim()) {
      return 'Passwords do not match.';
    }

    return null;
  }

  Future<void> _handleSubmit() async {
    if (_isSubmitting) {
      return;
    }

    setState(() {
      _hasAttemptedSubmit = true;
    });

    final formState = _formKey.currentState;
    if (formState == null || !formState.validate()) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    final result = await MicrosoftAuthService.instance.setPassword(
      accessToken: widget.args.accessToken,
      password: _passwordController.text.trim(),
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _isSubmitting = false;
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
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Form(
            key: _formKey,
            autovalidateMode: _hasAttemptedSubmit
                ? AutovalidateMode.onUserInteraction
                : AutovalidateMode.disabled,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Spacer(flex: 2),
                Text('Set Password', style: textTheme.titleLarge),
                if (widget.args.email != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    widget.args.email!,
                    style: textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                AppTextFormField(
                  controller: _passwordController,
                  focusNode: _passwordFocus,
                  obscureText: _obscurePassword,
                  enabled: !_isSubmitting,
                  textInputAction: TextInputAction.next,
                  onFieldSubmitted: (_) {
                    FocusScope.of(context).requestFocus(_confirmFocus);
                  },
                  validator: _validatePassword,
                  hintText: 'New password',
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
                AppTextFormField(
                  controller: _confirmController,
                  focusNode: _confirmFocus,
                  obscureText: _obscurePassword,
                  enabled: !_isSubmitting,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _handleSubmit(),
                  validator: _validateConfirmation,
                  hintText: 'Confirm password',
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
                const SizedBox(height: 24),
                AppPrimaryButton(
                  label: _isSubmitting ? 'Setting Password...' : 'Set Password',
                  isLoading: _isSubmitting,
                  onPressed: _isSubmitting ? null : _handleSubmit,
                ),
                const Spacer(flex: 3),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
