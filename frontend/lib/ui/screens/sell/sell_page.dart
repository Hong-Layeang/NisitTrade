import 'package:flutter/material.dart';
import '../../../utils/constants/colors.dart';
import '../../widgets/common/app_buttons.dart';
import '../../widgets/sell/sell_form_widgets.dart';

class SellPage extends StatelessWidget {
  const SellPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SellHeaderRow(),
            const SizedBox(height: 18),
            const SectionLabel(text: 'Title'),
            const SizedBox(height: 8),
            const OutlinedField(hintText: 'Name'),
            const SizedBox(height: 16),
            const SectionLabel(text: 'Description'),
            const SizedBox(height: 8),
            const OutlinedField(
              hintText: 'Detailed description of your product',
              maxLines: 5,
            ),
            const SizedBox(height: 16),
            const Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SectionLabel(text: 'Category'),
                      SizedBox(height: 8),
                      DropdownField(hintText: 'Select'),
                    ],
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SectionLabel(text: 'Price (in \$)'),
                      SizedBox(height: 8),
                      OutlinedField(
                        hintText: '0.0',
                        keyboardType: TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            const SectionLabel(text: 'Photos'),
            const SizedBox(height: 6),
            Text.rich(
              TextSpan(
                text:
                    'Capture all the angles and details. Your first square is the key image. ',
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
                children: const [
                  TextSpan(
                    text: 'At least 2 photos required.',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            const PhotoGrid(count: 6),
            const SizedBox(height: 22),
            AppPrimaryButton(label: 'Add', onPressed: () {}),
          ],
        ),
      ),
    );
  }
}