// Gene - Nov, 03, 2026: In-App Notifications Center Screen
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/neumorphic_colors.dart';
import '../../../core/widgets/neumorphic_container.dart';
import '../../../services/notification_service.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifications = ref.watch(notificationsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? NeumorphicColors.tealLight : NeumorphicColors.tealPrimary;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications', style: TextStyle(fontWeight: FontWeight.w700)),
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
                    child: GestureDetector(
                      onTap: () {
                        ref.read(notificationsProvider.notifier).markAsRead(notif.id);
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
                                        style: TextStyle(fontSize: 11, color: isDark ? Colors.white38 : Colors.black38),
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
                  );
                },
              ),
      ),
    );
  }
}
