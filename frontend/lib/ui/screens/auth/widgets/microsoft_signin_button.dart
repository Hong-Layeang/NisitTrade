import 'package:flutter/material.dart';

class MicrosoftSignInButton extends StatefulWidget {
  final VoidCallback onPressed;
  final bool isLoading;

  const MicrosoftSignInButton({
    super.key,
    required this.onPressed,
    this.isLoading = false,
  });

  @override
  State<MicrosoftSignInButton> createState() => _MicrosoftSignInButtonState();
}

class _MicrosoftSignInButtonState extends State<MicrosoftSignInButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: widget.isLoading ? null : (_) => setState(() => _isPressed = true),
      onTapUp: widget.isLoading ? null : (_) {
        setState(() => _isPressed = false);
        widget.onPressed();
      },
      onTapCancel: widget.isLoading ? null : () => setState(() => _isPressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: _isPressed && !widget.isLoading ? Colors.grey.shade200 : Colors.white,
          border: Border.all(color: Colors.grey.shade300, width: 1),
          borderRadius: BorderRadius.circular(6),
          boxShadow: [
            if (_isPressed && !widget.isLoading)
              BoxShadow(
                color: Colors.grey.withValues(alpha: 0.3),
                blurRadius: 2,
                offset: const Offset(0, 1),
              ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (!widget.isLoading)
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: _buildMicrosoftLogo(),
                ),
              if (widget.isLoading)
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.grey.shade600),
                    ),
                  ),
                ),
              Opacity(
                opacity: widget.isLoading ? 0.6 : 1.0,
                child: Text(
                  widget.isLoading ? 'Signing in...' : 'Sign in with Microsoft',
                  style: TextStyle(
                    color: Colors.grey.shade800,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMicrosoftLogo() {
    // Microsoft logo: 4 squares in 2x2 grid
    const logoSize = 16.0;
    const squareSize = 6.5;

    return SizedBox(
      width: logoSize,
      height: logoSize,
      child: Stack(
        children: [
          // Top-left (red)
          Positioned(
            top: 0,
            left: 0,
            child: Container(
              width: squareSize,
              height: squareSize,
              decoration: const BoxDecoration(
                color: Color(0xFFF25022),
              ),
            ),
          ),
          // Top-right (green)
          Positioned(
            top: 0,
            right: 0,
            child: Container(
              width: squareSize,
              height: squareSize,
              decoration: const BoxDecoration(
                color: Color(0xFF7FBA00),
              ),
            ),
          ),
          // Bottom-left (blue)
          Positioned(
            bottom: 0,
            left: 0,
            child: Container(
              width: squareSize,
              height: squareSize,
              decoration: const BoxDecoration(
                color: Color(0xFF00A4EF),
              ),
            ),
          ),
          // Bottom-right (yellow)
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              width: squareSize,
              height: squareSize,
              decoration: const BoxDecoration(
                color: Color(0xFFFFB900),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
