import 'dart:io';

import 'package:flutter/material.dart';
import '../../../utils/constants/colors.dart';

class SellHeaderRow extends StatelessWidget {
  const SellHeaderRow({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
        ),
        const SizedBox(width: 8),
        const Expanded(
          child: Text(
            'Add Your Listing',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        const SizedBox(width: 44),
      ],
    );
  }
}

class SectionLabel extends StatelessWidget {
  final String text;

  const SectionLabel({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      ),
    );
  }
}

class OutlinedField extends StatelessWidget {
  final String hintText;
  final int maxLines;
  final TextInputType? keyboardType;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final TextInputAction? textInputAction;
  final bool isDense;
  final EdgeInsets? contentPadding;

  const OutlinedField({
    super.key,
    required this.hintText,
    this.maxLines = 1,
    this.keyboardType,
    this.controller,
    this.onChanged,
    this.textInputAction,
    this.isDense = false,
    this.contentPadding,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(color: AppColors.textSecondary),
        isDense: isDense,
        contentPadding:
            contentPadding ??
            (isDense
                ? const EdgeInsets.symmetric(horizontal: 12, vertical: 10)
                : const EdgeInsets.symmetric(horizontal: 16, vertical: 14)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.6),
        ),
      ),
    );
  }
}

class DropdownField extends StatelessWidget {
  final String hintText;

  const DropdownField({super.key, required this.hintText});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 1.5),
      ),
      child: Row(
        children: [
          const Icon(Icons.keyboard_arrow_down, color: AppColors.textSecondary),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              hintText,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}

class CategoryDropdownField<T> extends StatelessWidget {
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?>? onChanged;
  final String hint;

  const CategoryDropdownField({
    super.key,
    required this.value,
    required this.items,
    required this.onChanged,
    this.hint = 'Select category',
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      value: value,
      decoration: InputDecoration(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 8,
        ),
        isDense: true,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: AppColors.border,
            width: 1.5,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: AppColors.primary,
            width: 1.6,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: Colors.red,
            width: 1.5,
          ),
        ),
      ),
      isExpanded: true,
      hint: Text(
        hint,
        style: const TextStyle(
          fontSize: 14,
          color: AppColors.textSecondary,
        ),
        overflow: TextOverflow.ellipsis,
      ),
      style: const TextStyle(
        fontSize: 14,
        color: AppColors.textPrimary,
      ),
      iconSize: 20,
      items: items,
      onChanged: onChanged,
      menuMaxHeight: 300,
      dropdownColor: Colors.white,
    );
  }
}

class PhotoGrid extends StatelessWidget {
  final List<String> imagePaths;
  final int maxCount;
  final VoidCallback onAddTap;
  final ValueChanged<int> onRemoveTap;

  const PhotoGrid({
    super.key,
    required this.imagePaths,
    required this.maxCount,
    required this.onAddTap,
    required this.onRemoveTap,
  });

  @override
  Widget build(BuildContext context) {
    final canAddMore = imagePaths.length < maxCount;
    final showMinimumSlots = imagePaths.length < 3;
    final itemCount = showMinimumSlots
        ? 3
        : (canAddMore ? imagePaths.length + 1 : imagePaths.length);

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: itemCount,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemBuilder: (context, index) {
        if (index >= imagePaths.length) {
          return PhotoTile(onTap: onAddTap);
        }

        return PhotoTile(
          imagePath: imagePaths[index],
          onRemoveTap: () => onRemoveTap(index),
        );
      },
    );
  }
}

class PhotoTile extends StatelessWidget {
  final String? imagePath;
  final VoidCallback? onTap;
  final VoidCallback? onRemoveTap;

  const PhotoTile({
    super.key,
    this.imagePath,
    this.onTap,
    this.onRemoveTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border, width: 1.2),
      ),
      child: imagePath == null
          ? InkWell(
              onTap: onTap,
              child: const Center(
                child: Icon(Icons.add, color: AppColors.textSecondary, size: 32),
              ),
            )
          : Stack(
              fit: StackFit.expand,
              children: [
                Image.file(
                  File(imagePath!),
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: AppColors.surface,
                    child: const Icon(
                      Icons.image,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                Positioned(
                  top: 6,
                  right: 6,
                  child: InkWell(
                    onTap: onRemoveTap,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 14,
                      ),
                    ),
                  ),
                ),
              ],
            ),
      );
  }
}
