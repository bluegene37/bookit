// Gene - Nov, 03, 2026: Universal dynamic booking wizard screen switching steps based on business template
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/neumorphic_colors.dart';
import '../../../../core/widgets/neumorphic_container.dart';
import '../../../../core/widgets/neumorphic_button.dart';
import '../../../../models/business.dart';
// Gene - Nov, 22, 2026: Added PlatformConfig and PlatformConfigService imports for DB-driven payment channels and multi-currency formatting
import '../../../../models/platform_config.dart';
import '../../../../services/platform_config_service.dart';
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
          // Gene - Nov, 22, 2026: Provide actionable return CTA when business ID cannot be loaded
          return Scaffold(
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.storefront_outlined, size: 48),
                    const SizedBox(height: 12),
                    const Text(
                      'Business not found',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 16),
                    NeumorphicButton(
                      isPrimary: true,
                      onPressed: () => context.go('/'),
                      child: const Text('Back to Explore'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        final wizardState = ref.watch(bookingWizardProvider(business));
        final wizardNotifier = ref.read(bookingWizardProvider(business).notifier);
        final platformConfig = ref.watch(activePlatformConfigProvider);

        // final services = servicesAsync.value ?? [];
        // final staff = staffAsync.value ?? [];
        // Gene - Nov, 7, 2026: Use valueOrNull instead of value to prevent rethrowing AsyncError during widget build
        final services = servicesAsync.valueOrNull ?? [];
        final staff = staffAsync.valueOrNull ?? [];

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
            // Gene - Nov, 04, 2026: AppBar leading without tooltip or deep-link GoRouter.canPop() safety
            // leading: IconButton(
            //   icon: const Icon(Icons.arrow_back_ios_new, size: 18),
            //   onPressed: () {
            //     if (wizardState.currentStep > 0 && wizardState.currentStep < 4) {
            //       wizardNotifier.prevStep();
            //     } else {
            //       // Gene - Nov, 7, 2026: Reset completed wizard state when exiting Step 4 so subsequent bookings start cleanly at Step 0
            //       if (wizardState.currentStep == 4) {
            //         wizardNotifier.reset();
            //       }
            //       context.pop();
            //     }
            //   },
            // ),
            // Gene - Nov, 14, 2026: Added semantic tooltip and canPop() fallback to '/' on cold-start deep links
            leading: IconButton(
              tooltip: 'Back',
              icon: const Icon(Icons.arrow_back_ios_new, size: 18),
              onPressed: () {
                if (wizardState.currentStep > 0 && wizardState.currentStep < 4) {
                  wizardNotifier.prevStep();
                } else {
                  if (wizardState.currentStep == 4) {
                    wizardNotifier.reset();
                  }
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    context.go('/');
                  }
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
                /*
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
                */
                // Gene - Nov, 7, 2026: Made completed step indicator nodes tappable so users can jump back to earlier steps directly
                if (wizardState.currentStep < 4) ...[
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: MediaQuery.sizeOf(context).width < 380 ? 10 : 20, vertical: 8),
                    /*
                    // Gene - Nov, 7, 2026: Step indicator Row without Expanded step nodes overflowed 320px @ 1.5x
                    child: Row(
                      children: [
                        _buildStepNode(
                          context,
                          step: 0,
                          currentStep: wizardState.currentStep,
                          label: 'Service',
                          onTap: wizardState.currentStep > 0 ? () => wizardNotifier.goToStep(0) : null,
                        ),
                        _buildStepLine(context, isActive: wizardState.currentStep > 0),
                        _buildStepNode(
                          context,
                          step: 1,
                          currentStep: wizardState.currentStep,
                          label: 'Schedule',
                          onTap: wizardState.currentStep > 1 ? () => wizardNotifier.goToStep(1) : null,
                        ),
                        _buildStepLine(context, isActive: wizardState.currentStep > 1),
                        _buildStepNode(
                          context,
                          step: 2,
                          currentStep: wizardState.currentStep,
                          label: 'Intake',
                          onTap: wizardState.currentStep > 2 ? () => wizardNotifier.goToStep(2) : null,
                        ),
                        _buildStepLine(context, isActive: wizardState.currentStep > 2),
                        _buildStepNode(
                          context,
                          step: 3,
                          currentStep: wizardState.currentStep,
                          label: 'Payment',
                        ),
                      ],
                    ),
                    */
                    // Gene - Nov, 14, 2026: Wrapped step nodes in Expanded so all 4 step columns share narrow 320px @ 1.5x widths cleanly
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildStepNode(
                            context,
                            step: 0,
                            currentStep: wizardState.currentStep,
                            label: 'Service',
                            onTap: wizardState.currentStep > 0 ? () => wizardNotifier.goToStep(0) : null,
                          ),
                        ),
                        _buildStepLine(context, isActive: wizardState.currentStep > 0),
                        Expanded(
                          child: _buildStepNode(
                            context,
                            step: 1,
                            currentStep: wizardState.currentStep,
                            label: 'Schedule',
                            onTap: wizardState.currentStep > 1 ? () => wizardNotifier.goToStep(1) : null,
                          ),
                        ),
                        _buildStepLine(context, isActive: wizardState.currentStep > 1),
                        Expanded(
                          child: _buildStepNode(
                            context,
                            step: 2,
                            currentStep: wizardState.currentStep,
                            label: 'Intake',
                            onTap: wizardState.currentStep > 2 ? () => wizardNotifier.goToStep(2) : null,
                          ),
                        ),
                        _buildStepLine(context, isActive: wizardState.currentStep > 2),
                        Expanded(
                          child: _buildStepNode(
                            context,
                            step: 3,
                            currentStep: wizardState.currentStep,
                            label: 'Payment',
                          ),
                        ),
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
                                  minDays: business.minDays,
                                  maxDays: business.maxDays,
                                  onRangeSelected: wizardNotifier.selectDateRange,
                                );

                              case BookingModelType.daily:
                                return DailyPickerStep(
                                  business: business,
                                  selectedDate: wizardState.selectedDate,
                                  onDateSelected: wizardNotifier.selectDate,
                                );
                            }

                          // Gene - Nov, 22, 2026: Pass initialResponses, onResponsesChanged, and onValidationChanged to persist Step 2 answers & gate required fields
                          case 2:
                            return ClientIntakeStep(
                              business: business,
                              service: wizardState.selectedService,
                              initialNotes: wizardState.clientNotes,
                              onNotesChanged: wizardNotifier.updateNotes,
                              onBlockerChanged: wizardNotifier.setIntakeBlocker,
                              initialResponses: wizardState.intakeResponses,
                              onResponsesChanged: (responses) => wizardNotifier.updateIntakeResponses(
                                responses,
                                hasMissingRequired: wizardState.hasMissingRequiredIntake,
                              ),
                              onValidationChanged: (hasMissing) => wizardNotifier.updateIntakeResponses(
                                wizardState.intakeResponses,
                                hasMissingRequired: hasMissing,
                              ),
                            );

                          case 3:
                            return PaymentCheckoutStep(
                              business: business,
                              platformConfig: platformConfig,
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
                              /*
                              return BookingConfirmationStep(
                                booking: wizardState.completedBooking!,
                                onViewBookings: () {
                                  context.go('/my-bookings');
                                },
                              );
                              */
                              // Gene - Nov, 7, 2026: Reset wizard state when viewing bookings or starting another booking from confirmation receipt
                              return BookingConfirmationStep(
                                booking: wizardState.completedBooking!,
                                onViewBookings: () {
                                  wizardNotifier.reset();
                                  context.go('/my-bookings');
                                },
                                onBookAnother: () {
                                  wizardNotifier.reset();
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
                            // Gene - Nov, 22, 2026: Use canProceedToNextStep (honoring min/max nights & required intake) + currency formatter
                            onPressed: wizardNotifier.canProceedToNextStep
                                ? () {
                                    wizardNotifier.nextStep();
                                  }
                                : null,
                            child: Text(
                              wizardState.currentStep == 2
                                  ? 'Review & Pay (${business.bookingModel == BookingModelType.dateRange ? PlatformConfig.formatCurrency(wizardState.calculateTotalPrice(), currencyCode: business.currency, decimals: 0, currencies: platformConfig.supportedCurrencies) : wizardState.selectedService?.formattedPrice ?? ''})'
                                  : 'Continue',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                // Gene - Nov, 22, 2026: Surface wizard validation/auth/payment error banner with Sign In shortcut when unauthenticated
                if (wizardState.errorMessage != null && wizardState.currentStep < 4) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: NeumorphicColors.error.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: NeumorphicColors.error.withValues(alpha: 0.4)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.error_outline, size: 18, color: NeumorphicColors.error),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              wizardState.errorMessage!,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: NeumorphicColors.error,
                              ),
                            ),
                          ),
                          if (wizardState.errorMessage!.toLowerCase().contains('sign in'))
                            TextButton(
                              onPressed: () => context.push('/login'),
                              child: const Text('Sign In'),
                            ),
                        ],
                      ),
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

  /*
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
  */

  // Gene - Nov, 7, 2026: Added optional onTap to _buildStepNode so completed steps can be tapped to navigate back
  Widget _buildStepNode(
    BuildContext context, {
    required int step,
    required int currentStep,
    required String label,
    VoidCallback? onTap,
  }) {
    final isDone = currentStep > step;
    final isCurrent = currentStep == step;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? NeumorphicColors.tealLight : NeumorphicColors.tealPrimary;

    final node = Column(
      children: [
        NeumorphicContainer(
          isCircle: true,
          width: 30,
          height: 30,
          isInset: isCurrent,
          border: isCurrent ? Border.all(color: accent, width: 2) : null,
          color: isDone ? accent : null,
          onTap: onTap,
                  child: Center(
                    child: isDone
                        ? const Icon(Icons.check, size: 16, color: Colors.white)
                        : Text(
                            '${step + 1}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              // color: isCurrent ? accent : (isDark ? Colors.white60 : Colors.black54),
                              // Gene - Nov, 14, 2026: Upgraded inactive step number contrast to WCAG AA secondary tokens
                              color: isCurrent
                                  ? accent
                                  : (isDark ? NeumorphicColors.darkTextSecondary : NeumorphicColors.lightTextSecondary),
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
                    // color: isCurrent ? accent : (isDark ? Colors.white38 : Colors.black38),
                    // Gene - Nov, 14, 2026: Upgraded inactive step label contrast to WCAG AA muted tokens with ellipsis clamp
                    color: isCurrent ? accent : (isDark ? NeumorphicColors.darkTextMuted : NeumorphicColors.lightTextMuted),
                  ),
                ),
              ],
            );

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: node,
      );
    }
    return node;
  }

  Widget _buildStepLine(BuildContext context, {required bool isActive}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? NeumorphicColors.tealLight : NeumorphicColors.tealPrimary;

    /*
    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
        color: isActive ? accent : (isDark ? Colors.white12 : Colors.black12),
      ),
    );
    */
    // Gene - Nov, 14, 2026: Use bounded width connector line so Expanded step nodes share horizontal budget evenly
    return SizedBox(
      width: MediaQuery.sizeOf(context).width < 420 ? 8 : 24,
      child: Container(
        height: 2,
        margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 10),
        color: isActive ? accent : (isDark ? Colors.white12 : Colors.black12),
      ),
    );
  }
}
