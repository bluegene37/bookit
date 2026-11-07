// Gene - Nov, 03, 2026: Booking management repository and Riverpod providers
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/booking.dart';
import 'supabase_service.dart';
// Gene - Nov 07, 2026: Added auth_service and demo_data imports for user-scoped clientBookingsProvider filtering
import 'auth_service.dart';
import '../core/constants/demo_data.dart';
// Gene - Nov 07, 2026: Added notification_item and notification_service imports for real-time lifecycle notifications
import '../models/notification_item.dart';
import 'notification_service.dart';
// Gene - Nov 07, 2026: Added AppErrorLogger, Business, BusinessStaff, and SlotCalculator imports for date-windowed queries and server-side RPC slot calculation
import '../core/utils/app_error_logger.dart';
import '../models/business.dart';
import '../models/business_staff.dart';
import '../features/booking_engine/domain/slot_calculator.dart';

class BookingNotifier extends StateNotifier<List<Booking>> {
  final Ref? _ref;
  /*
  // Gene - Nov, 03, 2026: Initial constructor with mock bookings only
  BookingNotifier() : super(List.from(SupabaseService.mockBookings));
  */

  /*
  // Gene - Nov, 04, 2026: Updated constructor automatically syncing with live Supabase bookings table
  BookingNotifier() : super(List.from(SupabaseService.mockBookings)) {
    loadBookings();
  }
  */

  // Gene - Nov 07, 2026: Added optional Ref to dispatch real-time in-app notifications on booking lifecycle events
  BookingNotifier([this._ref]) : super(List.from(SupabaseService.mockBookings)) {
    loadBookings();
  }

  void _emitNotification({
    required String userId,
    String? businessId,
    String? bookingId,
    required String title,
    required String body,
    required String type,
  }) {
    final item = NotificationItem(
      id: 'notif-${DateTime.now().microsecondsSinceEpoch}',
      userId: userId,
      businessId: businessId,
      bookingId: bookingId,
      title: title,
      body: body,
      type: type,
      isRead: false,
      createdAt: DateTime.now(),
    );
    if (_ref != null) {
      _ref.read(notificationsProvider.notifier).addNotification(item);
    } else {
      SupabaseService.mockNotifications.insert(0, item);
    }
  }

  /*
  // Gene - Nov, 04, 2026: Synchronize bookings table with joined relations from Supabase
  Future<void> loadBookings({String? businessId, String? clientId}) async {
    final client = SupabaseService.client;
    if (client != null) {
      try {
        var query = client.from('bookings').select('''
          *,
          businesses (name),
          services (name),
          business_staff (name),
          profiles:client_id (full_name)
        ''');

        if (businessId != null) {
          query = query.eq('business_id', businessId);
        }
        if (clientId != null) {
          query = query.eq('client_id', clientId);
        }

        final data = await query.order('created_at', ascending: false);
        final list = (data as List).map((row) => Booking.fromJson(row)).toList();
        if (list.isNotEmpty) {
          state = list;
        }
      } catch (_) {}
    }
  }
  */

  // Gene - Nov 07, 2026: Enhanced loadBookings with server-side date-windowing (fromDate/toDate), range pagination (limit/offset), and structured error telemetry
  Future<void> loadBookings({
    String? businessId,
    String? clientId,
    DateTime? fromDate,
    DateTime? toDate,
    int limit = 200,
    int offset = 0,
  }) async {
    final client = SupabaseService.client;
    if (client != null) {
      try {
        var query = client.from('bookings').select('''
          *,
          businesses (name),
          services (name),
          business_staff (name),
          profiles:client_id (full_name)
        ''');

        if (businessId != null) {
          query = query.eq('business_id', businessId);
        }
        if (clientId != null) {
          query = query.eq('client_id', clientId);
        }
        if (fromDate != null) {
          query = query.gte('start_time', fromDate.toUtc().toIso8601String());
        }
        if (toDate != null) {
          query = query.lte('start_time', toDate.toUtc().toIso8601String());
        }

        final data = await query
            .order('created_at', ascending: false)
            .range(offset, offset + limit - 1);
        final list = (data as List).map((row) => Booking.fromJson(row)).toList();
        if (list.isNotEmpty) {
          state = list;
        }
      } catch (e, st) {
        AppErrorLogger.report(
          service: 'BookingNotifier',
          operation: 'loadBookings',
          error: e,
          stackTrace: st,
        );
      }
    }
  }

