// Gene - Nov, 03, 2026: Universal dynamic booking wizard screen switching steps based on business template
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/neumorphic_colors.dart';
import '../../../../core/widgets/neumorphic_container.dart';
import '../../../../core/widgets/neumorphic_button.dart';
import '../../../../models/business.dart';
import '../../../../services/business_service.dart';
import '../../../../services/booking_service.dart';
import '../providers/booking_wizard_provider.dart';
import 'steps/select_service_step.dart';
import 'steps/slot_time_picker_step.dart';
import 'steps/date_range_picker_step.dart';
import 'steps/daily_picker_step.dart';
import 'steps/client_intake_step.dart';
import 'steps/booking_confirmation_step.dart';
import 'steps/payment_checkout_step.dart';
import '../../../../services/payment_service.dart';

class UniversalBookingScreen extends ConsumerWidget {
  final String businessId;

  const UniversalBookingScreen({super.key, required this.businessId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final businessAsync = ref.watch(businessDetailProvider(businessId));
    final servicesAsync = ref.watch(businessServicesProvider(businessId));
    final staffAsync = ref.watch(businessStaffProvider(businessId));
    final allBookings = ref.watch(bookingsProvider);

    // final isDark = Theme.of(context).brightness == Brightness.dark;
    // final accent = isDark ? NeumorphicColors.tealLight : NeumorphicColors.tealPrimary;

    return businessAsync.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('Error loading business: $e'))),
      data: (business) {
        if (business == null) {
          return const Scaffold(body: Center(child: Text('Business not found')));
        }

        final wizardState = ref.watch(bookingWizardProvider(business));
        final wizardNotifier = ref.read(bookingWizardProvider(business).notifier);

        final services = servicesAsync.value ?? [];
        final staff = staffAsync.value ?? [];

        return Scaffold(
          /*
          appBar: AppBar(
            title: Text(
              wizardState.currentStep == 3 ? 'Confirmed' : 'Book at ${business.name}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, size: 18),
              onPressed: () {
                if (wizardState.currentStep > 0 && wizardState.currentStep < 3) {
                  wizardNotifier.prevStep();
                } else {
                  context.pop();
                }
              },
            ),
          ),
          */
          // Gene - Nov, 04, 2026: Integrated PaymentCheckoutStep into universal booking wizard and enhanced confirmation receipt
          appBar: AppBar(
            title: Text(
              wizardState.currentStep == 4 ? 'Confirmed' : 'Book at ${business.name}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, size: 18),
              onPressed: () {
                if (wizardState.currentStep > 0 && wizardState.currentStep < 4) {
                  wizardNotifier.prevStep();
                } else {
                  context.pop();
                }
              },
            ),
          ),
          body: SafeArea(
            child: Column(
              children: [
                /*
                // Step Progress Indicator (Steps 0, 1, 2)
                if (wizardState.currentStep < 3) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: Row(
                      children: [
                        _buildStepNode(context, step: 0, currentStep: wizardState.currentStep, label: 'Service'),
                        _buildStepLine(context, isActive: wizardState.currentStep > 0),
                        _buildStepNode(context, step: 1, currentStep: wizardState.currentStep, label: 'Schedule'),
                        _buildStepLine(context, isActive: wizardState.currentStep > 1),
                        _buildStepNode(context, step: 2, currentStep: wizardState.currentStep, label: 'Details'),
                      ],
                    ),
                  ),
                ],
                */
                // Gene - Nov, 04, 2026: Integrated PaymentCheckoutStep into universal booking wizard and enhanced confirmation receipt
                if (wizardState.currentStep < 4) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: Row(
                      children: [
                        _buildStepNode(context, step: 0, currentStep: wizardState.currentStep, label: 'Service'),
                        _buildStepLine(context, isActive: wizardState.currentStep > 0),
                        _buildStepNode(context, step: 1, currentStep: wizardState.currentStep, label: 'Schedule'),
                        _buildStepLine(context, isActive: wizardState.currentStep > 1),
                        _buildStepNode(context, step: 2, currentStep: wizardState.currentStep, label: 'Intake'),
                        _buildStepLine(context, isActive: wizardState.currentStep > 2),
                        _buildStepNode(context, step: 3, currentStep: wizardState.currentStep, label: 'Payment'),
                      ],
                    ),
                  ),
                ],

                // Step Body
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Builder(
                      builder: (context) {
                        switch (wizardState.currentStep) {
                          case 0:
                            return SelectServiceStep(
                              services: services,
                              selectedService: wizardState.selectedService,
                              onSelect: (srv) {
                                wizardNotifier.selectService(srv);
                              },
                            );

                          case 1:
                            // Dynamic Scheduling Step based on business.bookingModel
                            switch (business.bookingModel) {
                              case BookingModelType.slotBased:
                                /*
                                return SlotTimePickerStep(
                                  business: business,
                                  staffList: staff,
                                  existingBookings: allBookings.where((b) => b.businessId == business.id).toList(),
                                  selectedDate: wizardState.selectedDate,
                                  selectedSlot: wizardState.selectedSlot,
                                  selectedStaff: wizardState.selectedStaff,
                                  onDateSelected: wizardNotifier.selectDate,
                                  onSlotSelected: wizardNotifier.selectSlot,
                                  onStaffSelected: wizardNotifier.selectStaff,
                                );
                                */
                                // Gene - Nov 07, 2026: Pass selectedService?.durationMinutes to SlotTimePickerStep for accurate slot duration & buffer checks
                                return SlotTimePickerStep(
                                  business: business,
                                  staffList: staff,
                                  existingBookings: allBookings.where((b) => b.businessId == business.id).toList(),
                                  selectedDate: wizardState.selectedDate,
                                  selectedSlot: wizardState.selectedSlot,
                                  selectedStaff: wizardState.selectedStaff,
                                  serviceDurationMinutes: wizardState.selectedService?.durationMinutes,
                                  onDateSelected: wizardNotifier.selectDate,
                                  onSlotSelected: wizardNotifier.selectSlot,
                                  onStaffSelected: wizardNotifier.selectStaff,
                                );

                              case BookingModelType.dateRange:
                                return DateRangePickerStep(
                                  business: business,
                                  service: wizardState.selectedService,
                                  startDate: wizardState.dateRangeStart,
                                  endDate: wizardState.dateRangeEnd,
                                  onRangeSelected: wizardNotifier.selectDateRange,
                                );

                              case BookingModelType.daily:
                                return DailyPickerStep(
                                  business: business,
                                  selectedDate: wizardState.selectedDate,
                                  onDateSelected: wizardNotifier.selectDate,
                                );
                            }

                          /*
                          // Gene - Nov, 03, 2026: Previous ClientIntakeStep without business template binding
                          case 2:
                            return ClientIntakeStep(
                              service: wizardState.selectedService,
                              initialNotes: wizardState.clientNotes,
                              onNotesChanged: wizardNotifier.updateNotes,
                            );
                          */
                          // Gene - Nov, 04, 2026: Passed business instance for dynamic template intake fields
                          case 2:
                            return ClientIntakeStep(
                              business: business,
                              service: wizardState.selectedService,
                              initialNotes: wizardState.clientNotes,
                              onNotesChanged: wizardNotifier.updateNotes,
                            );

                          /*
                          case 3:
                          default:
                            if (wizardState.completedBooking != null) {
                              return BookingConfirmationStep(
                                booking: wizardState.completedBooking!,
                                onViewBookings: () {
                                  context.go('/my-bookings');
                                },
                              );
                            }
                            return const Center(child: Text('Booking finalized'));
                          */
                          /*
                          // Gene - Nov, 04, 2026: Added Step 3 as Payment Review Step and moved Confirmation to Step 4
                          case 3:
                            return PaymentCheckoutStep(
                              service: wizardState.selectedService,
                              totalPrice: wizardState.calculateTotalPrice(),
                              dueToday: wizardState.dueTodayAmount,
                              dueAtVenue: wizardState.dueAtVenueAmount,
                              practitionerName: wizardState.selectedStaff?.name,
                              isLoading: wizardState.isSubmitting,
                              onProceed: () async {
                                final paymentService = ref.read(paymentServiceProvider);
                                await wizardNotifier.proceedToPaymentAndConfirm(paymentService);
                              },
                            );
                          */
                          // Gene - Nov 07, 2026: Bound business and hybrid payment method/reference/sender state to PaymentCheckoutStep
                          case 3:
                            return PaymentCheckoutStep(
                              business: business,
                              service: wizardState.selectedService,
                              totalPrice: wizardState.calculateTotalPrice(),
                              dueToday: wizardState.dueTodayAmount,
                              dueAtVenue: wizardState.dueAtVenueAmount,
                              practitionerName: wizardState.selectedStaff?.name,
                              isLoading: wizardState.isSubmitting,
                              selectedPaymentMethod: wizardState.selectedPaymentMethod,
                              onPaymentMethodChanged: wizardNotifier.selectPaymentMethod,
                              initialReferenceNumber: wizardState.paymentReference,
                              onReferenceNumberChanged: wizardNotifier.updatePaymentReference,
                              initialSenderAccount: wizardState.paymentSender,
                              onSenderAccountChanged: wizardNotifier.updatePaymentSender,
                              onProceed: () async {
                                final paymentService = ref.read(paymentServiceProvider);
                                await wizardNotifier.proceedToPaymentAndConfirm(paymentService);
                              },
                            );

                          case 4:
                          default:
                            if (wizardState.completedBooking != null) {
                              return BookingConfirmationStep(
                                booking: wizardState.completedBooking!,
                                onViewBookings: () {
                                  context.go('/my-bookings');
                                },
                              );
                            }
                            return const Center(child: Text('Booking finalized'));
                        }
                      },
                    ),
                  ),
                ),

                /*
                // Bottom Action Bar (Steps 0, 1, 2)
                if (wizardState.currentStep < 3) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    child: Row(
                      children: [
                        if (wizardState.currentStep > 0) ...[
                          Expanded(
                            flex: 1,
                            child: NeumorphicButton(
                              onPressed: wizardNotifier.prevStep,
                              child: const Text('Back'),
                            ),
                          ),
                          const SizedBox(width: 14),
                        ],
                        Expanded(
                          flex: 2,
                          child: NeumorphicButton(
                            isPrimary: true,
                            isLoading: wizardState.isSubmitting,
                            onPressed: wizardState.canProceed(business.bookingModel)
                                ? () {
                                    if (wizardState.currentStep == 2) {
                                      wizardNotifier.confirmBooking();
                                    } else {
                                      wizardNotifier.nextStep();
                                    }
                                  }
                                : null,
                            child: Text(
                              wizardState.currentStep == 2
                                  ? 'Confirm & Pay (${business.bookingModel == BookingModelType.dateRange ? '\$${wizardState.calculateTotalPrice().toStringAsFixed(0)}' : wizardState.selectedService?.formattedPrice ?? ''})'
                                  : 'Continue',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                */
                // Gene - Nov, 04, 2026: Updated Bottom Action Bar to advance from Step 2 to Step 3 payment review
                if (wizardState.currentStep < 3) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    child: Row(
                      children: [
                        if (wizardState.currentStep > 0) ...[
                          Expanded(
                            flex: 1,
                            child: NeumorphicButton(
                              onPressed: wizardNotifier.prevStep,
                              child: const Text('Back'),
                            ),
                          ),
                          const SizedBox(width: 14),
                        ],
                        Expanded(
                          flex: 2,
                          child: NeumorphicButton(
                            isPrimary: true,
                            isLoading: wizardState.isSubmitting,
                            onPressed: wizardState.canProceed(business.bookingModel)
                                ? () {
                                    wizardNotifier.nextStep();
                                  }
                                : null,
                            child: Text(
                              wizardState.currentStep == 2
                                  ? 'Review & Pay (${business.bookingModel == BookingModelType.dateRange ? '\$${wizardState.calculateTotalPrice().toStringAsFixed(0)}' : wizardState.selectedService?.formattedPrice ?? ''})'
                                  : 'Continue',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStepNode(BuildContext context, {required int step, required int currentStep, required String label}) {
    final isDone = currentStep > step;
    final isCurrent = currentStep == step;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? NeumorphicColors.tealLight : NeumorphicColors.tealPrimary;

    return Column(
      children: [
        NeumorphicContainer(
          isCircle: true,
          width: 30,
          height: 30,
          isInset: isCurrent,
          border: isCurrent ? Border.all(color: accent, width: 2) : null,
          color: isDone ? accent : null,
          child: Center(
            child: isDone
                ? const Icon(Icons.check, size: 16, color: Colors.white)
                : Text(
                    '${step + 1}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: isCurrent ? accent : (isDark ? Colors.white60 : Colors.black54),
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
            color: isCurrent ? accent : (isDark ? Colors.white38 : Colors.black38),
          ),
        ),
      ],
    );
  }

  Widget _buildStepLine(BuildContext context, {required bool isActive}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? NeumorphicColors.tealLight : NeumorphicColors.tealPrimary;

    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
        color: isActive ? accent : (isDark ? Colors.white12 : Colors.black12),
      ),
    );
  }
}
