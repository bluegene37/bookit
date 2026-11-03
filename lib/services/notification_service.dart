// Gene - Nov, 03, 2026: In-App Notifications service with read/unread state management
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/notification_item.dart';

class NotificationsNotifier extends StateNotifier<List<NotificationItem>> {
  NotificationsNotifier()
      : super([
          NotificationItem(
            id: 'n-1',
            userId: '00000000-0000-0000-0000-000000000003',
            title: 'Booking Confirmed! 🎉',
            body: 'Your appointment at Apex Dental & Orthodontic Care is confirmed for this week.',
            type: 'booking_confirmed',
            isRead: false,
            createdAt: DateTime.now().subtract(const Duration(hours: 1)),
          ),
          NotificationItem(
            id: 'n-2',
            userId: '00000000-0000-0000-0000-000000000003',
            title: 'Pre-Visit Dental Reminder 🦷',
            body: 'Please arrive 10 minutes early to complete initial health check questions.',
            type: 'booking_reminder',
            isRead: true,
            createdAt: DateTime.now().subtract(const Duration(days: 1)),
          ),
        ]);

  void markAsRead(String id) {
    state = state.map((n) {
      if (n.id == id) {
        return NotificationItem(
          id: n.id,
          userId: n.userId,
          businessId: n.businessId,
          bookingId: n.bookingId,
          title: n.title,
          body: n.body,
          type: n.type,
          isRead: true,
          createdAt: n.createdAt,
        );
      }
      return n;
    }).toList();
  }

  void addNotification(NotificationItem item) {
    state = [item, ...state];
  }
}

final notificationsProvider = StateNotifierProvider<NotificationsNotifier, List<NotificationItem>>((ref) {
  return NotificationsNotifier();
});

final unreadNotificationCountProvider = Provider<int>((ref) {
  final items = ref.watch(notificationsProvider);
  return items.where((n) => !n.isRead).length;
});
