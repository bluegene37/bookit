// Gene - Nov, 05, 2026: Comprehensive test suite for data-driven demo store, defensive fallback factories, multi-persona authentication, booking lifecycle, and customer review calculations
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bookit/core/constants/demo_data.dart';
import 'package:bookit/models/business.dart';
import 'package:bookit/models/business_staff.dart';
import 'package:bookit/models/service_item.dart';
import 'package:bookit/models/booking.dart';
import 'package:bookit/models/payment.dart';
import 'package:bookit/models/review.dart';
import 'package:bookit/models/user_profile.dart';
import 'package:bookit/services/supabase_service.dart';
import 'package:bookit/services/auth_service.dart';
import 'package:bookit/services/business_service.dart';
import 'package:bookit/services/booking_service.dart';
import 'package:bookit/core/widgets/safe_network_image.dart';
import 'package:bookit/features/client_bookings/presentation/client_bookings_screen.dart';

void main() {
  group('Demo Data & Defensive Fallback Tests', () {
    test('DemoData supplies businesses across all 6 industry sweet spots', () {
      final businesses = DemoData.freshBusinesses;
      expect(businesses.length, greaterThanOrEqualTo(8));

      final categories = businesses.map((b) => b.category).toSet();
      expect(categories.contains('Healthcare & Clinics'), isTrue);
      expect(categories.contains('Wellness & Therapy'), isTrue);
      expect(categories.contains('Beauty & Personal Care'), isTrue);
      expect(categories.contains('Fitness & Coaching'), isTrue);
      expect(categories.contains('Professional Consulting'), isTrue);
      expect(categories.contains('Studios & Space Rentals'), isTrue);
    });

    test('DemoData supplies 4 pre-configured personas with distinct roles', () {
      final users = DemoData.allDemoUsers;
      expect(users.length, equals(4));

      final admin = users.firstWhere((u) => u.email == 'admin@bookit.dev');
      expect(admin.role, equals('business_owner'));
      expect(admin.fullName, equals('Dr. Alexander Vance'));

      final retreatOwner = users.firstWhere((u) => u.email == 'retreat@bookit.dev');
      expect(retreatOwner.role, equals('business_owner'));
      expect(retreatOwner.fullName, equals('Elena Rostova'));

      final staff = users.firstWhere((u) => u.email == 'staff@bookit.dev');
      expect(staff.role, equals('staff'));
      expect(staff.fullName, equals('Dr. Sophia Martinez, DMD'));

      final client = users.firstWhere((u) => u.email == 'client@bookit.dev');
      expect(client.role, equals('client'));
      expect(client.fullName, equals('Michael Chen'));
    });

    test('Defensive fallback factories guarantee safe non-null defaults', () {
      final fallbackBiz = Business.fallback();
      expect(fallbackBiz.id, isNotEmpty);
      expect(fallbackBiz.name, isNotEmpty);
      expect(fallbackBiz.ratingAvg, greaterThan(0));

      final fallbackService = ServiceItem.fallback();
      expect(fallbackService.id, isNotEmpty);
      expect(fallbackService.price, greaterThan(0));

      final fallbackStaff = BusinessStaff.fallback();
      expect(fallbackStaff.id, isNotEmpty);
      expect(fallbackStaff.name, isNotEmpty);

      final fallbackBooking = Booking.fallback();
      expect(fallbackBooking.id, isNotEmpty);
      expect(fallbackBooking.status, equals('confirmed'));

      final fallbackPayment = Payment.fallback();
      expect(fallbackPayment.id, isNotEmpty);
      expect(fallbackPayment.grossAmount, greaterThan(0));

      final fallbackReview = Review.fallback();
      expect(fallbackReview.rating, equals(5));

      final fallbackUser = UserProfile.fallback();
      expect(fallbackUser.email, equals('admin@bookit.dev'));
    });

    test('Hardened fromJson parsers gracefully handle empty/null JSON without crashing', () {
      final emptyBiz = Business.fromJson(const {});
      expect(emptyBiz.id, equals('00000000-0000-0000-0000-000000000000'));
      expect(emptyBiz.name, equals('Sample Practice / Studio'));

      final emptyService = ServiceItem.fromJson(const {});
      expect(emptyService.id, equals('srv-fallback-0'));
      expect(emptyService.price, equals(0.0));

      final emptyStaff = BusinessStaff.fromJson(const {});
      expect(emptyStaff.name, equals('Available Specialist'));

      final emptyBooking = Booking.fromJson(const {});
      expect(emptyBooking.status, equals('pending'));

      final emptyPayment = Payment.fromJson(const {});
      expect(emptyPayment.grossAmount, equals(0.0));

      final emptyReview = Review.fromJson(const {});
      expect(emptyReview.rating, equals(5));

      final emptyUser = UserProfile.fromJson(const {});
      expect(emptyUser.fullName, equals('Valued User'));
    });

    test('SupabaseService.resetToDefaultData restores initial state', () {
      // Mutate state
      SupabaseService.mockBusinesses.clear();
      SupabaseService.mockBookings.clear();
      expect(SupabaseService.mockBusinesses.isEmpty, isTrue);

      // Reset
      SupabaseService.resetToDefaultData();
      expect(SupabaseService.mockBusinesses.length, greaterThanOrEqualTo(8));
      expect(SupabaseService.mockBookings.length, greaterThanOrEqualTo(4));
      expect(SupabaseService.mockReviews.length, greaterThanOrEqualTo(3));
    });
  });

  group('Multi-Persona Authentication Tests', () {
    test('AuthNotifier sign-in recognizes all 4 demo persona emails', () async {
      final authNotifier = AuthNotifier();

      await authNotifier.signIn('admin@bookit.dev', 'any');
      expect(authNotifier.state.user?.fullName, equals('Dr. Alexander Vance'));
      expect(authNotifier.state.isBusinessOwner, isTrue);

      await authNotifier.signIn('retreat@bookit.dev', 'any');
      expect(authNotifier.state.user?.fullName, equals('Elena Rostova'));
      expect(authNotifier.state.isBusinessOwner, isTrue);

      await authNotifier.signIn('staff@bookit.dev', 'any');
      expect(authNotifier.state.user?.fullName, equals('Dr. Sophia Martinez, DMD'));

      await authNotifier.signIn('client@bookit.dev', 'any');
      expect(authNotifier.state.user?.fullName, equals('Michael Chen'));
      expect(authNotifier.state.isBusinessOwner, isFalse);
    });

    test('AuthNotifier direct shortcuts switch personas accurately', () {
      final authNotifier = AuthNotifier();

      authNotifier.loginAsDemoRetreatOwner();
      expect(authNotifier.state.user?.email, equals('retreat@bookit.dev'));

      authNotifier.loginAsDemoStaff();
      expect(authNotifier.state.user?.email, equals('staff@bookit.dev'));

      authNotifier.loginAsDemoClient();
      expect(authNotifier.state.user?.email, equals('client@bookit.dev'));

      authNotifier.loginAsDemoAdmin();
      expect(authNotifier.state.user?.email, equals('admin@bookit.dev'));
    });
  });

  group('Booking Lifecycle & Review Submission Tests', () {
    test('BookingNotifier reschedule updates start and end time', () async {
      final notifier = BookingNotifier();
      final original = notifier.state.first;

      final newStart = DateTime.now().add(const Duration(days: 5, hours: 4));
      final newEnd = newStart.add(const Duration(minutes: 45));

      await notifier.rescheduleBooking(
        bookingId: original.id,
        newStartTime: newStart,
        newEndTime: newEnd,
      );

      final updated = notifier.state.firstWhere((b) => b.id == original.id);
      expect(updated.startTime, equals(newStart));
      expect(updated.endTime, equals(newEnd));
      expect(updated.status, equals('confirmed'));
    });

    test('BookingNotifier cancel marks booking as cancelled and refund status if deposit paid', () async {
      final notifier = BookingNotifier();
      final paidBooking = notifier.state.firstWhere((b) => b.amountPaid > 0);

      await notifier.cancelBooking(paidBooking.id, 'Patient schedule emergency');

      final cancelled = notifier.state.firstWhere((b) => b.id == paidBooking.id);
      expect(cancelled.status, equals('cancelled'));
      expect(cancelled.cancellationReason, equals('Patient schedule emergency'));
      expect(cancelled.paymentStatus, equals('refunded'));
    });

    test('BusinessService createReview submits review and dynamically recalculates business rating', () async {
      final service = BusinessService();
      final bizId = '11111111-1111-1111-1111-111111111111';
      final bizBefore = await service.getBusinessById(bizId);
      final initialCount = bizBefore!.ratingCount;

      final newReview = Review(
        id: 'rev-test-1',
        businessId: bizId,
        clientId: 'client-1',
        bookingId: 'bk-test-1',
        rating: 5,
        comment: 'Superb quality and friendly hygienist!',
        clientName: 'Alice Walker',
        createdAt: DateTime.now(),
      );

      final success = await service.createReview(newReview);
      expect(success, isTrue);

      final bizAfter = await service.getBusinessById(bizId);
      expect(bizAfter!.ratingCount, equals(initialCount + 1));

      final reviews = await service.getReviews(bizId);
      expect(reviews.any((r) => r.id == 'rev-test-1'), isTrue);
    });
  });

  group('Widget Tests: SafeNetworkImage & Client Bookings UI', () {
    testWidgets('SafeNetworkImage renders fallback icon gracefully when URL is null or empty', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SafeNetworkImage(
              imageUrl: null,
              width: 100,
              height: 100,
              fallbackIcon: Icons.local_hospital_rounded,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.local_hospital_rounded), findsOneWidget);
    });

    testWidgets('ClientBookingsScreen renders Reschedule and Leave a Review buttons', (tester) async {
      SupabaseService.resetToDefaultData();

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: ClientBookingsScreen(),
          ),
        ),
      );
      await tester.pump();
      await tester.pumpAndSettle();

      // Check upcoming tab has Reschedule button
      expect(find.text('Reschedule'), findsAtLeastNWidgets(1));

      // Switch to Past tab
      await tester.tap(find.textContaining('Past & Cancelled'));
      await tester.pumpAndSettle();

      // Check past tab has Leave a Review button for completed bookings
      expect(find.text('Leave a Review'), findsAtLeastNWidgets(1));
    });
  });
}
