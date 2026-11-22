// Gene - Nov, 04, 2026: Payment service handling Stripe Edge Functions, mock fallback, and refund operations
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/constants/supabase_config.dart';
// Gene - Nov, 22, 2026: Added PlatformConfig, Business, AppErrorLogger, and businessService imports for dynamic currency/fees & strict live error reporting
import '../core/utils/app_error_logger.dart';
import '../models/business.dart';
import '../models/platform_config.dart';
import '../models/payment.dart';
import '../models/booking.dart';
import '../models/service_item.dart';
import '../models/notification_item.dart';
import 'booking_service.dart';
import 'notification_service.dart';
import 'supabase_service.dart';

/*
final paymentServiceProvider = Provider<PaymentService>((ref) {
  return PaymentService(ref.watch(supabaseClientProvider));
});

final businessPaymentsProvider = StreamProvider.family<List<Payment>, String>((ref, businessId) {
  final client = ref.watch(supabaseClientProvider);
  return client
      .from('payments')
      .stream(primaryKey: ['id'])
      .eq('business_id', businessId)
      .order('created_at', ascending: false)
      .map((rows) => rows.map((r) => Payment.fromJson(r)).toList());
});
*/

// Gene - Nov, 04, 2026: Updated paymentServiceProvider and businessPaymentsProvider with offline mock fallback and Ref injection
final paymentServiceProvider = Provider<PaymentService>((ref) {
  return PaymentService(ref.watch(supabaseClientProvider), ref);
});

/*
final businessPaymentsProvider = StreamProvider.family<List<Payment>, String>((ref, businessId) {
  if (!SupabaseConfig.isConfigured) {
    return Stream.value(
      SupabaseService.mockPayments.where((p) => p.businessId == businessId).toList(),
    );
  }

  final client = ref.watch(supabaseClientProvider);
  return client
      .from('payments')
      .stream(primaryKey: ['id'])
      .eq('business_id', businessId)
      .order('created_at', ascending: false)
      .map((rows) => rows.map((r) => Payment.fromJson(r)).toList());
});
*/

// Gene - Nov, 22, 2026: Isolate live Supabase payment streams from local mock fixtures
final businessPaymentsProvider = StreamProvider.family<List<Payment>, String>((ref, businessId) async* {
  final isLive = SupabaseConfig.isConfigured && SupabaseService.client != null;
  final mockList = isLive
      ? const <Payment>[]
      : SupabaseService.mockPayments.where((p) => p.businessId == businessId).toList();
  if (!isLive) {
    yield mockList;
    return;
  }

  final client = SupabaseService.client!;
  List<Payment> currentList = [];
  try {
    final rows = await client
        .from('payments')
        .select()
        .eq('business_id', businessId)
        .order('created_at', ascending: false);
    currentList = (rows as List).map((r) => Payment.fromJson(r)).toList();
  } catch (e, st) {
    AppErrorLogger.report(
      service: 'PaymentService',
      operation: 'businessPaymentsProvider',
      error: e,
      stackTrace: st,
    );
  }

  yield currentList;

  if (client.auth.currentSession != null) {
    try {
      await for (final rows in client
          .from('payments')
          .stream(primaryKey: ['id'])
          .eq('business_id', businessId)
          .order('created_at', ascending: false)) {
        yield rows.map((r) => Payment.fromJson(r)).toList();
      }
    } catch (_) {
      // Gracefully absorb RealtimeSubscribeException when Realtime is not enabled for payments or session lacks RLS subscription access
    }
  }
});

class PaymentService {
  final SupabaseClient _client;
  final Ref? _ref;

  PaymentService(this._client, [this._ref]);

