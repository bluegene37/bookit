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

  // Gene - Nov, 7, 2026: Gate Step 2 progression when hasIntakeBlocker is active
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
        return !hasIntakeBlocker;
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

  // Gene - Nov, 7, 2026: Extended copyWith supporting hasIntakeBlocker
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
    bool? hasIntakeBlocker,
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
      hasIntakeBlocker: hasIntakeBlocker ?? this.hasIntakeBlocker,
    );
  }
}

class BookingWizardNotifier extends StateNotifier<BookingWizardState> {
  final Ref ref;
  final Business business;

  BookingWizardNotifier(this.ref, this.business) : super(BookingWizardState());

  void selectService(ServiceItem service) {
    state = state.copyWith(selectedService: service);
  }

  void selectStaff(BusinessStaff? staff) {
    state = state.copyWith(selectedStaff: staff, clearSlot: true);
  }

  void selectDate(DateTime date) {
    state = state.copyWith(selectedDate: date, clearSlot: true);
  }

  void selectSlot(TimeSlot slot) {
    state = state.copyWith(selectedSlot: slot);
  }

  void selectDateRange(DateTime start, DateTime end) {
    state = state.copyWith(dateRangeStart: start, dateRangeEnd: end);
  }

  void updateNotes(String notes) {
    state = state.copyWith(clientNotes: notes);
  }

  // Gene - Nov 07, 2026: Added state updaters for hybrid payment method, reference number, and sender account
  void selectPaymentMethod(String method) {
    state = state.copyWith(selectedPaymentMethod: method);
  }

  void updatePaymentReference(String reference) {
    state = state.copyWith(paymentReference: reference);
  }

  void updatePaymentSender(String sender) {
    state = state.copyWith(paymentSender: sender);
  }

  // Gene - Nov, 7, 2026: Added setIntakeBlocker, goToStep, and reset helpers for wizard lifecycle and step navigation
  void setIntakeBlocker(bool value) {
    if (state.hasIntakeBlocker != value) {
      state = state.copyWith(hasIntakeBlocker: value);
    }
  }

  void goToStep(int step) {
    if (step >= 0 && step < state.currentStep) {
      state = state.copyWith(currentStep: step);
    }
  }

  void reset() {
    state = BookingWizardState();
  }

  void nextStep() {
    if (state.canProceed(business.bookingModel)) {
      state = state.copyWith(currentStep: state.currentStep + 1);
    }
  }

  void prevStep() {
    if (state.currentStep > 0) {
      state = state.copyWith(currentStep: state.currentStep - 1);
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

  // Gene - Nov, 04, 2026: Updated confirmBooking and added proceedToPaymentAndConfirm to advance to Step 4 (Confirmed Receipt)
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

      final created = await ref.read(bookingsProvider.notifier).createBooking(booking);
      state = state.copyWith(isSubmitting: false, completedBooking: created, currentStep: 4);
      return true;
    } catch (_) {
      state = state.copyWith(isSubmitting: false);
      return false;
    }
  }

  // Gene - Nov, 04, 2026: Added proceedToPaymentAndConfirm to coordinate slot creation, Stripe checkout initiation, and final receipt display
  Future<bool> proceedToPaymentAndConfirm(PaymentService paymentService) async {
    state = state.copyWith(isSubmitting: true);
    try {
      final user = ref.read(authProvider).user;
      final clientId = user?.id ?? 'guest-client-${const Uuid().v4()}';
      final clientName = user?.fullName ?? 'Patient';

      final bookingId = const Uuid().v4();
      final total = state.calculateTotalPrice();
      final deposit = state.dueTodayAmount;
      final isPayAtVenue = state.isPayAtVenue || deposit == 0.0;

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
        paymentStatus: isPayAtVenue ? 'unpaid' : 'awaiting_payment',
        amountPaid: 0.0,
        amountDue: total,
      );

      final created = await ref.read(bookingsProvider.notifier).createBooking(booking);

      if (isPayAtVenue) {
        state = state.copyWith(isSubmitting: false, completedBooking: created, currentStep: 4);
        return true;
      }

      /*
      await paymentService.initiateCheckout(
        bookingId: bookingId,
        returnUrl: 'bookit://booking-success?id=$bookingId',
        cancelUrl: 'bookit://booking-cancel?id=$bookingId',
        onSuccess: (isMock) {
          final updatedList = ref.read(bookingsProvider);
          final updated = updatedList.firstWhere(
            (b) => b.id == bookingId,
            orElse: () => created.copyWith(
              status: 'confirmed',
              paymentStatus: deposit < total ? 'deposit_paid' : 'paid_in_full',
              amountPaid: deposit,
              amountDue: total - deposit,
            ),
          );
          state = state.copyWith(isSubmitting: false, completedBooking: updated, currentStep: 4);
        },
      );
      */
      // Gene - Nov 07, 2026: Pass selectedPaymentMethod, paymentReference, and paymentSender to initiateCheckout and receipt state
      final method = state.selectedPaymentMethod;
      final refNum = state.paymentReference.trim().isNotEmpty ? state.paymentReference.trim() : null;
      final sender = state.paymentSender.trim().isNotEmpty ? state.paymentSender.trim() : null;

      /*
      // Gene - Nov 07, 2026: Mobile-only custom scheme returnUrl and cancelUrl
      await paymentService.initiateCheckout(
        bookingId: bookingId,
        returnUrl: 'bookit://booking-success?id=$bookingId',
        cancelUrl: 'bookit://booking-cancel?id=$bookingId',
        paymentMethod: method,
        referenceNumber: refNum,
        senderAccount: sender,
        onSuccess: (isMock) {
          final updatedList = ref.read(bookingsProvider);
          final updated = updatedList.firstWhere(
            (b) => b.id == bookingId,
            orElse: () => created.copyWith(
              status: 'confirmed',
              paymentStatus: deposit < total ? 'deposit_paid' : 'paid_in_full',
              amountPaid: deposit,
              amountDue: total - deposit,
              paymentMethod: method,
              paymentReference: refNum,
              paymentSender: sender,
            ),
          );
          state = state.copyWith(isSubmitting: false, completedBooking: updated, currentStep: 4);
        },
      );
      */
      // Gene - Nov, 08, 2026: Use origin-based HTTPS return/cancel URLs on Web for Vercel & Stripe Checkout compatibility while preserving deep links on mobile
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
              status: 'confirmed',
              paymentStatus: deposit < total ? 'deposit_paid' : 'paid_in_full',
              amountPaid: deposit,
              amountDue: total - deposit,
              paymentMethod: method,
              paymentReference: refNum,
              paymentSender: sender,
            ),
          );
          state = state.copyWith(isSubmitting: false, completedBooking: updated, currentStep: 4);
        },
      );
      return true;
    } catch (_) {
      state = state.copyWith(isSubmitting: false);
      return false;
    }
  }
}

final bookingWizardProvider = StateNotifierProvider.family<BookingWizardNotifier, BookingWizardState, Business>((ref, business) {
  return BookingWizardNotifier(ref, business);
});