  // Gene - Nov 07, 2026: Privacy-safe server-side slot calculation via `get_available_slots` RPC with deterministic local fallback
  Future<List<TimeSlot>> fetchAvailableSlots({
    required Business business,
    required DateTime date,
    int? customDurationMinutes,
    String? filterStaffId,
    BusinessStaff? staffMember,
  }) async {
    final client = SupabaseService.client;
    if (client != null) {
      try {
        final dateStr =
            '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
        final rpcData = await client.rpc(
          'get_available_slots',
          params: {
            'p_business_id': business.id,
            'p_date': dateStr,
            'p_duration_minutes': customDurationMinutes,
            'p_staff_id': filterStaffId,
          },
        );
        if (rpcData is List && rpcData.isNotEmpty) {
          return SlotCalculator.fromRpcResponse(rpcData, staffMember: staffMember);
        }
      } catch (e, st) {
        AppErrorLogger.report(
          service: 'BookingNotifier',
          operation: 'fetchAvailableSlots',
          error: e,
          stackTrace: st,
        );
      }
    }

    final dayScopedBookings = SlotCalculator.filterBookingsForDate(
      state,
      date,
      businessId: business.id,
      staffId: filterStaffId,
    );

    return SlotCalculator.calculateAvailableSlots(
      business: business,
      date: date,
      existingBookings: dayScopedBookings,
      customDurationMinutes: customDurationMinutes,
      filterStaffId: filterStaffId,
      staffMember: staffMember,
    );
  }

  /*
  Future<void> createBooking(Booking booking) async {
    final client = SupabaseService.client;
    if (client != null) {
      try {
        final res = await client.from('bookings').insert(booking.toJson()).select().single();
        final newBooking = Booking.fromJson(res);
        state = [newBooking, ...state];
        return;
      } catch (_) {}
    }

    // Local mock state update
    state = [booking, ...state];
  }
  */

  /*
  // Gene - Nov, 04, 2026: Updated createBooking to set status 'awaiting_payment', hold_expires_at, and payment_status for Stripe checkout
  Future<Booking> createBooking(Booking booking) async {
    final holdExpiresAt = DateTime.now().add(const Duration(minutes: 15));
    final pendingBooking = booking.copyWith(
      status: 'awaiting_payment',
      holdExpiresAt: booking.holdExpiresAt ?? holdExpiresAt,
      paymentStatus: 'unpaid',
      amountDue: booking.amountDue > 0 ? booking.amountDue : booking.totalPrice,
      amountPaid: 0.0,
    );

    final client = SupabaseService.client;
    if (client != null) {
      try {
        final res = await client.from('bookings').insert(pendingBooking.toJson()).select().single();
        final newBooking = Booking.fromJson(res);
        state = [newBooking, ...state];
        return newBooking;
      } catch (_) {}
    }

    // Local mock state update
    state = [pendingBooking, ...state];
    return pendingBooking;
  }
  */

  // Gene - Nov, 04, 2026: Updated createBooking to preserve confirmed status without hold timer for pay_at_venue services
  Future<Booking> createBooking(Booking booking) async {
    /*
    final isConfirmed = booking.status == 'confirmed';
    final holdExpiresAt = isConfirmed ? null : (booking.holdExpiresAt ?? DateTime.now().add(const Duration(minutes: 15)));

    final bookingToInsert = booking.copyWith(
      status: isConfirmed ? 'confirmed' : 'awaiting_payment',
      holdExpiresAt: holdExpiresAt,
      paymentStatus: booking.paymentStatus.isNotEmpty ? booking.paymentStatus : 'unpaid',
      amountDue: booking.amountDue > 0 ? booking.amountDue : booking.totalPrice,
      amountPaid: booking.amountPaid,
    );
    */
    // Gene - Nov 07, 2026: Preserve 'confirmed' and 'checked_in' statuses (including reception walk-ins) without hold timer
    final isDirectStatus = booking.status == 'confirmed' || booking.status == 'checked_in';
    final holdExpiresAt = isDirectStatus ? null : (booking.holdExpiresAt ?? DateTime.now().add(const Duration(minutes: 15)));

    final bookingToInsert = booking.copyWith(
      status: isDirectStatus ? booking.status : 'awaiting_payment',
      holdExpiresAt: holdExpiresAt,
      paymentStatus: booking.paymentStatus.isNotEmpty ? booking.paymentStatus : 'unpaid',
      amountDue: booking.amountDue > 0 ? booking.amountDue : booking.totalPrice,
      amountPaid: booking.amountPaid,
    );

    final client = SupabaseService.client;
    if (client != null) {
      try {
        final res = await client.from('bookings').insert(bookingToInsert.toJson()).select().single();
        final newBooking = Booking.fromJson(res);
        state = [newBooking, ...state];
        return newBooking;
      } catch (_) {}
    }

    // Local mock state update
    state = [bookingToInsert, ...state];
    // Gene - Nov 07, 2026: Emit real-time in-app notifications for client and business owner upon booking creation
    _emitNotification(
      userId: bookingToInsert.clientId,
      businessId: bookingToInsert.businessId,
      bookingId: bookingToInsert.id,
      title: bookingToInsert.status == 'checked_in'
          ? 'Walk-In Checked In'
          : (bookingToInsert.status == 'confirmed' ? 'Appointment Confirmed' : 'Booking Request Submitted'),
      body:
          '${bookingToInsert.serviceName ?? 'Appointment'} at ${bookingToInsert.businessName ?? 'Clinic'} (${bookingToInsert.formattedSchedule}).',
      type: 'booking_${bookingToInsert.status}',
    );
    _emitNotification(
      userId: DemoData.adminOwnerId,
      businessId: bookingToInsert.businessId,
      bookingId: bookingToInsert.id,
      title: bookingToInsert.status == 'checked_in' ? 'New Walk-In Checked In' : 'New Booking Received',
      body:
          '${bookingToInsert.clientName ?? 'Client'} booked ${bookingToInsert.serviceName ?? 'Appointment'} (${bookingToInsert.formattedSchedule}).',
      type: 'booking_${bookingToInsert.status}',
    );
    return bookingToInsert;
  }