  /*
  Future<void> initiateCheckout({
    required String bookingId,
    required String returnUrl,
    required String cancelUrl,
    required Function(bool isMock) onSuccess,
  }) async {
    // Fast path for local mock mode when Supabase is not configured
    if (!SupabaseConfig.isConfigured) {
      await simulateMockPaymentSuccess(bookingId);
      onSuccess(true);
      return;
    }

    try {
      final res = await _client.functions.invoke(
        'create-checkout-session',
        body: {
          'booking_id': bookingId,
          'return_url': returnUrl,
          'cancel_url': cancelUrl,
        },
      );

      final data = res.data as Map<String, dynamic>;
      final url = data['url'] as String?;
      final isMock = data['is_mock'] as bool? ?? false;

      if (isMock) {
        // Execute mock checkout completion locally
        await simulateMockPaymentSuccess(bookingId);
        onSuccess(true);
        return;
      }

      if (url != null && await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      // Graceful offline mock fallback
      await simulateMockPaymentSuccess(bookingId);
      onSuccess(true);
    }
  }
  */

  /*
  // Gene - Nov 07, 2026: Updated initiateCheckout to support hybrid paymentMethod, referenceNumber, and senderAccount
  Future<void> initiateCheckout({
    required String bookingId,
    required String returnUrl,
    required String cancelUrl,
    String paymentMethod = 'stripe_card',
    String? referenceNumber,
    String? senderAccount,
    required Function(bool isMock) onSuccess,
  }) async {
    // Fast path for local mock mode or direct clinic transfer methods (GCash, Maya, Bank Transfer)
    if (!SupabaseConfig.isConfigured || paymentMethod != 'stripe_card') {
      await simulateMockPaymentSuccess(
        bookingId,
        paymentMethod: paymentMethod,
        referenceNumber: referenceNumber,
        senderAccount: senderAccount,
      );
      onSuccess(true);
      return;
    }

    try {
      final res = await _client.functions.invoke(
        'create-checkout-session',
        body: {
          'booking_id': bookingId,
          'return_url': returnUrl,
          'cancel_url': cancelUrl,
          'payment_method': paymentMethod,
          'reference_number': ?referenceNumber,
          'sender_account': ?senderAccount,
        },
      );

      final data = res.data as Map<String, dynamic>;
      final url = data['url'] as String?;
      final isMock = data['is_mock'] as bool? ?? false;

      if (isMock) {
        // Execute mock checkout completion locally
        await simulateMockPaymentSuccess(
          bookingId,
          paymentMethod: paymentMethod,
          referenceNumber: referenceNumber,
          senderAccount: senderAccount,
        );
        onSuccess(true);
        return;
      }

      if (url != null && await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      // Graceful offline mock fallback
      await simulateMockPaymentSuccess(
        bookingId,
        paymentMethod: paymentMethod,
        referenceNumber: referenceNumber,
        senderAccount: senderAccount,
      );
      onSuccess(true);
    }
  }
  */

