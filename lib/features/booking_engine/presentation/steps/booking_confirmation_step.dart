// Gene - Nov, 03, 2026: Step 4 - Booking Confirmation Ticket & Success screen
import 'package:flutter/material.dart';
import '../../../../core/theme/neumorphic_colors.dart';
import '../../../../core/widgets/neumorphic_container.dart';
import '../../../../core/widgets/neumorphic_button.dart';
import '../../../../models/booking.dart';

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
                    Text(
                      '#${booking.id.substring(0, 8).toUpperCase()}',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white54 : Colors.black45,
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
              ],
            ),
          ),
          const SizedBox(height: 28),

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
