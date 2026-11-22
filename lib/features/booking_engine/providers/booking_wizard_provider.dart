// Gene - Nov, 03, 2026: Universal dynamic booking wizard state manager and provider
// Gene - Nov, 08, 2026: Imported foundation.dart for kIsWeb origin-aware checkout redirect URLs
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../models/business.dart';
import '../../../models/business_staff.dart';
import '../../../models/service_item.dart';
import '../../../models/booking.dart';
import '../domain/slot_calculator.dart';
import '../../../services/booking_service.dart';
import '../../../services/auth_service.dart';
import '../../../services/payment_service.dart';
// Gene - Nov, 22, 2026: Added SupabaseConfig and SupabaseService imports for live-mode auth guard & demo separation
import '../../../core/constants/supabase_config.dart';
import '../../../services/supabase_service.dart';

class BookingWizardState {
  final int currentStep;
  final ServiceItem? selectedService;
  final BusinessStaff? selectedStaff;
  final DateTime selectedDate;
  final TimeSlot? selectedSlot;
  final DateTime? dateRangeStart;
  final DateTime? dateRangeEnd;
  final String clientNotes;
  final bool isSubmitting;
  final Booking? completedBooking;
  // Gene - Nov 07, 2026: Added hybrid payment method, reference number, and sender account fields to wizard state
  final String selectedPaymentMethod; // 'stripe_card', 'gcash', 'maya', 'bank_transfer'
  final String paymentReference;
  final String paymentSender;
  // Gene - Nov, 7, 2026: Added hasIntakeBlocker to prevent advancing past Step 2 when a clinical contraindication is active
  final bool hasIntakeBlocker;
  // Gene - Nov, 22, 2026: Added structured intakeResponses, required-field validation gate, and actionable wizard errorMessage
  final Map<String, dynamic> intakeResponses;
  final bool hasMissingRequiredIntake;
  final String? errorMessage;

  /*
  BookingWizardState({
    this.currentStep = 0,
    this.selectedService,
    this.selectedStaff,
    DateTime? selectedDate,
    this.selectedSlot,
    this.dateRangeStart,
    this.dateRangeEnd,
    this.clientNotes = '',
    this.isSubmitting = false,
    this.completedBooking,
  }) : selectedDate = selectedDate ?? DateTime.now().add(const Duration(days: 1));
  */

  /*
  // Gene - Nov 07, 2026: Updated BookingWizardState constructor supporting selectedPaymentMethod, paymentReference, and paymentSender
  BookingWizardState({
    this.currentStep = 0,
    this.selectedService,
    this.selectedStaff,
    DateTime? selectedDate,
    this.selectedSlot,
    this.dateRangeStart,
    this.dateRangeEnd,
    this.clientNotes = '',
    this.isSubmitting = false,
    this.completedBooking,
    this.selectedPaymentMethod = 'stripe_card',
    this.paymentReference = '',
    this.paymentSender = '',
  }) : selectedDate = selectedDate ?? DateTime.now().add(const Duration(days: 1));
  */

  /*
  // Gene - Nov, 7, 2026: Updated BookingWizardState constructor supporting hasIntakeBlocker
  BookingWizardState({
    this.currentStep = 0,
    this.selectedService,
    this.selectedStaff,
    DateTime? selectedDate,
    this.selectedSlot,
    this.dateRangeStart,
    this.dateRangeEnd,
    this.clientNotes = '',
    this.isSubmitting = false,
    this.completedBooking,
    this.selectedPaymentMethod = 'stripe_card',
    this.paymentReference = '',
    this.paymentSender = '',
    this.hasIntakeBlocker = false,
  }) : selectedDate = selectedDate ?? DateTime.now().add(const Duration(days: 1));
  */

  // Gene - Nov, 22, 2026: Extended BookingWizardState constructor with intakeResponses, hasMissingRequiredIntake, and errorMessage
  BookingWizardState({
    this.currentStep = 0,
    this.selectedService,
    this.selectedStaff,
    DateTime? selectedDate,
    this.selectedSlot,
    this.dateRangeStart,
    this.dateRangeEnd,
    this.clientNotes = '',
    this.isSubmitting = false,
    this.completedBooking,
    this.selectedPaymentMethod = 'stripe_card',
    this.paymentReference = '',
    this.paymentSender = '',
    this.hasIntakeBlocker = false,
    this.intakeResponses = const {},
    this.hasMissingRequiredIntake = false,
    this.errorMessage,
  }) : selectedDate = selectedDate ?? DateTime.now().add(const Duration(days: 1));

