import 'package:flutter/material.dart';
import '../../../core/constants/colors.dart';

class SearchBarWidget extends StatefulWidget {
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final String hintText;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;

  const SearchBarWidget({
    super.key,
    this.controller,
    this.focusNode,
    this.hintText = 'Search',
    this.onChanged,
    this.onTap,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  State<SearchBarWidget> createState() => _SearchBarWidgetState();
}

class _SearchBarWidgetState extends State<SearchBarWidget> {
  bool _hasText = false;
  late final TextEditingController _effectiveController;
  bool _ownsController = false;

  @override
  void initState() {
    super.initState();
    if (widget.controller == null) {
      _effectiveController = TextEditingController();
      _ownsController = true;
    } else {
      _effectiveController = widget.controller!;
    }
    _hasText = _effectiveController.text.isNotEmpty;
    _effectiveController.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    final hasText = _effectiveController.text.isNotEmpty;
    if (hasText != _hasText) {
      setState(() => _hasText = hasText);
    }
  }

  void _clearText() {
    _effectiveController.clear();
    widget.onChanged?.call('');
    widget.focusNode?.requestFocus();
  }

  @override
  void dispose() {
    _effectiveController.removeListener(_onTextChanged);
    if (_ownsController) {
      _effectiveController.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: widget.padding,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
        ),
        child: TextField(
          controller: _effectiveController,
          focusNode: widget.focusNode,
          onChanged: widget.onChanged,
          onTap: widget.onTap,
          onTapOutside: (_) {
            FocusScope.of(context).unfocus();
          },
          decoration: InputDecoration(
            hintText: widget.hintText,
            hintStyle: textTheme.bodyLarge?.copyWith(
              color: AppColors.textSecondary,
            ),
            prefixIcon: const Icon(
              Icons.search,
              color: AppColors.textSecondary,
            ),
            suffixIcon: _hasText
                ? IconButton(
                    icon: const Icon(
                      Icons.clear,
                      color: AppColors.textSecondary,
                    ),
                    onPressed: _clearText,
                  )
                : null,
            border: InputBorder.none,
            focusedBorder: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
        ),
      ),
    );
  }
}
