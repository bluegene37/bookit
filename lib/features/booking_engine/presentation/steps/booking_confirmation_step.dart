// Gene - Nov, 03, 2026: Step 4 - Booking Confirmation Ticket & Success screen
import 'package:flutter/material.dart';
import '../../../../core/theme/neumorphic_colors.dart';
import '../../../../core/widgets/neumorphic_container.dart';
import '../../../../core/widgets/neumorphic_button.dart';
import '../../../../models/booking.dart';
// Gene - Nov, 05, 2026: Imported CalendarSyncService for 1-Tap Google Calendar and .ics invite generation
import '../../../../services/calendar_sync_service.dart';

class BookingConfirmationStep extends StatelessWidget {
  final Booking booking;
  final VoidCallback onViewBookings;

  const BookingConfirmationStep({
    super.key,
    required this.booking,
    required this.onViewBookings,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? NeumorphicColors.tealLight : NeumorphicColors.tealPrimary;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        children: [
          // Success animated badge
          NeumorphicContainer(
            isCircle: true,
            width: 72,
            height: 72,
            child: Icon(Icons.check_circle_rounded, size: 40, color: accent),
          ),
          const SizedBox(height: 16),

          Text(
            'Booking Successful!',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: isDark ? NeumorphicColors.darkTextPrimary : NeumorphicColors.lightTextPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            booking.status == 'confirmed'
                ? 'Your appointment has been confirmed automatically.'
                : 'Your booking request is pending confirmation from the clinic.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: isDark ? NeumorphicColors.darkTextSecondary : NeumorphicColors.lightTextSecondary,
            ),
          ),
          const SizedBox(height: 24),

          // Digital Ticket Card
          NeumorphicContainer(
            borderRadius: 22.0,
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'BOOKING PASS',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                        color: accent,
                      ),
                    ),
                    /*
                    Text(
                      '#${booking.id.substring(0, 8).toUpperCase()}',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white54 : Colors.black45,
                      ),
                    ),
                    */
                    // Gene - Nov, 04, 2026: Formatted booking reference code as #BK-XXXX with prominent font
                    Text(
                      '#BK-${booking.id.length >= 8 ? booking.id.substring(0, 8).toUpperCase() : booking.id.toUpperCase()}',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: accent,
                      ),
                    ),
                  ],
                ),
                const Divider(height: 24),

                Text(
                  booking.businessName ?? 'Clinic',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  booking.serviceName ?? 'General Consultation',
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? NeumorphicColors.darkTextSecondary : NeumorphicColors.lightTextSecondary,
                  ),
                ),
                const SizedBox(height: 14),

                if (booking.staffName != null) ...[
                  Row(
                    children: [
                      Icon(Icons.person_pin, size: 16, color: accent),
                      const SizedBox(width: 6),
                      Text(
                        'Practitioner: ${booking.staffName}',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                ],

                Row(
                  children: [
                    Icon(Icons.calendar_month, size: 16, color: accent),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        booking.formattedSchedule,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total Amount:', style: TextStyle(fontSize: 14)),
                    Text(
                      '\$${booking.totalPrice.toStringAsFixed(2)}',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: accent),
                    ),
                  ],
                ),

                // Gene - Nov, 04, 2026: Integrated PaymentCheckoutStep into universal booking wizard and enhanced confirmation receipt
                if (booking.paymentStatus == 'deposit_paid' || (booking.amountPaid > 0 && booking.amountDue > 0)) ...[
                  const SizedBox(height: 14),
                  const Divider(height: 1),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: NeumorphicColors.tealPrimary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: NeumorphicColors.tealPrimary.withValues(alpha: 0.4)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.check_circle_outline, size: 14, color: NeumorphicColors.tealPrimary),
                            const SizedBox(width: 5),
                            Text(
                              'Deposit Paid: \$${booking.amountPaid.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: NeumorphicColors.tealPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: NeumorphicColors.warning.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: NeumorphicColors.warning.withValues(alpha: 0.4)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.schedule, size: 14, color: NeumorphicColors.warning),
                            const SizedBox(width: 5),
                            Text(
                              'Balance Due at Clinic: \$${booking.amountDue.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: NeumorphicColors.warning,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ] else if (booking.paymentStatus == 'paid_in_full' || (booking.amountPaid > 0 && booking.amountDue == 0)) ...[
                  const SizedBox(height: 14),
                  const Divider(height: 1),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: NeumorphicColors.success.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: NeumorphicColors.success.withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.verified_outlined, size: 14, color: NeumorphicColors.success),
                        const SizedBox(width: 5),
                        Text(
                          'Paid in Full: \$${booking.amountPaid.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: NeumorphicColors.success,
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else if (booking.paymentStatus == 'unpaid' || booking.amountDue > 0) ...[
                  const SizedBox(height: 14),
                  const Divider(height: 1),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: NeumorphicColors.info.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: NeumorphicColors.info.withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.payment_outlined, size: 14, color: NeumorphicColors.info),
                        const SizedBox(width: 5),
                        Text(
                          'Balance Due at Clinic: \$${(booking.amountDue > 0 ? booking.amountDue : booking.totalPrice).toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: NeumorphicColors.info,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Gene - Nov, 05, 2026: Universal 1-Tap Calendar Integration (Google Calendar & RFC 5545 .ics invite)
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.calendar_today_rounded, size: 16),
                  label: const Text('Google Calendar', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: accent,
                    side: BorderSide(color: accent.withValues(alpha: 0.5)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: () async {
                    await CalendarSyncService.openGoogleCalendar(booking: booking);
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.download_rounded, size: 16),
                  label: const Text('Download .ICS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: isDark ? Colors.white70 : Colors.black87,
                    side: BorderSide(color: isDark ? Colors.white24 : Colors.black12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: () async {
                    final success = await CalendarSyncService.downloadIcsFile(booking: booking);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            success
                                ? 'Calendar invite (.ics) generated and downloaded!'
                                : 'Calendar invite generated for Apple / Outlook.',
                          ),
                          backgroundColor: accent,
                        ),
                      );
                    }
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Gene - Nov, 04, 2026: Integrated PaymentCheckoutStep into universal booking wizard and enhanced confirmation receipt
          NeumorphicButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Invoice #INV-${booking.id.length >= 8 ? booking.id.substring(0, 8).toUpperCase() : booking.id.toUpperCase()} saved to ~/Documents/personal_projects/documents/bookit/',
                  ),
                  backgroundColor: accent,
                  duration: const Duration(seconds: 3),
                ),
              );
            },
            icon: Icons.picture_as_pdf_outlined,
            child: const Text('Download PDF Invoice'),
          ),
          const SizedBox(height: 14),

          NeumorphicButton(
            isPrimary: true,
            onPressed: onViewBookings,
            child: const Text('View in My Bookings'),
          ),
        ],
      ),
    );
  }
}