  double calculateTotalPrice() {
    if (selectedService == null) return 0.0;
    if (dateRangeStart != null && dateRangeEnd != null) {
      final days = dateRangeEnd!.difference(dateRangeStart!).inDays;
      final count = days <= 0 ? 1 : days;
      return selectedService!.price * count;
    }
    return selectedService!.price;
  }

  /*
  // Gene - Nov, 04, 2026: Added deposit and balance calculations to wizard state
  double get dueTodayAmount {
    if (selectedService == null) return 0.0;
    return selectedService!.calculateDepositAmount();
  }
  */

  /*
  // Gene - Nov, 7, 2026: Compute dueTodayAmount against calculateTotalPrice() so multi-day dateRange stays calculate accurate upfront/percentage deposits
  double get dueTodayAmount {
    if (selectedService == null) return 0.0;
    final total = calculateTotalPrice();
    final srv = selectedService!;
    if (srv.paymentPolicy == 'full_upfront') return total;
    if (srv.paymentPolicy == 'pay_at_venue') return 0.0;
    if (srv.depositType == 'percentage') {
      return double.parse((total * (srv.depositAmount / 100)).toStringAsFixed(2));
    }
    return srv.depositAmount > total ? total : srv.depositAmount;
  }

  double get dueAtVenueAmount {
    final total = calculateTotalPrice();
    final dueToday = dueTodayAmount;
    final balance = total - dueToday;
    return balance > 0 ? balance : 0.0;
  }

  /*
  bool get isDepositOnly => selectedService?.paymentPolicy == 'deposit';
  */
  // Gene - Nov 06, 2026: Support both 'deposit' and 'deposit_required' policy keys for deposit calculations
  bool get isDepositOnly =>
      selectedService?.paymentPolicy == 'deposit' || selectedService?.paymentPolicy == 'deposit_required';
  bool get isPayAtVenue => selectedService?.paymentPolicy == 'pay_at_venue';
  */

  // Gene - Nov, 22, 2026: Delegate dueTodayAmount to ServiceItem.calculateDepositAmount and support free_consultation as no-prepayment
  double get dueTodayAmount {
    if (selectedService == null) return 0.0;
    return selectedService!.calculateDepositAmount(
      totalOverride: calculateTotalPrice(),
    );
  }

  double get dueAtVenueAmount {
    final total = calculateTotalPrice();
    final dueToday = dueTodayAmount;
    final balance = total - dueToday;
    return balance > 0 ? balance : 0.0;
  }

  bool get isDepositOnly =>
      selectedService?.paymentPolicy == 'deposit' ||
      selectedService?.paymentPolicy == 'deposit_required';
  bool get isPayAtVenue =>
      selectedService?.paymentPolicy == 'pay_at_venue' ||
      selectedService?.paymentPolicy == 'free_consultation';

  /*
  bool canProceed(BookingModelType modelType) {
    switch (currentStep) {
      case 0: // Select Service
        return selectedService != null;
      case 1: // Scheduling Step
        if (modelType == BookingModelType.slotBased) {
          return selectedSlot != null;
        } else if (modelType == BookingModelType.dateRange) {
          return dateRangeStart != null && dateRangeEnd != null && dateRangeEnd!.isAfter(dateRangeStart!);
        } else {
          return true; // daily: selectedDate is always set
        }
      case 2: // Intake notes
        return true;
      default:
        return false;
    }
  }
  */

  /*
  // Gene - Nov, 04, 2026: Updated canProceed to support Step 3 payment review step
  bool canProceed(BookingModelType modelType) {
    switch (currentStep) {
      case 0: // Select Service
        return selectedService != null;
      case 1: // Scheduling Step
        if (modelType == BookingModelType.slotBased) {
          return selectedSlot != null;
        } else if (modelType == BookingModelType.dateRange) {
          return dateRangeStart != null && dateRangeEnd != null && dateRangeEnd!.isAfter(dateRangeStart!);
        } else {
          return true; // daily: selectedDate is always set
        }
      case 2: // Intake notes
        return true;
      case 3: // Payment review
        return true;
      default:
        return false;
    }
  }
  */

