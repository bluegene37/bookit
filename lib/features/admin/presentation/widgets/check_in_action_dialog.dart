// Gene - Nov, 05, 2026: Added reception QR scanner modal, check-in action sheet, and booking state transitions
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/neumorphic_colors.dart';
import '../../../../core/widgets/neumorphic_container.dart';
import '../../../../core/widgets/neumorphic_button.dart';
import '../../../../models/booking.dart';
import '../../../../services/booking_service.dart';

class CheckInActionDialog extends ConsumerStatefulWidget {
  final Booking booking;

  const CheckInActionDialog({super.key, required this.booking});

  static Future<void> show(BuildContext context, Booking booking) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => CheckInActionDialog(booking: booking),
    );
  }

  @override
  ConsumerState<CheckInActionDialog> createState() => _CheckInActionDialogState();
}

class _CheckInActionDialogState extends ConsumerState<CheckInActionDialog> {
  bool _isProcessing = false;
  Booking? _localBooking;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? NeumorphicColors.tealLight : NeumorphicColors.tealPrimary;
    final textPrimary = isDark ? NeumorphicColors.darkTextPrimary : NeumorphicColors.lightTextPrimary;
    final textSecondary = isDark ? NeumorphicColors.darkTextSecondary : NeumorphicColors.lightTextSecondary;

    // Watch current booking state from provider to react to payment/check-in mutations
    final allBookings = ref.watch(bookingsProvider);
    final bookingFromProvider = allBookings.cast<Booking?>().firstWhere(
      (b) => b?.id == widget.booking.id,
      orElse: () => null,
    );
    final currentBooking = _localBooking ?? bookingFromProvider ?? widget.booking;