  // Gene - Nov, 22, 2026: Use live submit_manual_payment RPC for direct transfers and fail loudly on live Stripe errors outside demo mode
  Future<void> initiateCheckout({
    required String bookingId,
    required String returnUrl,
    required String cancelUrl,
    String paymentMethod = 'stripe_card',
    String? referenceNumber,
    String? senderAccount,
    required Function(bool isMock) onSuccess,
  }) async {
    final liveClient = SupabaseService.client;

    if (!SupabaseConfig.isConfigured || liveClient == null) {
      await simulateMockPaymentSuccess(
        bookingId,
        paymentMethod: paymentMethod,
        referenceNumber: referenceNumber,
        senderAccount: senderAccount,
      );
      onSuccess(true);
      return;
    }

    if (paymentMethod != 'stripe_card') {
      try {
        await liveClient.rpc(
          'submit_manual_payment',
          params: {
            'p_booking_id': bookingId,
            'p_payment_method': paymentMethod,
            'p_reference_number': referenceNumber?.trim() ?? '',
            'p_sender_account': senderAccount?.trim(),
          },
        );
        if (_ref != null) {
          await _ref.read(bookingsProvider.notifier).loadBookings();
        }
        onSuccess(false);
        return;
      } catch (e, st) {
        AppErrorLogger.report(
          service: 'PaymentService',
          operation: 'submit_manual_payment',
          error: e,
          stackTrace: st,
        );
        rethrow;
      }
    }

    try {
      final res = await _client.functions.invoke(
        'create-checkout-session',
        body: {
          'booking_id': bookingId,
          'return_url': returnUrl,
          'cancel_url': cancelUrl,
          'payment_method': paymentMethod,
          'reference_number': ?referenceNumber,
          'sender_account': ?senderAccount,
        },
      );

      final data = res.data as Map<String, dynamic>;
      final url = data['url'] as String?;
      final isMock = data['is_mock'] as bool? ?? false;

      if (isMock) {
        if (!SupabaseConfig.isDemoModeEnabled) {
          throw StateError('Stripe checkout returned mock session in production mode.');
        }
        await simulateMockPaymentSuccess(
          bookingId,
          paymentMethod: paymentMethod,
          referenceNumber: referenceNumber,
          senderAccount: senderAccount,
        );
        onSuccess(true);
        return;
      }

      if (url != null && await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      }
    } catch (e, st) {
      AppErrorLogger.report(
        service: 'PaymentService',
        operation: 'initiateCheckout',
        error: e,
        stackTrace: st,
      );
      if (SupabaseConfig.isDemoModeEnabled) {
        await simulateMockPaymentSuccess(
          bookingId,
          paymentMethod: paymentMethod,
          referenceNumber: referenceNumber,
          senderAccount: senderAccount,
        );
        onSuccess(true);
        return;
      }
      rethrow;
    }
  }

  /*
  Future<void> simulateMockPaymentSuccess(String bookingId) async {
    if (!SupabaseConfig.isConfigured) {
      return;
    }

    try {
      final bookingRes = await _client.from('bookings').select('*').eq('id', bookingId).single();
      final totalPrice = (bookingRes['total_price'] as num?)?.toDouble() ?? 0.0;

      await _client.from('bookings').update({
        'status': 'confirmed',
        'payment_status': 'paid_in_full',
        'amount_paid': totalPrice,
        'amount_due': 0.0,
      }).eq('id', bookingId);
    } catch (_) {
      // Graceful fallback when database is not reachable
    }
  }
  */

