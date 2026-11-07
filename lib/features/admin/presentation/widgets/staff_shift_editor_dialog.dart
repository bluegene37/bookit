// Gene - Nov 06, 2026: StaffShiftEditorDialog for configuring 7-day practitioner shift matrix and lunch breaks
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/neumorphic_colors.dart';
import '../../../../core/widgets/neumorphic_container.dart';
import '../../../../core/widgets/neumorphic_button.dart';
import '../../../../models/business_staff.dart';
import '../../../../services/business_service.dart';

class StaffShiftEditorDialog extends ConsumerStatefulWidget {
  final BusinessStaff staff;
  final String businessId;

  const StaffShiftEditorDialog({
    super.key,
    required this.staff,
    required this.businessId,
  });

  static Future<void> show(BuildContext context, BusinessStaff staff, String businessId) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => StaffShiftEditorDialog(staff: staff, businessId: businessId),
    );
  }

  @override
  ConsumerState<StaffShiftEditorDialog> createState() => _StaffShiftEditorDialogState();
}

class _StaffShiftEditorDialogState extends ConsumerState<StaffShiftEditorDialog> {
  late Map<String, Map<String, dynamic>> _schedule;
  bool _isSaving = false;

  static const List<String> _weekdays = [
    'monday',
    'tuesday',
    'wednesday',
    'thursday',
    'friday',
    'saturday',
    'sunday',
  ];

  static const List<String> _timeOptions = [
    '06:00', '06:30', '07:00', '07:30', '08:00', '08:30', '09:00', '09:30',
    '10:00', '10:30', '11:00', '11:30', '12:00', '12:30', '13:00', '13:30',
    '14:00', '14:30', '15:00', '15:30', '16:00', '16:30', '17:00', '17:30',
    '18:00', '18:30', '19:00', '19:30', '20:00', '20:30', '21:00', '21:30', '22:00',
  ];

  @override
  void initState() {
    super.initState();
    _initSchedule();
  }

  void _initSchedule() {
    _schedule = {};
    for (final day in _weekdays) {
      _schedule[day] = {
        'is_working': widget.staff.isWorkingOn(day),
        'start': widget.staff.shiftStart(day),
        'end': widget.staff.shiftEnd(day),
        'has_break': widget.staff.hasBreak(day),
        'break_start': widget.staff.breakStart(day),
        'break_end': widget.staff.breakEnd(day),
      };
    }
  }

  String _formatTimeStr(String hhmm) {
    try {
      final parts = hhmm.split(':').map(int.parse).toList();
      final hour = parts[0];
      final min = parts[1];
      final period = hour >= 12 ? 'PM' : 'AM';
      final h12 = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
      final minStr = min == 0 ? '00' : (min < 10 ? '0$min' : '$min');
      return '$h12:$minStr $period';
    } catch (_) {
      return hhmm;
    }
  }

