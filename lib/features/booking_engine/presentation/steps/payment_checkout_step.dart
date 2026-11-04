// Gene - Nov, 04, 2026: Tactile Neumorphic Payment Checkout step with deposit breakdown and Stripe integration
import 'package:flutter/material.dart';
import '../../../../core/theme/neumorphic_colors.dart';
import '../../../../core/widgets/neumorphic_container.dart';
import '../../../../core/widgets/neumorphic_button.dart';
import '../../../../models/service_item.dart';

class PaymentCheckoutStep extends StatelessWidget {
  final ServiceItem? service;
  final double totalPrice;
  final double dueToday;
  final double dueAtVenue;
  final String? practitionerName;
  final VoidCallback onProceed;
  final bool isLoading;

  const PaymentCheckoutStep({
    super.key,
    this.service,
    required this.totalPrice,
    required this.dueToday,
    required this.dueAtVenue,
    this.practitionerName,
    required this.onProceed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? NeumorphicColors.tealLight : NeumorphicColors.tealPrimary;
    final textPrimary = isDark ? NeumorphicColors.darkTextPrimary : NeumorphicColors.lightTextPrimary;
    final textSecondary = isDark ? NeumorphicColors.darkTextSecondary : NeumorphicColors.lightTextSecondary;

    final isPayOnArrival = dueToday <= 0 || service?.paymentPolicy == 'pay_at_venue';

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header / Instruction
          Text(
            'Review & Payment',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Confirm appointment details and complete checkout securely.',
            style: TextStyle(
              fontSize: 13,
              color: textSecondary,
            ),
          ),
          const SizedBox(height: 20),

          // 1. Raised Neumorphic Container: Service & Practitioner Details
          NeumorphicContainer(
            borderRadius: 20.0,
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'SELECTED SERVICE',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                        color: accent,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        service?.paymentPolicy == 'deposit'
                            ? 'Deposit Policy'
                            : (service?.paymentPolicy == 'pay_at_venue' ? 'Pay at Venue' : 'Full Payment'),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: accent,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  service?.name ?? 'Standard Appointment',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: textPrimary,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Icon(Icons.schedule, size: 16, color: accent),
                    const SizedBox(width: 6),
                    Text(
                      service?.formattedDuration ?? '30 min',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: textSecondary,
                      ),
                    ),
                    if (practitionerName != null && practitionerName!.isNotEmpty) ...[
                      const SizedBox(width: 16),
                      Icon(Icons.person_outline, size: 16, color: accent),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          practitionerName!,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 2. Inset Neumorphic Container: Financial Breakdown
          NeumorphicContainer(
            borderRadius: 20.0,
            isInset: true,
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.receipt_long_outlined, size: 18, color: accent),
                    const SizedBox(width: 8),
                    Text(
                      'Payment Summary',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: textPrimary,
                      ),
                    ),
                  ],
                ),
                const Divider(height: 24),

                // Total Fee
                _buildFeeRow(
                  context,
                  label: 'Total Fee',
                  amount: '\$${totalPrice.toStringAsFixed(2)}',
                  isBold: true,
                  textColor: textPrimary,
                ),
                const SizedBox(height: 12),

                // Due Today / Deposit
                _buildFeeRow(
                  context,
                  label: (service?.paymentPolicy == 'deposit' || dueAtVenue > 0)
                      ? 'Due Today (Deposit)'
                      : 'Due Today',
                  amount: '\$${dueToday.toStringAsFixed(2)}',
                  isBold: true,
                  textColor: accent,
                ),

                // Remaining Balance Due at Clinic
                if (dueAtVenue > 0) ...[
                  const SizedBox(height: 12),
                  _buildFeeRow(
                    context,
                    label: 'Remaining Balance (Due at Clinic)',
                    amount: '\$${dueAtVenue.toStringAsFixed(2)}',
                    isBold: false,
                    textColor: textSecondary,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Security Trust Info
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock_outline, size: 14, color: textSecondary),
              const SizedBox(width: 6),
              Text(
                'Guaranteed secure checkout via Stripe',
                style: TextStyle(
                  fontSize: 12,
                  color: textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // 3. Neumorphic Action Button
          NeumorphicButton(
            isPrimary: true,
            isLoading: isLoading,
            onPressed: isLoading ? null : onProceed,
            icon: isPayOnArrival ? Icons.check_circle_outline : Icons.payment,
            child: Text(
              isPayOnArrival
                  ? 'Confirm Booking (Pay on Arrival)'
                  : 'Pay via Stripe',
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeeRow(
    BuildContext context, {
    required String label,
    required String amount,
    required bool isBold,
    required Color textColor,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
            color: textColor,
          ),
        ),
        Text(
          amount,
          style: TextStyle(
            fontSize: isBold ? 16 : 14,
            fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
            color: textColor,
          ),
        ),
      ],
    );
  }
}
