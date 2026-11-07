// Gene - Nov 07, 2026: Admin Walk-In & Manual Scheduled Appointment Creation Modal
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/theme/neumorphic_colors.dart';
import '../../../../core/widgets/neumorphic_button.dart';
import '../../../../models/booking.dart';
import '../../../../models/business.dart';
import '../../../../models/business_staff.dart';
import '../../../../models/service_item.dart';
import '../../../../services/booking_service.dart';
import '../../../../services/business_service.dart';
import '../../../../services/crm_service.dart';
import '../../../booking_engine/domain/slot_calculator.dart';

class AdminWalkInBookingDialog extends ConsumerStatefulWidget {
  final Business business;
  final DateTime? initialDate;
  final bool initialWalkInMode;

  const AdminWalkInBookingDialog({
    super.key,
    required this.business,
    this.initialDate,
    this.initialWalkInMode = true,
  });

  static Future<void> show(
    BuildContext context, {
    required Business business,
    DateTime? initialDate,
    bool initialWalkInMode = true,
  }) {
    return showDialog(
      context: context,
      builder: (ctx) => AdminWalkInBookingDialog(
        business: business,
        initialDate: initialDate,
        initialWalkInMode: initialWalkInMode,
      ),
    );
  }

  @override
  ConsumerState<AdminWalkInBookingDialog> createState() => _AdminWalkInBookingDialogState();
}

class _AdminWalkInBookingDialogState extends ConsumerState<AdminWalkInBookingDialog> {
  final _clientNameCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  late bool _isWalkInNow;
  late DateTime _selectedDate;
  ServiceItem? _selectedService;
  BusinessStaff? _selectedStaff;
  TimeSlot? _selectedSlot;

  @override
  void initState() {
    super.initState();
    _isWalkInNow = widget.initialWalkInMode;
    final baseDate = widget.initialDate ?? DateTime.now();
    _selectedDate = baseDate.weekday == DateTime.sunday
        ? baseDate.add(const Duration(days: 1))
        : baseDate;
  }