  // Gene - Nov, 22, 2026: Enforce date-range min/max nights & required intake fields (including waivers) in canProceed, and support clearStaff/clearError in copyWith
  bool canProceed(
    BookingModelType modelType, {
    int minDays = 1,
    int? maxDays,
  }) {
    switch (currentStep) {
      case 0: // Select Service
        return selectedService != null;
      case 1: // Scheduling Step
        if (modelType == BookingModelType.slotBased) {
          return selectedSlot != null;
        } else if (modelType == BookingModelType.dateRange) {
          if (dateRangeStart == null ||
              dateRangeEnd == null ||
              !dateRangeEnd!.isAfter(dateRangeStart!)) {
            return false;
          }
          final nights = dateRangeEnd!.difference(dateRangeStart!).inDays;
          if (nights < minDays) return false;
          if (maxDays != null && nights > maxDays) return false;
          return true;
        } else {
          return true; // daily: selectedDate is always set
        }
      case 2: // Intake notes & waivers
        return !hasIntakeBlocker && !hasMissingRequiredIntake;
      case 3: // Payment review
        return true;
      default:
        return false;
    }
  }

  /*
  BookingWizardState copyWith({
    int? currentStep,
    ServiceItem? selectedService,
    BusinessStaff? selectedStaff,
    DateTime? selectedDate,
    TimeSlot? selectedSlot,
    DateTime? dateRangeStart,
    DateTime? dateRangeEnd,
    String? clientNotes,
    bool? isSubmitting,
    Booking? completedBooking,
    bool clearSlot = false,
  }) {
    return BookingWizardState(
      currentStep: currentStep ?? this.currentStep,
      selectedService: selectedService ?? this.selectedService,
      selectedStaff: selectedStaff ?? this.selectedStaff,
      selectedDate: selectedDate ?? this.selectedDate,
      selectedSlot: clearSlot ? null : (selectedSlot ?? this.selectedSlot),
      dateRangeStart: dateRangeStart ?? this.dateRangeStart,
      dateRangeEnd: dateRangeEnd ?? this.dateRangeEnd,
      clientNotes: clientNotes ?? this.clientNotes,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      completedBooking: completedBooking ?? this.completedBooking,
    );
  }
  */

  /*
  // Gene - Nov 07, 2026: Extended copyWith supporting selectedPaymentMethod, paymentReference, and paymentSender
  BookingWizardState copyWith({
    int? currentStep,
    ServiceItem? selectedService,
    BusinessStaff? selectedStaff,
    DateTime? selectedDate,
    TimeSlot? selectedSlot,
    DateTime? dateRangeStart,
    DateTime? dateRangeEnd,
    String? clientNotes,
    bool? isSubmitting,
    Booking? completedBooking,
    bool clearSlot = false,
    String? selectedPaymentMethod,
    String? paymentReference,
    String? paymentSender,
  }) {
    return BookingWizardState(
      currentStep: currentStep ?? this.currentStep,
      selectedService: selectedService ?? this.selectedService,
      selectedStaff: selectedStaff ?? this.selectedStaff,
      selectedDate: selectedDate ?? this.selectedDate,
      selectedSlot: clearSlot ? null : (selectedSlot ?? this.selectedSlot),
      dateRangeStart: dateRangeStart ?? this.dateRangeStart,
      dateRangeEnd: dateRangeEnd ?? this.dateRangeEnd,
      clientNotes: clientNotes ?? this.clientNotes,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      completedBooking: completedBooking ?? this.completedBooking,
      selectedPaymentMethod: selectedPaymentMethod ?? this.selectedPaymentMethod,
      paymentReference: paymentReference ?? this.paymentReference,
      paymentSender: paymentSender ?? this.paymentSender,
    );
  }
  */

