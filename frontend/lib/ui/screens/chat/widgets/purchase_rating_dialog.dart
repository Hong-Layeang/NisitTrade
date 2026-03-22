import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/constants/colors.dart';

Future<bool?> showDidYouBuyPrompt(
  BuildContext context, {
  required String productTitle,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.45),
    builder: (_) => _DidYouBuySheet(productTitle: productTitle),
  );
}

class _DidYouBuySheet extends StatelessWidget {
  final String productTitle;
  const _DidYouBuySheet({required this.productTitle});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        bottom: math.max(MediaQuery.viewInsetsOf(context).bottom, 16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _DragHandle(),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
            child: Column(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.10),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.shopping_bag_outlined,
                    color: AppColors.primary,
                    size: 28,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Purchase window expired',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Did you complete this purchase with the seller?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.sell_outlined,
                          size: 13, color: AppColors.primary),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          productTitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          side: const BorderSide(color: AppColors.border),
                          foregroundColor: AppColors.textSecondary,
                          textStyle: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        child: const Text("No, I didn't"),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size.fromHeight(50),
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          textStyle: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        child: const Text('Yes, I bought it!'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------

Future<bool?> showDidYouSellPrompt(
  BuildContext context, {
  required String productTitle,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.45),
    builder: (_) => _DidYouSellSheet(productTitle: productTitle),
  );
}

class _DidYouSellSheet extends StatelessWidget {
  final String productTitle;
  const _DidYouSellSheet({required this.productTitle});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        bottom: math.max(MediaQuery.viewInsetsOf(context).bottom, 16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _DragHandle(),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
            child: Column(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.10),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.storefront_outlined,
                    color: AppColors.primary,
                    size: 28,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Sale window expired',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Did you complete this sale with the buyer?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.sell_outlined,
                          size: 13, color: AppColors.primary),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          productTitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          side: const BorderSide(color: AppColors.border),
                          foregroundColor: AppColors.textSecondary,
                          textStyle: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        child: const Text("No, it didn't"),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size.fromHeight(50),
                          backgroundColor: const Color(0xFF0FBA81),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          textStyle: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        child: const Text('Yes, sold it!'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------

/// Result returned when the user submits a rating.
class PurchaseRatingResult {
  final int rating;
  final String? feedback;

  const PurchaseRatingResult({required this.rating, this.feedback});
}

/// Preset tag chips the user can tap for quick feedback.
const _kFeedbackTags = [
  'Quick response',
  'Good quality',
  'As described',
  'Nice packaging',
  'Trustworthy seller',
];

/// Shows the purchase-rating bottom sheet and returns PurchaseRatingResult
Future<PurchaseRatingResult?> showPurchaseRatingDialog(
  BuildContext context, {
  required String sellerName,
  required String productTitle,
  String? sellerAvatarUrl,
}) {
  return showModalBottomSheet<PurchaseRatingResult>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.45),
    builder: (_) => _PurchaseRatingSheet(
      sellerName: sellerName,
      productTitle: productTitle,
      sellerAvatarUrl: sellerAvatarUrl,
    ),
  );
}

// ---------------------------------------------------------------------------

class _PurchaseRatingSheet extends StatefulWidget {
  final String sellerName;
  final String productTitle;
  final String? sellerAvatarUrl;

  const _PurchaseRatingSheet({
    required this.sellerName,
    required this.productTitle,
    this.sellerAvatarUrl,
  });

  @override
  State<_PurchaseRatingSheet> createState() => _PurchaseRatingSheetState();
}

class _PurchaseRatingSheetState extends State<_PurchaseRatingSheet>
    with TickerProviderStateMixin {
  int _hoveredStar = 0;
  int _selectedRating = 0;
  final Set<String> _selectedTags = {};
  final TextEditingController _feedbackController = TextEditingController();
  bool _isSubmitting = false;

  // Per-star bounce controllers
  late final List<AnimationController> _starControllers;
  late final List<Animation<double>> _starScales;

  // Success checkmark enter animation
  late final AnimationController _checkEnterController;
  late final Animation<double> _checkScale;

  @override
  void initState() {
    super.initState();

    _starControllers = List.generate(5, (_) {
      return AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 280),
      );
    });

