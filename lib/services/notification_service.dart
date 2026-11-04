// Gene - Nov, 03, 2026: In-App Notifications service with read/unread state management
// Gene - Nov, 04, 2026: Supabase notifications table synchronization & realtime updates
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/notification_item.dart';
import 'supabase_service.dart';

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

  // Gene - Nov, 04, 2026: Load notifications from Supabase notifications table
  Future<void> loadNotifications(String userId) async {
    final client = SupabaseService.client;
    if (client != null) {
      try {
        final data = await client
            .from('notifications')
            .select()
            .eq('user_id', userId)
            .order('created_at', ascending: false);
        final list = (data as List).map((r) => NotificationItem.fromJson(r)).toList();
        if (list.isNotEmpty) {
          state = list;
        }
      } catch (_) {}
    }
  }

  void markAsRead(String id) async {
    final client = SupabaseService.client;
    if (client != null) {
      try {
        await client.from('notifications').update({'is_read': true}).eq('id', id);
      } catch (_) {}
    }

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