  // Gene - Nov, 04, 2026: Added updateBookingPayment to update payment status and financial amounts
  Future<void> updateBookingPayment({
    required String bookingId,
    required String paymentStatus,
    required double amountPaid,
    required double amountDue,
  }) async {
    final client = SupabaseService.client;
    if (client != null) {
      try {
        await client.from('bookings').update({
          'status': 'confirmed',
          'payment_status': paymentStatus,
          'amount_paid': amountPaid,
          'amount_due': amountDue,
          'hold_expires_at': null,
        }).eq('id', bookingId);
      } catch (_) {}
    }

    state = state.map((b) {
      if (b.id == bookingId) {
        return b.copyWith(
          status: 'confirmed',
          paymentStatus: paymentStatus,
          amountPaid: amountPaid,
          amountDue: amountDue,
          holdExpiresAt: null,
        );
      }
      return b;
    }).toList();
  }

  /*
  // Gene - Nov, 03, 2026: Original updateBookingStatus and cancelBooking
  Future<void> updateBookingStatus(String bookingId, String newStatus) async {
    final client = SupabaseService.client;
    if (client != null) {
      try {
        await client.from('bookings').update({'status': newStatus}).eq('id', bookingId);
      } catch (_) {}
    }

    state = state.map((b) {
      if (b.id == bookingId) {
        return Booking(
          id: b.id,
          businessId: b.businessId,
          clientId: b.clientId,
          serviceId: b.serviceId,
          staffId: b.staffId,
          bookingModel: b.bookingModel,
          startTime: b.startTime,
          endTime: b.endTime,
          dateFrom: b.dateFrom,
          dateTo: b.dateTo,
          status: newStatus,
          totalPrice: b.totalPrice,
          clientNotes: b.clientNotes,
          adminNotes: b.adminNotes,
          cancellationReason: b.cancellationReason,
          createdAt: b.createdAt,
          businessName: b.businessName,
          serviceName: b.serviceName,
          staffName: b.staffName,
          clientName: b.clientName,
        );
      }
      return b;
    }).toList();
  }

  Future<void> cancelBooking(String bookingId, String reason) async {
    final client = SupabaseService.client;
    if (client != null) {
      try {
        await client.from('bookings').update({
          'status': 'cancelled',
          'cancellation_reason': reason,
        }).eq('id', bookingId);
      } catch (_) {}
    }

    state = state.map((b) {
      if (b.id == bookingId) {
        return Booking(
          id: b.id,
          businessId: b.businessId,
          clientId: b.clientId,
          serviceId: b.serviceId,
          staffId: b.staffId,
          bookingModel: b.bookingModel,
          startTime: b.startTime,
          endTime: b.endTime,
          dateFrom: b.dateFrom,
          dateTo: b.dateTo,
          status: 'cancelled',
          totalPrice: b.totalPrice,
          clientNotes: b.clientNotes,
          adminNotes: b.adminNotes,
          cancellationReason: reason,
          createdAt: b.createdAt,
          businessName: b.businessName,
          serviceName: b.serviceName,
          staffName: b.staffName,
          clientName: b.clientName,
        );
      }
      return b;
    }).toList();
  }
  */