  void _copyMondayToWeekdays() {
    final mon = _schedule['monday']!;
    setState(() {
      for (final day in ['tuesday', 'wednesday', 'thursday', 'friday']) {
        _schedule[day] = Map<String, dynamic>.from(mon);
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Monday schedule copied to Tuesday–Friday!'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _resetToDefault() {
    setState(() {
      final def = BusinessStaff.defaultSchedule();
      for (final day in _weekdays) {
        _schedule[day] = Map<String, dynamic>.from(def[day] as Map);
      }
    });
  }

  Future<void> _handleSave() async {
    setState(() => _isSaving = true);
    try {
      final updatedStaff = widget.staff.copyWith(
        scheduleOverride: _schedule,
      );

      await ref.read(businessServiceProvider).updateStaff(updatedStaff);
      /*
      ref.invalidate(businessStaffProvider(widget.businessId));
      */
      // Gene - Nov 07, 2026: Invalidate both admin and client staff providers so shift updates reflect immediately
      ref.invalidate(adminBusinessStaffProvider(widget.businessId));
      ref.invalidate(businessStaffProvider(widget.businessId));

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Shift schedule updated for ${widget.staff.name}'),
            backgroundColor: NeumorphicColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving schedule: $e'), backgroundColor: NeumorphicColors.error),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? NeumorphicColors.tealLight : NeumorphicColors.tealPrimary;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: isDark ? NeumorphicColors.darkSurface : NeumorphicColors.lightSurface,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 680, maxHeight: 780),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundImage: NetworkImage(
                      widget.staff.avatarUrl ??
                          'https://images.unsplash.com/photo-1622253692010-333f2da6031d?w=200',
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                widget.staff.name,
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: accent.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                widget.staff.specialty ?? 'Specialist',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: accent,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Configure working days, shift hours, and scheduled lunch breaks',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.white60 : Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    tooltip: 'Close',
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Quick Actions Bar
              Row(
                children: [
                  NeumorphicButton(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    onPressed: _copyMondayToWeekdays,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.copy_rounded, size: 14, color: accent),
                        const SizedBox(width: 6),
                        const Text(
                          'Copy Mon to Weekdays',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  NeumorphicButton(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    onPressed: _resetToDefault,
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.restore_rounded, size: 14),
                        SizedBox(width: 6),
                        Text(
                          'Reset Default',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              const Divider(height: 1),
              const SizedBox(height: 12),

              // Scrollable 7-day matrix
              Expanded(
                child: ListView.separated(
                  itemCount: _weekdays.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final day = _weekdays[index];
                    final dayData = _schedule[day]!;
                    final isWorking = dayData['is_working'] as bool;
                    final hasBreak = dayData['has_break'] as bool;

                    return NeumorphicContainer(
                      borderRadius: 14,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Day row with toggle
                          Row(
                            children: [
                              SizedBox(
                                width: 100,
                                child: Text(
                                  day[0].toUpperCase() + day.substring(1),
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: isWorking
                                        ? (isDark ? Colors.white : Colors.black87)
                                        : (isDark ? Colors.white38 : Colors.black38),
                                  ),
                                ),
                              ),
                              Switch.adaptive(
                                value: isWorking,
                                activeTrackColor: accent,
                                onChanged: (val) {
                                  setState(() {
                                    dayData['is_working'] = val;
                                  });
                                },
                              ),
                              const SizedBox(width: 4),
                              Text(
                                isWorking ? 'Working' : 'Off Duty',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: isWorking ? NeumorphicColors.success : (isDark ? Colors.white38 : Colors.black38),
                                ),
                              ),
                            ],
                          ),

                          if (isWorking) ...[
                            const SizedBox(height: 8),
                            // Shift hours selector
                            Row(
                              children: [
                                const Icon(Icons.access_time_rounded, size: 15, color: Colors.grey),
                                const SizedBox(width: 6),
                                const Text(
                                  'Shift:',
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                                ),
                                const SizedBox(width: 10),
                                _buildTimeDropdown(
                                  value: dayData['start'] as String,
                                  isDark: isDark,
                                  accent: accent,
                                  onChanged: (val) {
                                    if (val != null) setState(() => dayData['start'] = val);
                                  },
                                ),
                                const Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 6),
                                  child: Text('–', style: TextStyle(fontWeight: FontWeight.w700)),
                                ),
                                _buildTimeDropdown(
                                  value: dayData['end'] as String,
                                  isDark: isDark,
                                  accent: accent,
                                  onChanged: (val) {
                                    if (val != null) setState(() => dayData['end'] = val);
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),

                            // Lunch Break selector
                            Row(
                              children: [
                                SizedBox(
                                  height: 24,
                                  width: 24,
                                  child: Checkbox(
                                    value: hasBreak,
                                    activeColor: accent,
                                    onChanged: (val) {
                                      setState(() {
                                        dayData['has_break'] = val ?? false;
                                      });
                                    },
                                  ),
                                ),
                                const SizedBox(width: 6),
                                const Text(
                                  'Lunch Break',
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                                ),
                                if (hasBreak) ...[
                                  const SizedBox(width: 12),
                                  _buildTimeDropdown(
                                    value: dayData['break_start'] as String,
                                    isDark: isDark,
                                    accent: accent,
                                    onChanged: (val) {
                                      if (val != null) setState(() => dayData['break_start'] = val);
                                    },
                                  ),
                                  const Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 6),
                                    child: Text('–', style: TextStyle(fontWeight: FontWeight.w700)),
                                  ),
                                  _buildTimeDropdown(
                                    value: dayData['break_end'] as String,
                                    isDark: isDark,
                                    accent: accent,
                                    onChanged: (val) {
                                      if (val != null) setState(() => dayData['break_end'] = val);
                                    },
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 16),

              // Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 12),
                  NeumorphicButton(
                    isPrimary: true,
                    height: 42,
                    onPressed: _isSaving ? null : _handleSave,
                    child: _isSaving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.check_rounded, size: 16),
                              SizedBox(width: 6),
                              Text('Save Shift Schedule', style: TextStyle(fontWeight: FontWeight.w700)),
                            ],
                          ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimeDropdown({
    required String value,
    required bool isDark,
    required Color accent,
    required ValueChanged<String?> onChanged,
  }) {
    final validValue = _timeOptions.contains(value) ? value : _timeOptions[6]; // default 09:00

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: accent.withValues(alpha: 0.2)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: validValue,
          isDense: true,
          dropdownColor: isDark ? NeumorphicColors.darkSurface : NeumorphicColors.lightSurface,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : Colors.black87,
          ),
          items: _timeOptions.map((time) {
            return DropdownMenuItem<String>(
              value: time,
              child: Text(_formatTimeStr(time)),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
