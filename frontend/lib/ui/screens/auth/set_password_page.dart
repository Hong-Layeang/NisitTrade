import 'package:flutter/material.dart';

import '../../../services/auth/microsoft_auth_service.dart';
import '../../../utils/routes/app_routes.dart';

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
  bool _obscureConfirm = true;
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

  InputDecoration _buildInputDecoration({
    required String hintText,
    required bool obscureText,
    required VoidCallback onToggleVisibility,
  }) {
    return InputDecoration(
      hintText: hintText,
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
          obscureText ? Icons.visibility_off : Icons.visibility,
          color: Colors.grey,
        ),
        onPressed: onToggleVisibility,
      ),
    );
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
    return Scaffold(
      backgroundColor: Colors.white,
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
                const Text(
                  'Set Password',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (widget.args.email != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    widget.args.email!,
                    style: const TextStyle(
                      color: Colors.black54,
                      fontSize: 14,
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                TextFormField(
                  controller: _passwordController,
                  focusNode: _passwordFocus,
                  obscureText: _obscurePassword,
                  enabled: !_isSubmitting,
                  textInputAction: TextInputAction.next,
                  onFieldSubmitted: (_) {
                    FocusScope.of(context).requestFocus(_confirmFocus);
                  },
                  validator: _validatePassword,
                  decoration: _buildInputDecoration(
                    hintText: 'New password',
                    obscureText: _obscurePassword,
                    onToggleVisibility: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _confirmController,
                  focusNode: _confirmFocus,
                  obscureText: _obscureConfirm,
                  enabled: !_isSubmitting,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _handleSubmit(),
                  validator: _validateConfirmation,
                  decoration: _buildInputDecoration(
                    hintText: 'Confirm password',
                    obscureText: _obscureConfirm,
                    onToggleVisibility: () {
                      setState(() {
                        _obscureConfirm = !_obscureConfirm;
                      });
                    },
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _handleSubmit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00BCD4),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      _isSubmitting ? 'Setting Password...' : 'Set Password',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
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