  // Gene - Nov, 05, 2026: Re-sync in-memory bookings with freshly reset DemoData
  void reloadDemoBookings() {
    state = List.from(SupabaseService.mockBookings);
  }

  // Gene - Nov, 05, 2026: Reschedule booking with support for slot and date range models
  Future<void> rescheduleBooking({
    required String bookingId,
    DateTime? newStartTime,
    DateTime? newEndTime,
    DateTime? newDateFrom,
    DateTime? newDateTo,
  }) async {
    final client = SupabaseService.client;
    if (client != null) {
      try {
        final updateMap = <String, dynamic>{
          'status': 'confirmed',
          if (newStartTime != null) 'start_time': newStartTime.toIso8601String(),
          if (newEndTime != null) 'end_time': newEndTime.toIso8601String(),
          if (newDateFrom != null) 'date_from': newDateFrom.toIso8601String(),
          if (newDateTo != null) 'date_to': newDateTo.toIso8601String(),
        };
        await client.from('bookings').update(updateMap).eq('id', bookingId);
      } catch (_) {}
    }

    state = state.map((b) {
      if (b.id == bookingId) {
        final updated = b.copyWith(
          status: 'confirmed',
          startTime: newStartTime ?? b.startTime,
          endTime: newEndTime ?? b.endTime,
          dateFrom: newDateFrom ?? b.dateFrom,
          dateTo: newDateTo ?? b.dateTo,
        );
        // Gene - Nov 07, 2026: Emit notification when appointment is rescheduled
        _emitNotification(
          userId: updated.clientId,
          businessId: updated.businessId,
          bookingId: updated.id,
          title: 'Appointment Rescheduled',
          body:
              'Your ${updated.serviceName ?? 'appointment'} at ${updated.businessName ?? 'Clinic'} is now scheduled for ${updated.formattedSchedule}.',
          type: 'booking_rescheduled',
        );
        return updated;
      }
      return b;
    }).toList();
  }

  // Gene - Nov, 05, 2026: Robust updateBookingStatus preserving payment, hold, and financial states via copyWith
  Future<void> updateBookingStatus(String bookingId, String newStatus) async {
    final client = SupabaseService.client;
    if (client != null) {
      try {
        await client.from('bookings').update({'status': newStatus}).eq('id', bookingId);
      } catch (_) {}
    }

    state = state.map((b) {
      if (b.id == bookingId) {
        final updated = b.copyWith(status: newStatus);
        // Gene - Nov 07, 2026: Emit notification on booking status transition
        _emitNotification(
          userId: updated.clientId,
          businessId: updated.businessId,
          bookingId: updated.id,
          title: 'Booking Status: ${newStatus.replaceAll('_', ' ').toUpperCase()}',
          body:
              'Your ${updated.serviceName ?? 'appointment'} at ${updated.businessName ?? 'Clinic'} was updated to ${newStatus.replaceAll('_', ' ')}.',
          type: 'booking_$newStatus',
        );
        return updated;
      }
      return b;
    }).toList();
  }

  // Gene - Nov, 05, 2026: Enhanced cancelBooking with automatic refund status marking and reason persistence
  Future<void> cancelBooking(String bookingId, String reason) async {
    final client = SupabaseService.client;
    if (client != null) {
      try {
        await client.from('bookings').update({
          'status': 'cancelled',
          'cancellation_reason': reason,
        }).eq('id', bookingId);
      } catch (_) {}
    }

    state = state.map((b) {
      if (b.id == bookingId) {
        final hasPaid = b.amountPaid > 0;
        final updated = b.copyWith(
          status: 'cancelled',
          cancellationReason: reason,
          paymentStatus: hasPaid ? 'refunded' : b.paymentStatus,
        );
        // Gene - Nov 07, 2026: Emit notification on booking cancellation
        _emitNotification(
          userId: updated.clientId,
          businessId: updated.businessId,
          bookingId: updated.id,
          title: 'Appointment Cancelled',
          body:
              'Your ${updated.serviceName ?? 'appointment'} at ${updated.businessName ?? 'Clinic'} has been cancelled ($reason).',
          type: 'booking_cancelled',
        );
        return updated;
      }
      return b;
    }).toList();
  }