  @override
  void dispose() {
    _clientNameCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _selectedSlot = null;
      });
    }
  }

  Future<void> _handleSubmit(
    ServiceItem? service,
    BusinessStaff? staff,
    TimeSlot? slot,
  ) async {
    final clientName = _clientNameCtrl.text.trim();
    if (clientName.isEmpty || service == null) return;
    if (!_isWalkInNow && widget.business.bookingModel == BookingModelType.slotBased && slot == null) {
      return;
    }

    final now = DateTime.now();
    final startTime = _isWalkInNow ? now : (slot?.startTime ?? _selectedDate);
    final endTime = _isWalkInNow
        ? now.add(Duration(minutes: service.durationMinutes))
        : (slot?.endTime ?? _selectedDate.add(Duration(minutes: service.durationMinutes)));

    final booking = Booking(
      id: const Uuid().v4(),
      businessId: widget.business.id,
      clientId: 'walkin-${clientName.toLowerCase().replaceAll(' ', '-')}-${now.millisecondsSinceEpoch}',
      serviceId: service.id,
      staffId: staff?.id,
      bookingModel: widget.business.bookingModel.toDbString(),
      startTime: startTime,
      endTime: endTime,
      status: _isWalkInNow ? 'checked_in' : 'confirmed',
      checkedInAt: _isWalkInNow ? now : null,
      totalPrice: service.price,
      paymentStatus: 'unpaid',
      amountPaid: 0.0,
      amountDue: service.price,
      clientNotes: _notesCtrl.text.trim().isNotEmpty ? _notesCtrl.text.trim() : 'Reception walk-in / phone booking',
      createdAt: now,
      businessName: widget.business.name,
      serviceName: service.name,
      staffName: staff?.name,
      clientName: clientName,
    );

    await ref.read(bookingsProvider.notifier).createBooking(booking);
    ref.invalidate(businessClientsProvider(widget.business.id));

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isWalkInNow
                ? 'Checked in $clientName into the Waiting Room!'
                : 'Scheduled appointment for $clientName!',
          ),
          backgroundColor: NeumorphicColors.success,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? NeumorphicColors.tealLight : NeumorphicColors.tealPrimary;
    final services = ref.watch(businessServicesProvider(widget.business.id)).value ?? [];
    final staffList = ref.watch(businessStaffProvider(widget.business.id)).value ?? [];
    final existingBookings = ref.watch(adminBookingsProvider(widget.business.id));

    final activeService = _selectedService ?? services.firstOrNull;
    final activeStaff = _selectedStaff;

    final availableSlots = (!_isWalkInNow && widget.business.bookingModel == BookingModelType.slotBased)
        ? SlotCalculator.calculateAvailableSlots(
            business: widget.business,
            date: _selectedDate,
            existingBookings: existingBookings,
            customDurationMinutes: activeService?.durationMinutes,
            filterStaffId: activeStaff?.id,
            staffMember: activeStaff,
          )
        : <TimeSlot>[];

    final effectiveSlot = _selectedSlot != null &&
            availableSlots.any((s) => s.isAvailable && s.startTime == _selectedSlot!.startTime)
        ? _selectedSlot
        : availableSlots.where((s) => s.isAvailable).firstOrNull;

    return AlertDialog(
      title: const Text(
        'New Walk-In / Appointment',
        style: TextStyle(fontWeight: FontWeight.w800),
      ),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Mode Toggle: Walk-In vs Scheduled Slot
              Row(
                children: [
                  Expanded(
                    child: ChoiceChip(
                      label: const Text('Walk-In (Check-In Now)', style: TextStyle(fontSize: 12)),
                      selected: _isWalkInNow,
                      selectedColor: accent.withValues(alpha: 0.2),
                      onSelected: (_) => setState(() => _isWalkInNow = true),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ChoiceChip(
                      label: const Text('Scheduled Slot', style: TextStyle(fontSize: 12)),
                      selected: !_isWalkInNow,
                      selectedColor: accent.withValues(alpha: 0.2),
                      onSelected: (_) => setState(() => _isWalkInNow = false),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              TextField(
                controller: _clientNameCtrl,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                  labelText: 'Patient / Client Full Name *',
                  hintText: 'e.g. Jordan Taylor',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),

              if (services.isNotEmpty) ...[
                DropdownButtonFormField<ServiceItem>(
                  initialValue: activeService,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: widget.business.serviceLabel,
                    border: const OutlineInputBorder(),
                  ),
                  items: services.map((s) {
                    return DropdownMenuItem(
                      value: s,
                      child: Text(
                        '${s.name} (${s.formattedPrice} • ${s.formattedDuration})',
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                  onChanged: (val) => setState(() {
                    _selectedService = val;
                    _selectedSlot = null;
                  }),
                ),
                const SizedBox(height: 12),
              ],

              if (staffList.isNotEmpty) ...[
                DropdownButtonFormField<BusinessStaff?>(
                  initialValue: activeStaff,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: 'Assign ${widget.business.resourceLabel}',
                    border: const OutlineInputBorder(),
                  ),
                  items: [
                    DropdownMenuItem<BusinessStaff?>(
                      value: null,
                      child: Text('Any Available ${widget.business.resourceLabel}'),
                    ),
                    ...staffList.map((st) {
                      return DropdownMenuItem<BusinessStaff?>(
                        value: st,
                        child: Text(
                          '${st.name} (${st.specialty ?? 'Specialist'})',
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }),
                  ],
                  onChanged: (val) => setState(() {
                    _selectedStaff = val;
                    _selectedSlot = null;
                  }),
                ),
                const SizedBox(height: 12),
              ],

              if (!_isWalkInNow) ...[
                OutlinedButton.icon(
                  onPressed: _pickDate,
                  icon: const Icon(Icons.calendar_today_rounded, size: 16),
                  label: Text('Date: ${DateFormat('EEE, MMM d, yyyy').format(_selectedDate)}'),
                ),
                const SizedBox(height: 10),
                if (widget.business.bookingModel == BookingModelType.slotBased) ...[
                  Text(
                    'Select Available Time Slot (${availableSlots.where((s) => s.isAvailable).length} open)',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 6),
                  if (availableSlots.where((s) => s.isAvailable).isEmpty)
                    const Text(
                      'No open slots on this date.',
                      style: TextStyle(fontSize: 12, color: NeumorphicColors.error),
                    )
                  else
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: availableSlots.where((s) => s.isAvailable).map((slot) {
                        final isSelected = effectiveSlot?.startTime == slot.startTime;
                        return ChoiceChip(
                          label: Text(slot.formattedTime, style: const TextStyle(fontSize: 11)),
                          selected: isSelected,
                          selectedColor: accent.withValues(alpha: 0.2),
                          onSelected: (_) => setState(() => _selectedSlot = slot),
                        );
                      }).toList(),
                    ),
                  const SizedBox(height: 12),
                ],
              ],

              TextField(
                controller: _notesCtrl,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Clinical / Intake Notes (Optional)',
                  hintText: 'Symptoms, room preference, walk-in notes...',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        NeumorphicButton(
          isPrimary: true,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          onPressed: _clientNameCtrl.text.trim().isNotEmpty &&
                  activeService != null &&
                  (_isWalkInNow ||
                      widget.business.bookingModel != BookingModelType.slotBased ||
                      effectiveSlot != null)
              ? () => _handleSubmit(activeService, activeStaff, effectiveSlot)
              : null,
          child: Text(
            _isWalkInNow ? 'Check In Walk-In' : 'Create Appointment',
            style: const TextStyle(fontSize: 13),
          ),
        ),
      ],
    );
  }
}