    _starScales = _starControllers.map((c) {
      return TweenSequence<double>([
        TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.35), weight: 40),
        TweenSequenceItem(tween: Tween(begin: 1.35, end: 0.90), weight: 30),
        TweenSequenceItem(tween: Tween(begin: 0.90, end: 1.0), weight: 30),
      ]).animate(CurvedAnimation(parent: c, curve: Curves.easeOut));
    }).toList();

    _checkEnterController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _checkScale = CurvedAnimation(parent: _checkEnterController, curve: Curves.elasticOut);
    _checkEnterController.forward();
  }

  @override
  void dispose() {
    for (final c in _starControllers) {
      c.dispose();
    }
    _checkEnterController.dispose();
    _feedbackController.dispose();
    super.dispose();
  }

  void _onStarTap(int starIndex) {
    HapticFeedback.lightImpact();
    setState(() => _selectedRating = starIndex + 1);

    // Bounce each newly-filled star in sequence
    for (int i = 0; i <= starIndex; i++) {
      Future.delayed(Duration(milliseconds: i * 40), () {
        if (mounted) {
          _starControllers[i].forward(from: 0);
        }
      });
    }
  }

  void _toggleTag(String tag) {
    HapticFeedback.selectionClick();
    setState(() {
      if (_selectedTags.contains(tag)) {
        _selectedTags.remove(tag);
      } else {
        _selectedTags.add(tag);
      }
    });
  }

  Future<void> _submit() async {
    if (_selectedRating == 0) {
      // Shake the stars row to hint selection is required
      for (int i = 0; i < 5; i++) {
        await Future.delayed(Duration(milliseconds: i * 30));
        if (mounted) _starControllers[i].forward(from: 0);
      }
      return;
    }

    // Build combined feedback from tags + optional text
    final parts = <String>[
      ..._selectedTags,
      if (_feedbackController.text.trim().isNotEmpty)
        _feedbackController.text.trim(),
    ];
    final feedback = parts.isNotEmpty ? parts.join(' · ') : null;

    Navigator.of(context).pop(
      PurchaseRatingResult(rating: _selectedRating, feedback: feedback),
    );
  }

  void _skip() => Navigator.of(context).pop();

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.viewInsetsOf(context).bottom;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: EdgeInsets.only(bottom: math.max(bottomPad, 16)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _DragHandle(),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 4, 24, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildSuccessIcon(),
                    const SizedBox(height: 18),
                    _buildHeader(),
                    const SizedBox(height: 24),
                    _buildStarRow(),
                    const SizedBox(height: 8),
                    _buildRatingLabel(),
                    const SizedBox(height: 24),
                    _buildTagChips(),
                    const SizedBox(height: 20),
                    _buildFeedbackField(),
                    const SizedBox(height: 28),
                    _buildActions(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccessIcon() {
    return ScaleTransition(
      scale: _checkScale,
      child: Container(
        width: 68,
        height: 68,
        decoration: BoxDecoration(
          color: const Color(0xFF0FBA81).withValues(alpha: 0.12),
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: Container(
          width: 50,
          height: 50,
          decoration: const BoxDecoration(
            color: Color(0xFF0FBA81),
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: const Icon(Icons.check_rounded, color: Colors.white, size: 28),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        const Text(
          'Purchase Confirmed!',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
            children: [
              const TextSpan(text: 'How was your experience with '),
              TextSpan(
                text: widget.sellerName,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const TextSpan(text: '?'),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.shopping_bag_outlined,
                  size: 14, color: AppColors.primary),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  widget.productTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStarRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (i) {
        final filled = i < _selectedRating;
        return GestureDetector(
          onTap: () => _onStarTap(i),
          onTapDown: (_) => setState(() => _hoveredStar = i + 1),
          onTapCancel: () => setState(() => _hoveredStar = 0),
          onTapUp: (_) => setState(() => _hoveredStar = 0),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 5),
            child: ScaleTransition(
              scale: _starScales[i],
              child: Icon(
                filled || i < _hoveredStar
                    ? Icons.star_rounded
                    : Icons.star_outline_rounded,
                size: 52,
                color: filled || i < _hoveredStar
                    ? const Color(0xFFF5A623)
                    : const Color(0xFFD4D4D4),
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildRatingLabel() {
    const labels = ['', 'Poor', 'Fair', 'Good', 'Great', 'Excellent'];
    const colors = [
      Colors.transparent,
      Color(0xFFD64545),
      Color(0xFFE67E22),
      Color(0xFFF5A623),
      Color(0xFF27AE60),
      Color(0xFF0FBA81),
    ];

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      transitionBuilder: (child, anim) =>
          FadeTransition(opacity: anim, child: child),
      child: _selectedRating == 0
          ? Text(
              'Tap a star to rate',
              key: const ValueKey('hint'),
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary.withValues(alpha: 0.7),
              ),
            )
          : Text(
              labels[_selectedRating],
              key: ValueKey(_selectedRating),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: colors[_selectedRating],
              ),
            ),
    );
  }

  Widget _buildTagChips() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: _kFeedbackTags.map((tag) {
          final selected = _selectedTags.contains(tag);
          return _TagChip(
            label: tag,
            isSelected: selected,
            onTap: () => _toggleTag(tag),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildFeedbackField() {
    return TextField(
      controller: _feedbackController,
      maxLines: 3,
      minLines: 1,
      maxLength: 300,
      decoration: InputDecoration(
        hintText: 'Add a comment (optional)',
        hintStyle: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 14,
        ),
        filled: true,
        fillColor: AppColors.surface,
        counterStyle: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
      ),
    );
  }

  Widget _buildActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Submit button
        SizedBox(
          height: 52,
          child: ElevatedButton(
            onPressed: _isSubmitting ? null : _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.5),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            child: _isSubmitting
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                        strokeWidth: 2.5, color: Colors.white),
                  )
                : const Text('Submit Review'),
          ),
        ),
        const SizedBox(height: 10),
        // Skip link
        TextButton(
          onPressed: _skip,
          style: TextButton.styleFrom(
            foregroundColor: AppColors.textSecondary,
            textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
          child: const Text('Skip for now'),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------

class _DragHandle extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 4),
      child: Container(
        width: 38,
        height: 4,
        decoration: BoxDecoration(
          color: const Color(0xFFDDDDDD),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------

class _TagChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _TagChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primary.withValues(alpha: 0.12)
                : AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.border,
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected ? AppColors.primary : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}
