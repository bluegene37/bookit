// Gene - Nov, 03, 2026: In-App Notifications Center Screen
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
// Gene - Nov 07, 2026: Added go_router and auth_service imports for notification navigation and Mark All Read
import 'package:go_router/go_router.dart';
import '../../../core/theme/neumorphic_colors.dart';
import '../../../core/widgets/neumorphic_container.dart';
import '../../../services/notification_service.dart';
import '../../../services/auth_service.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    /*
    final notifications = ref.watch(notificationsProvider);
    */
    // Gene - Nov 07, 2026: Watch userNotificationsProvider and active user for Mark All Read & contextual navigation
    final notifications = ref.watch(userNotificationsProvider);
    final authState = ref.watch(authProvider);
    final hasUnread = notifications.any((n) => !n.isRead);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? NeumorphicColors.tealLight : NeumorphicColors.tealPrimary;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications', style: TextStyle(fontWeight: FontWeight.w700)),
        actions: [
          if (hasUnread)
            TextButton.icon(
              onPressed: () {
                ref.read(notificationsProvider.notifier).markAllAsRead(
                      userId: authState.user?.id,
                    );
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('All notifications marked as read'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
              icon: Icon(Icons.done_all_rounded, size: 16, color: accent),
              label: Text(
                'Mark All Read',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: accent),
              ),
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: notifications.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.notifications_none, size: 48, color: isDark ? Colors.white24 : Colors.black26),
                    const SizedBox(height: 12),
                    Text(
                      'No notifications yet',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white60 : Colors.black54,
                      ),
                    ),
                  ],
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                itemCount: notifications.length,
                itemBuilder: (context, index) {
                  final notif = notifications[index];

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    /*
                    // Gene - Nov 07, 2026: Notification GestureDetector missing Semantics wrapper and used overloaded isBusinessOwner
                    child: GestureDetector(
                      onTap: () {
                        ref.read(notificationsProvider.notifier).markAsRead(notif.id);
                        if (notif.bookingId != null) {
                          if (authState.isBusinessOwner) {
                            context.go('/admin');
                          } else {
                            context.push('/my-bookings');
                          }
                        }
                      },
                    */
                    // Gene - Nov, 14, 2026: Added Semantics(button: true) and routed portal notification taps via canAccessAdminPortal
                    child: Semantics(
                      button: true,
                      label: '${notif.title}. ${notif.body}',
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () {
                          ref.read(notificationsProvider.notifier).markAsRead(notif.id);
                          if (notif.bookingId != null) {
                            if (authState.canAccessAdminPortal) {
                              context.go('/admin');
                            } else {
                              context.push('/my-bookings');
                            }
                          }
                        },
                        child: NeumorphicContainer(
                          borderRadius: 18.0,
                          isInset: notif.isRead,
                          border: !notif.isRead ? Border.all(color: accent.withValues(alpha: 0.5), width: 1.5) : null,
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              NeumorphicContainer(
                                isCircle: true,
                                width: 38,
                                height: 38,
                                child: Icon(
                                  notif.type.contains('confirmed') ? Icons.check_circle_outline : Icons.notifications_active_outlined,
                                  size: 20,
                                  color: accent,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            notif.title,
                                            style: TextStyle(
                                              fontSize: 15,
                                              fontWeight: notif.isRead ? FontWeight.w600 : FontWeight.w700,
                                              color: isDark ? Colors.white : Colors.black87,
                                            ),
                                          ),
                                        ),
                                        Text(
                                          DateFormat('h:mm a').format(notif.createdAt),
                                          // Gene - Nov, 14, 2026: Upgraded timestamp contrast from white38/black38 to WCAG AA muted tokens
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: isDark ? NeumorphicColors.darkTextMuted : NeumorphicColors.lightTextMuted,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      notif.body,
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: isDark ? NeumorphicColors.darkTextSecondary : NeumorphicColors.lightTextSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
