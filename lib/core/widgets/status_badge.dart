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
