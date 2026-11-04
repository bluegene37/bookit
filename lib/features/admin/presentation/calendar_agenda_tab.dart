// Gene - Nov, 03, 2026: Admin Calendar & Agenda tab for scheduled appointments
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/neumorphic_colors.dart';
import '../../../../core/widgets/neumorphic_container.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../../models/business.dart';
// import '../../../../models/booking.dart';
import '../../../../services/booking_service.dart';

class CalendarAgendaTab extends ConsumerStatefulWidget {
  final Business business;

  const CalendarAgendaTab({super.key, required this.business});

  @override
  ConsumerState<CalendarAgendaTab> createState() => _CalendarAgendaTabState();
}

class _CalendarAgendaTabState extends ConsumerState<CalendarAgendaTab> {
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final bookings = ref.watch(adminBookingsProvider(widget.business.id));
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? NeumorphicColors.tealLight : NeumorphicColors.tealPrimary;

    final selectedDayBookings = bookings.where((b) {
      if (b.startTime != null) {
        return DateUtils.isSameDay(b.startTime!, _selectedDay);
      } else if (b.dateFrom != null) {
        if (b.dateTo != null) {
          return (_selectedDay.isAfter(b.dateFrom!) || DateUtils.isSameDay(_selectedDay, b.dateFrom!)) &&
              (_selectedDay.isBefore(b.dateTo!) || DateUtils.isSameDay(_selectedDay, b.dateTo!));
        }
        return DateUtils.isSameDay(b.dateFrom!, _selectedDay);
      }
      return false;
    }).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Appointment Agenda & Calendar',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: isDark ? NeumorphicColors.darkTextPrimary : NeumorphicColors.lightTextPrimary,
            ),
          ),
          const SizedBox(height: 16),

          // Neumorphic Calendar Container
          NeumorphicContainer(
            borderRadius: 22.0,
            padding: const EdgeInsets.all(16),
            child: TableCalendar(
              firstDay: DateTime.now().subtract(const Duration(days: 30)),
              lastDay: DateTime.now().add(const Duration(days: 365)),
              focusedDay: _focusedDay,
              selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
              calendarFormat: CalendarFormat.month,
              headerStyle: HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
                titleTextStyle: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              calendarStyle: CalendarStyle(
                todayDecoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.3),
                  shape: BoxShape.circle,
                ),
                selectedDecoration: BoxDecoration(
                  color: accent,
                  shape: BoxShape.circle,
                ),
              ),
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay;
                });
              },
            ),
          ),
          const SizedBox(height: 28),

          // Day Appointments Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Schedule for ${DateFormat('EEEE, MMM d, yyyy').format(_selectedDay)}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: isDark ? NeumorphicColors.darkTextPrimary : NeumorphicColors.lightTextPrimary,
                ),
              ),
              Text(
                '${selectedDayBookings.length} Bookings',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: accent),
              ),
            ],
          ),
          const SizedBox(height: 14),

          if (selectedDayBookings.isEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  'No visits scheduled for this date.',
                  style: TextStyle(color: isDark ? Colors.white54 : Colors.black54),
                ),
              ),
            ),
          ] else ...[
            ...selectedDayBookings.map((b) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: NeumorphicContainer(
                  borderRadius: 18.0,
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          b.startTime != null ? DateFormat('h:mm a').format(b.startTime!) : 'Full Day',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: accent),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  b.clientName ?? 'Patient',
                                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                                ),
                                const SizedBox(width: 8),
                                StatusBadge(status: b.status),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              b.serviceName ?? 'Consultation',
                              style: TextStyle(fontSize: 13, color: isDark ? Colors.white70 : Colors.black87),
                            ),
                            if (b.clientNotes != null) ...[
                              const SizedBox(height: 2),
                              Text('Note: ${b.clientNotes}', style: TextStyle(fontSize: 11, color: isDark ? Colors.white38 : Colors.black45)),
                            ],
                          ],
                        ),
                      ),
                      // Gene - Nov, 05, 2026: Admin inline booking state transitions (Approve, Decline, Complete, No-Show)
                      if (b.status == 'pending') ...[
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.check_circle_outline, color: NeumorphicColors.success),
                              tooltip: 'Approve',
                              onPressed: () {
                                ref.read(bookingsProvider.notifier).updateBookingStatus(b.id, 'confirmed');
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.cancel_outlined, color: NeumorphicColors.error),
                              tooltip: 'Decline',
                              onPressed: () {
                                ref.read(bookingsProvider.notifier).updateBookingStatus(b.id, 'rejected');
                              },
                            ),
                          ],
                        ),
                      ] else if (b.status == 'confirmed') ...[
                        PopupMenuButton<String>(
                          icon: Icon(Icons.more_vert, size: 18, color: isDark ? Colors.white70 : Colors.black54),
                          tooltip: 'Manage Booking',
                          onSelected: (val) {
                            if (val == 'complete') {
                              ref.read(bookingsProvider.notifier).updateBookingStatus(b.id, 'completed');
                            } else if (val == 'no_show') {
                              ref.read(bookingsProvider.notifier).updateBookingStatus(b.id, 'rejected');
                            } else if (val == 'cancel') {
                              ref.read(bookingsProvider.notifier).cancelBooking(b.id, 'Admin cancelled');
                            }
                          },
                          itemBuilder: (ctx) => [
                            const PopupMenuItem(
                              value: 'complete',
                              child: Row(
                                children: [
                                  Icon(Icons.check_rounded, size: 16, color: NeumorphicColors.success),
                                  SizedBox(width: 8),
                                  Text('Mark Completed', style: TextStyle(fontSize: 13)),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'no_show',
                              child: Row(
                                children: [
                                  Icon(Icons.person_off_rounded, size: 16, color: NeumorphicColors.warning),
                                  SizedBox(width: 8),
                                  Text('Mark No-Show', style: TextStyle(fontSize: 13)),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'cancel',
                              child: Row(
                                children: [
                                  Icon(Icons.cancel_outlined, size: 16, color: NeumorphicColors.error),
                                  SizedBox(width: 8),
                                  Text('Cancel Visit', style: TextStyle(fontSize: 13)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
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
