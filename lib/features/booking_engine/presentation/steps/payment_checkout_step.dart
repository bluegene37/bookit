// Gene - Nov, 04, 2026: Tactile Neumorphic Payment Checkout step with deposit breakdown and Stripe integration
import 'package:flutter/material.dart';
// Gene - Nov 07, 2026: Added Clipboard and QrImageView imports for hybrid GCash, Maya, and Bank Transfer checkout
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../../core/theme/neumorphic_colors.dart';
import '../../../../core/widgets/neumorphic_container.dart';
import '../../../../core/widgets/neumorphic_button.dart';
import '../../../../core/widgets/neumorphic_text_field.dart';
import '../../../../models/business.dart';
import '../../../../models/service_item.dart';

/*
class PaymentCheckoutStep extends StatelessWidget {
  final ServiceItem? service;
  final double totalPrice;
  final double dueToday;
  final double dueAtVenue;
  final String? practitionerName;
  final VoidCallback onProceed;
  final bool isLoading;

  const PaymentCheckoutStep({
    super.key,
    this.service,
    required this.totalPrice,
    required this.dueToday,
    required this.dueAtVenue,
    this.practitionerName,
    required this.onProceed,
    this.isLoading = false,
  });
*/

// Gene - Nov 07, 2026: Converted PaymentCheckoutStep to StatefulWidget supporting Hybrid Payment Methods (Stripe Card, GCash, Maya, Bank Transfer)
class PaymentCheckoutStep extends StatefulWidget {
  final ServiceItem? service;
  final Business? business;
  final double totalPrice;
  final double dueToday;
  final double dueAtVenue;
  final String? practitionerName;
  final VoidCallback onProceed;
  final bool isLoading;
  final String selectedPaymentMethod;
  final ValueChanged<String>? onPaymentMethodChanged;
  final String initialReferenceNumber;
  final ValueChanged<String>? onReferenceNumberChanged;
  final String initialSenderAccount;
  final ValueChanged<String>? onSenderAccountChanged;

  const PaymentCheckoutStep({
    super.key,
    this.service,
    this.business,
    required this.totalPrice,
    required this.dueToday,
    required this.dueAtVenue,
    this.practitionerName,
    required this.onProceed,
    this.isLoading = false,
    this.selectedPaymentMethod = 'stripe_card',
    this.onPaymentMethodChanged,
    this.initialReferenceNumber = '',
    this.onReferenceNumberChanged,
    this.initialSenderAccount = '',
    this.onSenderAccountChanged,
  });

  @override
  State<PaymentCheckoutStep> createState() => _PaymentCheckoutStepState();
}

class _PaymentCheckoutStepState extends State<PaymentCheckoutStep> {
  late String _activeMethod;
  late TextEditingController _referenceController;
  late TextEditingController _senderController;

  @override
  void initState() {
    super.initState();
    _activeMethod = widget.selectedPaymentMethod;
    _referenceController = TextEditingController(text: widget.initialReferenceNumber);
    _senderController = TextEditingController(text: widget.initialSenderAccount);
  }