  /*
  // Gene - Nov, 04, 2026: Updated simulateMockPaymentSuccess to calculate deposit vs full payment, update in-memory mock state, and insert payments & notifications
  // Gene - Nov 07, 2026: Extended simulateMockPaymentSuccess with paymentMethod, referenceNumber, and senderAccount support
  Future<void> simulateMockPaymentSuccess(
    String bookingId, {
    double? amount,
    String paymentMethod = 'stripe_card',
    String? referenceNumber,
    String? senderAccount,
  }) async {
    // 1. Locate booking in memory (Riverpod state or mockBookings)
    Booking? booking;
    if (_ref != null) {
      final all = _ref.read(bookingsProvider);
      final idx = all.indexWhere((b) => b.id == bookingId);
      if (idx != -1) booking = all[idx];
    }
    booking ??= SupabaseService.mockBookings.cast<Booking?>().firstWhere(
      (b) => b?.id == bookingId,
      orElse: () => null,
    );

    double totalPrice = booking?.totalPrice ?? 0.0;
    String businessId = booking?.businessId ?? '11111111-1111-1111-1111-111111111111';
    String clientId = booking?.clientId ?? '00000000-0000-0000-0000-000000000003';

    // 2. Determine charged amount & deposit logic
    double paidAmount = amount ?? totalPrice;
    if (amount == null && booking?.serviceId != null) {
      final service = SupabaseService.mockServices.cast<ServiceItem?>().firstWhere(
        (s) => s?.id == booking!.serviceId,
        orElse: () => null,
      );
      /*
      if (service != null && service.paymentPolicy == 'deposit') {
      */
      // Gene - Nov 06, 2026: Support both 'deposit' and 'deposit_required' policy keys
      if (service != null && (service.paymentPolicy == 'deposit' || service.paymentPolicy == 'deposit_required')) {
        if (service.depositType == 'percentage') {
          paidAmount = double.parse((totalPrice * (service.depositAmount / 100)).toStringAsFixed(2));
        } else {
          paidAmount = service.depositAmount < totalPrice ? service.depositAmount : totalPrice;
        }
      }
    }

    final remainingDue = double.parse((totalPrice - paidAmount).clamp(0.0, double.infinity).toStringAsFixed(2));
    final paymentStatus = remainingDue == 0 ? 'paid_in_full' : 'deposit_paid';

    final effectiveRef = (referenceNumber != null && referenceNumber.trim().isNotEmpty)
        ? referenceNumber.trim()
        : (paymentMethod == 'gcash'
            ? 'GC-${DateTime.now().millisecondsSinceEpoch}'
            : (paymentMethod == 'maya'
                ? 'MY-${DateTime.now().millisecondsSinceEpoch}'
                : (paymentMethod == 'bank_transfer'
                    ? 'BNK-${DateTime.now().millisecondsSinceEpoch}'
                    : null)));

    // 3. Update in-memory booking state
    if (_ref != null) {
      await _ref.read(bookingsProvider.notifier).updateBookingPayment(
        bookingId: bookingId,
        paymentStatus: paymentStatus,
        amountPaid: paidAmount,
        amountDue: remainingDue,
        paymentMethod: paymentMethod,
        paymentReference: effectiveRef,
        paymentSender: senderAccount,
      );
    }

    final mockBookingIdx = SupabaseService.mockBookings.indexWhere((b) => b.id == bookingId);
    if (mockBookingIdx != -1) {
      final b = SupabaseService.mockBookings[mockBookingIdx];
      SupabaseService.mockBookings[mockBookingIdx] = b.copyWith(
        status: 'confirmed',
        paymentStatus: paymentStatus,
        amountPaid: paidAmount,
        amountDue: remainingDue,
        holdExpiresAt: null,
        paymentMethod: paymentMethod,
        paymentReference: effectiveRef,
        paymentSender: senderAccount,
      );
    }

    // 4. Create and insert payment record into mock ledger
    final isDirectTransfer = paymentMethod != 'stripe_card';
    final payment = Payment(
      id: 'pay-mock-${DateTime.now().millisecondsSinceEpoch}',
      bookingId: bookingId,
      businessId: businessId,
      clientId: clientId,
      stripeSessionId: isDirectTransfer ? null : 'cs_mock_${DateTime.now().millisecondsSinceEpoch}',
      stripePaymentIntentId: isDirectTransfer ? effectiveRef : 'pi_mock_${DateTime.now().millisecondsSinceEpoch}',
      grossAmount: paidAmount,
      applicationFeeAmount: double.parse(((paidAmount * 0.025) + 0.30).toStringAsFixed(2)),
      stripeFeeAmount: isDirectTransfer ? 0.0 : double.parse(((paidAmount * 0.029) + 0.30).toStringAsFixed(2)),
      netAmount: isDirectTransfer
          ? paidAmount
          : double.parse((paidAmount - ((paidAmount * 0.025) + 0.30)).toStringAsFixed(2)),
      currency: 'usd',
      paymentStatus: 'succeeded',
      createdAt: DateTime.now(),
      paymentMethod: paymentMethod,
      referenceNumber: effectiveRef,
      senderAccount: senderAccount,
    );
    SupabaseService.mockPayments.insert(0, payment);
    // Gene - Nov, 7, 2026: Invalidate businessPaymentsProvider so payment streams immediately emit the newly recorded payment
    if (_ref != null) {
      try {
        _ref.invalidate(businessPaymentsProvider(businessId));
      } catch (_) {}
    }

    // 5. Create and insert notification record
    final methodLabel = payment.paymentMethodLabel;
    final notifTitle = paymentStatus == 'deposit_paid' ? 'Deposit Payment Confirmed! 💳' : 'Payment Confirmed! 💳';
    final notifBody = effectiveRef != null
        ? 'Your $methodLabel payment of \$${paidAmount.toStringAsFixed(2)} (Ref: $effectiveRef) was recorded.'
        : 'Your payment of \$${paidAmount.toStringAsFixed(2)} was successfully processed.';
    final notification = NotificationItem(
      id: 'notif-${DateTime.now().millisecondsSinceEpoch}',
      userId: clientId,
      businessId: businessId,
      bookingId: bookingId,
      title: notifTitle,
      body: notifBody,
      type: 'payment_success',
      isRead: false,
      createdAt: DateTime.now(),
    );
    SupabaseService.mockNotifications.insert(0, notification);
    if (_ref != null) {
      try {
        _ref.read(notificationsProvider.notifier).addNotification(notification);
      } catch (_) {}
    }

    // 6. If Supabase is configured, sync to database tables
    if (SupabaseConfig.isConfigured) {
      try {
        await _client.from('bookings').update({
          'status': 'confirmed',
          'payment_status': paymentStatus,
          'amount_paid': paidAmount,
          'amount_due': remainingDue,
          'hold_expires_at': null,
          'payment_method': paymentMethod,
          'payment_reference': ?effectiveRef,
          'payment_sender': ?senderAccount,
        }).eq('id', bookingId);

        await _client.from('payments').insert({
          'booking_id': bookingId,
          'business_id': businessId,
          'client_id': clientId,
          'stripe_session_id': payment.stripeSessionId,
          'stripe_payment_intent_id': payment.stripePaymentIntentId,
          'gross_amount': paidAmount,
          'application_fee_amount': payment.applicationFeeAmount,
          'stripe_fee_amount': payment.stripeFeeAmount,
          'net_amount': payment.netAmount,
          'currency': 'usd',
          'payment_status': 'succeeded',
          'payment_method': paymentMethod,
          'reference_number': ?effectiveRef,
          'sender_account': ?senderAccount,
        });

        await _client.from('notifications').insert({
          'user_id': clientId,
          'business_id': businessId,
          'booking_id': bookingId,
          'title': notifTitle,
          'body': notifBody,
          'type': 'payment_success',
        });
      } catch (_) {
        // Database write error gracefully ignored in offline/mock mode
      }
    }
  }
  */

  // Gene - Nov, 22, 2026: Dynamic business currency, platform fee rates, service deposit policy, and safe notification formatting in simulateMockPaymentSuccess
  Future<void> simulateMockPaymentSuccess(
    String bookingId, {
    double? amount,
    String paymentMethod = 'stripe_card',
    String? referenceNumber,
    String? senderAccount,
  }) async {
    Booking? booking;
    if (_ref != null) {
      final all = _ref.read(bookingsProvider);
      final idx = all.indexWhere((b) => b.id == bookingId);
      if (idx != -1) booking = all[idx];
    }
    booking ??= SupabaseService.mockBookings.cast<Booking?>().firstWhere(
      (b) => b?.id == bookingId,
      orElse: () => null,
    );

    final double totalPrice = booking?.totalPrice ?? 0.0;
    final String businessId =
        booking?.businessId ?? '11111111-1111-1111-1111-111111111111';
    final String clientId = booking?.clientId ?? '';

    final Business? business = SupabaseService.mockBusinesses
        .cast<Business?>()
        .firstWhere((b) => b?.id == businessId, orElse: () => null);
    final String currencyCode = booking?.currency ?? business?.currency ?? 'USD';
    final double feePercent = business?.platformFeePercent ?? 2.50;
    final double feeFixed = business?.platformFeeFixed ?? 0.30;

    double paidAmount = amount ?? totalPrice;
    if (amount == null && booking?.serviceId != null) {
      final service = SupabaseService.mockServices.cast<ServiceItem?>().firstWhere(
        (s) => s?.id == booking!.serviceId,
        orElse: () => null,
      );
      if (service != null) {
        paidAmount = service.calculateDepositAmount(totalOverride: totalPrice);
      }
    }

    final remainingDue = double.parse(
      (totalPrice - paidAmount).clamp(0.0, double.infinity).toStringAsFixed(2),
    );
    final paymentStatus = paidAmount <= 0
        ? 'unpaid'
        : (remainingDue == 0 ? 'paid_in_full' : 'deposit_paid');

    final effectiveRef = (referenceNumber != null && referenceNumber.trim().isNotEmpty)
        ? referenceNumber.trim()
        : (SupabaseConfig.isDemoModeEnabled
            ? (paymentMethod == 'gcash'
                ? 'GC-${DateTime.now().millisecondsSinceEpoch}'
                : (paymentMethod == 'maya'
                    ? 'MY-${DateTime.now().millisecondsSinceEpoch}'
                    : (paymentMethod == 'bank_transfer'
                        ? 'BNK-${DateTime.now().millisecondsSinceEpoch}'
                        : null)))
            : null);

    if (_ref != null) {
      await _ref.read(bookingsProvider.notifier).updateBookingPayment(
        bookingId: bookingId,
        paymentStatus: paymentStatus,
        amountPaid: paidAmount,
        amountDue: remainingDue,
        paymentMethod: paymentMethod,
        paymentReference: effectiveRef,
        paymentSender: senderAccount,
      );
    }

    final mockBookingIdx = SupabaseService.mockBookings.indexWhere((b) => b.id == bookingId);
    if (mockBookingIdx != -1) {
      final b = SupabaseService.mockBookings[mockBookingIdx];
      SupabaseService.mockBookings[mockBookingIdx] = b.copyWith(
        status: 'confirmed',
        paymentStatus: paymentStatus,
        amountPaid: paidAmount,
        amountDue: remainingDue,
        holdExpiresAt: null,
        paymentMethod: paymentMethod,
        paymentReference: effectiveRef,
        paymentSender: senderAccount,
      );
    }

    final isDirectTransfer = paymentMethod != 'stripe_card';
    final appFee = double.parse(
      ((paidAmount * (feePercent / 100.0)) + feeFixed).toStringAsFixed(2),
    );
    final payment = Payment(
      id: 'pay-mock-${DateTime.now().millisecondsSinceEpoch}',
      bookingId: bookingId,
      businessId: businessId,
      clientId: clientId,
      stripeSessionId: isDirectTransfer ? null : 'cs_mock_${DateTime.now().millisecondsSinceEpoch}',
      stripePaymentIntentId: isDirectTransfer ? null : 'pi_mock_${DateTime.now().millisecondsSinceEpoch}',
      grossAmount: paidAmount,
      applicationFeeAmount: appFee,
      stripeFeeAmount: isDirectTransfer
          ? 0.0
          : double.parse(((paidAmount * 0.029) + 0.30).toStringAsFixed(2)),
      netAmount: isDirectTransfer
          ? paidAmount
          : double.parse((paidAmount - appFee).toStringAsFixed(2)),
      currency: currencyCode.toLowerCase(),
      paymentStatus: 'succeeded',
      createdAt: DateTime.now(),
      paymentMethod: paymentMethod,
      referenceNumber: effectiveRef,
      senderAccount: senderAccount,
    );
    SupabaseService.mockPayments.insert(0, payment);
    if (_ref != null) {
      try {
        _ref.invalidate(businessPaymentsProvider(businessId));
      } catch (_) {}
    }

    final methodLabel = payment.paymentMethodLabel;
    final formattedPaid = PlatformConfig.formatCurrency(paidAmount, currencyCode: currencyCode);
    final notifTitle = paymentStatus == 'deposit_paid'
        ? 'Deposit Payment Confirmed! 💳'
        : 'Payment Confirmed! 💳';
    final notifBody = effectiveRef != null
        ? 'Your $methodLabel payment of $formattedPaid (Ref: $effectiveRef) was recorded.'
        : 'Your payment of $formattedPaid was successfully processed.';

    if (clientId.isNotEmpty) {
      final notification = NotificationItem(
        id: 'notif-${DateTime.now().millisecondsSinceEpoch}',
        userId: clientId,
        businessId: businessId,
        bookingId: bookingId,
        title: notifTitle,
        body: notifBody,
        type: 'payment_success',
        isRead: false,
        createdAt: DateTime.now(),
      );
      SupabaseService.mockNotifications.insert(0, notification);
      if (_ref != null) {
        try {
          _ref.read(notificationsProvider.notifier).addNotification(notification);
        } catch (_) {}
      }
    }

    if (SupabaseConfig.isConfigured && SupabaseService.client != null) {
      try {
        await _client.from('bookings').update({
          'status': 'confirmed',
          'payment_status': paymentStatus,
          'amount_paid': paidAmount,
          'amount_due': remainingDue,
          'hold_expires_at': null,
          'payment_method': paymentMethod,
          'payment_reference': ?effectiveRef,
          'payment_sender': ?senderAccount,
        }).eq('id', bookingId);

        if (clientId.isNotEmpty) {
          await _client.from('payments').insert({
            'booking_id': bookingId,
            'business_id': businessId,
            'client_id': clientId,
            'stripe_session_id': payment.stripeSessionId,
            'stripe_payment_intent_id': payment.stripePaymentIntentId,
            'gross_amount': paidAmount,
            'application_fee_amount': payment.applicationFeeAmount,
            'stripe_fee_amount': payment.stripeFeeAmount,
            'net_amount': payment.netAmount,
            'currency': currencyCode.toLowerCase(),
            'payment_status': 'succeeded',
            'payment_method': paymentMethod,
            'reference_number': ?effectiveRef,
            'sender_account': ?senderAccount,
          });

          await _client.from('notifications').insert({
            'user_id': clientId,
            'business_id': businessId,
            'booking_id': bookingId,
            'title': notifTitle,
            'body': notifBody,
            'type': 'payment_success',
          });
        }
      } catch (e, st) {
        AppErrorLogger.report(
          service: 'PaymentService',
          operation: 'simulateMockPaymentSuccess',
          error: e,
          stackTrace: st,
        );
      }
    }
  }

  /*
  Future<void> processRefund({
    required String paymentId,
    required String bookingId,
    required double amount,
    required String reason,
    String? createdBy,
  }) async {
    if (!SupabaseConfig.isConfigured) {
      return;
    }

    await _client.functions.invoke(
      'process-refund',
      body: {
        'payment_id': paymentId,
        'booking_id': bookingId,
        'amount': amount,
        'reason': reason,
        'created_by': ?createdBy,
      },
    );
  }
  */

  // Gene - Nov, 22, 2026: Execute live process-refund Edge Function with strict error reporting before updating local mock stores
  Future<void> processRefund({
    required String paymentId,
    required String bookingId,
    required double amount,
    required String reason,
    String? createdBy,
  }) async {
    if (SupabaseConfig.isConfigured && SupabaseService.client != null) {
      try {
        await _client.functions.invoke(
          'process-refund',
          body: {
            'payment_id': paymentId,
            'booking_id': bookingId,
            'amount': amount,
            'reason': reason,
            'created_by': createdBy,
          },
        );
        if (_ref != null) {
          await _ref.read(bookingsProvider.notifier).loadBookings();
        }
        return;
      } catch (e, st) {
        AppErrorLogger.report(
          service: 'PaymentService',
          operation: 'processRefund',
          error: e,
          stackTrace: st,
        );
        if (!SupabaseConfig.isDemoModeEnabled) rethrow;
      }
    }

    // 1. Update in-memory mock payments
    final payIdx = SupabaseService.mockPayments.indexWhere((p) => p.id == paymentId);
    if (payIdx != -1) {
      final p = SupabaseService.mockPayments[payIdx];
      final newStatus = amount >= p.grossAmount ? 'refunded' : 'partially_refunded';
      SupabaseService.mockPayments[payIdx] = Payment(
        id: p.id,
        bookingId: p.bookingId,
        businessId: p.businessId,
        clientId: p.clientId,
        stripeSessionId: p.stripeSessionId,
        stripePaymentIntentId: p.stripePaymentIntentId,
        grossAmount: p.grossAmount,
        applicationFeeAmount: p.applicationFeeAmount,
        stripeFeeAmount: p.stripeFeeAmount,
        netAmount: double.parse((p.netAmount - amount).clamp(0.0, double.infinity).toStringAsFixed(2)),
        currency: p.currency,
        paymentStatus: newStatus,
        receiptUrl: p.receiptUrl,
        createdAt: p.createdAt,
        paymentMethod: p.paymentMethod,
        referenceNumber: p.referenceNumber,
        senderAccount: p.senderAccount,
      );
      if (_ref != null) {
        try {
          _ref.invalidate(businessPaymentsProvider(p.businessId));
        } catch (_) {}
      }
    }

    // 2. Update booking payment status in mock list
    final bkIdx = SupabaseService.mockBookings.indexWhere((b) => b.id == bookingId);
    if (bkIdx != -1) {
      final b = SupabaseService.mockBookings[bkIdx];
      final newStatus = amount >= b.amountPaid ? 'refunded' : 'partially_refunded';
      final newAmountPaid = double.parse((b.amountPaid - amount).clamp(0.0, double.infinity).toStringAsFixed(2));
      final newAmountDue = double.parse((b.amountDue + amount).clamp(0.0, b.totalPrice).toStringAsFixed(2));
      SupabaseService.mockBookings[bkIdx] = b.copyWith(
        paymentStatus: newStatus,
        amountPaid: newAmountPaid,
        amountDue: newAmountDue,
      );

      if (_ref != null) {
        try {
          await _ref.read(bookingsProvider.notifier).updateBookingPayment(
            bookingId: bookingId,
            paymentStatus: newStatus,
            amountPaid: newAmountPaid,
            amountDue: newAmountDue,
          );
        } catch (_) {}
      }
    }
  }

  Future<String?> createConnectOnboardingUrl({
    required String businessId,
    required String returnUrl,
    String? refreshUrl,
    String? action,
  }) async {
    if (!SupabaseConfig.isConfigured) {
      return '$returnUrl?stripe_connected=true&mock=true';
    }

    try {
      final res = await _client.functions.invoke(
        'connect-onboarding',
        body: {
          'business_id': businessId,
          'return_url': returnUrl,
          'refresh_url': refreshUrl ?? returnUrl,
          'action': action ?? 'onboard',
        },
      );
      final data = res.data as Map<String, dynamic>;
      return data['url'] as String?;
    } catch (_) {
      return '$returnUrl?stripe_connected=true&mock=true';
    }
  }

  // Gene - Nov, 04, 2026: Alias method for createConnectOnboardingUrl
  Future<String?> getConnectOnboardingUrl({
    required String businessId,
    required String returnUrl,
    String? refreshUrl,
    String? action,
  }) => createConnectOnboardingUrl(
    businessId: businessId,
    returnUrl: returnUrl,
    refreshUrl: refreshUrl,
    action: action,
  );

  Future<void> launchConnectOnboarding({
    required String businessId,
    required String returnUrl,
    String? refreshUrl,
    String? action,
  }) async {
    final url = await createConnectOnboardingUrl(
      businessId: businessId,
      returnUrl: returnUrl,
      refreshUrl: refreshUrl,
      action: action,
    );
    if (url != null && await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    }
  }
}
