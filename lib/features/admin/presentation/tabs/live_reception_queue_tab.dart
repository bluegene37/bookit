// Gene - Nov, 05, 2026: Live Reception Queue & Waiting Room Tracker Tab with real-time wait duration SLA badges and 1-tap workflow transitions
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/neumorphic_colors.dart';
import '../../../../models/booking.dart';
import '../../../../models/business.dart';
import '../../../../services/booking_service.dart';
import '../widgets/reception_qr_scanner_modal.dart';
// Gene - Nov 07, 2026: Added AdminWalkInBookingDialog and SupabaseService imports for 1-tap Walk-In patient check-in
import '../../../../services/supabase_service.dart';
import '../widgets/admin_walk_in_booking_dialog.dart';

class LiveReceptionQueueTab extends ConsumerStatefulWidget {
  final String businessId;
  final Business? business;

  const LiveReceptionQueueTab({
    super.key,
    required this.businessId,
    this.business,
  });

  @override
  ConsumerState<LiveReceptionQueueTab> createState() => _LiveReceptionQueueTabState();
}

class _LiveReceptionQueueTabState extends ConsumerState<LiveReceptionQueueTab> {
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    // Gene - Nov, 05, 2026: 30-second periodic ticker refreshing real-time patient wait durations
    _ticker = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? NeumorphicColors.tealLight : NeumorphicColors.tealPrimary;

    final allBookings = ref.watch(bookingsProvider);
    final bookings = widget.businessId.isEmpty
        ? allBookings
        : allBookings.where((b) => b.businessId == widget.businessId).toList();

    // 4 reactive swimlane partitions
    final expectedBookings = bookings.where((b) {
      return b.status == 'confirmed' || b.status == 'pending' || b.status == 'awaiting_payment';
    }).toList();

    final waitingBookings = bookings.where((b) => b.status == 'checked_in').toList();
    final inServiceBookings = bookings.where((b) => b.status == 'in_service').toList();
    final completedBookings = bookings.where((b) => b.status == 'completed').toList();

    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Queue Dashboard Header
          _buildQueueHeader(
            context,
            isDark,
            accent,
            expectedCount: expectedBookings.length,
            waitingCount: waitingBookings.length,
            inServiceCount: inServiceBookings.length,
            completedCount: completedBookings.length,
            waitingBookings: waitingBookings,
          ),

          const SizedBox(height: 18),

          // 2. 4-Column Reactive Swimlane Board
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= 950;

                final columns = [
                  _buildSwimlaneColumn(
                    context: context,
                    title: 'Expected (Upcoming)',
                    icon: Icons.event_available_rounded,
                    accentColor: isDark ? NeumorphicColors.tealLight : NeumorphicColors.tealPrimary,
                    columnBookings: expectedBookings,
                    isDark: isDark,
                    accent: accent,
                    emptyMessage: 'No upcoming expected appointments',
                  ),
                  _buildSwimlaneColumn(
                    context: context,
                    title: 'In Waiting Room (Checked-In)',
                    icon: Icons.hourglass_top_rounded,
                    accentColor: NeumorphicColors.warning,
                    columnBookings: waitingBookings,
                    isDark: isDark,
                    accent: accent,
                    emptyMessage: 'Waiting room is currently clear',
                  ),
                  _buildSwimlaneColumn(
                    context: context,
                    title: 'In-Service (With Provider)',
                    icon: Icons.medical_services_rounded,
                    accentColor: Colors.purpleAccent,
                    columnBookings: inServiceBookings,
                    isDark: isDark,
                    accent: accent,
                    emptyMessage: 'No treatments currently in progress',
                  ),
                  _buildSwimlaneColumn(
                    context: context,
                    title: 'Completed (Discharged)',
                    icon: Icons.check_circle_outline_rounded,
                    accentColor: NeumorphicColors.success,
                    columnBookings: completedBookings,
                    isDark: isDark,
                    accent: accent,
                    emptyMessage: 'No completed appointments today',
                  ),
                ];