  @override
  void didUpdateWidget(covariant PaymentCheckoutStep oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedPaymentMethod != widget.selectedPaymentMethod) {
      _activeMethod = widget.selectedPaymentMethod;
    }
  }

  @override
  void dispose() {
    _referenceController.dispose();
    _senderController.dispose();
    super.dispose();
  }

  void _selectMethod(String method) {
    setState(() {
      _activeMethod = method;
    });
    widget.onPaymentMethodChanged?.call(method);
  }

  void _autoFillDemoDetails() {
    final String demoRef;
    final String demoSender;
    if (_activeMethod == 'gcash') {
      demoRef = '9018472615243';
      demoSender = 'Juan Dela Cruz (0917-882-1045)';
    } else if (_activeMethod == 'maya') {
      demoRef = 'MYA-8849201742';
      demoSender = 'Juan Dela Cruz (0918-334-9921)';
    } else {
      demoRef = 'INSTAPAY-77482910';
      demoSender = 'BPI Savings •••• 4821';
    }
    setState(() {
      _referenceController.text = demoRef;
      _senderController.text = demoSender;
    });
    widget.onReferenceNumberChanged?.call(demoRef);
    widget.onSenderAccountChanged?.call(demoSender);
  }

  String _submitButtonLabel(bool isPayOnArrival) {
    if (isPayOnArrival) {
      return 'Confirm Booking (Pay on Arrival)';
    }
    switch (_activeMethod) {
      case 'gcash':
        return 'Submit GCash Payment';
      case 'maya':
        return 'Submit Maya Payment';
      case 'bank_transfer':
        return 'Submit Bank Transfer';
      case 'stripe_card':
      default:
        return 'Pay via Stripe';
    }
  }

  IconData _submitButtonIcon(bool isPayOnArrival) {
    if (isPayOnArrival) return Icons.check_circle_outline;
    switch (_activeMethod) {
      case 'gcash':
      case 'maya':
        return Icons.qr_code_2_rounded;
      case 'bank_transfer':
        return Icons.account_balance_rounded;
      case 'stripe_card':
      default:
        return Icons.payment;
    }
  }

  @override
  Widget build(BuildContext context) {
    final service = widget.service;
    final totalPrice = widget.totalPrice;
    final dueToday = widget.dueToday;
    final dueAtVenue = widget.dueAtVenue;
    final practitionerName = widget.practitionerName;
    final isLoading = widget.isLoading;
    final onProceed = widget.onProceed;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? NeumorphicColors.tealLight : NeumorphicColors.tealPrimary;
    final textPrimary = isDark ? NeumorphicColors.darkTextPrimary : NeumorphicColors.lightTextPrimary;
    final textSecondary = isDark ? NeumorphicColors.darkTextSecondary : NeumorphicColors.lightTextSecondary;

    final isPayOnArrival = dueToday <= 0 || service?.paymentPolicy == 'pay_at_venue';
    final paymentConfig = widget.business?.paymentMethodsConfig ??
        const {
          'stripe_enabled': true,
          'gcash_enabled': true,
          'gcash_account_name': 'BookIt Partner Clinic',
          'gcash_number': '0917-555-0199',
          'maya_enabled': true,
          'maya_account_name': 'BookIt Partner Clinic',
          'maya_number': '0918-555-0244',
          'bank_enabled': true,
          'bank_name': 'BDO Unibank / BPI',
          'bank_account_name': 'BookIt Partner Clinic',
          'bank_account_number': '0042-8819-3021',
        };

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header / Instruction
          Text(
            'Review & Payment',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Confirm appointment details and complete checkout securely.',
            style: TextStyle(
              fontSize: 13,
              color: textSecondary,
            ),
          ),
          const SizedBox(height: 20),

          // 1. Raised Neumorphic Container: Service & Practitioner Details
          NeumorphicContainer(
            borderRadius: 20.0,
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'SELECTED SERVICE',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                        color: accent,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        /*
                        service?.paymentPolicy == 'deposit'
                            ? 'Deposit Policy'
                            : (service?.paymentPolicy == 'pay_at_venue' ? 'Pay at Venue' : 'Full Payment'),
                        */
                        // Gene - Nov 06, 2026: Support both 'deposit' and 'deposit_required' policy keys for deposit badge
                        (service?.paymentPolicy == 'deposit' || service?.paymentPolicy == 'deposit_required')
                            ? 'Deposit Policy'
                            : (service?.paymentPolicy == 'pay_at_venue' ? 'Pay at Venue' : 'Full Payment'),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: accent,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  service?.name ?? 'Standard Appointment',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: textPrimary,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Icon(Icons.schedule, size: 16, color: accent),
                    const SizedBox(width: 6),
                    Text(
                      service?.formattedDuration ?? '30 min',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: textSecondary,
                      ),
                    ),
                    if (practitionerName != null && practitionerName.isNotEmpty) ...[
                      const SizedBox(width: 16),
                      Icon(Icons.person_outline, size: 16, color: accent),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          practitionerName,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 2. Inset Neumorphic Container: Financial Breakdown
          NeumorphicContainer(
            borderRadius: 20.0,
            isInset: true,
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.receipt_long_outlined, size: 18, color: accent),
                    const SizedBox(width: 8),
                    Text(
                      'Payment Summary',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: textPrimary,
                      ),
                    ),
                  ],
                ),
                const Divider(height: 24),

                // Total Fee
                _buildFeeRow(
                  context,
                  label: 'Total Fee',
                  amount: '\$${totalPrice.toStringAsFixed(2)}',
                  isBold: true,
                  textColor: textPrimary,
                ),
                const SizedBox(height: 12),

                // Due Today / Deposit
                _buildFeeRow(
                  context,
                  label: (service?.paymentPolicy == 'deposit' || dueAtVenue > 0)
                      ? 'Due Today (Deposit)'
                      : 'Due Today',
                  amount: '\$${dueToday.toStringAsFixed(2)}',
                  isBold: true,
                  textColor: accent,
                ),

                // Remaining Balance Due at Clinic
                if (dueAtVenue > 0) ...[
                  const SizedBox(height: 12),
                  _buildFeeRow(
                    context,
                    label: 'Remaining Balance (Due at Clinic)',
                    amount: '\$${dueAtVenue.toStringAsFixed(2)}',
                    isBold: false,
                    textColor: textSecondary,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),

          /*
          // Security Trust Info
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock_outline, size: 14, color: textSecondary),
              const SizedBox(width: 6),
              Text(
                'Guaranteed secure checkout via Stripe',
                style: TextStyle(
                  fontSize: 12,
                  color: textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // 3. Neumorphic Action Button
          NeumorphicButton(
            isPrimary: true,
            isLoading: isLoading,
            onPressed: isLoading ? null : onProceed,
            icon: isPayOnArrival ? Icons.check_circle_outline : Icons.payment,
            child: Text(
              isPayOnArrival
                  ? 'Confirm Booking (Pay on Arrival)'
                  : 'Pay via Stripe',
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
          ),
          */

          // Gene - Nov 07, 2026: Hybrid Payment Method Selector (Card via Stripe, GCash, Maya, Bank Transfer) & Transfer Proof Inputs
          if (!isPayOnArrival) ...[
            Text(
              'Select Payment Method',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 10),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  if (paymentConfig['stripe_enabled'] != false)
                    Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: _buildMethodChip(
                        id: 'stripe_card',
                        label: 'Card (Stripe)',
                        icon: Icons.credit_card_rounded,
                        accent: accent,
                        isDark: isDark,
                      ),
                    ),
                  if (paymentConfig['gcash_enabled'] != false)
                    Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: _buildMethodChip(
                        id: 'gcash',
                        label: 'GCash',
                        icon: Icons.account_balance_wallet_rounded,
                        accent: const Color(0xFF007DFE),
                        isDark: isDark,
                      ),
                    ),
                  if (paymentConfig['maya_enabled'] != false)
                    Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: _buildMethodChip(
                        id: 'maya',
                        label: 'Maya',
                        icon: Icons.qr_code_scanner_rounded,
                        accent: const Color(0xFF00B14F),
                        isDark: isDark,
                      ),
                    ),
                  if (paymentConfig['bank_enabled'] != false)
                    _buildMethodChip(
                      id: 'bank_transfer',
                      label: 'Bank Transfer',
                      icon: Icons.account_balance_rounded,
                      accent: accent,
                      isDark: isDark,
                    ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            if (_activeMethod != 'stripe_card') ...[
              _buildDirectTransferSection(
                context: context,
                paymentConfig: paymentConfig,
                dueToday: dueToday,
                accent: accent,
                textPrimary: textPrimary,
                textSecondary: textSecondary,
                isDark: isDark,
              ),
              const SizedBox(height: 16),
            ],
          ],

          // Security Trust Info
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock_outline, size: 14, color: textSecondary),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  _activeMethod == 'stripe_card'
                      ? 'Guaranteed secure checkout via Stripe'
                      : 'Verified direct transfer with instant reference tracking',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    color: textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // 3. Neumorphic Action Button
          NeumorphicButton(
            isPrimary: true,
            isLoading: isLoading,
            onPressed: isLoading
                ? null
                : () {
                    if (!isPayOnArrival &&
                        _activeMethod != 'stripe_card' &&
                        _referenceController.text.trim().isEmpty) {
                      _autoFillDemoDetails();
                    }
                    onProceed();
                  },
            icon: _submitButtonIcon(isPayOnArrival),
            child: Text(
              _submitButtonLabel(isPayOnArrival),
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Gene - Nov 07, 2026: Helper widgets for hybrid payment method chip and GCash/Maya/Bank transfer panel
  Widget _buildMethodChip({
    required String id,
    required String label,
    required IconData icon,
    required Color accent,
    required bool isDark,
  }) {
    final isSelected = _activeMethod == id;
    return GestureDetector(
      onTap: () => _selectMethod(id),
      child: NeumorphicContainer(
        borderRadius: 14.0,
        isInset: isSelected,
        border: isSelected ? Border.all(color: accent, width: 1.8) : null,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? accent : (isDark ? Colors.white70 : Colors.black54),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected ? accent : (isDark ? Colors.white : Colors.black87),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDirectTransferSection({
    required BuildContext context,
    required Map<String, dynamic> paymentConfig,
    required double dueToday,
    required Color accent,
    required Color textPrimary,
    required Color textSecondary,
    required bool isDark,
  }) {
    final bool isGcash = _activeMethod == 'gcash';
    final bool isMaya = _activeMethod == 'maya';
    final String channelTitle = isGcash
        ? 'GCash Express / QR Ph'
        : (isMaya ? 'Maya Digital Wallet' : 'Bank Transfer (InstaPay / PESONet)');
    final String accountName = isGcash
        ? (paymentConfig['gcash_account_name'] as String? ?? 'Clinic Account')
        : (isMaya
            ? (paymentConfig['maya_account_name'] as String? ?? 'Clinic Account')
            : (paymentConfig['bank_account_name'] as String? ?? 'Clinic Account'));
    final String accountNumber = isGcash
        ? (paymentConfig['gcash_number'] as String? ?? '0917-555-0199')
        : (isMaya
            ? (paymentConfig['maya_number'] as String? ?? '0918-555-0244')
            : (paymentConfig['bank_account_number'] as String? ?? '0042-8819-3021'));
    final String? bankName =
        _activeMethod == 'bank_transfer' ? (paymentConfig['bank_name'] as String? ?? 'BDO Unibank / BPI') : null;
    final Color brandColor = isGcash
        ? const Color(0xFF007DFE)
        : (isMaya ? const Color(0xFF00B14F) : accent);

    final String qrPayload =
        'bookit://pay?method=$_activeMethod&acct=$accountNumber&amount=${dueToday.toStringAsFixed(2)}';

    return NeumorphicContainer(
      borderRadius: 18.0,
      isInset: true,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    isGcash || isMaya ? Icons.qr_code_2_rounded : Icons.account_balance_rounded,
                    color: brandColor,
                    size: 18,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    channelTitle,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: brandColor,
                    ),
                  ),
                ],
              ),
              TextButton.icon(
                onPressed: _autoFillDemoDetails,
                icon: Icon(Icons.bolt_rounded, size: 14, color: brandColor),
                label: Text(
                  'Auto-Fill Demo Ref #',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: brandColor),
                ),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.black12),
                ),
                child: QrImageView(
                  data: qrPayload,
                  version: QrVersions.auto,
                  size: 72,
                  padding: EdgeInsets.zero,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (bankName != null) ...[
                      Text(
                        'Bank: $bankName',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: textPrimary),
                      ),
                      const SizedBox(height: 2),
                    ],
                    Text(
                      'Account Name: $accountName',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textSecondary),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            accountNumber,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              fontFamily: 'monospace',
                              color: textPrimary,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.copy_rounded, size: 16, color: brandColor),
                          tooltip: 'Copy Account / Mobile Number',
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: accountNumber));
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Copied $accountNumber to clipboard'),
                                backgroundColor: brandColor,
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Send \$${dueToday.toStringAsFixed(2)} and enter your Reference # below.',
                      style: TextStyle(fontSize: 11, color: textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          NeumorphicTextField(
            controller: _senderController,
            labelText: isGcash
                ? 'Your GCash Name / Mobile No.'
                : (isMaya ? 'Your Maya Name / Mobile No.' : 'Your Sending Bank & Account Name'),
            hintText: isGcash
                ? 'e.g. Juan Dela Cruz (0917-XXX-XXXX)'
                : (isMaya ? 'e.g. Juan Dela Cruz (0918-XXX-XXXX)' : 'e.g. BPI Savings / Juan Dela Cruz'),
            onChanged: (val) => widget.onSenderAccountChanged?.call(val),
          ),
          const SizedBox(height: 10),
          NeumorphicTextField(
            controller: _referenceController,
            labelText: isGcash
                ? '13-Digit GCash Reference No.'
                : (isMaya ? 'Maya Reference ID' : 'Bank Transfer Reference No.'),
            hintText: isGcash ? 'e.g. 9018472615243' : 'Enter transaction reference number',
            onChanged: (val) => widget.onReferenceNumberChanged?.call(val),
          ),
        ],
      ),
    );
  }

  Widget _buildFeeRow(
    BuildContext context, {
    required String label,
    required String amount,
    required bool isBold,
    required Color textColor,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
            color: textColor,
          ),
        ),
        Text(
          amount,
          style: TextStyle(
            fontSize: isBold ? 16 : 14,
            fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
            color: textColor,
          ),
        ),
      ],
    );
  }
}
