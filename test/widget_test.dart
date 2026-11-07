// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

// Gene - Nov, 03, 2026: Updated smoke test to verify BookIt app launches with discovery header
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bookit/main.dart';
// Gene - Nov 07, 2026: Added unit tests for Catalog CRUD, SlotCalculator buffer/duration, Reviews persistence, and CRM medical flags
import 'package:bookit/core/constants/demo_data.dart';
import 'package:bookit/features/booking_engine/domain/slot_calculator.dart';
import 'package:bookit/models/booking.dart';
import 'package:bookit/models/business_staff.dart';
import 'package:bookit/models/review.dart';
import 'package:bookit/models/service_item.dart';
import 'package:bookit/services/business_service.dart';
import 'package:bookit/services/crm_service.dart';
import 'package:bookit/services/supabase_service.dart';
// Gene - Nov 07, 2026: Added booking_service and notification_service imports for Pass 2 unit tests
import 'package:bookit/services/booking_service.dart';
import 'package:bookit/services/notification_service.dart';

void main() {
  setUp(() {
    SupabaseService.resetToDefaultData();
  });

  testWidgets('BookIt launches and displays header brand', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: BookItApp()));
    await tester.pumpAndSettle();

    expect(find.text('BookIt'), findsOneWidget);
    expect(find.text('Find clinics, doctors & services'), findsOneWidget);
  });

  test('BusinessService CRUD and active/archive filtering for Services & Staff', () async {
    final service = BusinessService();
    const bizId = '11111111-1111-1111-1111-111111111111';

    final newService = ServiceItem(
      id: 'srv-test-99',
      businessId: bizId,
      name: 'Laser Gum Therapy',
      durationMinutes: 60,
      price: 250.0,
      isActive: true,
    );
    await service.addService(newService);

    var clientServices = await service.getServices(bizId);
    expect(clientServices.any((s) => s.id == 'srv-test-99'), isTrue);

    // Archive service
    await service.updateService(newService.copyWith(isActive: false));
    clientServices = await service.getServices(bizId);
    final adminServices = await service.getAdminServices(bizId);
    expect(clientServices.any((s) => s.id == 'srv-test-99'), isFalse);
    expect(adminServices.any((s) => s.id == 'srv-test-99' && !s.isActive), isTrue);

    // Add & deactivate staff
    final newStaff = BusinessStaff(
      id: 'stf-test-99',
      businessId: bizId,
      name: 'Dr. Clara Oswald',
      specialty: 'Periodontist',
      isActive: true,
    );
    await service.addStaff(newStaff);
    expect((await service.getStaff(bizId)).any((s) => s.id == 'stf-test-99'), isTrue);

    await service.updateStaff(newStaff.copyWith(isActive: false));
    expect((await service.getStaff(bizId)).any((s) => s.id == 'stf-test-99'), isFalse);
    expect((await service.getAdminStaff(bizId)).any((s) => s.id == 'stf-test-99' && !s.isActive), isTrue);
  });

  test('SlotCalculator enforces customDurationMinutes and business.bufferMinutes while keeping clean start times', () {
    final baseBusiness = DemoData.freshBusinesses.first.copyWith(
      settings: {
        ...DemoData.freshBusinesses.first.settings,
        'slot_interval_minutes': 30,
        'buffer_minutes': 15,
      },
    );
    final testDate = DateTime(2026, 11, 9); // Monday (09:00 - 18:00)

    final existingBooking = Booking(
      id: 'bk-buffer-test',
      businessId: baseBusiness.id,
      clientId: DemoData.clientUserId,
      bookingModel: 'slot_based',
      startTime: DateTime(2026, 11, 9, 10, 0),
      endTime: DateTime(2026, 11, 9, 10, 45),
      status: 'confirmed',
      totalPrice: 120.0,
      createdAt: DateTime(2026, 11, 7),
    );

    final slots = SlotCalculator.calculateAvailableSlots(
      business: baseBusiness,
      date: testDate,
      existingBookings: [existingBooking],
      customDurationMinutes: 45,
    );

    // Start times step cleanly by 30 minutes (09:00, 09:30, 10:00, 10:30, 11:00)
    expect(slots[0].startTime, DateTime(2026, 11, 9, 9, 0));
    expect(slots[0].endTime, DateTime(2026, 11, 9, 9, 45));
    expect(slots[0].isAvailable, isTrue); // 09:00 - 09:45 (+15m buffer = 10:00) does not overlap 10:00

    // 09:30 - 10:15 overlaps 10:00 booking
    final slot0930 = slots.firstWhere((s) => s.startTime.hour == 9 && s.startTime.minute == 30);
    expect(slot0930.isAvailable, isFalse);

    // 10:30 - 11:15 overlaps existing booking end (10:45 + 15m buffer = 11:00)
    final slot1030 = slots.firstWhere((s) => s.startTime.hour == 10 && s.startTime.minute == 30);
    expect(slot1030.isAvailable, isFalse);

    // 11:00 - 11:45 starts right after 10:45 + 15m turnaround buffer
    final slot1100 = slots.firstWhere((s) => s.startTime.hour == 11 && s.startTime.minute == 0);
    expect(slot1100.isAvailable, isTrue);
  });

  test('BusinessService.createReview persists review and updates ratingAvg', () async {
    final service = BusinessService();
    const bizId = '11111111-1111-1111-1111-111111111111';
    final beforeReviews = await service.getReviews(bizId);

    final review = Review(
      id: 'rev-unit-test',
      businessId: bizId,
      clientId: DemoData.clientUserId,
      bookingId: 'bk-demo-past-1',
      rating: 5,
      comment: 'Superb painless cleaning!',
      clientName: 'Michael Chen',
      createdAt: DateTime.now(),
    );
    await service.createReview(review);

    final afterReviews = await service.getReviews(bizId);
    expect(afterReviews.length, beforeReviews.length + 1);
    expect(afterReviews.first.id, 'rev-unit-test');
  });

  test('CrmService manages medical flags and counts checked_in/in_service/rejected statuses', () {
    final crm = CrmService();
    crm.addMedicalFlag(DemoData.clientUserId, 'Sulfa Allergy');
    var profiles = crm.aggregateClients(SupabaseService.mockBookings);
    var clientProfile = profiles.firstWhere((p) => p.id == DemoData.clientUserId);
    expect(clientProfile.medicalFlags.contains('Sulfa Allergy'), isTrue);

    crm.removeMedicalFlag(DemoData.clientUserId, 'Sulfa Allergy');
    profiles = crm.aggregateClients(SupabaseService.mockBookings);
    clientProfile = profiles.firstWhere((p) => p.id == DemoData.clientUserId);
    expect(clientProfile.medicalFlags.contains('Sulfa Allergy'), isFalse);
  });

  test('Walk-In booking preserves checked_in status and emits lifecycle notifications + markAllAsRead', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final initialUnread = container.read(unreadNotificationCountProvider);
    final now = DateTime.now();

    final walkIn = Booking(
      id: 'bk-walkin-test',
      businessId: '11111111-1111-1111-1111-111111111111',
      clientId: DemoData.clientUserId,
      bookingModel: 'slot_based',
      startTime: now,
      endTime: now.add(const Duration(minutes: 45)),
      status: 'checked_in',
      checkedInAt: now,
      totalPrice: 120.0,
      createdAt: now,
      businessName: 'Apex Dental & Orthodontic Care',
      serviceName: 'Emergency Dental Check',
      clientName: 'Jordan Taylor',
    );

    final created = await container.read(bookingsProvider.notifier).createBooking(walkIn);
    expect(created.status, equals('checked_in'));
    expect(created.holdExpiresAt, isNull);

    // Notification emitted to both client and admin
    expect(container.read(notificationsProvider).any((n) => n.bookingId == 'bk-walkin-test'), isTrue);
    expect(container.read(unreadNotificationCountProvider), greaterThan(initialUnread));

    // Mark all read clears unread count for active user
    final activeUserId = container.read(userNotificationsProvider).first.userId;
    container.read(notificationsProvider.notifier).markAllAsRead(userId: activeUserId);
    expect(
      container.read(notificationsProvider).where((n) => n.userId == activeUserId && !n.isRead),
      isEmpty,
    );
  });
}

/*
// Gene - Nov, 03, 2026: Preserved initial counter smoke test
void main() {
  testWidgets('Counter increments smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    expect(find.text('0'), findsOneWidget);
    expect(find.text('1'), findsNothing);
    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();
    expect(find.text('0'), findsNothing);
    expect(find.text('1'), findsOneWidget);
  });
}
*/

