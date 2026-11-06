// Gene - Nov, 03, 2026: Universal dynamic booking wizard state manager and provider
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

  double calculateTotalPrice() {
    if (selectedService == null) return 0.0;
    if (dateRangeStart != null && dateRangeEnd != null) {
      final days = dateRangeEnd!.difference(dateRangeStart!).inDays;
      final count = days <= 0 ? 1 : days;
      return selectedService!.price * count;
    }
    return selectedService!.price;
  }

  // Gene - Nov, 04, 2026: Added deposit and balance calculations to wizard state
  double get dueTodayAmount {
    if (selectedService == null) return 0.0;
    return selectedService!.calculateDepositAmount();
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
