// Gene - Nov, 05, 2026: Comprehensive test suite for Universal CalendarSyncService and Dual-Stage Reminders
import 'package:flutter_test/flutter_test.dart';
import 'package:bookit/services/calendar_sync_service.dart';
import 'package:bookit/models/booking.dart';
import 'package:bookit/models/business.dart';
import 'package:bookit/models/service_item.dart';
import 'package:bookit/models/business_staff.dart';

void main() {
  group('CalendarSyncService Date & Time Formatter Tests', () {
    test('formatIsoUtcCompact formats UTC datetime into RFC 5545 standard YYYYMMDDTHHmmssZ', () {
      final dt = DateTime.utc(2026, 11, 10, 14, 30, 0);
      final formatted = CalendarSyncService.formatIsoUtcCompact(dt);
      expect(formatted, equals('20261110T143000Z'));
    });

    test('formatDateCompact formats datetime into RFC 5545 date-only YYYYMMDD', () {
      final dt = DateTime(2026, 12, 25);
      final formatted = CalendarSyncService.formatDateCompact(dt);
      expect(formatted, equals('20261225'));
    });
  });

  group('CalendarSyncService .ICS File Generation Tests', () {
    late Booking testBooking;
    late Business testBusiness;
    late ServiceItem testService;
    late BusinessStaff testStaff;

    setUp(() {
      testBooking = Booking(
        id: '12345678-abcd-ef01-2345-6789abcdef01',
        businessId: 'biz-1',
        clientId: 'client-1',
        bookingModel: 'slot_based',
        startTime: DateTime.utc(2026, 11, 15, 10, 0, 0),
        endTime: DateTime.utc(2026, 11, 15, 10, 45, 0),
        status: 'confirmed',
        totalPrice: 120.0,
        businessName: 'Apex Dental Care',
        serviceName: 'Comprehensive Exam',
        staffName: 'Dr. Alexander Vance',
        clientNotes: 'Sensitive lower right molar',
        createdAt: DateTime.utc(2026, 11, 1, 9, 0, 0),
      );

      testBusiness = Business(
        id: 'biz-1',
        ownerId: 'owner-1',
        name: 'Apex Dental Care',
        slug: 'apex-dental',
        category: 'Dental',
        bookingModel: BookingModelType.slotBased,
        description: 'Quality oral healthcare',
        address: '742 Evergreen Suites',
        city: 'San Francisco',
        contactPhone: '+1 (555) 456-7890',
        contactEmail: 'contact@apexdental.com',
        ratingAvg: 4.9,
        ratingCount: 50,
      );

      testService = const ServiceItem(
        id: 'srv-1',
        businessId: 'biz-1',
        name: 'Comprehensive Exam',
        durationMinutes: 45,
        price: 120.0,
      );

      testStaff = const BusinessStaff(
        id: 'staff-1',
        businessId: 'biz-1',
        name: 'Dr. Alexander Vance',
        specialty: 'Lead Orthodontist',
      );
    });

    test('generateIcsContent produces RFC 5545 compliant structure with VALARM 2-hour reminder', () {
      final ics = CalendarSyncService.generateIcsContent(
        booking: testBooking,
        business: testBusiness,
        service: testService,
        staff: testStaff,
      );

      expect(ics, contains('BEGIN:VCALENDAR'));
      expect(ics, contains('VERSION:2.0'));
      expect(ics, contains('PRODID:-//BookIt//Universal Booking Platform//EN'));
      expect(ics, contains('BEGIN:VEVENT'));
      expect(ics, contains('UID:12345678-abcd-ef01-2345-6789abcdef01@bookit.app'));
      expect(ics, contains('DTSTART:20261115T100000Z'));
      expect(ics, contains('DTEND:20261115T104500Z'));
      expect(ics, contains('SUMMARY:Comprehensive Exam at Apex Dental Care'));
      expect(ics, contains('LOCATION:742 Evergreen Suites, San Francisco'));
      expect(ics, contains('STATUS:CONFIRMED'));
      expect(ics, contains('BEGIN:VALARM'));
      expect(ics, contains('TRIGGER:-PT2H'));
      expect(ics, contains('ACTION:DISPLAY'));
      expect(ics, contains('END:VALARM'));
      expect(ics, contains('END:VEVENT'));
      expect(ics, contains('END:VCALENDAR'));
    });

    test('generateGoogleCalendarUrl creates valid Google Calendar web creation URL with encoded parameters', () {
      final url = CalendarSyncService.generateGoogleCalendarUrl(
        booking: testBooking,
        business: testBusiness,
        service: testService,
        staff: testStaff,
      );

      expect(url.scheme, equals('https'));
      expect(url.host, equals('calendar.google.com'));
      expect(url.path, equals('/calendar/render'));
      expect(url.queryParameters['action'], equals('TEMPLATE'));
      expect(url.queryParameters['text'], equals('Comprehensive Exam at Apex Dental Care'));
      expect(url.queryParameters['dates'], equals('20261115T100000Z/20261115T104500Z'));
      expect(url.queryParameters['location'], equals('742 Evergreen Suites, San Francisco'));
      expect(url.queryParameters['details'], contains('Dr. Alexander Vance'));
      expect(url.queryParameters['details'], contains('https://bookit.app/my-bookings?reschedule='));
    });

    test('generateOutlookCalendarUrl creates valid Outlook Web calendar URL with ISO datetime range', () {
      final url = CalendarSyncService.generateOutlookCalendarUrl(
        booking: testBooking,
        business: testBusiness,
        service: testService,
        staff: testStaff,
      );

      expect(url.scheme, equals('https'));
      expect(url.host, equals('outlook.live.com'));
      expect(url.path, equals('/calendar/0/deeplink/compose'));
      expect(url.queryParameters['subject'], equals('Comprehensive Exam at Apex Dental Care'));
      expect(url.queryParameters['location'], equals('742 Evergreen Suites, San Francisco'));
      expect(url.queryParameters['startdt'], contains('2026-11-15T10:00:00'));
      expect(url.queryParameters['enddt'], contains('2026-11-15T10:45:00'));
    });
  });

  group('Booking Model Dual-Stage Reminder Timestamp Serialization Tests', () {
    test('Booking model serializes and deserializes reminder24hSent and reminder2hSent correctly', () {
      final sent24h = DateTime.utc(2026, 11, 4, 10, 0, 0);
      final sent2h = DateTime.utc(2026, 11, 5, 8, 0, 0);

      final booking = Booking(
        id: 'bk-rem-1',
        businessId: 'biz-1',
        clientId: 'client-1',
        bookingModel: 'slot_based',
        totalPrice: 150.0,
        createdAt: DateTime.now(),
        reminder24hSent: sent24h,
        reminder2hSent: sent2h,
      );

      final json = booking.toJson();
      expect(json['reminder_24h_sent'], equals(sent24h.toIso8601String()));
      expect(json['reminder_2h_sent'], equals(sent2h.toIso8601String()));

      final reconstructed = Booking.fromJson(json);
      expect(reconstructed.reminder24hSent, equals(sent24h));
      expect(reconstructed.reminder2hSent, equals(sent2h));
    });

    test('Booking copyWith correctly preserves or updates reminder timestamps', () {
      final initial = Booking(
        id: 'bk-rem-2',
        businessId: 'biz-1',
        clientId: 'client-1',
        bookingModel: 'slot_based',
        totalPrice: 150.0,
        createdAt: DateTime.now(),
      );

      expect(initial.reminder24hSent, isNull);
      expect(initial.reminder2hSent, isNull);

      final now = DateTime.now();
      final updated = initial.copyWith(reminder24hSent: now);
      expect(updated.reminder24hSent, equals(now));
      expect(updated.reminder2hSent, isNull);
    });
  });
}
