// Gene - Nov, 03, 2026: In-App Notifications service with read/unread state management
// Gene - Nov, 04, 2026: Supabase notifications table synchronization & realtime updates
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/notification_item.dart';
import 'supabase_service.dart';
// Gene - Nov 07, 2026: Added auth_service and demo_data imports for user-scoped notification filtering and markAllAsRead
import 'auth_service.dart';
import '../core/constants/demo_data.dart';

class NotificationsNotifier extends StateNotifier<List<NotificationItem>> {
  /*
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
  */
  // Gene - Nov 07, 2026: Seed NotificationsNotifier from SupabaseService.mockNotifications
  NotificationsNotifier() : super(List.from(SupabaseService.mockNotifications));

  void reloadDemoNotifications() {
    state = List.from(SupabaseService.mockNotifications);
  }

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

  /*
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
  */
  // Gene - Nov 07, 2026: Sync addNotification and markAllAsRead with SupabaseService.mockNotifications (avoid duplicate insert)
  void addNotification(NotificationItem item) {
    if (!SupabaseService.mockNotifications.any((n) => n.id == item.id)) {
      SupabaseService.mockNotifications.insert(0, item);
    }
    state = [item, ...state];
  }

  void markAllAsRead({String? userId}) async {
    final client = SupabaseService.client;
    if (client != null && userId != null) {
      try {
        await client.from('notifications').update({'is_read': true}).eq('user_id', userId);
      } catch (_) {}
    }

    for (int i = 0; i < SupabaseService.mockNotifications.length; i++) {
      final n = SupabaseService.mockNotifications[i];
      if (userId == null || n.userId == userId) {
        SupabaseService.mockNotifications[i] = NotificationItem(
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
    }

    state = state.map((n) {
      if (userId == null || n.userId == userId) {
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
}

final notificationsProvider = StateNotifierProvider<NotificationsNotifier, List<NotificationItem>>((ref) {
  return NotificationsNotifier();
});

// Gene - Nov 07, 2026: User-scoped notifications provider with Demo fallback
final userNotificationsProvider = Provider<List<NotificationItem>>((ref) {
  final items = ref.watch(notificationsProvider);
  final user = ref.watch(authProvider).user;
  if (user == null) {
    return items.where((n) => n.userId == DemoData.clientUserId).toList();
  }
  final filtered = items.where((n) => n.userId == user.id).toList();
  return filtered.isNotEmpty ? filtered : items;
});

final unreadNotificationCountProvider = Provider<int>((ref) {
  final items = ref.watch(userNotificationsProvider);
  return items.where((n) => !n.isRead).length;
});