  // Gene - Nov, 22, 2026: Extended copyWith with clearStaff, clearError, intakeResponses, hasMissingRequiredIntake, and errorMessage
  BookingWizardState copyWith({
    int? currentStep,
    ServiceItem? selectedService,
    BusinessStaff? selectedStaff,
    DateTime? selectedDate,
    TimeSlot? selectedSlot,
    DateTime? dateRangeStart,
    DateTime? dateRangeEnd,
    String? clientNotes,
    bool? isSubmitting,
    Booking? completedBooking,
    bool clearSlot = false,
    bool clearStaff = false,
    bool clearError = false,
    String? selectedPaymentMethod,
    String? paymentReference,
    String? paymentSender,
    bool? hasIntakeBlocker,
    Map<String, dynamic>? intakeResponses,
    bool? hasMissingRequiredIntake,
    String? errorMessage,
  }) {
    return BookingWizardState(
      currentStep: currentStep ?? this.currentStep,
      selectedService: selectedService ?? this.selectedService,
      selectedStaff: clearStaff ? null : (selectedStaff ?? this.selectedStaff),
      selectedDate: selectedDate ?? this.selectedDate,
      selectedSlot: clearSlot ? null : (selectedSlot ?? this.selectedSlot),
      dateRangeStart: dateRangeStart ?? this.dateRangeStart,
      dateRangeEnd: dateRangeEnd ?? this.dateRangeEnd,
      clientNotes: clientNotes ?? this.clientNotes,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      completedBooking: completedBooking ?? this.completedBooking,
      selectedPaymentMethod: selectedPaymentMethod ?? this.selectedPaymentMethod,
      paymentReference: paymentReference ?? this.paymentReference,
      paymentSender: paymentSender ?? this.paymentSender,
      hasIntakeBlocker: hasIntakeBlocker ?? this.hasIntakeBlocker,
      intakeResponses: intakeResponses ?? this.intakeResponses,
      hasMissingRequiredIntake: hasMissingRequiredIntake ?? this.hasMissingRequiredIntake,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class BookingWizardNotifier extends StateNotifier<BookingWizardState> {
  final Ref ref;
  final Business business;

  static String _initialPaymentMethod(Business business) {
    final cfg = business.paymentMethodsConfig;
    if (cfg['stripe_enabled'] != false) return 'stripe_card';
    if (cfg['gcash_enabled'] == true) return 'gcash';
    if (cfg['maya_enabled'] == true) return 'maya';
    if (cfg['bank_enabled'] == true) return 'bank_transfer';
    return 'stripe_card';
  }

  BookingWizardNotifier(this.ref, this.business)
      : super(
          BookingWizardState(
            selectedPaymentMethod: _initialPaymentMethod(business),
          ),
        );

  void selectService(ServiceItem service) {
    state = state.copyWith(selectedService: service, clearError: true);
  }

  void selectStaff(BusinessStaff? staff) {
    state = state.copyWith(
      selectedStaff: staff,
      clearStaff: staff == null,
      clearSlot: true,
      clearError: true,
    );
  }

  void selectDate(DateTime date) {
    state = state.copyWith(selectedDate: date, clearSlot: true, clearError: true);
  }

  void selectSlot(TimeSlot slot) {
    state = state.copyWith(selectedSlot: slot, clearError: true);
  }

  void selectDateRange(DateTime start, DateTime end) {
    state = state.copyWith(dateRangeStart: start, dateRangeEnd: end, clearError: true);
  }

  void updateNotes(String notes) {
    state = state.copyWith(clientNotes: notes);
  }

  void updateIntakeResponses(
    Map<String, dynamic> responses, {
    required bool hasMissingRequired,
  }) {
    state = state.copyWith(
      intakeResponses: Map<String, dynamic>.unmodifiable(responses),
      hasMissingRequiredIntake: hasMissingRequired,
    );
  }

  // Gene - Nov 07, 2026: Added state updaters for hybrid payment method, reference number, and sender account
  void selectPaymentMethod(String method) {
    state = state.copyWith(selectedPaymentMethod: method, clearError: true);
  }

  void updatePaymentReference(String reference) {
    state = state.copyWith(paymentReference: reference, clearError: true);
  }

  void updatePaymentSender(String sender) {
    state = state.copyWith(paymentSender: sender, clearError: true);
  }

  void clearError() {
    if (state.errorMessage != null) {
      state = state.copyWith(clearError: true);
    }
  }

  // Gene - Nov, 7, 2026: Added setIntakeBlocker, goToStep, and reset helpers for wizard lifecycle and step navigation
  void setIntakeBlocker(bool value) {
    if (state.hasIntakeBlocker != value) {
      state = state.copyWith(hasIntakeBlocker: value);
    }
  }

  bool get canProceedToNextStep => state.canProceed(
        business.bookingModel,
        minDays: business.minDays,
        maxDays: business.maxDays,
      );

  void goToStep(int step) {
    if (step >= 0 && step < state.currentStep) {
      state = state.copyWith(currentStep: step, clearError: true);
    }
  }

  void reset() {
    state = BookingWizardState(
      selectedPaymentMethod: _initialPaymentMethod(business),
    );
  }

  void nextStep() {
    if (canProceedToNextStep) {
      state = state.copyWith(currentStep: state.currentStep + 1, clearError: true);
    }
  }

  void prevStep() {
    if (state.currentStep > 0) {
      state = state.copyWith(currentStep: state.currentStep - 1, clearError: true);
    }
  }

  /*
  Future<bool> confirmBooking() async {
    state = state.copyWith(isSubmitting: true);
    try {
      final user = ref.read(authProvider).user;
      final clientId = user?.id ?? 'guest-client-${const Uuid().v4()}';
      final clientName = user?.fullName ?? 'Patient';

      final booking = Booking(
        id: const Uuid().v4(),
        businessId: business.id,
        clientId: clientId,
        serviceId: state.selectedService?.id,
        staffId: state.selectedStaff?.id,
        bookingModel: business.bookingModel.toDbString(),
        startTime: state.selectedSlot?.startTime,
        endTime: state.selectedSlot?.endTime,
        dateFrom: business.bookingModel == BookingModelType.slotBased
            ? null
            : (state.dateRangeStart ?? state.selectedDate),
        dateTo: business.bookingModel == BookingModelType.dateRange
            ? state.dateRangeEnd
            : null,
        status: business.requiresApproval ? 'pending' : 'confirmed',
        totalPrice: state.calculateTotalPrice(),
        clientNotes: state.clientNotes,
        createdAt: DateTime.now(),
        businessName: business.name,
        serviceName: state.selectedService?.name,
        staffName: state.selectedStaff?.name,
        clientName: clientName,
      );

      await ref.read(bookingsProvider.notifier).createBooking(booking);
      state = state.copyWith(isSubmitting: false, completedBooking: booking, currentStep: 3);
      return true;
    } catch (_) {
      state = state.copyWith(isSubmitting: false);
      return false;
    }
  }
  */

  // Gene - Nov, 22, 2026: Live auth guard, valid 'unpaid' paymentStatus, intakeResponses JSONB, dynamic currency & clientLabel, and actionable error messages
  Future<bool> confirmBooking() async {
    state = state.copyWith(isSubmitting: true, clearError: true);
    try {
      final user = ref.read(authProvider).user;
      final isLiveOrRelease =
          SupabaseService.client != null || !SupabaseConfig.isDemoModeEnabled;
      if (isLiveOrRelease && user == null) {
        state = state.copyWith(
          isSubmitting: false,
          errorMessage: 'Please sign in to complete your booking.',
        );
        return false;
      }

      final clientId = user?.id ?? 'guest-client-${const Uuid().v4()}';
      final clientName = user?.fullName ?? business.clientLabel;

      final booking = Booking(
        id: const Uuid().v4(),
        businessId: business.id,
        clientId: clientId,
        serviceId: state.selectedService?.id,
        staffId: state.selectedStaff?.id,
        bookingModel: business.bookingModel.toDbString(),
        startTime: state.selectedSlot?.startTime,
        endTime: state.selectedSlot?.endTime,
        dateFrom: business.bookingModel == BookingModelType.slotBased
            ? null
            : (state.dateRangeStart ?? state.selectedDate),
        dateTo: business.bookingModel == BookingModelType.dateRange
            ? state.dateRangeEnd
            : null,
        status: business.requiresApproval ? 'pending' : 'confirmed',
        totalPrice: state.calculateTotalPrice(),
        clientNotes: state.clientNotes,
        createdAt: DateTime.now(),
        businessName: business.name,
        serviceName: state.selectedService?.name,
        staffName: state.selectedStaff?.name,
        clientName: clientName,
        intakeResponses: state.intakeResponses,
        currency: business.currency,
      );

      final created = await ref.read(bookingsProvider.notifier).createBooking(booking);
      state = state.copyWith(isSubmitting: false, completedBooking: created, currentStep: 4, clearError: true);
      return true;
    } catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      );
      return false;
    }
  }

  Future<bool> proceedToPaymentAndConfirm(PaymentService paymentService) async {
    state = state.copyWith(isSubmitting: true, clearError: true);
    try {
      final user = ref.read(authProvider).user;
      final isLiveOrRelease =
          SupabaseService.client != null || !SupabaseConfig.isDemoModeEnabled;
      if (isLiveOrRelease && user == null) {
        state = state.copyWith(
          isSubmitting: false,
          errorMessage: 'Please sign in to complete your booking.',
        );
        return false;
      }

      final clientId = user?.id ?? 'guest-client-${const Uuid().v4()}';
      final clientName = user?.fullName ?? business.clientLabel;

      final bookingId = const Uuid().v4();
      final total = state.calculateTotalPrice();
      final deposit = state.dueTodayAmount;
      final isPayAtVenue = state.isPayAtVenue || deposit == 0.0;

      final method = state.selectedPaymentMethod;
      final refNum = state.paymentReference.trim().isNotEmpty ? state.paymentReference.trim() : null;
      final sender = state.paymentSender.trim().isNotEmpty ? state.paymentSender.trim() : null;

      if (!isPayAtVenue &&
          method != 'stripe_card' &&
          !SupabaseConfig.isDemoModeEnabled &&
          refNum == null) {
        state = state.copyWith(
          isSubmitting: false,
          errorMessage: 'Please enter the transaction reference number to proceed.',
        );
        return false;
      }

      final booking = Booking(
        id: bookingId,
        businessId: business.id,
        clientId: clientId,
        serviceId: state.selectedService?.id,
        staffId: state.selectedStaff?.id,
        bookingModel: business.bookingModel.toDbString(),
        startTime: state.selectedSlot?.startTime,
        endTime: state.selectedSlot?.endTime,
        dateFrom: business.bookingModel == BookingModelType.slotBased
            ? null
            : (state.dateRangeStart ?? state.selectedDate),
        dateTo: business.bookingModel == BookingModelType.dateRange
            ? state.dateRangeEnd
            : null,
        status: isPayAtVenue ? (business.requiresApproval ? 'pending' : 'confirmed') : 'awaiting_payment',
        totalPrice: total,
        clientNotes: state.clientNotes,
        createdAt: DateTime.now(),
        businessName: business.name,
        serviceName: state.selectedService?.name,
        staffName: state.selectedStaff?.name,
        clientName: clientName,
        paymentStatus: 'unpaid',
        amountPaid: 0.0,
        amountDue: total,
        intakeResponses: state.intakeResponses,
        currency: business.currency,
      );

      final created = await ref.read(bookingsProvider.notifier).createBooking(booking);

      if (isPayAtVenue) {
        state = state.copyWith(isSubmitting: false, completedBooking: created, currentStep: 4, clearError: true);
        return true;
      }

      final webOrigin = kIsWeb ? Uri.base.origin : '';
      final effectiveReturnUrl = kIsWeb && webOrigin.startsWith('http')
          ? '$webOrigin/my-bookings?booking_id=$bookingId&status=success'
          : 'bookit://booking-success?id=$bookingId';
      final effectiveCancelUrl = kIsWeb && webOrigin.startsWith('http')
          ? '$webOrigin/book/${business.id}?cancelled=true'
          : 'bookit://booking-cancel?id=$bookingId';

      await paymentService.initiateCheckout(
        bookingId: bookingId,
        returnUrl: effectiveReturnUrl,
        cancelUrl: effectiveCancelUrl,
        paymentMethod: method,
        referenceNumber: refNum,
        senderAccount: sender,
        onSuccess: (isMock) {
          final updatedList = ref.read(bookingsProvider);
          final updated = updatedList.firstWhere(
            (b) => b.id == bookingId,
            orElse: () => created.copyWith(
              status: business.requiresApproval ? 'pending' : 'confirmed',
              paymentStatus: deposit < total ? 'deposit_paid' : 'paid_in_full',
              amountPaid: deposit,
              amountDue: total - deposit,
              paymentMethod: method,
              paymentReference: refNum,
              paymentSender: sender,
            ),
          );
          state = state.copyWith(isSubmitting: false, completedBooking: updated, currentStep: 4, clearError: true);
        },
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      );
      return false;
    }
  }
}

final bookingWizardProvider = StateNotifierProvider.family<BookingWizardNotifier, BookingWizardState, Business>((ref, business) {
  return BookingWizardNotifier(ref, business);
});
