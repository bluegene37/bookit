// Gene - Nov, 03, 2026: Booking management repository and Riverpod providers
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/booking.dart';
import 'supabase_service.dart';

class BookingNotifier extends StateNotifier<List<Booking>> {
  BookingNotifier() : super(List.from(SupabaseService.mockBookings));

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
