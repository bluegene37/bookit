// Gene - Nov, 05, 2026: Universal Calendar Sync Service generating RFC 5545 .ics files and Google/Outlook web deep links
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/booking.dart';
import '../models/business.dart';
import '../models/service_item.dart';
import '../models/business_staff.dart';

class CalendarSyncService {
  CalendarSyncService._();

  /// Formats DateTime into RFC 5545 UTC compact format: YYYYMMDDTHHmmssZ
  static String formatIsoUtcCompact(DateTime dt) {
    final utc = dt.toUtc();
    final y = utc.year.toString().padLeft(4, '0');
    final m = utc.month.toString().padLeft(2, '0');
    final d = utc.day.toString().padLeft(2, '0');
    final h = utc.hour.toString().padLeft(2, '0');
    final min = utc.minute.toString().padLeft(2, '0');
    final s = utc.second.toString().padLeft(2, '0');
    return '$y$m${d}T$h$min${s}Z';
  }

  /// Formats Date into RFC 5545 DATE-only format: YYYYMMDD
  static String formatDateCompact(DateTime dt) {
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    return '$y$m$d';
  }

  /// Generates a standard RFC 5545 iCalendar (.ics) string with alarm reminders
  static String generateIcsContent({
    required Booking booking,
    Business? business,
    ServiceItem? service,
    BusinessStaff? staff,
  }) {
    final businessName = business?.name ?? booking.businessName ?? 'Clinic / Practice';
    final serviceName = service?.name ?? booking.serviceName ?? 'Appointment';
    final staffName = staff?.name ?? booking.staffName ?? 'Specialist';
    final address = business?.address != null
        ? '${business!.address}, ${business.city}'
        : 'Confirmed Location';

    final nowUtc = formatIsoUtcCompact(DateTime.now());
    final isSlotBased = (booking.isSlotBased || booking.bookingModel == 'slot_based') &&
        booking.startTime != null &&
        booking.endTime != null;

    final startStr = isSlotBased
        ? 'DTSTART:${formatIsoUtcCompact(booking.startTime!)}'
        : (booking.dateFrom != null
            ? 'DTSTART;VALUE=DATE:${formatDateCompact(booking.dateFrom!)}'
            : 'DTSTART:$nowUtc');

    final endStr = isSlotBased
        ? 'DTEND:${formatIsoUtcCompact(booking.endTime!)}'
        : (booking.dateTo != null
            ? 'DTEND;VALUE=DATE:${formatDateCompact(booking.dateTo!)}'
            : 'DTEND:$nowUtc');

    final description = 'Reservation with $staffName at $businessName.\\n'
        'Booking Ref: #${booking.formattedId}\\n'
        'Client Notes: ${booking.clientNotes ?? "None"}\\n'
        '1-Tap Reschedule: https://bookit.app/my-bookings?reschedule=${booking.id}';

    return [
      'BEGIN:VCALENDAR',
      'VERSION:2.0',
      'PRODID:-//BookIt//Universal Booking Platform//EN',
      'CALSCALE:GREGORIAN',
      'METHOD:PUBLISH',
      'BEGIN:VEVENT',
      'UID:${booking.id}@bookit.app',
      'DTSTAMP:$nowUtc',
      startStr,
      endStr,
      'SUMMARY:$serviceName at $businessName',
      'DESCRIPTION:$description',
      'LOCATION:$address',
      'STATUS:CONFIRMED',
      'BEGIN:VALARM',
      'TRIGGER:-PT2H',
      'ACTION:DISPLAY',
      'DESCRIPTION:Reminder: Appointment in 2 hours',
      'END:VALARM',
      'END:VEVENT',
      'END:VCALENDAR',
    ].join('\r\n');
  }

