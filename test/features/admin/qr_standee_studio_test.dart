// Gene - Nov, 05, 2026: Widget tests for Storefront QR Standee Studio in Business Settings
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bookit/models/business.dart';
import 'package:bookit/features/admin/presentation/widgets/qr_standee_studio_card.dart';
import 'package:bookit/features/admin/presentation/business_settings_tab.dart';

void main() {
  const business = Business(
    id: 'biz-101',
    ownerId: 'owner-101',
    name: 'Downtown Dental Studio',
    slug: 'downtown-dental-studio',
    category: 'medical_dental',
    bookingModel: BookingModelType.slotBased,
  );

  testWidgets('QrStandeeStudioCard renders live preview, headline selector, and copy link button', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: QrStandeeStudioCard(business: business),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Storefront QR & Marketing Standee'), findsOneWidget);
    expect(find.text('Downtown Dental Studio'), findsWidgets);
    expect(find.text('Scan to Book in 30 Seconds'), findsWidgets);
    expect(find.text('Copy Link'), findsOneWidget);
  });

  testWidgets('Switching headline presets updates preview text', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: QrStandeeStudioCard(business: business),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Tap on second preset: "Walk-Ins Welcome — Check Today's Openings"
    final secondPresetFinder = find.text("Walk-Ins Welcome — Check Today's Openings");
    expect(secondPresetFinder, findsOneWidget);
    await tester.ensureVisible(secondPresetFinder);
    await tester.tap(secondPresetFinder);
    await tester.pumpAndSettle();

    // Now it should appear both in the selector chip and in the standee card preview
    expect(find.text("Walk-Ins Welcome — Check Today's Openings"), findsWidgets);
  });

  testWidgets('Format selector toggles between Desk Standee and Storefront Poster', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: QrStandeeStudioCard(business: business),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Acrylic Desk Standee (A5)'), findsOneWidget);
    expect(find.text('Storefront Door Poster (A4)'), findsOneWidget);

    final posterOption = find.text('Storefront Door Poster (A4)');
    await tester.ensureVisible(posterOption);
    await tester.tap(posterOption);
    await tester.pumpAndSettle();

    final printPosterBtn = find.text('Print Poster');
    await tester.ensureVisible(printPosterBtn);
    expect(printPosterBtn, findsOneWidget);
  });

  testWidgets('Copy Link copies booking URL to clipboard and shows SnackBar', (tester) async {
    String? clipboardText;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (MethodCall methodCall) async {
        if (methodCall.method == 'Clipboard.setData') {
          clipboardText = (methodCall.arguments as Map)['text'] as String?;
        }
        return null;
      },
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: QrStandeeStudioCard(business: business),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    final copyBtn = find.text('Copy Link');
    await tester.ensureVisible(copyBtn);
    await tester.tap(copyBtn);
    await tester.pumpAndSettle();

    expect(clipboardText, 'https://bookit.app/book/biz-101?ref=storefront_qr');
    expect(find.text('Booking link copied to clipboard!'), findsOneWidget);
  });

  testWidgets('Print Standee opens print preview dialog with full mockup and print action', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: QrStandeeStudioCard(business: business),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    final printBtn = find.text('Print Standee');
    await tester.ensureVisible(printBtn);
    expect(printBtn, findsOneWidget);
    await tester.tap(printBtn);
    await tester.pumpAndSettle();

    expect(find.text('Print Preview'), findsOneWidget);
    expect(find.text('Send to Printer'), findsOneWidget);
  });

  testWidgets('BusinessSettingsTab embeds QrStandeeStudioCard', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: BusinessSettingsTab(business: business),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.byType(QrStandeeStudioCard), findsOneWidget);
    expect(find.text('Storefront QR & Marketing Standee'), findsOneWidget);
  });
}
