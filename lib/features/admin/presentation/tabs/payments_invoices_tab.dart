// Gene - Nov, 04, 2026: Admin Payments & Invoices Tab with KPI summary cards, Stripe Express banner, and Neumorphic transaction ledger
// Gene - Nov, 08, 2026: Imported foundation.dart for kIsWeb origin-aware Stripe Connect return URLs
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/neumorphic_colors.dart';
import '../../../../core/widgets/neumorphic_container.dart';
import '../../../../core/widgets/neumorphic_button.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../../models/business.dart';
import '../../../../models/payment.dart';
import '../../../../services/payment_service.dart';
import '../widgets/kpi_metric_card.dart';
import '../widgets/refund_dialog.dart';

class PaymentsInvoicesTab extends ConsumerWidget {
  final Business business;

  const PaymentsInvoicesTab({super.key, required this.business});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final paymentsAsync = ref.watch(businessPaymentsProvider(business.id));
    final stripeConnected = (business.stripeAccountId != null && business.stripeAccountId!.isNotEmpty) ||
        business.stripeChargesEnabled;

    return paymentsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error loading payments: $e')),
      data: (payments) {
        return PaymentsInvoicesView(
          payments: payments,
          businessId: business.id,
          stripeConnected: stripeConnected,
        );
      },
    );
  }
}

class PaymentsInvoicesView extends StatefulWidget {
  final List<Payment> payments;
  final String businessId;
  final bool stripeConnected;
  final VoidCallback? onOpenStripeDashboard;
  final VoidCallback? onConnectStripe;

  const PaymentsInvoicesView({
    super.key,
    required this.payments,
    required this.businessId,
    this.stripeConnected = false,
    this.onOpenStripeDashboard,
    this.onConnectStripe,
  });

  @override
  State<PaymentsInvoicesView> createState() => _PaymentsInvoicesViewState();
}

class _PaymentsInvoicesViewState extends State<PaymentsInvoicesView> {
  // Financial calculation helpers
  double get _grossVolume {
    return widget.payments
        .where((p) => p.paymentStatus != 'refunded')
        .fold(0.0, (sum, p) => sum + p.grossAmount);
  }

  double get _netPayouts {
    return widget.payments
        .where((p) => p.paymentStatus != 'refunded')
        .fold(0.0, (sum, p) => sum + p.netAmount);
  }

  double get _balancesDue {
    // Balances due at clinic for partial/deposit bookings
    return widget.payments
        .where((p) => p.paymentStatus == 'deposit_paid')
        .fold(0.0, (sum, p) => sum + (p.grossAmount * 0.5));
  }

  double get _refundsTotal {
    return widget.payments
        .where((p) => p.paymentStatus == 'refunded' || p.paymentStatus == 'partially_refunded')
        .fold(0.0, (sum, p) => sum + p.grossAmount);
  }

  void _openRefundDialog(Payment payment) {
    showDialog(
      context: context,
      builder: (ctx) => RefundDialog(payment: payment),
    );
  }

  Future<void> _handleStripeDashboard() async {
    if (widget.onOpenStripeDashboard != null) {
      widget.onOpenStripeDashboard!();
      return;
    }

    try {
      final container = ProviderScope.containerOf(context, listen: false);
      /*
      await container.read(paymentServiceProvider).launchConnectOnboarding(
        businessId: widget.businessId,
        returnUrl: '/admin',
        action: 'dashboard',
      );
      */
      // Gene - Nov, 08, 2026: Pass full origin URL on Web so Edge Function URL validation succeeds without relative-URL errors
      final returnUrl = kIsWeb && Uri.base.origin.startsWith('http')
          ? '${Uri.base.origin}/admin'
          : 'https://bookit.app/admin';
      await container.read(paymentServiceProvider).launchConnectOnboarding(
        businessId: widget.businessId,
        returnUrl: returnUrl,
        action: 'dashboard',
      );
    } catch (_) {
      // Fallback in tests
    }
  }

