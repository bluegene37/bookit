// Gene - Nov, 03, 2026: Booking management repository and Riverpod providers
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/booking.dart';
import 'supabase_service.dart';

class BookingNotifier extends StateNotifier<List<Booking>> {
  /*
  // Gene - Nov, 03, 2026: Initial constructor with mock bookings only
  BookingNotifier() : super(List.from(SupabaseService.mockBookings));
  */

  // Gene - Nov, 04, 2026: Updated constructor automatically syncing with live Supabase bookings table
  BookingNotifier() : super(List.from(SupabaseService.mockBookings)) {
    loadBookings();
  }

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
    final isConfirmed = booking.status == 'confirmed';
    final holdExpiresAt = isConfirmed ? null : (booking.holdExpiresAt ?? DateTime.now().add(const Duration(minutes: 15)));

    final bookingToInsert = booking.copyWith(
      status: isConfirmed ? 'confirmed' : 'awaiting_payment',
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
}

final bookingsProvider = StateNotifierProvider<BookingNotifier, List<Booking>>((ref) {
  return BookingNotifier();
});

final clientBookingsProvider = Provider<List<Booking>>((ref) {
  final all = ref.watch(bookingsProvider);
  return all;
});

final adminBookingsProvider = Provider.family<List<Booking>, String>((ref, businessId) {
  final all = ref.watch(bookingsProvider);
  return all.where((b) => b.businessId == businessId).toList();
});