  /// Generates 1-tap Google Calendar web composition URL
  static Uri generateGoogleCalendarUrl({
    required Booking booking,
    Business? business,
    ServiceItem? service,
    BusinessStaff? staff,
  }) {
    final businessName = business?.name ?? booking.businessName ?? 'Clinic / Practice';
    final serviceName = service?.name ?? booking.serviceName ?? 'Appointment';
    final staffName = staff?.name ?? booking.staffName ?? 'Specialist';
    final address = business?.address != null
        ? '${business!.address}, ${business.city}'
        : 'Confirmed Practice Address';

    final isSlotBased = (booking.isSlotBased || booking.bookingModel == 'slot_based') &&
        booking.startTime != null &&
        booking.endTime != null;

    final dateRange = isSlotBased
        ? '${formatIsoUtcCompact(booking.startTime!)}/${formatIsoUtcCompact(booking.endTime!)}'
        : (booking.dateFrom != null && booking.dateTo != null
            ? '${formatDateCompact(booking.dateFrom!)}/${formatDateCompact(booking.dateTo!)}'
            : '${formatIsoUtcCompact(DateTime.now())}/${formatIsoUtcCompact(DateTime.now().add(const Duration(hours: 1)))}');

    final details = 'Appointment with $staffName at $businessName.\n'
        'Booking Reference: #${booking.formattedId}\n'
        'Reschedule Link: https://bookit.app/my-bookings?reschedule=${booking.id}';

    return Uri.https('calendar.google.com', '/calendar/render', {
      'action': 'TEMPLATE',
      'text': '$serviceName at $businessName',
      'dates': dateRange,
      'details': details,
      'location': address,
    });
  }

  /// Generates 1-tap Outlook web calendar composition URL
  static Uri generateOutlookCalendarUrl({
    required Booking booking,
    Business? business,
    ServiceItem? service,
    BusinessStaff? staff,
  }) {
    final businessName = business?.name ?? booking.businessName ?? 'Clinic / Practice';
    final serviceName = service?.name ?? booking.serviceName ?? 'Appointment';
    final staffName = staff?.name ?? booking.staffName ?? 'Specialist';
    final address = business?.address != null
        ? '${business!.address}, ${business.city}'
        : 'Confirmed Practice Address';

    final startIso = (booking.startTime ?? booking.dateFrom ?? DateTime.now()).toIso8601String();
    final endIso = (booking.endTime ?? booking.dateTo ?? DateTime.now().add(const Duration(hours: 1))).toIso8601String();

    final body = 'Appointment with $staffName at $businessName.\n'
        'Booking Reference: #${booking.formattedId}\n'
        'Reschedule Link: https://bookit.app/my-bookings?reschedule=${booking.id}';

    return Uri.https('outlook.live.com', '/calendar/0/deeplink/compose', {
      'subject': '$serviceName at $businessName',
      'startdt': startIso,
      'enddt': endIso,
      'body': body,
      'location': address,
    });
  }

  /// Launches Google Calendar web composer directly
  static Future<bool> openGoogleCalendar({
    required Booking booking,
    Business? business,
    ServiceItem? service,
    BusinessStaff? staff,
  }) async {
    final uri = generateGoogleCalendarUrl(
      booking: booking,
      business: business,
      service: service,
      staff: staff,
    );
    return await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  /// Launches Outlook Web calendar composer directly
  static Future<bool> openOutlookCalendar({
    required Booking booking,
    Business? business,
    ServiceItem? service,
    BusinessStaff? staff,
  }) async {
    final uri = generateOutlookCalendarUrl(
      booking: booking,
      business: business,
      service: service,
      staff: staff,
    );
    return await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  /// Triggers RFC 5545 .ics download via browser data URI link
  static Future<bool> downloadIcsFile({
    required Booking booking,
    Business? business,
    ServiceItem? service,
    BusinessStaff? staff,
  }) async {
    final icsContent = generateIcsContent(
      booking: booking,
      business: business,
      service: service,
      staff: staff,
    );

    final dataUri = Uri.dataFromString(
      icsContent,
      mimeType: 'text/calendar',
      encoding: Uri.encodeFull(icsContent).contains('%') ? null : null,
    );

    try {
      return await launchUrl(dataUri, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('Error downloading .ics calendar file: $e');
      return false;
    }
  }
}