  Future<void> _handleStripeConnect() async {
    if (widget.onConnectStripe != null) {
      widget.onConnectStripe!();
      return;
    }

    try {
      final container = ProviderScope.containerOf(context, listen: false);
      /*
      await container.read(paymentServiceProvider).launchConnectOnboarding(
        businessId: widget.businessId,
        returnUrl: '/admin',
        action: 'onboard',
      );
      */
      // Gene - Nov, 08, 2026: Pass full origin URL on Web so Edge Function URL validation succeeds without relative-URL errors
      final returnUrl = kIsWeb && Uri.base.origin.startsWith('http')
          ? '${Uri.base.origin}/admin'
          : 'https://bookit.app/admin';
      await container.read(paymentServiceProvider).launchConnectOnboarding(
        businessId: widget.businessId,
        returnUrl: returnUrl,
        action: 'onboard',
      );
    } catch (_) {
      // Fallback in tests
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? NeumorphicColors.tealLight : NeumorphicColors.tealPrimary;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Payments & Financial Invoices',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: isDark ? NeumorphicColors.darkTextPrimary : NeumorphicColors.lightTextPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Track deposits, client card transactions, and automated clinic payouts',
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? Colors.white60 : Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
              if (widget.stripeConnected) ...[
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: NeumorphicColors.success.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: NeumorphicColors.success.withValues(alpha: 0.3)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle_rounded, color: NeumorphicColors.success, size: 16),
                      SizedBox(width: 6),
                      Text(
                        'Stripe Express Active',
                        style: TextStyle(
                          color: NeumorphicColors.success,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 24),

          // 1. Top KPI Row: Gross Volume, Net Payouts, Balances Due at Clinic, Refunds
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 900;
              final cardWidth = isWide
                  ? (constraints.maxWidth - (3 * 16)) / 4
                  : (constraints.maxWidth - 16) / 2;

              return Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  SizedBox(
                    width: cardWidth,
                    height: 130,
                    child: KpiMetricCard(
                      label: 'Gross Volume',
                      value: '\$${_grossVolume.toStringAsFixed(2)}',
                      icon: Icons.monetization_on_rounded,
                      accentColor: accent,
                      subtitle: '${widget.payments.length} transactions processed',
                    ),
                  ),
                  SizedBox(
                    width: cardWidth,
                    height: 130,
                    child: KpiMetricCard(
                      label: 'Net Payouts',
                      value: '\$${_netPayouts.toStringAsFixed(2)}',
                      icon: Icons.account_balance_wallet_rounded,
                      accentColor: NeumorphicColors.success,
                      subtitle: 'Transferred via Stripe Express',
                    ),
                  ),
                  SizedBox(
                    width: cardWidth,
                    height: 130,
                    child: KpiMetricCard(
                      label: 'Balances Due at Clinic',
                      value: '\$${_balancesDue.toStringAsFixed(2)}',
                      icon: Icons.pending_actions_rounded,
                      accentColor: NeumorphicColors.warning,
                      subtitle: 'Payable at reception',
                    ),
                  ),
                  SizedBox(
                    width: cardWidth,
                    height: 130,
                    child: KpiMetricCard(
                      label: 'Refunds',
                      value: '\$${_refundsTotal.toStringAsFixed(2)}',
                      icon: Icons.replay_rounded,
                      accentColor: NeumorphicColors.error,
                      subtitle: 'Reversed transactions',
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 28),

          // 2. Stripe Express Banner
          _buildStripeBanner(isDark, accent),
          const SizedBox(height: 32),

          // 3. Neumorphic DataTable Transaction Ledger
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Transaction Ledger',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: isDark ? NeumorphicColors.darkTextPrimary : NeumorphicColors.lightTextPrimary,
                ),
              ),
              Text(
                'Showing ${widget.payments.length} records',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.white54 : Colors.black54,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          _buildLedgerTable(isDark, accent),
        ],
      ),
    );
  }

  Widget _buildStripeBanner(bool isDark, Color accent) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 680;

        if (widget.stripeConnected) {
          return NeumorphicContainer(
            borderRadius: 20.0,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
            child: isNarrow
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          NeumorphicContainer(
                            isCircle: true,
                            width: 44,
                            height: 44,
                            child: const Icon(Icons.shield_outlined, color: NeumorphicColors.tealPrimary, size: 22),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Text(
                              'Stripe Express Account Active',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: isDark ? NeumorphicColors.darkTextPrimary : NeumorphicColors.lightTextPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Your business is authorized to collect card charges and deposits directly to your bank account.',
                        style: TextStyle(fontSize: 12, color: isDark ? Colors.white60 : Colors.black54),
                      ),
                      const SizedBox(height: 14),
                      NeumorphicButton(
                        isPrimary: true,
                        height: 44,
                        onPressed: _handleStripeDashboard,
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.open_in_new_rounded, size: 16),
                            SizedBox(width: 8),
                            Text(
                              'Open Stripe Express Dashboard',
                              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    ],
                  )
                : Row(
                    children: [
                      NeumorphicContainer(
                        isCircle: true,
                        width: 48,
                        height: 48,
                        child: const Icon(Icons.shield_outlined, color: NeumorphicColors.tealPrimary, size: 24),
                      ),
                      const SizedBox(width: 18),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Stripe Express Account Active',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: isDark ? NeumorphicColors.darkTextPrimary : NeumorphicColors.lightTextPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Your business is authorized to collect card charges and deposits directly to your bank account.',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? Colors.white60 : Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      NeumorphicButton(
                        isPrimary: true,
                        height: 44,
                        onPressed: _handleStripeDashboard,
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.open_in_new_rounded, size: 16),
                            SizedBox(width: 8),
                            Text(
                              'Open Stripe Express Dashboard',
                              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
          );
        } else {
          return NeumorphicContainer(
            borderRadius: 20.0,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: isNarrow
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          NeumorphicContainer(
                            isCircle: true,
                            width: 44,
                            height: 44,
                            child: const Icon(Icons.account_balance_rounded, color: NeumorphicColors.warning, size: 22),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Text(
                              'Connect Stripe Express to Accept Online Payments',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: isDark ? NeumorphicColors.darkTextPrimary : NeumorphicColors.lightTextPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Set up your Stripe Connect account to enable credit card deposits and automatic client invoicing.',
                        style: TextStyle(fontSize: 12, color: isDark ? Colors.white60 : Colors.black54),
                      ),
                      const SizedBox(height: 14),
                      NeumorphicButton(
                        isPrimary: true,
                        height: 44,
                        onPressed: _handleStripeConnect,
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.link_rounded, size: 18),
                            SizedBox(width: 8),
                            Text(
                              'Connect Stripe Express',
                              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    ],
                  )
                : Row(
                    children: [
                      NeumorphicContainer(
                        isCircle: true,
                        width: 48,
                        height: 48,
                        child: const Icon(Icons.account_balance_rounded, color: NeumorphicColors.warning, size: 24),
                      ),
                      const SizedBox(width: 18),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Connect Stripe Express to Accept Online Payments',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: isDark ? NeumorphicColors.darkTextPrimary : NeumorphicColors.lightTextPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Set up your Stripe Connect account to enable credit card deposits and automatic client invoicing.',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? Colors.white60 : Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      NeumorphicButton(
                        isPrimary: true,
                        height: 44,
                        onPressed: _handleStripeConnect,
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.link_rounded, size: 18),
                            SizedBox(width: 8),
                            Text(
                              'Connect Stripe Express',
                              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
          );
        }
      },
    );
  }

  Widget _buildLedgerTable(bool isDark, Color accent) {
    if (widget.payments.isEmpty) {
      return NeumorphicContainer(
        borderRadius: 20.0,
        padding: const EdgeInsets.all(40),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.receipt_long_rounded,
                size: 48,
                color: isDark ? Colors.white24 : Colors.black26,
              ),
              const SizedBox(height: 12),
              Text(
                'No transactions recorded yet',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: isDark ? NeumorphicColors.darkTextPrimary : NeumorphicColors.lightTextPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Client payments and booking deposits will appear here in real-time.',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.white54 : Colors.black54,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final dateFormat = DateFormat('MMM dd, yyyy HH:mm');

    return NeumorphicContainer(
      borderRadius: 20.0,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: constraints.maxWidth),
              child: DataTable(
                columnSpacing: 24,
                horizontalMargin: 12,
                headingRowHeight: 48,
                dataRowMinHeight: 52,
                dataRowMaxHeight: 64,
                /*
                columns: const [
                  DataColumn(label: Text('Date', style: TextStyle(fontWeight: FontWeight.w800))),
                  DataColumn(label: Text('Client', style: TextStyle(fontWeight: FontWeight.w800))),
                  DataColumn(label: Text('Service / Booking', style: TextStyle(fontWeight: FontWeight.w800))),
                  DataColumn(label: Text('Total', style: TextStyle(fontWeight: FontWeight.w800))),
                  DataColumn(label: Text('Paid', style: TextStyle(fontWeight: FontWeight.w800))),
                  DataColumn(label: Text('Due', style: TextStyle(fontWeight: FontWeight.w800))),
                  DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.w800))),
                  DataColumn(label: Text('Actions', style: TextStyle(fontWeight: FontWeight.w800))),
                ],
                */
                // Gene - Nov 07, 2026: Added Method / Ref # column to Transaction Ledger for GCash, Maya, Bank Transfer, and Stripe auditing
                columns: const [
                  DataColumn(label: Text('Date', style: TextStyle(fontWeight: FontWeight.w800))),
                  DataColumn(label: Text('Client', style: TextStyle(fontWeight: FontWeight.w800))),
                  DataColumn(label: Text('Service / Booking', style: TextStyle(fontWeight: FontWeight.w800))),
                  DataColumn(label: Text('Method / Ref #', style: TextStyle(fontWeight: FontWeight.w800))),
                  DataColumn(label: Text('Total', style: TextStyle(fontWeight: FontWeight.w800))),
                  DataColumn(label: Text('Paid', style: TextStyle(fontWeight: FontWeight.w800))),
                  DataColumn(label: Text('Due', style: TextStyle(fontWeight: FontWeight.w800))),
                  DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.w800))),
                  DataColumn(label: Text('Actions', style: TextStyle(fontWeight: FontWeight.w800))),
                ],
                rows: widget.payments.map((p) {
                  final clientDisplay = p.clientId.length > 8
                      ? 'Client #${p.clientId.substring(0, 8)}'
                      : 'Client #${p.clientId}';
                  final bookingDisplay = p.bookingId.length > 8
                      ? 'Booking #${p.bookingId.substring(0, 8)}'
                      : 'Booking #${p.bookingId}';
                  final isRefunded = p.paymentStatus == 'refunded';
                  final methodDisplay = p.referenceNumber != null && p.referenceNumber!.isNotEmpty
                      ? '${p.paymentMethodLabel} (${p.referenceNumber})'
                      : p.paymentMethodLabel;

                  return DataRow(
                    cells: [
                      DataCell(
                        Text(
                          dateFormat.format(p.createdAt),
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                        ),
                      ),
                      DataCell(
                        Text(
                          clientDisplay,
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                      ),
                      DataCell(
                        Text(
                          bookingDisplay,
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.white70 : Colors.black87,
                          ),
                        ),
                      ),
                      DataCell(
                        Text(
                          methodDisplay,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: p.paymentMethod == 'gcash'
                                ? const Color(0xFF007DFE)
                                : (p.paymentMethod == 'maya'
                                    ? const Color(0xFF00B14F)
                                    : accent),
                          ),
                        ),
                      ),
                      DataCell(
                        Text(
                          '\$ ${p.grossAmount.toStringAsFixed(2)}',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                        ),
                      ),
                      DataCell(
                        Text(
                          isRefunded ? '\$ 0.00' : '\$ ${p.grossAmount.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: isRefunded ? NeumorphicColors.error : accent,
                          ),
                        ),
                      ),
                      DataCell(
                        Text(
                          '\$ 0.00',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.white60 : Colors.black54,
                          ),
                        ),
                      ),
                      DataCell(
                        StatusBadge(status: p.paymentStatus),
                      ),
                      DataCell(
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (!isRefunded)
                              IconButton(
                                icon: const Icon(Icons.replay_rounded, size: 18),
                                tooltip: 'Issue Refund',
                                color: NeumorphicColors.error,
                                onPressed: () => _openRefundDialog(p),
                              ),
                            if (p.receiptUrl != null)
                              IconButton(
                                icon: const Icon(Icons.receipt_long_rounded, size: 18),
                                tooltip: 'View Stripe Receipt',
                                color: accent,
                                onPressed: () async {
                                  final uri = Uri.parse(p.receiptUrl!);
                                  if (await canLaunchUrl(uri)) {
                                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                                  }
                                },
                              ),
                          ],
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          );
        },
      ),
    );
  }
}