    final isCheckedIn = currentBooking.status == 'checked_in';
    final isInService = currentBooking.status == 'in_service';
    final hasBalanceDue = currentBooking.amountDue > 0.0;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: SingleChildScrollView(
          child: NeumorphicContainer(
            borderRadius: 24,
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top Header Row
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.how_to_reg_rounded, size: 22, color: accent),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Patient & Client Check-In',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: textPrimary,
                            ),
                          ),
                          Text(
                            'Fast-Track Front Desk Verification',
                            style: TextStyle(
                              fontSize: 12,
                              color: textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close_rounded, size: 20, color: textSecondary),
                      onPressed: () => Navigator.of(context).pop(),
                      tooltip: 'Close',
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Client & Service Info Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.black.withValues(alpha: 0.02),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark ? Colors.white12 : Colors.black12,
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  currentBooking.clientName ?? 'Walk-In Guest',
                                  style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w800,
                                    color: textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  currentBooking.serviceName ?? 'General Appointment',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: accent,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          _buildStatusPill(currentBooking.status, isDark),
                        ],
                      ),
                      const Divider(height: 24),
                      Row(
                        children: [
                          Icon(Icons.person_pin_circle_outlined, size: 16, color: textSecondary),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Staff: ${currentBooking.staffName ?? 'Any Available Specialist'}',
                              style: TextStyle(fontSize: 12, color: textSecondary),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (currentBooking.startTime != null) ...[
                            const SizedBox(width: 8),
                            Icon(Icons.schedule_rounded, size: 16, color: textSecondary),
                            const SizedBox(width: 6),
                            Text(
                              DateFormat('MMM d, h:mm a').format(currentBooking.startTime!),
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textPrimary),
                            ),
                          ],
                        ],
                      ),
                      if (currentBooking.qrToken != null) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.qr_code_rounded, size: 16, color: textSecondary),
                            const SizedBox(width: 6),
                            Text(
                              'Pass Code: ${currentBooking.qrToken}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: textSecondary,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Balance Clearance Section
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: hasBalanceDue
                        ? NeumorphicColors.warning.withValues(alpha: isDark ? 0.15 : 0.08)
                        : NeumorphicColors.success.withValues(alpha: isDark ? 0.15 : 0.08),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: hasBalanceDue
                          ? NeumorphicColors.warning.withValues(alpha: 0.35)
                          : NeumorphicColors.success.withValues(alpha: 0.35),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        hasBalanceDue ? Icons.account_balance_wallet_outlined : Icons.check_circle_outline_rounded,
                        color: hasBalanceDue ? NeumorphicColors.warning : NeumorphicColors.success,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              hasBalanceDue
                                  ? 'Balance Due: \$${currentBooking.amountDue.toStringAsFixed(2)}'
                                  : 'Paid in Full',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: hasBalanceDue
                                    ? (isDark ? Colors.amber[300] : Colors.orange[900])
                                    : (isDark ? Colors.green[300] : Colors.green[800]),
                              ),
                            ),
                            Text(
                              hasBalanceDue
                                  ? 'Total: \$${currentBooking.totalPrice.toStringAsFixed(2)} (Paid: \$${currentBooking.amountPaid.toStringAsFixed(2)})'
                                  : 'Zero balance remaining (\$${currentBooking.totalPrice.toStringAsFixed(2)} paid)',
                              style: TextStyle(
                                fontSize: 11,
                                color: textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (hasBalanceDue)
                        NeumorphicButton(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          icon: Icons.point_of_sale_rounded,
                          onPressed: _isProcessing
                              ? null
                              : () async {
                                  setState(() => _isProcessing = true);
                                  final messenger = ScaffoldMessenger.of(context);
                                  await ref.read(bookingsProvider.notifier).updateBookingPayment(
                                        bookingId: currentBooking.id,
                                        paymentStatus: 'paid_in_full',
                                        amountPaid: currentBooking.totalPrice,
                                        amountDue: 0.0,
                                      );
                                  if (!mounted) return;
                                  setState(() {
                                    _isProcessing = false;
                                    _localBooking = currentBooking.copyWith(
                                      paymentStatus: 'paid_in_full',
                                      amountPaid: currentBooking.totalPrice,
                                      amountDue: 0.0,
                                    );
                                  });
                                  messenger.showSnackBar(
                                    SnackBar(
                                      content: Text('Collected \$${currentBooking.amountDue.toStringAsFixed(2)} via POS terminal'),
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                },
                          child: const Text(
                            'Collect Balance',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Action Buttons
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    NeumorphicButton(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      icon: isCheckedIn ? Icons.done_all_rounded : Icons.check_circle_outline_rounded,
                      onPressed: (_isProcessing || isCheckedIn || isInService)
                          ? null
                          : () async {
                              setState(() => _isProcessing = true);
                              final messenger = ScaffoldMessenger.of(context);
                              final navigator = Navigator.of(context);
                              await ref.read(bookingsProvider.notifier).checkInBooking(currentBooking.id);
                              if (!mounted) return;
                              setState(() {
                                _isProcessing = false;
                                _localBooking = currentBooking.copyWith(
                                  status: 'checked_in',
                                  checkedInAt: DateTime.now(),
                                );
                              });
                              navigator.pop();
                              messenger.showSnackBar(
                                SnackBar(
                                  content: Text('✓ Checked in ${currentBooking.clientName ?? "Guest"}. Added to Waiting Room queue.'),
                                  backgroundColor: NeumorphicColors.success,
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            },
                      child: Text(
                        isCheckedIn ? 'Checked In' : 'Confirm Check-In',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: isCheckedIn ? NeumorphicColors.success : textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    NeumorphicButton(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      icon: isInService ? Icons.meeting_room_rounded : Icons.door_front_door_outlined,
                      onPressed: (_isProcessing || isInService)
                          ? null
                          : () async {
                              setState(() => _isProcessing = true);
                              final messenger = ScaffoldMessenger.of(context);
                              final navigator = Navigator.of(context);
                              await ref.read(bookingsProvider.notifier).startServiceBooking(currentBooking.id);
                              if (!mounted) return;
                              setState(() {
                                _isProcessing = false;
                                _localBooking = currentBooking.copyWith(
                                  status: 'in_service',
                                  inServiceAt: DateTime.now(),
                                );
                              });
                              navigator.pop();
                              messenger.showSnackBar(
                                SnackBar(
                                  content: Text('✓ ${currentBooking.clientName ?? "Guest"} moved to In-Service / Room Ready.'),
                                  backgroundColor: accent,
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            },
                      child: Text(
                        isInService ? 'In Service' : 'Start Service / Room Ready',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: isInService ? NeumorphicColors.success : textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusPill(String status, bool isDark) {
    Color bg;
    Color fg;
    String label;

    switch (status) {
      case 'checked_in':
        bg = Colors.blue.withValues(alpha: 0.15);
        fg = Colors.blue;
        label = 'Checked In';
        break;
      case 'in_service':
        bg = Colors.purple.withValues(alpha: 0.15);
        fg = Colors.purple;
        label = 'In Service';
        break;
      case 'confirmed':
        bg = NeumorphicColors.success.withValues(alpha: 0.15);
        fg = NeumorphicColors.success;
        label = 'Confirmed';
        break;
      case 'completed':
        bg = Colors.teal.withValues(alpha: 0.15);
        fg = Colors.teal;
        label = 'Completed';
        break;
      case 'cancelled':
        bg = NeumorphicColors.error.withValues(alpha: 0.15);
        fg = NeumorphicColors.error;
        label = 'Cancelled';
        break;
      default:
        bg = Colors.grey.withValues(alpha: 0.15);
        fg = Colors.grey;
        label = status.toUpperCase();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: fg),
      ),
    );
  }
}
