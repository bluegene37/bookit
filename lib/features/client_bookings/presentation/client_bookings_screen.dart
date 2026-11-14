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
// Gene - Nov, 05, 2026: Imported CalendarSyncService for 1-Tap Google/Outlook and .ics export
import '../../../services/calendar_sync_service.dart';
// Gene - Nov, 05, 2026: Added digital QR boarding pass modal and pass preview
import 'widgets/booking_qr_pass_modal.dart';
// Gene - Nov 07, 2026: Added business_service and supabase_service imports to check if a completed booking was already reviewed
import '../../../services/business_service.dart';
import '../../../services/supabase_service.dart';
// Gene - Nov, 14, 2026: Added auth_service import for unified release-mode demo gating
import '../../../services/auth_service.dart';

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

    /*
    final upcoming = bookings.where((b) => b.status == 'confirmed' || b.status == 'pending').toList();
    */
    /*
    // Gene - Nov, 05, 2026: Included checked_in and in_service statuses in active upcoming bookings
    final upcoming = bookings.where((b) => b.status == 'confirmed' || b.status == 'pending' || b.status == 'checked_in' || b.status == 'in_service').toList();
    */
    // Gene - Nov, 7, 2026: Include arrived, in_session, and awaiting_payment statuses in active upcoming bookings
    final upcoming = bookings
        .where((b) =>
            b.status == 'confirmed' ||
            b.status == 'pending' ||
            b.status == 'checked_in' ||
            b.status == 'arrived' ||
            b.status == 'in_service' ||
            b.status == 'in_session' ||
            b.status == 'awaiting_payment')
        .toList();
    final past = bookings.where((b) => b.status == 'completed' || b.status == 'cancelled' || b.status == 'rejected').toList();
    final displayedList = _showUpcoming ? upcoming : past;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Appointments', style: TextStyle(fontWeight: FontWeight.w700)),
        /*
        // Gene - Nov, 03, 2026: Back IconButton missing tooltip
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
        */
        // Gene - Nov, 14, 2026: Added Back tooltip and gated Demo Persona Switcher behind AuthNotifier.isDemoModeEnabled
        leading: IconButton(
          tooltip: 'Back',
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/');
            }
          },
        ),
        actions: [
          if (AuthNotifier.isDemoModeEnabled)
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
            // Gene - Nov, 14, 2026: Stack segmented filter tabs vertically when effective scaled width is narrow (e.g., 320px or 1.5x scaling)
            /*
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
            */
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final textScale = MediaQuery.textScalerOf(context).scale(1.0);
                  final isStacked = constraints.maxWidth < 300 * textScale;
                  final upcomingChip = NeumorphicChip(
                    label: 'Upcoming (${upcoming.length})',
                    isSelected: _showUpcoming,
                    onTap: () => setState(() => _showUpcoming = true),
                  );
                  final pastChip = NeumorphicChip(
                    label: 'Past & Cancelled (${past.length})',
                    isSelected: !_showUpcoming,
                    onTap: () => setState(() => _showUpcoming = false),
                  );
                  if (isStacked) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        upcomingChip,
                        const SizedBox(height: 10),
                        pastChip,
                      ],
                    );
                  }
                  return Row(
                    children: [
                      Expanded(child: upcomingChip),
                      const SizedBox(width: 14),
                      Expanded(child: pastChip),
                    ],
                  );
                },
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
                                    /*
                                    Expanded(
                                      child: Text(
                                        booking.businessName ?? 'Clinic',
                                        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    */
                                    // Gene - Nov, 7, 2026: Make clinic name tappable to open the business storefront page
                                    Expanded(
                                      child: InkWell(
                                        borderRadius: BorderRadius.circular(6),
                                        onTap: () => context.push('/business/${booking.businessId}'),
                                        child: Text(
                                          booking.businessName ?? 'Clinic',
                                          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
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

                                /*
                                // Original unconstrained staff name row
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
                                */
                                // Gene - Nov 06, 2026: Wrapped staffName in Expanded with ellipsis to prevent overflow on mobile viewport
                                if (booking.staffName != null) ...[
                                  Row(
                                    children: [
                                      Icon(Icons.badge_outlined, size: 15, color: accent),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          booking.staffName!,
                                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
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

                                /*
                                // Gene - Nov, 05, 2026: Outer Row forced nested Wrap unbounded, causing severe horizontal overflows on 320px/375px viewports
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(... totalPrice ...),
                                    Wrap(...)
                                  ],
                                ),
                                */
                                // Gene - Nov, 14, 2026: Converted footer to full-width Wrap with 48dp accessible action buttons and WCAG AA error color on Cancel
                                SizedBox(
                                  width: double.infinity,
                                  child: Wrap(
                                    spacing: 10,
                                    runSpacing: 10,
                                    alignment: WrapAlignment.spaceBetween,
                                    crossAxisAlignment: WrapCrossAlignment.center,
                                    children: [
                                      Text(
                                        '\$${booking.totalPrice.toStringAsFixed(2)}',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w800,
                                          color: accent,
                                        ),
                                      ),
                                      // Gene - Nov, 05, 2026: Added digital QR boarding pass modal and pass preview button
                                      if (booking.status == 'confirmed' ||
                                          booking.status == 'pending' ||
                                          booking.status == 'checked_in' ||
                                          booking.status == 'in_service')
                                        OutlinedButton.icon(
                                          icon: const Icon(Icons.qr_code_rounded, size: 14),
                                          label: const Text('View QR Pass', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: accent,
                                            side: BorderSide(color: accent, width: 1.2),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                            minimumSize: const Size(48, 48),
                                          ),
                                          onPressed: () => BookingQrPassModal.show(context, booking),
                                        ),
                                      if (booking.status == 'confirmed' || booking.status == 'pending') ...[
                                        // Gene - Nov, 05, 2026: 1-Tap Calendar Sync dropdown (Google Calendar & RFC 5545 .ics invite)
                                        PopupMenuButton<String>(
                                          tooltip: 'Add to Calendar',
                                          constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                                          icon: Icon(Icons.calendar_month_rounded, size: 18, color: accent),
                                          padding: const EdgeInsets.all(10),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                          onSelected: (val) async {
                                            if (val == 'google') {
                                              await CalendarSyncService.openGoogleCalendar(booking: booking);
                                            } else if (val == 'ics') {
                                              final success = await CalendarSyncService.downloadIcsFile(booking: booking);
                                              if (context.mounted) {
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  SnackBar(
                                                    content: Text(
                                                      success
                                                          ? 'Calendar invite (.ics) downloaded!'
                                                          : 'Generated calendar invite.',
                                                    ),
                                                    backgroundColor: accent,
                                                  ),
                                                );
                                              }
                                            }
                                          },
                                          itemBuilder: (ctx) => [
                                            const PopupMenuItem(
                                              value: 'google',
                                              child: Row(
                                                children: [
                                                  Icon(Icons.open_in_new, size: 16),
                                                  SizedBox(width: 8),
                                                  Text('Google Calendar', style: TextStyle(fontSize: 13)),
                                                ],
                                              ),
                                            ),
                                            const PopupMenuItem(
                                              value: 'ics',
                                              child: Row(
                                                children: [
                                                  Icon(Icons.download_rounded, size: 16),
                                                  SizedBox(width: 8),
                                                  Text('Download .ICS File', style: TextStyle(fontSize: 13)),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                        OutlinedButton.icon(
                                          icon: const Icon(Icons.edit_calendar_rounded, size: 14),
                                          label: const Text('Reschedule', style: TextStyle(fontSize: 12)),
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: accent,
                                            side: BorderSide(color: accent.withValues(alpha: 0.4)),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                            minimumSize: const Size(48, 48),
                                          ),
                                          onPressed: () => RescheduleBookingDialog.show(context, booking),
                                        ),
                                        TextButton(
                                          style: TextButton.styleFrom(
                                            minimumSize: const Size(48, 48),
                                          ),
                                          onPressed: () => _showCancelDialog(context, booking),
                                          child: Text(
                                            'Cancel',
                                            style: TextStyle(
                                              color: NeumorphicColors.errorFor(isDark),
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ],
                                      // Gene - Nov 07, 2026: Duplicate-review guard showing a 'Reviewed ★' badge once a review is submitted
                                      if (booking.status == 'completed') ...[
                                        Builder(
                                          builder: (context) {
                                            final businessReviews = ref.watch(businessReviewsProvider(booking.businessId)).valueOrNull ?? [];
                                            final existingReview = businessReviews
                                                    .where((r) => r.bookingId == booking.id)
                                                    .firstOrNull ??
                                                SupabaseService.mockReviews
                                                    .where((r) => r.bookingId == booking.id)
                                                    .firstOrNull;

                                            if (existingReview != null) {
                                              return Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                                decoration: BoxDecoration(
                                                  color: Colors.amber.withValues(alpha: 0.14),
                                                  borderRadius: BorderRadius.circular(10),
                                                  border: Border.all(color: Colors.amber.withValues(alpha: 0.45)),
                                                ),
                                                child: Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    const Icon(Icons.star_rounded, size: 14, color: Colors.amber),
                                                    const SizedBox(width: 4),
                                                    // Gene - Nov, 14, 2026: Use WCAG AA warning token for Reviewed label contrast in light and dark mode
                                                    Text(
                                                      'Reviewed (${existingReview.rating}★)',
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        fontWeight: FontWeight.w700,
                                                        // color: isDark ? Colors.amberAccent : Colors.amber.shade900,
                                                        color: NeumorphicColors.warningFor(isDark),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              );
                                            }

                                            return ElevatedButton.icon(
                                              icon: const Icon(Icons.star_rate_rounded, size: 15, color: Colors.amber),
                                              label: const Text('Leave a Review', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: isDark ? NeumorphicColors.darkHighlight : Colors.white,
                                                foregroundColor: textPrimary,
                                                elevation: 2,
                                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                                minimumSize: const Size(48, 48),
                                              ),
                                              onPressed: () async {
                                                await ReviewSubmissionDialog.show(context, booking);
                                                if (mounted) setState(() {});
                                              },
                                            );
                                          },
                                        ),
                                      ],
                                      // Gene - Nov, 7, 2026: Added 1-Tap Book Again action on past/completed/cancelled appointments
                                      if (booking.status == 'completed' || booking.status == 'cancelled' || booking.status == 'rejected')
                                        OutlinedButton.icon(
                                          icon: const Icon(Icons.replay_rounded, size: 14),
                                          label: const Text('Book Again', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: accent,
                                            side: BorderSide(color: accent.withValues(alpha: 0.45)),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                            minimumSize: const Size(48, 48),
                                          ),
                                          onPressed: () => context.push('/book/${booking.businessId}'),
                                        ),
                                    ],
                                  ),
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
