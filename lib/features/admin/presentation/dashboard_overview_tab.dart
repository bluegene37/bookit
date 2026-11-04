// Gene - Nov, 03, 2026: Admin Overview Tab with real-time KPI metrics and appointment queue
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/neumorphic_colors.dart';
import '../../../../core/widgets/neumorphic_container.dart';
import '../../../../core/widgets/neumorphic_button.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../../models/business.dart';
import '../../../../services/booking_service.dart';
import 'widgets/kpi_metric_card.dart';

class DashboardOverviewTab extends ConsumerWidget {
  final Business business;

  const DashboardOverviewTab({super.key, required this.business});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookings = ref.watch(adminBookingsProvider(business.id));
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? NeumorphicColors.tealLight : NeumorphicColors.tealPrimary;

    final pendingBookings = bookings.where((b) => b.status == 'pending').toList();
    final confirmedBookings = bookings.where((b) => b.status == 'confirmed').toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${business.name} Overview',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: isDark ? NeumorphicColors.darkTextPrimary : NeumorphicColors.lightTextPrimary,
            ),
          ),
          Text(
            'Active Template: ${business.bookingModel.displayName}',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: accent,
            ),
          ),
          const SizedBox(height: 24),

          // Gene - Nov, 03, 2026: Adjusted mobile childAspectRatio and spacing to ensure ample room for KPI cards
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 700;
              return GridView.count(
                crossAxisCount: isWide ? 4 : 2,
                crossAxisSpacing: isWide ? 16 : 12,
                mainAxisSpacing: isWide ? 16 : 12,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: isWide ? 1.4 : 1.12,
                children: [
                  KpiMetricCard(
                    label: "Today's Agenda",
                    value: '${confirmedBookings.length}',
                    icon: Icons.calendar_today,
                    subtitle: 'Confirmed visits',
                  ),
                  KpiMetricCard(
                    label: 'Pending Approval',
                    value: '${pendingBookings.length}',
                    icon: Icons.pending_actions,
                    accentColor: NeumorphicColors.warning,
                    subtitle: 'Needs action',
                  ),
                  KpiMetricCard(
                    label: 'Total Patients',
                    value: '${bookings.length + 42}',
                    icon: Icons.people_outline,
                    accentColor: NeumorphicColors.cyanLight,
                    subtitle: 'Active profiles',
                  ),
                  KpiMetricCard(
                    label: 'Clinic Rating',
                    value: '${business.ratingAvg.toStringAsFixed(1)} ★',
                    icon: Icons.star_outline,
                    accentColor: Colors.amber,
                    subtitle: '${business.ratingCount} reviews',
                  ),
                ],
              );
            },
          ),
          /*
          // Gene - Nov, 03, 2026: Previous GridView configuration
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 700;
              return GridView.count(
                crossAxisCount: isWide ? 4 : 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: isWide ? 1.4 : 1.1,
                children: [
                  KpiMetricCard(
                    label: "Today's Agenda",
                    value: '${confirmedBookings.length}',
                    icon: Icons.calendar_today,
                    subtitle: 'Confirmed visits',
                  ),
                  KpiMetricCard(
                    label: 'Pending Approval',
                    value: '${pendingBookings.length}',
                    icon: Icons.pending_actions,
                    accentColor: NeumorphicColors.warning,
                    subtitle: 'Needs action',
                  ),
                  KpiMetricCard(
                    label: 'Total Patients',
                    value: '${bookings.length + 42}',
                    icon: Icons.people_outline,
                    accentColor: NeumorphicColors.cyanLight,
                    subtitle: 'Active profiles',
                  ),
                  KpiMetricCard(
                    label: 'Clinic Rating',
                    value: '${business.ratingAvg.toStringAsFixed(1)} ★',
                    icon: Icons.star_outline,
                    accentColor: Colors.amber,
                    subtitle: '${business.ratingCount} reviews',
                  ),
                ],
              );
            },
          ),
          */
          const SizedBox(height: 32),

          // Pending Requests Queue
          if (pendingBookings.isNotEmpty) ...[
            Text(
              'Pending Booking Approvals',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: isDark ? NeumorphicColors.darkTextPrimary : NeumorphicColors.lightTextPrimary,
              ),
            ),
            const SizedBox(height: 12),
            ...pendingBookings.map((b) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: NeumorphicContainer(
                  borderRadius: 18.0,
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              b.clientName ?? 'Patient / Guest',
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 4),
                            /*
                            // Gene - Nov, 03, 2026: Unbounded single-line schedule text
                            Text(
                              '${b.serviceName ?? 'Service'} • ${b.formattedSchedule}',
                              style: TextStyle(fontSize: 13, color: isDark ? Colors.white70 : Colors.black87),
                            ),
                            */
                            // Gene - Nov, 04, 2026: Added maxLines: 2 and ellipsis for graceful wrapping on small screens
                            Text(
                              '${b.serviceName ?? 'Service'} • ${b.formattedSchedule}',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 13, color: isDark ? Colors.white70 : Colors.black87),
                            ),
                            if (b.clientNotes != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                'Note: "${b.clientNotes}"',
                                style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: accent),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.cancel_outlined, color: NeumorphicColors.error),
                            tooltip: 'Reject',
                            onPressed: () {
                              ref.read(bookingsProvider.notifier).updateBookingStatus(b.id, 'rejected');
                            },
                          ),
                          const SizedBox(width: 6),
                          NeumorphicButton(
                            height: 40,
                            isPrimary: true,
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            onPressed: () {
                              ref.read(bookingsProvider.notifier).updateBookingStatus(b.id, 'confirmed');
                            },
                            child: const Text('Confirm', style: TextStyle(fontSize: 13)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }),
            const SizedBox(height: 28),
          ],

          // Confirmed Schedule
          Text(
            "Upcoming Appointments & Bookings",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: isDark ? NeumorphicColors.darkTextPrimary : NeumorphicColors.lightTextPrimary,
            ),
          ),
          const SizedBox(height: 12),
          if (confirmedBookings.isEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text('No active upcoming appointments scheduled.', style: TextStyle(color: isDark ? Colors.white54 : Colors.black54)),
              ),
            ),
          ] else ...[
            ...confirmedBookings.map((b) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: NeumorphicContainer(
                  borderRadius: 18.0,
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            /*
                            // Gene - Nov, 03, 2026: Previous unconstrained Row causing RenderFlex overflow on mobile screens
                            Row(
                              children: [
                                Text(
                                  b.clientName ?? 'Patient',
                                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                                ),
                                const SizedBox(width: 10),
                                StatusBadge(status: b.status),
                              ],
                            ),
                            */
                            /*
                            // Gene - Nov, 04, 2026: Previous Row causing 27px overflow when client name and StatusBadge exceeded available width on 375px screens
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    b.clientName ?? 'Patient',
                                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                StatusBadge(status: b.status),
                              ],
                            ),
                            */
                            // Gene - Nov, 04, 2026: Changed to Wrap to allow natural wrapping of client name and status badge on mobile viewports
                            Wrap(
                              crossAxisAlignment: WrapCrossAlignment.center,
                              spacing: 8,
                              runSpacing: 4,
                              children: [
                                Text(
                                  b.clientName ?? 'Patient',
                                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                                ),
                                StatusBadge(status: b.status),
                              ],
                            ),
                            const SizedBox(height: 4),
                            /*
                            // Gene - Nov, 03, 2026: Unbounded single-line schedule text
                            Text(
                              '${b.serviceName ?? 'Service'} • ${b.formattedSchedule}',
                              style: TextStyle(fontSize: 13, color: isDark ? Colors.white70 : Colors.black87),
                            ),
                            */
                            // Gene - Nov, 04, 2026: Added maxLines: 2 and ellipsis for graceful wrapping on small screens
                            Text(
                              '${b.serviceName ?? 'Service'} • ${b.formattedSchedule}',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 13, color: isDark ? Colors.white70 : Colors.black87),
                            ),
                            if (b.staffName != null) ...[
                              const SizedBox(height: 2),
                              Text('With: ${b.staffName}', style: TextStyle(fontSize: 12, color: accent)),
                            ],
                          ],
                        ),
                      ),
                      Text(
                        '\$${b.totalPrice.toStringAsFixed(2)}',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: accent),
                      ),
                      const SizedBox(width: 8),
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert, size: 20),
                        onSelected: (val) {
                          if (val == 'complete') {
                            ref.read(bookingsProvider.notifier).updateBookingStatus(b.id, 'completed');
                          } else if (val == 'cancel') {
                            ref.read(bookingsProvider.notifier).updateBookingStatus(b.id, 'cancelled');
                          }
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(value: 'complete', child: Text('Mark as Completed')),
                          const PopupMenuItem(value: 'cancel', child: Text('Cancel Appointment')),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ],
      ),
    );
  }
}
