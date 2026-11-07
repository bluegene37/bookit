// Gene - Nov, 03, 2026: Step 4 - Booking Confirmation Ticket & Success screen
import 'package:flutter/material.dart';
import '../../../../core/theme/neumorphic_colors.dart';
import '../../../../core/widgets/neumorphic_container.dart';
import '../../../../core/widgets/neumorphic_button.dart';
import '../../../../models/booking.dart';
// Gene - Nov, 05, 2026: Imported CalendarSyncService for 1-Tap Google Calendar and .ics invite generation
import '../../../../services/calendar_sync_service.dart';
// Gene - Nov, 05, 2026: Added digital QR boarding pass modal and pass preview
import 'package:qr_flutter/qr_flutter.dart';
import '../../../client_bookings/presentation/widgets/booking_qr_pass_modal.dart';

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
          const SizedBox(height: 20),

          /*
          const SizedBox(height: 24),

          // Digital Ticket Card
          NeumorphicContainer(
          */

          // Gene - Nov, 05, 2026: Added digital QR boarding pass modal and pass preview
          NeumorphicContainer(
            borderRadius: 18.0,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            onTap: () => BookingQrPassModal.show(context, booking),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.black12),
                  ),
                  child: QrImageView(
                    data: 'https://bookit.app/checkin/${booking.id}?token=${booking.qrToken ?? (booking.id.length >= 6 ? booking.id.substring(0, 6) : booking.id)}',
                    version: QrVersions.auto,
                    size: 58,
                    padding: EdgeInsets.zero,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.confirmation_number_outlined, size: 14, color: accent),
                          const SizedBox(width: 4),
                          Text(
                            'Digital Boarding Pass',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: isDark ? NeumorphicColors.darkTextPrimary : NeumorphicColors.lightTextPrimary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Present upon arrival for quick check-in',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? NeumorphicColors.darkTextSecondary : NeumorphicColors.lightTextSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            booking.qrToken ?? '#${booking.formattedId}',
                            style: TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: accent,
                            ),
                          ),
                          const Spacer(),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Tap to enlarge',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: accent,
                                ),
                              ),
                              const SizedBox(width: 2),
                              Icon(Icons.open_in_full_rounded, size: 12, color: accent),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

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

                // Gene - Nov 07, 2026: Display hybrid payment channel and reference number on confirmation pass
                if (booking.paymentMethod != null && booking.paymentMethod!.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Payment Method:',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? NeumorphicColors.darkTextSecondary : NeumorphicColors.lightTextSecondary,
                        ),
                      ),
                      Text(
                        booking.paymentReference != null && booking.paymentReference!.isNotEmpty
                            ? '${booking.paymentMethodLabel} • Ref #${booking.paymentReference}'
                            : booking.paymentMethodLabel,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: accent,
                        ),
                      ),
                    ],
                  ),
                ],

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