                if (isWide) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (int i = 0; i < columns.length; i++) ...[
                        if (i > 0) const SizedBox(width: 14),
                        Expanded(child: columns[i]),
                      ],
                    ],
                  );
                } else {
                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (int i = 0; i < columns.length; i++) ...[
                          if (i > 0) const SizedBox(width: 14),
                          SizedBox(
                            width: 240,
                            child: columns[i],
                          ),
                        ],
                      ],
                    ),
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  // --- Top Header with Metrics and Fast Scan Check-In Button ---
  Widget _buildQueueHeader(
    BuildContext context,
    bool isDark,
    Color accent, {
    required int expectedCount,
    required int waitingCount,
    required int inServiceCount,
    required int completedCount,
    required List<Booking> waitingBookings,
  }) {
    // Calculate average wait time in minutes
    int avgWaitMins = 0;
    if (waitingBookings.isNotEmpty) {
      final totalWaitSecs = waitingBookings.fold<int>(
        0,
        (sum, b) => sum + (b.currentWaitDuration?.inSeconds ?? 0),
      );
      avgWaitMins = (totalWaitSecs / (waitingBookings.length * 60)).round();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? NeumorphicColors.darkSurface : NeumorphicColors.lightSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.08),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.people_alt_outlined, color: accent, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    /*
                    Text(
                      'Live Reception Queue',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: isDark ? NeumorphicColors.darkTextPrimary : NeumorphicColors.lightTextPrimary,
                      ),
                    ),
                    Text(
                      'Real-time patient waiting room & SLA tracking',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? NeumorphicColors.darkTextSecondary : NeumorphicColors.lightTextSecondary,
                      ),
                    ),
                    */
                    // Gene - Nov 07, 2026: Prevent header title/subtitle wrapping when action buttons are present
                    Text(
                      'Live Reception Queue',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: isDark ? NeumorphicColors.darkTextPrimary : NeumorphicColors.lightTextPrimary,
                      ),
                    ),
                    Text(
                      'Real-time patient waiting room & SLA tracking',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? NeumorphicColors.darkTextSecondary : NeumorphicColors.lightTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              // Gene - Nov 07, 2026: Quick '+ Walk-In' action button alongside Scan Check-In
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    final resolvedBusiness = widget.business ??
                        SupabaseService.mockBusinesses
                            .where((b) => b.id == widget.businessId)
                            .firstOrNull ??
                        Business.fallback(id: widget.businessId);
                    AdminWalkInBookingDialog.show(
                      context,
                      business: resolvedBusiness,
                      initialWalkInMode: true,
                    );
                  },
                  borderRadius: BorderRadius.circular(10),
                  child: Ink(
                    decoration: BoxDecoration(
                      color: accent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.person_add_alt_1_rounded, size: 15, color: Colors.white),
                        SizedBox(width: 6),
                        Text(
                          '+ Walk-In',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => ReceptionQrScannerModal.show(context),
                  borderRadius: BorderRadius.circular(10),
                  child: Ink(
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: accent.withValues(alpha: 0.4)),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.qr_code_scanner_rounded, size: 16, color: accent),
                        const SizedBox(width: 6),
                        Text(
                          'Scan Check-In',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: accent,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _buildMetricChip('Expected: $expectedCount', Icons.calendar_today_rounded, isDark),
              _buildMetricChip('In Waiting: $waitingCount', Icons.hourglass_top_rounded, isDark,
                  color: NeumorphicColors.warning),
              _buildMetricChip('In-Service: $inServiceCount', Icons.medical_services_rounded, isDark,
                  color: Colors.purpleAccent),
              _buildMetricChip('Discharged: $completedCount', Icons.check_circle_rounded, isDark,
                  color: NeumorphicColors.success),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: (avgWaitMins > 15 ? NeumorphicColors.error : accent).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: (avgWaitMins > 15 ? NeumorphicColors.error : accent).withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      avgWaitMins > 15 ? Icons.warning_amber_rounded : Icons.timer_outlined,
                      size: 14,
                      color: avgWaitMins > 15 ? NeumorphicColors.error : accent,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Avg Wait: ${avgWaitMins}m',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: avgWaitMins > 15 ? NeumorphicColors.error : accent,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricChip(String text, IconData icon, bool isDark, {Color? color}) {
    final chipColor = color ?? (isDark ? Colors.white70 : Colors.black87);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: chipColor),
          const SizedBox(width: 5),
          Text(
            text,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: chipColor,
            ),
          ),
        ],
      ),
    );
  }

  // --- Swimlane Column ---
  Widget _buildSwimlaneColumn({
    required BuildContext context,
    required String title,
    required IconData icon,
    required Color accentColor,
    required List<Booking> columnBookings,
    required bool isDark,
    required Color accent,
    required String emptyMessage,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? NeumorphicColors.darkSurface : NeumorphicColors.lightSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.08),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Swimlane Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.08),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
              border: Border(
                bottom: BorderSide(color: accentColor.withValues(alpha: 0.2)),
              ),
            ),
            child: Row(
              children: [
                Icon(icon, size: 16, color: accentColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: isDark ? NeumorphicColors.darkTextPrimary : NeumorphicColors.lightTextPrimary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${columnBookings.length}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: accentColor,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Cards List
          Expanded(
            child: columnBookings.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            icon,
                            size: 32,
                            color: isDark ? Colors.white24 : Colors.black26,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            emptyMessage,
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? NeumorphicColors.darkTextSecondary : NeumorphicColors.lightTextSecondary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      children: [
                        for (final booking in columnBookings)
                          _buildBookingCard(booking, isDark, accent),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  // --- Booking Card ---
  Widget _buildBookingCard(Booking booking, bool isDark, Color accent) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? NeumorphicColors.darkHighlight : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.06),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Client Name & Monospace Reference ID
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  booking.clientName ?? 'Unknown Client',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: isDark ? NeumorphicColors.darkTextPrimary : NeumorphicColors.lightTextPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '#${booking.formattedId}',
                  style: TextStyle(
                    fontSize: 10,
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white60 : Colors.black54,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),

          // Service Name
          Text(
            booking.serviceName ?? 'General Appointment',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: accent,
            ),
            overflow: TextOverflow.ellipsis,
          ),

          // Staff Assignment
          if (booking.staffName != null && booking.staffName!.isNotEmpty) ...[
            const SizedBox(height: 2),
            Row(
              children: [
                Icon(Icons.person_outline, size: 12, color: isDark ? Colors.white54 : Colors.black45),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    'With ${booking.staffName}',
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? Colors.white60 : Colors.black54,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],

          // Schedule time
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.schedule, size: 12, color: isDark ? Colors.white38 : Colors.black38),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  booking.formattedSchedule,
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? Colors.white54 : Colors.black45,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),

          // Color-coded SLA Wait Duration Badge
          if (booking.status == 'checked_in' || booking.status == 'in_service') ...[
            const SizedBox(height: 8),
            _buildWaitBadge(booking, isDark),
          ],

          // 1-Tap Workflow Action Button
          const SizedBox(height: 10),
          _buildCardAction(booking, isDark, accent),
        ],
      ),
    );
  }

  // --- Real-time Wait Duration SLA Badge ---
  Widget _buildWaitBadge(Booking booking, bool isDark) {
    final waitDuration = booking.currentWaitDuration;
    if (waitDuration == null) return const SizedBox.shrink();

    final mins = waitDuration.inMinutes;
    final minsStr = mins.toString().padLeft(2, '0');

    final Color badgeColor;
    final Color bgColor;
    final String label;
    final IconData icon;

    if (mins < 10) {
      badgeColor = isDark ? NeumorphicColors.tealLight : NeumorphicColors.tealPrimary;
      bgColor = badgeColor.withValues(alpha: 0.12);
      label = 'Wait: ${minsStr}m';
      icon = Icons.timer_outlined;
    } else if (mins <= 15) {
      badgeColor = NeumorphicColors.warning;
      bgColor = badgeColor.withValues(alpha: 0.12);
      label = 'Wait: ${minsStr}m';
      icon = Icons.hourglass_bottom_rounded;
    } else {
      badgeColor = NeumorphicColors.error;
      bgColor = badgeColor.withValues(alpha: 0.15);
      label = 'Wait: ${minsStr}m — SLA Target Exceeded';
      icon = Icons.warning_amber_rounded;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: badgeColor.withValues(alpha: 0.3)),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: badgeColor),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: badgeColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- 1-Tap Workflow Action Button ---
  Widget _buildCardAction(Booking booking, bool isDark, Color accent) {
    if (booking.status == 'confirmed' || booking.status == 'pending' || booking.status == 'awaiting_payment') {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            ref.read(bookingsProvider.notifier).checkInBooking(booking.id);
          },
          borderRadius: BorderRadius.circular(8),
          child: Ink(
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: accent.withValues(alpha: 0.35)),
            ),
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
            child: Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.how_to_reg_rounded, size: 15, color: accent),
                    const SizedBox(width: 6),
                    Text(
                      'Check-In',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: accent,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    if (booking.status == 'checked_in') {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            ref.read(bookingsProvider.notifier).startServiceBooking(booking.id);
          },
          borderRadius: BorderRadius.circular(8),
          child: Ink(
            decoration: BoxDecoration(
              color: NeumorphicColors.warning.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: NeumorphicColors.warning.withValues(alpha: 0.35)),
            ),
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
            child: Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.play_arrow_rounded, size: 15, color: NeumorphicColors.warning),
                    SizedBox(width: 6),
                    Text(
                      'Call In / Start',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: NeumorphicColors.warning,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    if (booking.status == 'in_service') {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            ref.read(bookingsProvider.notifier).updateBookingStatus(booking.id, 'completed');
          },
          borderRadius: BorderRadius.circular(8),
          child: Ink(
            decoration: BoxDecoration(
              color: NeumorphicColors.success.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: NeumorphicColors.success.withValues(alpha: 0.35)),
            ),
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
            child: Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.check_circle_rounded, size: 15, color: NeumorphicColors.success),
                    SizedBox(width: 6),
                    Text(
                      'Complete & Invoice',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: NeumorphicColors.success,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      decoration: BoxDecoration(
        color: NeumorphicColors.success.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.task_alt_rounded, size: 14, color: NeumorphicColors.success),
              SizedBox(width: 6),
              Text(
                'Discharged',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: NeumorphicColors.success,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
