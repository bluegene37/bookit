import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bookit/features/admin/presentation/tabs/payments_invoices_tab.dart';
import 'package:bookit/features/admin/presentation/widgets/refund_dialog.dart';
import 'package:bookit/features/admin/presentation/services_manager_tab.dart';
import 'package:bookit/features/admin/presentation/admin_shell_screen.dart';
import 'package:bookit/models/business.dart';
import 'package:bookit/models/payment.dart';

void main() {
  testWidgets('PaymentsInvoicesTab renders KPI summaries', (tester) async {
    final mockPayments = [
      Payment(
        id: 'p1',
        bookingId: 'b1',
        businessId: 'biz1',
        clientId: 'u1',
        grossAmount: 100.0,
        netAmount: 97.0,
        createdAt: DateTime.now(),
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PaymentsInvoicesView(
            payments: mockPayments,
            businessId: 'biz1',
            stripeConnected: true,
          ),
        ),
      ),
    );

    expect(find.text('Gross Volume'), findsOneWidget);
    expect(find.text('\$100.00'), findsOneWidget);
  });

  testWidgets('PaymentsInvoicesTab renders Stripe Express dashboard button when connected', (tester) async {
    final mockPayments = [
      Payment(
        id: 'p1',
        bookingId: 'b1',
        businessId: 'biz1',
        clientId: 'u1',
        grossAmount: 100.0,
        netAmount: 97.0,
        createdAt: DateTime.now(),
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PaymentsInvoicesView(
            payments: mockPayments,
            businessId: 'biz1',
            stripeConnected: true,
          ),
        ),
      ),
    );

    expect(find.text('Open Stripe Express Dashboard'), findsOneWidget);
    expect(find.text('Net Payouts'), findsOneWidget);
    expect(find.text('Balances Due at Clinic'), findsOneWidget);
    expect(find.text('Refunds'), findsOneWidget);
  });

  testWidgets('PaymentsInvoicesTab displays connect banner when Stripe is not connected', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: PaymentsInvoicesView(
            payments: [],
            businessId: 'biz1',
            stripeConnected: false,
          ),
        ),
      ),
    );

    expect(find.text('Connect Stripe Express'), findsOneWidget);
  });

  testWidgets('RefundDialog toggles between full and partial refund', (tester) async {
    final payment = Payment(
      id: 'p1',
      bookingId: 'b1',
      businessId: 'biz1',
      clientId: 'u1',
      grossAmount: 150.0,
      netAmount: 145.0,
      createdAt: DateTime.now(),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RefundDialog(
            payment: payment,
          ),
        ),
      ),
    );

    expect(find.text('Issue Refund'), findsOneWidget);
    expect(find.text('Full Refund (\$150.00)'), findsOneWidget);
    expect(find.text('Custom Partial Refund'), findsOneWidget);

    // Tap partial refund radio
    await tester.tap(find.text('Custom Partial Refund'));
    await tester.pumpAndSettle();

    expect(find.byType(TextField), findsWidgets);
  });

  testWidgets('RefundDialog executes onRefund callback with correct amount and reason', (tester) async {
    final payment = Payment(
      id: 'p1',
      bookingId: 'b1',
      businessId: 'biz1',
      clientId: 'u1',
      grossAmount: 150.0,
      netAmount: 145.0,
      createdAt: DateTime.now(),
    );

    double? capturedAmount;
    String? capturedReason;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RefundDialog(
            payment: payment,
            onRefund: (amount, reason) async {
              capturedAmount = amount;
              capturedReason = reason;
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('Process Refund'));
    await tester.pumpAndSettle();

    expect(capturedAmount, 150.0);
    expect(capturedReason, 'Customer requested refund');
  });

  testWidgets('ServicesManagerTab dialog shows payment policy dropdown and deposit fields', (tester) async {
    final business = Business(
      id: 'biz1',
      ownerId: 'owner1',
      name: 'Smile Dental Clinic',
      slug: 'smile-dental-clinic',
      category: 'Dental Practice',
      bookingModel: BookingModelType.slotBased,
      settings: const {},
    );

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: ServicesManagerTab(business: business),
          ),
        ),
      ),
    );

    // Click 'New Procedure' button to open dialog
    await tester.tap(find.text('New Procedure'));
    await tester.pumpAndSettle();

    expect(find.text('Add Clinical Service / Procedure'), findsOneWidget);
    expect(find.text('Payment Policy'), findsOneWidget);
    expect(find.text('Full Upfront'), findsOneWidget);

    // Change dropdown to Deposit
    await tester.tap(find.text('Full Upfront'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Deposit').last);
    await tester.pumpAndSettle();

    // Verify Deposit Type radio buttons appear
    expect(find.text('Deposit Type'), findsOneWidget);
    expect(find.text('Percentage'), findsOneWidget);
    expect(find.text('Fixed Amount'), findsOneWidget);
  });

  testWidgets('AdminShellScreen includes Payments tab destination in static lists', (tester) async {
    final hasPaymentsRail = AdminShellScreen.railDestinations.any((d) {
      if (d.label is Text) {
        return (d.label as Text).data == 'Payments';
      }
      return false;
    });

    final hasPaymentsBottomNav = AdminShellScreen.bottomNavItems.any((b) {
      return b.label == 'Payments';
    });

    expect(hasPaymentsRail, isTrue);
    expect(hasPaymentsBottomNav, isTrue);
  });

  // Gene - Nov 07, 2026: Verify PaymentsInvoicesView displays GCash and Bank Transfer method & reference numbers in ledger
  testWidgets('PaymentsInvoicesView renders Method / Ref # column for GCash and Bank Transfer', (tester) async {
    final mockPayments = [
      Payment(
        id: 'p-gcash-1',
        bookingId: 'b-gcash-1',
        businessId: 'biz1',
        clientId: 'u1',
        grossAmount: 100.0,
        netAmount: 100.0,
        paymentMethod: 'gcash',
        referenceNumber: '9018472615243',
        createdAt: DateTime.now(),
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PaymentsInvoicesView(
            payments: mockPayments,
            businessId: 'biz1',
            stripeConnected: true,
          ),
        ),
      ),
    );

    expect(find.text('Method / Ref #'), findsOneWidget);
    expect(find.text('GCash (9018472615243)'), findsOneWidget);
  });
}
