// Gene - Nov, 05, 2026: Tactile Neumorphic Digital Boarding Pass modal with scannable QR code and check-in status
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../../core/theme/neumorphic_colors.dart';
import '../../../../core/widgets/neumorphic_container.dart';
import '../../../../core/widgets/neumorphic_button.dart';
import '../../../../models/booking.dart';
import '../../../../services/calendar_sync_service.dart';

class BookingQrPassModal extends StatelessWidget {
  final Booking booking;

  const BookingQrPassModal({super.key, required this.booking});

  static Future<void> show(BuildContext context, Booking booking) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => BookingQrPassModal(booking: booking),
    );
  }

  String get _checkinUrl {
    final token = booking.qrToken ?? (booking.id.length >= 6 ? booking.id.substring(0, 6) : booking.id);
    return 'https://bookit.app/checkin/${booking.id}?token=$token';
  }

  String get _passId {
    return booking.qrToken ?? (booking.id.length >= 8 ? booking.id.substring(0, 8).toUpperCase() : booking.id.toUpperCase());
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? NeumorphicColors.tealLight : NeumorphicColors.tealPrimary;
    final textPrimary = isDark ? NeumorphicColors.darkTextPrimary : NeumorphicColors.lightTextPrimary;
    final textSecondary = isDark ? NeumorphicColors.darkTextSecondary : NeumorphicColors.lightTextSecondary;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: SingleChildScrollView(
          child: NeumorphicContainer(
            borderRadius: 24,
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top Header Row
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.confirmation_number_outlined, size: 20, color: accent),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Digital Boarding Pass',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            'Fast-Track Front Desk Check-In',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: textSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close_rounded, size: 20, color: textSecondary),
                      onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
                      tooltip: 'Close',
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Scalloped Perforation Card
                Container(
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1F242F) : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isDark ? Colors.white10 : Colors.black12,
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.06),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Upper Section: Business & Appointment Metadata
                      Padding(
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    booking.businessName ?? 'Clinic / Practice',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800,
                                      color: textPrimary,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: accent.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: accent.withValues(alpha: 0.3)),
                                  ),
                                  child: Text(
                                    _passId,
                                    style: TextStyle(
                                      fontFamily: 'monospace',
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                      color: accent,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              booking.serviceName ?? 'General Appointment',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: textSecondary,
                              ),
                            ),
                            const SizedBox(height: 14),

                            /*
                            // Original unconstrained rows for clientName and staffName
                            if (booking.clientName != null) ...[
                              Row(
                                children: [
                                  Icon(Icons.person_outline_rounded, size: 15, color: textSecondary),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Patient: ${booking.clientName}',
                                    style: TextStyle(fontSize: 13, color: textPrimary, fontWeight: FontWeight.w500),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                            ],

                            if (booking.staffName != null) ...[
                              Row(
                                children: [
                                  Icon(Icons.badge_outlined, size: 15, color: textSecondary),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Specialist: ${booking.staffName}',
                                    style: TextStyle(fontSize: 13, color: textPrimary, fontWeight: FontWeight.w500),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                            ],
                            */
                            // Gene - Nov 06, 2026: Wrapped client and specialist name strings in Expanded with text ellipsis to prevent RenderFlex overflow on mobile screens
                            if (booking.clientName != null) ...[
                              Row(
                                children: [
                                  Icon(Icons.person_outline_rounded, size: 15, color: textSecondary),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      'Patient: ${booking.clientName}',
                                      style: TextStyle(fontSize: 13, color: textPrimary, fontWeight: FontWeight.w500),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                            ],

                            if (booking.staffName != null) ...[
                              Row(
                                children: [
                                  Icon(Icons.badge_outlined, size: 15, color: textSecondary),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      'Specialist: ${booking.staffName}',
                                      style: TextStyle(fontSize: 13, color: textPrimary, fontWeight: FontWeight.w500),
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
                                Icon(Icons.access_time_rounded, size: 15, color: accent),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    booking.formattedSchedule,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: textPrimary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // Perforated Tear Line with Half-Circle Cutouts
                      Row(
                        children: [
                          Container(
                            width: 14,
                            height: 24,
                            decoration: BoxDecoration(
                              color: isDark ? NeumorphicColors.darkSurface : NeumorphicColors.lightSurface,
                              borderRadius: const BorderRadius.horizontal(right: Radius.circular(12)),
                            ),
                          ),
                          Expanded(
                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                final boxWidth = constraints.constrainWidth();
                                const dashWidth = 6.0;
                                const dashSpace = 4.0;
                                final dashCount = (boxWidth / (dashWidth + dashSpace)).floor();
                                return Flex(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  direction: Axis.horizontal,
                                  children: List.generate(dashCount, (_) {
                                    return SizedBox(
                                      width: dashWidth,
                                      height: 1.5,
                                      child: DecoratedBox(
                                        decoration: BoxDecoration(
                                          color: isDark ? Colors.white24 : Colors.black26,
                                        ),
                                      ),
                                    );
                                  }),
                                );
                              },
                            ),
                          ),
                          Container(
                            width: 14,
                            height: 24,
                            decoration: BoxDecoration(
                              color: isDark ? NeumorphicColors.darkSurface : NeumorphicColors.lightSurface,
                              borderRadius: const BorderRadius.horizontal(left: Radius.circular(12)),
                            ),
                          ),
                        ],
                      ),

                      // Lower Section: Scannable Vector QR Code & Instructions
                      Padding(
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.black12, width: 1.5),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.08),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: QrImageView(
                                data: _checkinUrl,
                                version: QrVersions.auto,
                                size: 180,
                                backgroundColor: Colors.white,
                                eyeStyle: const QrEyeStyle(
                                  eyeShape: QrEyeShape.square,
                                  color: Color(0xFF0F172A),
                                ),
                                dataModuleStyle: const QrDataModuleStyle(
                                  dataModuleShape: QrDataModuleShape.square,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Present this QR code at front desk',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Staff can scan this directly to verify your check-in instantly.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 11,
                                color: textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Real-time Status Banner
                _buildStatusBanner(context),
                const SizedBox(height: 16),

                // Action Buttons: Share Pass & Add to Calendar
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.share_outlined, size: 16),
                        label: const Text('Share Pass', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: textPrimary,
                          side: BorderSide(color: isDark ? Colors.white24 : Colors.black12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: _checkinUrl));
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Boarding pass check-in link copied to clipboard: $_checkinUrl'),
                              backgroundColor: accent,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: PopupMenuButton<String>(
                        tooltip: 'Add to Calendar',
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
                                        : 'Calendar invite generated for Apple / Outlook.',
                                  ),
                                  backgroundColor: accent,
                                  behavior: SnackBarBehavior.floating,
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
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                          decoration: BoxDecoration(
                            border: Border.all(color: isDark ? Colors.white24 : Colors.black12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          alignment: Alignment.center,
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.calendar_today_rounded, size: 16, color: accent),
                                const SizedBox(width: 6),
                                Text(
                                  'Add to Calendar',
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
                  ],
                ),
                const SizedBox(height: 10),

                // Dismiss Button
                NeumorphicButton(
                  onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
                  child: const Text('Dismiss Pass'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBanner(BuildContext context) {
    Color bannerBg;
    Color bannerBorder;
    Color iconColor;
    IconData icon;
    String statusText;

    if (booking.status == 'checked_in') {
      bannerBg = NeumorphicColors.success.withValues(alpha: 0.15);
      bannerBorder = NeumorphicColors.success.withValues(alpha: 0.4);
      iconColor = NeumorphicColors.success;
      icon = Icons.check_circle_rounded;
      statusText = 'Checked In! You are in the queue.';
    } else if (booking.status == 'in_service') {
      bannerBg = NeumorphicColors.cyanAccent.withValues(alpha: 0.15);
      bannerBorder = NeumorphicColors.cyanAccent.withValues(alpha: 0.4);
      iconColor = NeumorphicColors.cyanAccent;
      icon = Icons.health_and_safety_rounded;
      statusText = 'In Service — Currently in appointment.';
    } else if (booking.status == 'confirmed') {
      bannerBg = NeumorphicColors.tealPrimary.withValues(alpha: 0.15);
      bannerBorder = NeumorphicColors.tealPrimary.withValues(alpha: 0.4);
      iconColor = NeumorphicColors.tealPrimary;
      icon = Icons.verified_rounded;
      statusText = 'Scheduled — Present upon arrival';
    } else if (booking.status == 'pending') {
      bannerBg = NeumorphicColors.warning.withValues(alpha: 0.15);
      bannerBorder = NeumorphicColors.warning.withValues(alpha: 0.4);
      iconColor = NeumorphicColors.warning;
      icon = Icons.hourglass_top_rounded;
      statusText = 'Pending Confirmation — Present upon arrival';
    } else {
      bannerBg = NeumorphicColors.info.withValues(alpha: 0.15);
      bannerBorder = NeumorphicColors.info.withValues(alpha: 0.4);
      iconColor = NeumorphicColors.info;
      icon = Icons.info_outline_rounded;
      statusText = 'Status: ${booking.status.toUpperCase()}';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: bannerBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: bannerBorder),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: iconColor),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              statusText,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: iconColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
