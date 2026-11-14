// Gene - Nov, 03, 2026: Semantic status badge with neumorphic inset styling
import 'package:flutter/material.dart';
import '../theme/neumorphic_colors.dart';
import 'neumorphic_container.dart';

class StatusBadge extends StatelessWidget {
  final String status;

  const StatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    // Gene - Nov, 14, 2026: Resolve theme-aware WCAG AA semantic colors for Light and Dark surfaces
    final isDark = Theme.of(context).brightness == Brightness.dark;
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

    /*
    // Gene - Nov, 04, 2026: Extended StatusBadge without dark-mode high-contrast tokens
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
    */
    // Gene - Nov, 14, 2026: Applied theme-aware WCAG AA semantic color pairs across all status variants
    switch (status.toLowerCase()) {
      case 'confirmed':
        color = NeumorphicColors.successFor(isDark);
        label = 'Confirmed';
        icon = Icons.check_circle_rounded;
        break;
      case 'completed':
        color = NeumorphicColors.infoFor(isDark);
        label = 'Completed';
        icon = Icons.task_alt_rounded;
        break;
      case 'cancelled':
        color = NeumorphicColors.errorFor(isDark);
        label = 'Cancelled';
        icon = Icons.cancel_rounded;
        break;
      case 'rejected':
        color = NeumorphicColors.errorFor(isDark);
        label = 'Rejected';
        icon = Icons.block_rounded;
        break;
      case 'succeeded':
      case 'paid':
      case 'paid_in_full':
        color = NeumorphicColors.successFor(isDark);
        label = 'Succeeded';
        icon = Icons.check_circle_rounded;
        break;
      case 'deposit_paid':
        color = isDark ? NeumorphicColors.tealLight : NeumorphicColors.tealPrimary;
        label = 'Deposit Paid';
        icon = Icons.payments_rounded;
        break;
      case 'refunded':
        color = NeumorphicColors.errorFor(isDark);
        label = 'Refunded';
        icon = Icons.replay_rounded;
        break;
      case 'partially_refunded':
        color = NeumorphicColors.warningFor(isDark);
        label = 'Partially Refunded';
        icon = Icons.replay_rounded;
        break;
      case 'unpaid':
      case 'awaiting_payment':
        color = NeumorphicColors.warningFor(isDark);
        label = 'Awaiting Payment';
        icon = Icons.pending_actions_rounded;
        break;
      case 'pending':
      default:
        color = NeumorphicColors.warningFor(isDark);
        label = status.isNotEmpty ? '${status[0].toUpperCase()}${status.substring(1)}' : 'Pending';
        icon = Icons.hourglass_top_rounded;
        break;
    }

    return NeumorphicContainer(
      borderRadius: 12.0,
      isInset: true,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
      /*
      // Gene - Nov, 04, 2026: Fixed StatusBadge layout without flex constraint
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
      */
      // Gene - Nov 06, 2026: Wrapped status badge label in Flexible with ellipsis to prevent RenderFlex overflow in compact/mobile containers
      // child: Row(
      //   mainAxisSize: MainAxisSize.min,
      //   children: [
      //     Icon(icon, size: 14, color: color),
      //     const SizedBox(width: 5),
      //     Flexible(
      //       child: Text(
      //         label,
      //         style: TextStyle(
      //           color: color,
      //           fontWeight: FontWeight.w600,
      //           fontSize: 12,
      //         ),
      //         maxLines: 1,
      //         overflow: TextOverflow.ellipsis,
      //       ),
      //     ),
      //   ],
      // ),
      // // Gene - Nov, 14, 2026: Guard extreme sub-32dp badge constraints by omitting leading icon to avoid sub-pixel Row overflow
      // child: LayoutBuilder(
      //   builder: (context, constraints) {
      //     final textWidget = Text(
      //       label,
      //       style: TextStyle(
      //         color: color,
      //         fontWeight: FontWeight.w600,
      //         fontSize: 12,
      //       ),
      //       maxLines: 1,
      //       overflow: TextOverflow.ellipsis,
      //     );
      //     if (constraints.maxWidth < 32) {
      //       return textWidget;
      //     }
      //     return Row(
      //       mainAxisSize: MainAxisSize.min,
      //       children: [
      //         Icon(icon, size: 14, color: color),
      //         const SizedBox(width: 5),
      //         Flexible(child: textWidget),
      //       ],
      //     );
      //   },
      // ),
      // Gene - Nov, 14, 2026: Use intrinsic-safe Row + Flexible Text (no LayoutBuilder) so StatusBadge works inside DataTable cells
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