  // Gene - Nov, 05, 2026: Added reception QR scanner modal, check-in action sheet, and booking state transitions
  Future<void> checkInBooking(String bookingId) async {
    final now = DateTime.now();
    final client = SupabaseService.client;
    if (client != null) {
      try {
        await client.from('bookings').update({
          'status': 'checked_in',
          'checked_in_at': now.toIso8601String(),
        }).eq('id', bookingId);
      } catch (_) {}
    }
    state = [
      for (final b in state)
        if (b.id == bookingId)
          () {
            final updated = b.copyWith(status: 'checked_in', checkedInAt: now);
            _emitNotification(
              userId: updated.clientId,
              businessId: updated.businessId,
              bookingId: updated.id,
              title: 'Checked In at Reception',
              body: 'You are checked in for ${updated.serviceName ?? 'your visit'} at ${updated.businessName ?? 'Clinic'}.',
              type: 'booking_checked_in',
            );
            return updated;
          }()
        else
          b,
    ];
  }

  // Gene - Nov, 05, 2026: Transition booking from waiting room to in_service
  Future<void> startServiceBooking(String bookingId) async {
    final now = DateTime.now();
    final client = SupabaseService.client;
    if (client != null) {
      try {
        await client.from('bookings').update({
          'status': 'in_service',
          'in_service_at': now.toIso8601String(),
        }).eq('id', bookingId);
      } catch (_) {}
    }
    state = [
      for (final b in state)
        if (b.id == bookingId)
          () {
            final updated = b.copyWith(status: 'in_service', inServiceAt: now);
            _emitNotification(
              userId: updated.clientId,
              businessId: updated.businessId,
              bookingId: updated.id,
              title: 'Your Specialist is Ready',
              body: '${updated.staffName ?? 'Your provider'} is ready for your ${updated.serviceName ?? 'session'} now.',
              type: 'booking_in_service',
            );
            return updated;
          }()
        else
          b,
    ];
  }
}

/*
final bookingsProvider = StateNotifierProvider<BookingNotifier, List<Booking>>((ref) {
  return BookingNotifier();
});
*/
// Gene - Nov 07, 2026: Pass ref into BookingNotifier to dispatch real-time notifications
final bookingsProvider = StateNotifierProvider<BookingNotifier, List<Booking>>((ref) {
  return BookingNotifier(ref);
});

// Gene - Nov, 05, 2026: Provider alias for backwards compatibility
final bookingProvider = bookingsProvider;

/*
final clientBookingsProvider = Provider<List<Booking>>((ref) {
  final all = ref.watch(bookingsProvider);
  return all;
});
*/
// Gene - Nov 07, 2026: Filter clientBookingsProvider by authenticated client user ID (with Demo Client fallback when previewing as Demo Admin)
final clientBookingsProvider = Provider<List<Booking>>((ref) {
  final all = ref.watch(bookingsProvider);
  final user = ref.watch(authProvider).user;

  if (user == null) {
    return all
        .where((b) => b.clientId == DemoData.clientUserId || b.clientId.startsWith('guest-client-'))
        .toList();
  }

  final userBookings = all
      .where((b) => b.clientId == user.id || b.clientId.startsWith('guest-client-'))
      .toList();

  if (userBookings.isNotEmpty || !user.isBusinessOwner) {
    return userBookings.isNotEmpty
        ? userBookings
        : all.where((b) => b.clientId == DemoData.clientUserId).toList();
  }

  return all.where((b) => b.clientId == DemoData.clientUserId).toList();
});

final adminBookingsProvider = Provider.family<List<Booking>, String>((ref, businessId) {
  final all = ref.watch(bookingsProvider);
  return all.where((b) => b.businessId == businessId).toList();
});

// Gene - Nov 07, 2026: Date-windowed bookings provider scoping agenda/calendar views to [from, to]
typedef DateWindowBookingFilter = ({String businessId, DateTime from, DateTime to});

final dateWindowedBookingsProvider =
    Provider.family<List<Booking>, DateWindowBookingFilter>((ref, filter) {
  final all = ref.watch(bookingsProvider);
  return all.where((b) {
    if (b.businessId != filter.businessId) return false;
    final effectiveStart = b.startTime ?? b.dateFrom;
    final effectiveEnd = b.endTime ?? b.dateTo ?? effectiveStart;
    if (effectiveStart == null || effectiveEnd == null) return false;
    return !effectiveStart.isAfter(filter.to) && !effectiveEnd.isBefore(filter.from);
  }).toList();
});
