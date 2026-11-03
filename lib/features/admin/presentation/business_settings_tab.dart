// Gene - Nov, 03, 2026: Business Template and Settings Configurator (Slot-based vs Date-Range vs Daily)
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/neumorphic_colors.dart';
import '../../../../core/widgets/neumorphic_container.dart';
import '../../../../core/widgets/neumorphic_button.dart';
import '../../../../core/widgets/neumorphic_text_field.dart';
import '../../../../models/business.dart';
// import '../../../../services/business_service.dart';

class BusinessSettingsTab extends ConsumerStatefulWidget {
  final Business business;

  const BusinessSettingsTab({super.key, required this.business});

  @override
  ConsumerState<BusinessSettingsTab> createState() => _BusinessSettingsTabState();
}

class _BusinessSettingsTabState extends ConsumerState<BusinessSettingsTab> {
  late BookingModelType _selectedModel;
  late TextEditingController _nameController;
  late TextEditingController _addressController;
  late TextEditingController _phoneController;
  late int _slotInterval;
  late int _bufferMinutes;
  late bool _requiresApproval;
  bool _saved = false;

  @override
  void initState() {
    super.initState();
    _selectedModel = widget.business.bookingModel;
    _nameController = TextEditingController(text: widget.business.name);
    _addressController = TextEditingController(text: widget.business.address ?? '');
    _phoneController = TextEditingController(text: widget.business.contactPhone ?? '');
    _slotInterval = widget.business.slotIntervalMinutes;
    _bufferMinutes = widget.business.bufferMinutes;
    _requiresApproval = widget.business.requiresApproval;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _saveSettings() {
    setState(() => _saved = true);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Saved template configuration as ${_selectedModel.displayName}!'),
        backgroundColor: NeumorphicColors.tealPrimary,
      ),
    );
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _saved = false);
    });
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
          Text(
            'Business Template & Configuration',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: isDark ? NeumorphicColors.darkTextPrimary : NeumorphicColors.lightTextPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Configure your universal booking behavior. Changing the template dynamically updates the client booking flow.',
            style: TextStyle(
              fontSize: 13,
              color: isDark ? NeumorphicColors.darkTextSecondary : NeumorphicColors.lightTextSecondary,
            ),
          ),
          const SizedBox(height: 24),

          // Template Model Selector Cards
          Text(
            'Select Booking Model Template',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: isDark ? NeumorphicColors.darkTextPrimary : NeumorphicColors.lightTextPrimary,
            ),
          ),
          const SizedBox(height: 12),

          _buildTemplateOption(
            type: BookingModelType.slotBased,
            title: '1. Time Slot Appointments (Clinic / Doctor)',
            description: 'Clients select procedures, choose a dentist/doctor, and book discrete 15-60 min time slots.',
            icon: Icons.calendar_today,
          ),
          const SizedBox(height: 12),

          _buildTemplateOption(
            type: BookingModelType.dateRange,
            title: '2. Date Range Booking (Stay / Recovery / Rental)',
            description: 'Clients pick "Date From" and "Date To", with automatic nightly rate calculation.',
            icon: Icons.date_range,
          ),
          const SizedBox(height: 12),

          _buildTemplateOption(
            type: BookingModelType.daily,
            title: '3. Daily Session (Day Clinic / Passes)',
            description: 'Clients book single calendar days with capacity tracking.',
            icon: Icons.view_day,
          ),
          const SizedBox(height: 28),

          // Template-Specific Parameters
          if (_selectedModel == BookingModelType.slotBased) ...[
            Text(
              'Time Slot Parameters',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: isDark ? NeumorphicColors.darkTextPrimary : NeumorphicColors.lightTextPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: NeumorphicContainer(
                    borderRadius: 18.0,
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Slot Interval', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 8),
                        DropdownButton<int>(
                          value: _slotInterval,
                          isExpanded: true,
                          underline: const SizedBox(),
                          items: const [
                            DropdownMenuItem(value: 15, child: Text('15 Minutes')),
                            DropdownMenuItem(value: 30, child: Text('30 Minutes (Standard)')),
                            DropdownMenuItem(value: 45, child: Text('45 Minutes')),
                            DropdownMenuItem(value: 60, child: Text('60 Minutes')),
                          ],
                          onChanged: (val) {
                            if (val != null) setState(() => _slotInterval = val);
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: NeumorphicContainer(
                    borderRadius: 18.0,
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Buffer Time Between Patients', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 8),
                        DropdownButton<int>(
                          value: _bufferMinutes,
                          isExpanded: true,
                          underline: const SizedBox(),
                          items: const [
                            DropdownMenuItem(value: 0, child: Text('No buffer')),
                            DropdownMenuItem(value: 10, child: Text('10 Min Clean & Prep')),
                            DropdownMenuItem(value: 15, child: Text('15 Min Buffer')),
                          ],
                          onChanged: (val) {
                            if (val != null) setState(() => _bufferMinutes = val);
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],

          // Gene - Nov, 03, 2026: Wrapped SwitchListTile in Material widget to resolve ListTile DecoratedBox assertion
          NeumorphicContainer(
            borderRadius: 18.0,
            padding: const EdgeInsets.all(16),
            child: Material(
              type: MaterialType.transparency,
              child: SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Require Manual Approval for Bookings', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                subtitle: const Text('If enabled, bookings stay in "Pending" status until accepted by staff.', style: TextStyle(fontSize: 12)),
                value: _requiresApproval,
                activeThumbColor: accent,
                onChanged: (val) => setState(() => _requiresApproval = val),
              ),
            ),
          ),
          /*
          // Gene - Nov, 03, 2026: Previous SwitchListTile without explicit Material wrapper
          NeumorphicContainer(
            borderRadius: 18.0,
            padding: const EdgeInsets.all(16),
            child: SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Require Manual Approval for Bookings', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
              subtitle: const Text('If enabled, bookings stay in "Pending" status until accepted by staff.', style: TextStyle(fontSize: 12)),
              value: _requiresApproval,
              activeThumbColor: accent,
              onChanged: (val) => setState(() => _requiresApproval = val),
            ),
          ),
          */
          const SizedBox(height: 24),

          // Clinic Details
          Text(
            'Business Profile Info',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: isDark ? NeumorphicColors.darkTextPrimary : NeumorphicColors.lightTextPrimary,
            ),
          ),
          const SizedBox(height: 12),
          NeumorphicTextField(controller: _nameController, labelText: 'Business Name'),
          const SizedBox(height: 12),
          NeumorphicTextField(controller: _addressController, labelText: 'Clinic Address'),
          const SizedBox(height: 12),
          NeumorphicTextField(controller: _phoneController, labelText: 'Contact Phone'),
          const SizedBox(height: 28),

          NeumorphicButton(
            isPrimary: true,
            onPressed: _saveSettings,
            child: Text(_saved ? 'Settings Saved! ✓' : 'Save Template Settings'),
          ),
        ],
      ),
    );
  }

  Widget _buildTemplateOption({
    required BookingModelType type,
    required String title,
    required String description,
    required IconData icon,
  }) {
    final isSelected = _selectedModel == type;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? NeumorphicColors.tealLight : NeumorphicColors.tealPrimary;

    return GestureDetector(
      onTap: () => setState(() => _selectedModel = type),
      child: NeumorphicContainer(
        borderRadius: 20.0,
        isInset: isSelected,
        border: isSelected ? Border.all(color: accent, width: 2) : null,
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            NeumorphicContainer(
              isCircle: true,
              width: 44,
              height: 44,
              color: isSelected ? accent.withValues(alpha: 0.15) : null,
              child: Icon(icon, color: isSelected ? accent : (isDark ? Colors.white60 : Colors.black54)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: isSelected ? accent : (isDark ? Colors.white : Colors.black87),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? NeumorphicColors.darkTextSecondary : NeumorphicColors.lightTextSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected) ...[
              Icon(Icons.check_circle, color: accent, size: 22),
            ],
          ],
        ),
      ),
    );
  }
}
