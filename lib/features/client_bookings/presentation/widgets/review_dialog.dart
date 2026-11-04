// Gene - Nov, 05, 2026: Tactile Neumorphic Review Submission Dialog with interactive 5-star rating and live business score updates
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/neumorphic_colors.dart';
import '../../../../core/widgets/neumorphic_button.dart';
import '../../../../models/booking.dart';
import '../../../../models/review.dart';
import '../../../../services/business_service.dart';

class ReviewSubmissionDialog extends ConsumerStatefulWidget {
  final Booking booking;

  const ReviewSubmissionDialog({super.key, required this.booking});

  static Future<void> show(BuildContext context, Booking booking) {
    return showDialog(
      context: context,
      builder: (ctx) => ReviewSubmissionDialog(booking: booking),
    );
  }

  @override
  ConsumerState<ReviewSubmissionDialog> createState() => _ReviewSubmissionDialogState();
}

class _ReviewSubmissionDialogState extends ConsumerState<ReviewSubmissionDialog> {
  int _selectedRating = 5;
  final _commentController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  void _submitReview() async {
    setState(() => _isSubmitting = true);

    final review = Review(
      id: 'rev-${DateTime.now().millisecondsSinceEpoch}',
      businessId: widget.booking.businessId,
      clientId: widget.booking.clientId,
      bookingId: widget.booking.id,
      rating: _selectedRating,
      comment: _commentController.text.trim().isNotEmpty
          ? _commentController.text.trim()
          : 'Great experience and attentive care!',
      clientName: widget.booking.clientName ?? 'Michael Chen',
      createdAt: DateTime.now(),
    );

    await ref.read(businessServiceProvider).createReview(review);

    // Refresh providers
    ref.invalidate(businessReviewsProvider(widget.booking.businessId));
    ref.invalidate(businessDetailProvider(widget.booking.businessId));
    ref.invalidate(businessListProvider);

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Thank you! Your $_selectedRating-star review for ${widget.booking.businessName} was posted.'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: NeumorphicColors.success,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? NeumorphicColors.darkTextPrimary : NeumorphicColors.lightTextPrimary;
    final textSecondary = isDark ? NeumorphicColors.darkTextSecondary : NeumorphicColors.lightTextSecondary;

    return AlertDialog(
      title: Text('Rate & Review Experience', style: TextStyle(fontWeight: FontWeight.w800, color: textPrimary)),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'How was your visit at ${widget.booking.businessName} for "${widget.booking.serviceName ?? 'Service'}"?',
              style: TextStyle(fontSize: 13, color: textSecondary),
            ),
            const SizedBox(height: 20),

            // Interactive Star Rating Bar
            Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  final starNum = index + 1;
                  final isFilled = starNum <= _selectedRating;

                  return GestureDetector(
                    onTap: () => setState(() => _selectedRating = starNum),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Icon(
                        isFilled ? Icons.star_rounded : Icons.star_outline_rounded,
                        size: 38,
                        color: isFilled ? Colors.amber : textSecondary.withValues(alpha: 0.4),
                      ),
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: 6),
            Center(
              child: Text(
                _getRatingLabel(_selectedRating),
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.amber),
              ),
            ),
            const SizedBox(height: 18),

            // Comment text area
            Text('Your Comments (Optional)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: textPrimary)),
            const SizedBox(height: 6),
            TextField(
              controller: _commentController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Share details of your experience, staff professionalism, cleanliness...',
                hintStyle: TextStyle(fontSize: 12, color: textSecondary.withValues(alpha: 0.6)),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        NeumorphicButton(
          isPrimary: true,
          isLoading: _isSubmitting,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          onPressed: _submitReview,
          child: const Text('Submit Review', style: TextStyle(fontSize: 13)),
        ),
      ],
    );
  }

  String _getRatingLabel(int rating) {
    switch (rating) {
      case 5:
        return 'Exceptional (5 / 5)';
      case 4:
        return 'Great (4 / 5)';
      case 3:
        return 'Average (3 / 5)';
      case 2:
        return 'Needs Improvement (2 / 5)';
      case 1:
      default:
        return 'Poor (1 / 5)';
    }
  }
}
