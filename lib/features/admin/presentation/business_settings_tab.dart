// Gene - Nov, 03, 2026: Business Template and Settings Configurator (Slot-based vs Date-Range vs Daily)
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/neumorphic_colors.dart';
// Gene - Nov, 22, 2026: Added AppErrorFormatter import for user-friendly business settings error notifications
import '../../../../core/utils/app_error_formatter.dart';
import '../../../../core/widgets/neumorphic_container.dart';
import '../../../../core/widgets/neumorphic_button.dart';
import '../../../../core/widgets/neumorphic_text_field.dart';
import '../../../../models/business.dart';
// Gene - Nov, 22, 2026: Added PlatformConfigService and SupabaseConfig imports for DB-driven dropdown presets & safe payment input defaults
import '../../../../core/constants/supabase_config.dart';
// import '../../../../models/platform_config.dart';
// Gene - Nov, 22, 2026: Commented out unused platform_config import (provided transitively / via service)
import '../../../../services/platform_config_service.dart';
import '../../../../services/business_service.dart';
// Gene - Nov, 05, 2026: Added Storefront QR Standee Studio import
import 'widgets/qr_standee_studio_card.dart';
// Gene - Nov 06, 2026: Added LocationGeocodingService and LocationPinPicker imports
import 'dart:async';
import '../../../../services/location_geocoding_service.dart';
import 'widgets/location_pin_picker.dart';

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
  // Gene - Nov, 22, 2026: Added DB-driven currency, advance booking horizon, min notice window, and date-range stay bounds
  late String _selectedCurrency;
  late int _advanceBookingDays;
  late int _minNoticeHours;
  late int _minDays;
  late int _maxDays;
  bool _saved = false;

  // Gene - Nov 06, 2026: Added coordinates and debounce for interactive map pin-picker
  late double? _latitude;
  late double? _longitude;
  final GlobalKey<LocationPinPickerState> _pinPickerKey = GlobalKey<LocationPinPickerState>();
  Timer? _addressDebounce;
  // Gene - Nov 07, 2026: Weekly venue working hours map for editing open/close schedule per day
  late Map<String, Map<String, dynamic>> _workingHours;
  static const List<String> _weekdays = [
    'monday',
    'tuesday',
    'wednesday',
    'thursday',
    'friday',
    'saturday',
    'sunday',
  ];

  // Gene - Nov 07, 2026: Hybrid payment channels state & controllers for GCash, Maya, and Bank Transfer
  late bool _stripeEnabled;
  late bool _gcashEnabled;
  late TextEditingController _gcashNameController;
  late TextEditingController _gcashNumberController;
  late bool _mayaEnabled;
  late TextEditingController _mayaNameController;
  late TextEditingController _mayaNumberController;
  late bool _bankEnabled;
  late TextEditingController _bankNameController;
  late TextEditingController _bankAccountNameController;
  late TextEditingController _bankAccountNumberController;

  @override
  void initState() {
    super.initState();
    final branding = ref.read(activePlatformConfigProvider).branding;
    _selectedModel = widget.business.bookingModel;
    _nameController = TextEditingController(text: widget.business.name);
    _addressController = TextEditingController(text: widget.business.address ?? '');
    _phoneController = TextEditingController(text: widget.business.contactPhone ?? '');
    _slotInterval = widget.business.slotIntervalMinutes;
    _bufferMinutes = widget.business.bufferMinutes;
    _requiresApproval = widget.business.requiresApproval;
    _selectedCurrency = widget.business.currency;
    _advanceBookingDays = widget.business.advanceBookingDays;
    _minNoticeHours = widget.business.minNoticeHours;
    _minDays = widget.business.minDays;
    _maxDays = widget.business.maxDays;
    _latitude = widget.business.latitude ?? branding.defaultLatitude;
    _longitude = widget.business.longitude ?? branding.defaultLongitude;
    _workingHours = _initWorkingHours(widget.business.workingHours);

    final payCfg = widget.business.paymentMethodsConfig;
    final allowDemo = SupabaseConfig.isDemoModeEnabled && !SupabaseConfig.isConfigured;
    _stripeEnabled = payCfg['stripe_enabled'] as bool? ?? true;
    _gcashEnabled = payCfg['gcash_enabled'] as bool? ?? allowDemo;
    _gcashNameController = TextEditingController(text: payCfg['gcash_account_name'] as String? ?? widget.business.name);
    _gcashNumberController = TextEditingController(text: payCfg['gcash_number'] as String? ?? '');
    _mayaEnabled = payCfg['maya_enabled'] as bool? ?? allowDemo;
    _mayaNameController = TextEditingController(text: payCfg['maya_account_name'] as String? ?? widget.business.name);
    _mayaNumberController = TextEditingController(text: payCfg['maya_number'] as String? ?? '');
    _bankEnabled = payCfg['bank_enabled'] as bool? ?? allowDemo;
    _bankNameController = TextEditingController(text: payCfg['bank_name'] as String? ?? '');
    _bankAccountNameController = TextEditingController(text: payCfg['bank_account_name'] as String? ?? widget.business.name);
    _bankAccountNumberController = TextEditingController(text: payCfg['bank_account_number'] as String? ?? '');

    _addressController.addListener(_onAddressChanged);
  }

  Map<String, Map<String, dynamic>> _initWorkingHours(Map<String, dynamic>? existing) {
    final result = <String, Map<String, dynamic>>{};
    for (final day in _weekdays) {
      final raw = existing != null ? existing[day] : null;
      if (raw is Map) {
        result[day] = {
          'open': raw['open']?.toString() ?? '09:00',
          'close': raw['close']?.toString() ?? '17:00',
          'is_open': raw['is_open'] == true,
        };
      } else {
        final isWeekend = day == 'saturday' || day == 'sunday';
        result[day] = {
          'open': '09:00',
          'close': '17:00',
          'is_open': !isWeekend,
        };
      }
    }
    return result;
  }

  void _onAddressChanged() {
    _addressDebounce?.cancel();
    _addressDebounce = Timer(const Duration(milliseconds: 600), () async {
      final query = _addressController.text.trim();
      if (query.length > 5) {
        final geocoder = ref.read(locationGeocodingServiceProvider);
        final results = await geocoder.searchAddress(query);
        if (results.isNotEmpty && mounted) {
          final loc = results.first;
          setState(() {
            _latitude = loc.latitude;
            _longitude = loc.longitude;
          });
          _pinPickerKey.currentState?.moveToLocation(loc.latitude, loc.longitude, addressLabel: loc.formattedAddress);
        }
      }
    });
  }

  @override
  void dispose() {
    _addressDebounce?.cancel();
    _addressController.removeListener(_onAddressChanged);
    _nameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    // Gene - Nov 07, 2026: Dispose hybrid payment channel controllers
    _gcashNameController.dispose();
    _gcashNumberController.dispose();
    _mayaNameController.dispose();
    _mayaNumberController.dispose();
    _bankNameController.dispose();
    _bankAccountNameController.dispose();
    _bankAccountNumberController.dispose();
    super.dispose();
  }

  /*
  // Original _saveSettings without persistence
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
  */
  // Gene - Nov 06, 2026: Persist updated business profile, coordinates, and address via BusinessService
  void _saveSettings() async {
    final updatedBusiness = widget.business.copyWith(
      name: _nameController.text.trim(),
      address: _addressController.text.trim(),
      contactPhone: _phoneController.text.trim(),
      bookingModel: _selectedModel,
      latitude: _latitude,
      longitude: _longitude,
      /*
      settings: {
        ...widget.business.settings,
        'slot_interval_minutes': _slotInterval,
        'buffer_minutes': _bufferMinutes,
        'requires_approval': _requiresApproval,
      },
      */
      /*
      // Gene - Nov 07, 2026: Persist updated working_hours map alongside slot and buffer settings
      settings: {
        ...widget.business.settings,
        'slot_interval_minutes': _slotInterval,
        'buffer_minutes': _bufferMinutes,
        'requires_approval': _requiresApproval,
        'working_hours': _workingHours,
      },
      */
      // Gene - Nov, 22, 2026: Persist DB-driven currency, advance booking horizon, min notice, min/max nights, working hours & payment methods
      settings: {
        ...widget.business.settings,
        'currency': _selectedCurrency,
        'advance_booking_days': _advanceBookingDays,
        'min_notice_hours': _minNoticeHours,
        'min_days': _minDays,
        'max_days': _maxDays,
        'slot_interval_minutes': _slotInterval,
        'buffer_minutes': _bufferMinutes,
        'requires_approval': _requiresApproval,
        'working_hours': _workingHours,
        'payment_methods': {
          'stripe_enabled': _stripeEnabled,
          'gcash_enabled': _gcashEnabled,
          'gcash_account_name': _gcashNameController.text.trim(),
          'gcash_number': _gcashNumberController.text.trim(),
          'maya_enabled': _mayaEnabled,
          'maya_account_name': _mayaNameController.text.trim(),
          'maya_number': _mayaNumberController.text.trim(),
          'bank_enabled': _bankEnabled,
          'bank_name': _bankNameController.text.trim(),
          'bank_account_name': _bankAccountNameController.text.trim(),
          'bank_account_number': _bankAccountNumberController.text.trim(),
        },
      },
    );
    /*
    // Gene - Nov 06, 2026: Uncaught updateBusiness call silently failed on live DB errors
    await ref.read(businessServiceProvider).updateBusiness(updatedBusiness);
    ref.invalidate(businessDetailProvider(widget.business.id));
    ref.invalidate(businessListProvider);
    if (mounted) {
      setState(() => _saved = true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Saved ${widget.business.venueLabel.toLowerCase()} settings & map location!'),
          backgroundColor: NeumorphicColors.tealPrimary,
        ),
      );
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) setState(() => _saved = false);
      });
    }
    */
    // Gene - Nov, 22, 2026: Catch live DB errors on settings save and display user-friendly SnackBar notification
    try {
      await ref.read(businessServiceProvider).updateBusiness(updatedBusiness);
      ref.invalidate(businessDetailProvider(widget.business.id));
      ref.invalidate(businessListProvider);
      if (mounted) {
        setState(() => _saved = true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Saved ${widget.business.venueLabel.toLowerCase()} settings & map location!'),
            backgroundColor: NeumorphicColors.tealPrimary,
          ),
        );
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) setState(() => _saved = false);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppErrorFormatter.format(e, context: AppErrorContext.business)),
            backgroundColor: NeumorphicColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? NeumorphicColors.tealLight : NeumorphicColors.tealPrimary;
    // Gene - Nov, 22, 2026: Load global booking models, currencies, scheduling presets, and payment channels from PlatformConfig
    final platformConfig = ref.watch(activePlatformConfigProvider);
    final schedulingPresets = platformConfig.schedulingPresets;
    /*
    final slotIntervalOptions = schedulingPresets.slotIntervals.contains(_slotInterval)
        ? schedulingPresets.slotIntervals
        : [...schedulingPresets.slotIntervals, _slotInterval]..sort();
    final bufferOptions = schedulingPresets.bufferOptions.contains(_bufferMinutes)
        ? schedulingPresets.bufferOptions
        : [...schedulingPresets.bufferOptions, _bufferMinutes]..sort();
    */
    // Gene - Nov, 22, 2026: Parenthesize spread+sort so unmodifiable const default lists are never sorted in-place
    final slotIntervalOptions = schedulingPresets.slotIntervals.contains(_slotInterval)
        ? schedulingPresets.slotIntervals
        : ([...schedulingPresets.slotIntervals, _slotInterval]..sort());
    final bufferOptions = schedulingPresets.bufferOptions.contains(_bufferMinutes)
        ? schedulingPresets.bufferOptions
        : ([...schedulingPresets.bufferOptions, _bufferMinutes]..sort());
    final currencies = platformConfig.supportedCurrencies;
    final openOptions = schedulingPresets.openTimes;
    final closeOptions = schedulingPresets.closeTimes;

    BookingModelType parseModelType(String id) => BookingModelType.fromString(id);
    IconData resolveModelIcon(String iconName) {
      switch (iconName) {
        case 'date_range':
          return Icons.date_range;
        case 'view_day':
          return Icons.view_day;
        case 'calendar_today':
        default:
          return Icons.calendar_today;
      }
    }

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

          // Gene - Nov, 22, 2026: Dynamic DB-driven booking models, scheduling presets, notice/horizon bounds, currency & payment channel labels
          ...platformConfig.bookingModels.map((bm) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildTemplateOption(
                type: parseModelType(bm.id),
                title: bm.title,
                description: bm.description,
                icon: resolveModelIcon(bm.icon),
              ),
            );
          }),
          const SizedBox(height: 16),

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
                          items: slotIntervalOptions
                              .map((m) => DropdownMenuItem(value: m, child: Text('$m Minutes')))
                              .toList(),
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
                        const Text('Buffer Time', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 8),
                        DropdownButton<int>(
                          value: _bufferMinutes,
                          isExpanded: true,
                          underline: const SizedBox(),
                          items: bufferOptions
                              .map((m) => DropdownMenuItem(
                                    value: m,
                                    child: Text(m == 0 ? 'No buffer' : '$m Min Buffer'),
                                  ))
                              .toList(),
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

          // Currency, Booking Window & Stay Constraints
          Text(
            'Currency & Booking Window',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: isDark ? NeumorphicColors.darkTextPrimary : NeumorphicColors.lightTextPrimary,
            ),
          ),
          const SizedBox(height: 12),
          NeumorphicContainer(
            borderRadius: 18.0,
            padding: const EdgeInsets.all(16),
            child: Wrap(
              spacing: 16,
              runSpacing: 14,
              children: [
                SizedBox(
                  width: 200,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Billing Currency', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                      DropdownButton<String>(
                        value: currencies.any((c) => c.code == _selectedCurrency)
                            ? _selectedCurrency
                            : currencies.first.code,
                        isExpanded: true,
                        underline: const SizedBox(),
                        items: currencies
                            .map((c) => DropdownMenuItem(
                                  value: c.code,
                                  child: Text('${c.code} (${c.symbol})'),
                                ))
                            .toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _selectedCurrency = val);
                        },
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  width: 170,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Advance Booking Window', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                      DropdownButton<int>(
                        value: const [7, 14, 30, 60, 90, 180, 365].contains(_advanceBookingDays)
                            ? _advanceBookingDays
                            : 14,
                        isExpanded: true,
                        underline: const SizedBox(),
                        items: const [7, 14, 30, 60, 90, 180, 365]
                            .map((d) => DropdownMenuItem(value: d, child: Text('$d Days')))
                            .toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _advanceBookingDays = val);
                        },
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  width: 170,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Minimum Notice', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                      DropdownButton<int>(
                        value: const [0, 1, 2, 4, 12, 24, 48].contains(_minNoticeHours)
                            ? _minNoticeHours
                            : 0,
                        isExpanded: true,
                        underline: const SizedBox(),
                        items: const [0, 1, 2, 4, 12, 24, 48]
                            .map((h) => DropdownMenuItem(
                                  value: h,
                                  child: Text(h == 0 ? 'Instant / Same-Hour' : '$h Hours Notice'),
                                ))
                            .toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _minNoticeHours = val);
                        },
                      ),
                    ],
                  ),
                ),
                if (_selectedModel == BookingModelType.dateRange) ...[
                  SizedBox(
                    width: 140,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Min Nights', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                        DropdownButton<int>(
                          value: const [1, 2, 3, 5, 7, 14].contains(_minDays) ? _minDays : 1,
                          isExpanded: true,
                          underline: const SizedBox(),
                          items: const [1, 2, 3, 5, 7, 14]
                              .map((d) => DropdownMenuItem(value: d, child: Text('$d Night${d == 1 ? '' : 's'}')))
                              .toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() {
                                _minDays = val;
                                if (_maxDays < _minDays) _maxDays = _minDays;
                              });
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: 140,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Max Nights', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                        DropdownButton<int>(
                          value: const [7, 14, 30, 60, 90, 180].contains(_maxDays) ? _maxDays : 30,
                          isExpanded: true,
                          underline: const SizedBox(),
                          items: const [7, 14, 30, 60, 90, 180]
                              .where((d) => d >= _minDays)
                              .map((d) => DropdownMenuItem(value: d, child: Text('$d Nights')))
                              .toList(),
                          onChanged: (val) {
                            if (val != null) setState(() => _maxDays = val);
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Weekly Venue Operating Hours Editor Card
          if (_selectedModel != BookingModelType.dateRange) ...[
            Text(
              'Weekly ${widget.business.venueLabel} Operating Hours',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: isDark ? NeumorphicColors.darkTextPrimary : NeumorphicColors.lightTextPrimary,
              ),
            ),
            const SizedBox(height: 12),
            NeumorphicContainer(
              borderRadius: 18.0,
              padding: const EdgeInsets.all(16),
              child: Column(
                children: _weekdays.map((day) {
                  final dayCfg = _workingHours[day]!;
                  final isOpen = dayCfg['is_open'] == true;
                  final openTime = dayCfg['open'] as String? ?? '09:00';
                  final closeTime = dayCfg['close'] as String? ?? '17:00';
                  final label = day[0].toUpperCase() + day.substring(1);

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 100,
                          child: Text(
                            label,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: isOpen
                                  ? (isDark ? Colors.white : Colors.black87)
                                  : (isDark ? Colors.white38 : Colors.black38),
                            ),
                          ),
                        ),
                        Switch(
                          value: isOpen,
                          activeThumbColor: accent,
                          onChanged: (val) {
                            setState(() {
                              _workingHours[day] = {
                                ...dayCfg,
                                'is_open': val,
                              };
                            });
                          },
                        ),
                        const SizedBox(width: 8),
                        if (!isOpen)
                          Text(
                            'Closed',
                            style: TextStyle(
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                              color: isDark ? Colors.white38 : Colors.black38,
                            ),
                          )
                        else
                          Expanded(
                            child: Wrap(
                              spacing: 8,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                DropdownButton<String>(
                                  value: openOptions.contains(openTime) ? openTime : openOptions.first,
                                  isDense: true,
                                  underline: const SizedBox(),
                                  items: openOptions
                                      .map((t) => DropdownMenuItem(value: t, child: Text(t, style: const TextStyle(fontSize: 12))))
                                      .toList(),
                                  onChanged: (val) {
                                    if (val != null) {
                                      setState(() {
                                        _workingHours[day] = {...dayCfg, 'open': val};
                                      });
                                    }
                                  },
                                ),
                                const Text('to', style: TextStyle(fontSize: 12)),
                                DropdownButton<String>(
                                  value: closeOptions.contains(closeTime) ? closeTime : closeOptions.first,
                                  isDense: true,
                                  underline: const SizedBox(),
                                  items: closeOptions
                                      .map((t) => DropdownMenuItem(value: t, child: Text(t, style: const TextStyle(fontSize: 12))))
                                      .toList(),
                                  onChanged: (val) {
                                    if (val != null) {
                                      setState(() {
                                        _workingHours[day] = {...dayCfg, 'close': val};
                                      });
                                    }
                                  },
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  );
                }).toList(),
              ),
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
          NeumorphicTextField(
            controller: _addressController,
            labelText: '${widget.business.venueLabel} Address',
          ),
          // Gene - Nov 06, 2026: Embedded interactive LocationPinPicker for business location configuration
          const SizedBox(height: 12),
          LocationPinPicker(
            key: _pinPickerKey,
            initialLatitude: _latitude ?? platformConfig.branding.defaultLatitude,
            initialLongitude: _longitude ?? platformConfig.branding.defaultLongitude,
            height: 220,
            label: 'Location Pin on Map',
            onLocationChanged: (loc) {
              setState(() {
                _latitude = loc.latitude;
                _longitude = loc.longitude;
                _addressController.removeListener(_onAddressChanged);
                _addressController.text = loc.formattedAddress;
                _addressController.addListener(_onAddressChanged);
              });
            },
          ),
          const SizedBox(height: 12),
          NeumorphicTextField(controller: _phoneController, labelText: 'Contact Phone'),
          const SizedBox(height: 28),

          // Gene - Nov 07, 2026: Hybrid Payment Channels & Receiving Accounts Configurator (Stripe, GCash, Maya, Bank Transfer)
          Text(
            'Payment Channels & Receiving Accounts',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: isDark ? NeumorphicColors.darkTextPrimary : NeumorphicColors.lightTextPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Configure accepted payment methods and receiving account numbers displayed to clients during checkout.',
            style: TextStyle(
              fontSize: 12,
              color: isDark ? NeumorphicColors.darkTextSecondary : NeumorphicColors.lightTextSecondary,
            ),
          ),
          const SizedBox(height: 12),
          NeumorphicContainer(
            borderRadius: 18.0,
            padding: const EdgeInsets.all(16),
            child: Material(
              type: MaterialType.transparency,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Credit / Debit Card (Stripe)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                    subtitle: const Text('Online card checkout via Stripe Express', style: TextStyle(fontSize: 12)),
                    value: _stripeEnabled,
                    activeThumbColor: accent,
                    onChanged: (val) => setState(() => _stripeEnabled = val),
                  ),
                  const Divider(height: 20),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('GCash (E-Wallet & QR Ph)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                    subtitle: const Text('Clients scan QR or transfer to your GCash number and input their 13-digit Reference No.', style: TextStyle(fontSize: 12)),
                    value: _gcashEnabled,
                    activeThumbColor: const Color(0xFF007DFE),
                    onChanged: (val) => setState(() => _gcashEnabled = val),
                  ),
                  if (_gcashEnabled) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: NeumorphicTextField(
                            controller: _gcashNameController,
                            labelText: 'GCash Account Name',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: NeumorphicTextField(
                            controller: _gcashNumberController,
                            labelText: 'GCash Mobile No.',
                          ),
                        ),
                      ],
                    ),
                  ],
                  const Divider(height: 20),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Maya (Digital Wallet)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                    subtitle: const Text('Direct transfer via Maya mobile number or QR Ph', style: TextStyle(fontSize: 12)),
                    value: _mayaEnabled,
                    activeThumbColor: const Color(0xFF00B14F),
                    onChanged: (val) => setState(() => _mayaEnabled = val),
                  ),
                  if (_mayaEnabled) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: NeumorphicTextField(
                            controller: _mayaNameController,
                            labelText: 'Maya Account Name',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: NeumorphicTextField(
                            controller: _mayaNumberController,
                            labelText: 'Maya Mobile No.',
                          ),
                        ),
                      ],
                    ),
                  ],
                  const Divider(height: 20),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Bank Transfer (InstaPay / PESONet)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                    subtitle: const Text('Clients transfer to your clinic bank account (BDO, BPI, UnionBank, etc.)', style: TextStyle(fontSize: 12)),
                    value: _bankEnabled,
                    activeThumbColor: accent,
                    onChanged: (val) => setState(() => _bankEnabled = val),
                  ),
                  if (_bankEnabled) ...[
                    const SizedBox(height: 8),
                    NeumorphicTextField(
                      controller: _bankNameController,
                      labelText: 'Bank Name (e.g. BDO Unibank / BPI / UnionBank)',
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: NeumorphicTextField(
                            controller: _bankAccountNameController,
                            labelText: 'Bank Account Name',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: NeumorphicTextField(
                            controller: _bankAccountNumberController,
                            labelText: 'Bank Account Number',
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 28),

          /*
          // Gene - Nov, 03, 2026: Previous bottom action without Storefront QR Standee Studio
          NeumorphicButton(
            isPrimary: true,
            onPressed: _saveSettings,
            child: Text(_saved ? 'Settings Saved! ✓' : 'Save Template Settings'),
          ),
          */

          // Gene - Nov, 05, 2026: Added Storefront QR Standee Studio to business settings
          NeumorphicButton(
            isPrimary: true,
            onPressed: _saveSettings,
            child: Text(_saved ? 'Settings Saved! ✓' : 'Save Template Settings'),
          ),
          const SizedBox(height: 32),

          // Gene - Nov, 05, 2026: Storefront QR & Marketing Standee Studio
          QrStandeeStudioCard(business: widget.business),
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
