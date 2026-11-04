// Gene - Nov, 03, 2026: Semantic status badge with neumorphic inset styling
import 'package:flutter/material.dart';
import '../theme/neumorphic_colors.dart';
import 'neumorphic_container.dart';

class StatusBadge extends StatelessWidget {
  final String status;

  const StatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;
    IconData icon;

    /*
    // Gene - Nov, 03, 2026: Semantic status badge with neumorphic inset styling
    switch (status.toLowerCase()) {
      case 'confirmed':
        color = NeumorphicColors.success;
        label = 'Confirmed';
        icon = Icons.check_circle_rounded;
        break;
      case 'completed':
        color = NeumorphicColors.info;
        label = 'Completed';
        icon = Icons.task_alt_rounded;
        break;
      case 'cancelled':
        color = NeumorphicColors.error;
        label = 'Cancelled';
        icon = Icons.cancel_rounded;
        break;
      case 'rejected':
        color = NeumorphicColors.error;
        label = 'Rejected';
        icon = Icons.block_rounded;
        break;
      case 'pending':
      default:
        color = NeumorphicColors.warning;
        label = 'Pending';
        icon = Icons.hourglass_top_rounded;
        break;
    }
    */

    // Gene - Nov, 04, 2026: Extended StatusBadge to support financial and payment statuses (succeeded, deposit_paid, refunded, partially_refunded, unpaid)
    switch (status.toLowerCase()) {
      case 'confirmed':
        color = NeumorphicColors.success;
        label = 'Confirmed';
        icon = Icons.check_circle_rounded;
        break;
      case 'completed':
        color = NeumorphicColors.info;
        label = 'Completed';
        icon = Icons.task_alt_rounded;
        break;
      case 'cancelled':
        color = NeumorphicColors.error;
        label = 'Cancelled';
        icon = Icons.cancel_rounded;
        break;
      case 'rejected':
        color = NeumorphicColors.error;
        label = 'Rejected';
        icon = Icons.block_rounded;
        break;
      case 'succeeded':
      case 'paid':
      case 'paid_in_full':
        color = NeumorphicColors.success;
        label = 'Succeeded';
        icon = Icons.check_circle_rounded;
        break;
      case 'deposit_paid':
        color = NeumorphicColors.tealPrimary;
        label = 'Deposit Paid';
        icon = Icons.payments_rounded;
        break;
      case 'refunded':
        color = NeumorphicColors.error;
        label = 'Refunded';
        icon = Icons.replay_rounded;
        break;
      case 'partially_refunded':
        color = NeumorphicColors.warning;
        label = 'Partially Refunded';
        icon = Icons.replay_rounded;
        break;
      case 'unpaid':
      case 'awaiting_payment':
        color = NeumorphicColors.warning;
        label = 'Awaiting Payment';
        icon = Icons.pending_actions_rounded;
        break;
      case 'pending':
      default:
        color = NeumorphicColors.warning;
        label = status.isNotEmpty ? '${status[0].toUpperCase()}${status.substring(1)}' : 'Pending';
        icon = Icons.hourglass_top_rounded;
        break;
    }

    return NeumorphicContainer(
      borderRadius: 12.0,
      isInset: true,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
