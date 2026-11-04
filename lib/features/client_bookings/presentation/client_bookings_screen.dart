// Gene - Nov, 03, 2026: Appointments Hub for Clients (Upcoming & Past Bookings with status management)
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/neumorphic_colors.dart';
import '../../../core/widgets/neumorphic_container.dart';
import '../../../core/widgets/neumorphic_chip.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../services/booking_service.dart';
import '../../../models/booking.dart';
// Gene - Nov, 05, 2026: Added dialog imports for rescheduling and leaving customer reviews
import 'widgets/reschedule_dialog.dart';
import 'widgets/review_dialog.dart';
import '../../../core/widgets/demo_persona_switcher.dart';

class ClientBookingsScreen extends ConsumerStatefulWidget {
  const ClientBookingsScreen({super.key});

  @override
  ConsumerState<ClientBookingsScreen> createState() => _ClientBookingsScreenState();
}

class _ClientBookingsScreenState extends ConsumerState<ClientBookingsScreen> {
  bool _showUpcoming = true;

  void _showCancelDialog(BuildContext context, Booking booking) {
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Cancel Appointment'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Are you sure you want to cancel your appointment with ${booking.businessName}?'),
              const SizedBox(height: 14),
              TextField(
                controller: reasonController,
                decoration: const InputDecoration(
                  labelText: 'Reason for cancellation',
                  hintText: 'e.g., Scheduling conflict, ill...',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Keep Appointment'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: NeumorphicColors.error),
              onPressed: () {
                ref.read(bookingsProvider.notifier).cancelBooking(
                  booking.id,
                  reasonController.text.isNotEmpty ? reasonController.text : 'Patient requested cancellation',
                );
                Navigator.pop(context);
              },
              child: const Text('Confirm Cancellation', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final bookings = ref.watch(clientBookingsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? NeumorphicColors.tealLight : NeumorphicColors.tealPrimary;
    final textPrimary = isDark ? NeumorphicColors.darkTextPrimary : NeumorphicColors.lightTextPrimary;

    final upcoming = bookings.where((b) => b.status == 'confirmed' || b.status == 'pending').toList();
    final past = bookings.where((b) => b.status == 'completed' || b.status == 'cancelled' || b.status == 'rejected').toList();
    final displayedList = _showUpcoming ? upcoming : past;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Appointments', style: TextStyle(fontWeight: FontWeight.w700)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => context.go('/'),
        ),
        // Gene - Nov, 05, 2026: Quick Demo Persona Switcher action in AppBar
        actions: [
          IconButton(
            tooltip: 'Switch Demo Persona',
            icon: Icon(Icons.switch_account_outlined, color: accent),
            onPressed: () => DemoPersonaSwitcherDialog.show(context),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Segmented Filter Tabs
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    child: NeumorphicChip(
                      label: 'Upcoming (${upcoming.length})',
                      isSelected: _showUpcoming,
                      onTap: () => setState(() => _showUpcoming = true),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: NeumorphicChip(
                      label: 'Past & Cancelled (${past.length})',
                      isSelected: !_showUpcoming,
                      onTap: () => setState(() => _showUpcoming = false),
                    ),
                  ),
                ],
              ),
            ),

            // Bookings List
            Expanded(
              child: displayedList.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.event_busy, size: 48, color: isDark ? Colors.white24 : Colors.black26),
                          const SizedBox(height: 12),
                          Text(
                            _showUpcoming ? 'No upcoming bookings found' : 'No past bookings found',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white60 : Colors.black54,
                            ),
                          ),
                          const SizedBox(height: 16),
                          OutlinedButton(
                            onPressed: () => context.go('/'),
                            child: const Text('Browse Clinics & Services'),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
                      itemCount: displayedList.length,
                      itemBuilder: (context, index) {
                        final booking = displayedList[index];

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: NeumorphicContainer(
                            borderRadius: 20.0,
                            padding: const EdgeInsets.all(18),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        booking.businessName ?? 'Clinic',
                                        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    StatusBadge(status: booking.status),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  booking.serviceName ?? 'General Appointment',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: isDark ? NeumorphicColors.darkTextSecondary : NeumorphicColors.lightTextSecondary,
                                  ),
                                ),
                                const Divider(height: 20),

                                if (booking.staffName != null) ...[
                                  Row(
                                    children: [
                                      Icon(Icons.badge_outlined, size: 15, color: accent),
                                      const SizedBox(width: 6),
                                      Text(
                                        booking.staffName!,
                                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                ],

                                Row(
                                  children: [
                                    Icon(Icons.schedule, size: 15, color: accent),
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
                                    Text(
                                      '\$${booking.totalPrice.toStringAsFixed(2)}',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w800,
                                        color: accent,
                                      ),
                                    ),
                                    /*
                                    // Gene - Nov, 03, 2026: Single Cancel button for upcoming visits
                                    if (booking.status == 'confirmed' || booking.status == 'pending') ...[
                                      TextButton(
                                        onPressed: () => _showCancelDialog(context, booking),
                                        child: const Text('Cancel', style: TextStyle(color: NeumorphicColors.error, fontSize: 13)),
                                      ),
                                    ],
                                    */

                                    // Gene - Nov, 05, 2026: Interactive Reschedule, Cancel, and Customer Review actions
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 6,
                                      crossAxisAlignment: WrapCrossAlignment.center,
                                      children: [
                                        if (booking.status == 'confirmed' || booking.status == 'pending') ...[
                                          OutlinedButton.icon(
                                            icon: const Icon(Icons.edit_calendar_rounded, size: 14),
                                            label: const Text('Reschedule', style: TextStyle(fontSize: 12)),
                                            style: OutlinedButton.styleFrom(
                                              foregroundColor: accent,
                                              side: BorderSide(color: accent.withValues(alpha: 0.4)),
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                            ),
                                            onPressed: () => RescheduleBookingDialog.show(context, booking),
                                          ),
                                          TextButton(
                                            onPressed: () => _showCancelDialog(context, booking),
                                            child: const Text('Cancel', style: TextStyle(color: NeumorphicColors.error, fontSize: 13)),
                                          ),
                                        ],
                                        if (booking.status == 'completed') ...[
                                          ElevatedButton.icon(
                                            icon: const Icon(Icons.star_rate_rounded, size: 15, color: Colors.amber),
                                            label: const Text('Leave a Review', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: isDark ? NeumorphicColors.darkHighlight : Colors.white,
                                              foregroundColor: textPrimary,
                                              elevation: 2,
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                            ),
                                            onPressed: () => ReviewSubmissionDialog.show(context, booking),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
