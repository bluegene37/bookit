// Gene - Nov, 03, 2026: Step 3 - Client Intake Form for clinical symptoms and special requests
// Gene - Nov, 04, 2026: Dynamic Intake Form rendering custom template intake fields (boolean, text, textarea)
import 'package:flutter/material.dart';
import '../../../../core/theme/neumorphic_colors.dart';
import '../../../../core/widgets/neumorphic_text_field.dart';
import '../../../../models/service_item.dart';
import '../../../../models/business.dart';

class ClientIntakeStep extends StatefulWidget {
  final Business? business;
  final ServiceItem? service;
  final String initialNotes;
  final ValueChanged<String> onNotesChanged;

  /*
  // Gene - Nov, 03, 2026: Previous constructor without business parameter
  const ClientIntakeStep({
    super.key,
    required this.service,
    required this.initialNotes,
    required this.onNotesChanged,
  });
  */

  // Gene - Nov, 04, 2026: Updated constructor accepting business for template intake fields
  const ClientIntakeStep({
    super.key,
    this.business,
    required this.service,
    required this.initialNotes,
    required this.onNotesChanged,
  });

  @override
  State<ClientIntakeStep> createState() => _ClientIntakeStepState();
}

class _ClientIntakeStepState extends State<ClientIntakeStep> {
  late TextEditingController _notesController;
  final Map<String, TextEditingController> _dynamicControllers = {};
  final Map<String, bool> _dynamicBooleans = {};
  // Gene - Nov 06, 2026: Added dynamic select state map for dropdown options (e.g. Fitzpatrick scale)
  final Map<String, String> _dynamicSelects = {};
  // Gene - Nov 06, 2026: Added multi-select chips and signature/waiver state maps for specialized intake
  final Map<String, Set<String>> _dynamicMultiSelects = {};
  final Map<String, bool> _dynamicSignatures = {};

  @override
  void initState() {
    super.initState();
    _notesController = TextEditingController(text: widget.initialNotes);

    // Initialize dynamic controllers if business has custom intake fields
    if (widget.business != null && widget.business!.intakeFields.isNotEmpty) {
      for (final field in widget.business!.intakeFields) {
        final id = field['id'] as String;
        final type = field['type'] as String? ?? 'text';
        if (type == 'boolean') {
          _dynamicBooleans[id] = false;
        } else if (type == 'select') {
          final options = (field['options'] as List?)?.map((e) => e.toString()).toList() ?? [];
          _dynamicSelects[id] = options.isNotEmpty ? options.first : '';
        } else if (type == 'multiselect') {
          _dynamicMultiSelects[id] = <String>{};
        } else if (type == 'signature') {
          _dynamicSignatures[id] = false;
        } else {
          _dynamicControllers[id] = TextEditingController();
        }
      }
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    for (final c in _dynamicControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _syncNotes() {
    if (widget.business != null && widget.business!.intakeFields.isNotEmpty) {
      final buffer = StringBuffer();
      for (final field in widget.business!.intakeFields) {
        final id = field['id'] as String;
        final label = field['label'] as String;
        final type = field['type'] as String? ?? 'text';
        if (type == 'boolean') {
          final val = _dynamicBooleans[id] == true ? 'Yes' : 'No';
          buffer.writeln('$label: $val');
        } else if (type == 'select') {
          final val = _dynamicSelects[id] ?? '';
          if (val.isNotEmpty) {
            buffer.writeln('$label: $val');
          }
        // Gene - Nov 06, 2026: Format multi-select choices and signed waivers into appointment clinical notes
        } else if (type == 'multiselect') {
          final set = _dynamicMultiSelects[id] ?? <String>{};
          if (set.isNotEmpty) {
            buffer.writeln('$label: ${set.join(', ')}');
          }
        } else if (type == 'signature') {
          final signed = _dynamicSignatures[id] == true ? 'Acknowledged & Signed' : 'Pending Signature';
          buffer.writeln('$label: $signed');
        } else {
          final val = _dynamicControllers[id]?.text.trim() ?? '';
          if (val.isNotEmpty) {
            buffer.writeln('$label: $val');
          }
        }
      }
      final general = _notesController.text.trim();
      if (general.isNotEmpty) {
        buffer.writeln('\nAdditional Notes: $general');
      }
      widget.onNotesChanged(buffer.toString().trim());
    } else {
      widget.onNotesChanged(_notesController.text);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? NeumorphicColors.tealLight : NeumorphicColors.tealPrimary;
    final intakeFields = widget.business?.intakeFields ?? [];

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.business != null
                ? '${widget.business!.serviceLabel} Intake & Requirements'
                : 'Intake & Visit Notes',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: isDark ? NeumorphicColors.darkTextPrimary : NeumorphicColors.lightTextPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Please complete the preliminary intake details below to ensure your booking is prepared with care.',
            style: TextStyle(
              fontSize: 13,
              color: isDark ? NeumorphicColors.darkTextSecondary : NeumorphicColors.lightTextSecondary,
            ),
          ),
          const SizedBox(height: 20),

          // Render Dynamic Template Fields if present
          if (intakeFields.isNotEmpty) ...[
            ...intakeFields.map((field) {
              final id = field['id'] as String;
              final label = field['label'] as String;
              final type = field['type'] as String? ?? 'text';
              final placeholder = field['placeholder'] as String? ?? '';
              final required = field['required'] as bool? ?? false;

              /*
              // Gene - Nov, 04, 2026: Previous dynamic field rendering supporting only basic boolean and text fields
              if (type == 'boolean') {
                final isChecked = _dynamicBooleans[id] ?? false;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            label + (required ? ' *' : ''),
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                        ),
                        Switch(
                          value: isChecked,
                          activeTrackColor: accent,
                          onChanged: (val) {
                            setState(() => _dynamicBooleans[id] = val);
                            _syncNotes();
                          },
                        ),
                      ],
                    ),
                  ),
                );
              }
              */

              // Gene - Nov 06, 2026: Added select dropdown, contraindication alert banner, and helper text rendering
              if (type == 'select') {
                final options = (field['options'] as List?)?.map((e) => e.toString()).toList() ?? [];
                final selectedVal = _dynamicSelects[id] ?? (options.isNotEmpty ? options.first : '');
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          label + (required ? ' *' : ''),
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 6),
                        DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: options.contains(selectedVal) ? selectedVal : (options.isNotEmpty ? options.first : null),
                            isExpanded: true,
                            dropdownColor: isDark ? NeumorphicColors.darkSurface : NeumorphicColors.lightSurface,
                            items: options.map((opt) {
                              return DropdownMenuItem<String>(
                                value: opt,
                                child: Text(opt, style: const TextStyle(fontSize: 13)),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setState(() => _dynamicSelects[id] = val);
                                _syncNotes();
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              if (type == 'boolean') {
                final isChecked = _dynamicBooleans[id] ?? false;
                final helperText = field['helper_text'] as String?;
                final blockingCondition = field['blocking_condition'] as bool? ?? false;
                final blockingMessage = field['blocking_message'] as String?;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                label + (required ? ' *' : ''),
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                              ),
                            ),
                            Switch(
                              value: isChecked,
                              activeTrackColor: accent,
                              onChanged: (val) {
                                setState(() => _dynamicBooleans[id] = val);
                                _syncNotes();
                              },
                            ),
                          ],
                        ),
                        if (helperText != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            helperText,
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark ? Colors.white60 : Colors.black54,
                            ),
                          ),
                        ],
                        if (blockingCondition && isChecked && blockingMessage != null) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: NeumorphicColors.error.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: NeumorphicColors.error.withValues(alpha: 0.3)),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.warning_amber_rounded, size: 16, color: NeumorphicColors.error),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    blockingMessage,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: NeumorphicColors.error,
                                      fontWeight: FontWeight.w600,
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
              }

              // Gene - Nov 06, 2026: Added multiselect chip group rendering (e.g. massage focus areas, chemical history, fitness limitations)
              if (type == 'multiselect') {
                final options = (field['options'] as List?)?.map((e) => e.toString()).toList() ?? [];
                final selectedSet = _dynamicMultiSelects[id] ?? <String>{};
                final helperText = field['helper_text'] as String?;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          label + (required ? ' *' : ''),
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                        if (helperText != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            helperText,
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark ? Colors.white60 : Colors.black54,
                            ),
                          ),
                        ],
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: options.map((opt) {
                            final isSelected = selectedSet.contains(opt);
                            return FilterChip(
                              label: Text(
                                opt,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                ),
                              ),
                              selected: isSelected,
                              selectedColor: accent,
                              checkmarkColor: Colors.white,
                              backgroundColor: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.05),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              onSelected: (selected) {
                                setState(() {
                                  if (selected) {
                                    selectedSet.add(opt);
                                  } else {
                                    selectedSet.remove(opt);
                                  }
                                  _dynamicMultiSelects[id] = selectedSet;
                                });
                                _syncNotes();
                              },
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                );
              }

              // Gene - Nov 06, 2026: Added signature & waiver disclaimer card with acknowledgment toggle
              if (type == 'signature') {
                final isSigned = _dynamicSignatures[id] ?? false;
                final disclaimer = field['disclaimer'] as String? ?? '';

                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSigned
                            ? NeumorphicColors.tealPrimary.withValues(alpha: 0.5)
                            : (isDark ? Colors.white12 : Colors.black12),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          label + (required ? ' *' : ''),
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                        ),
                        if (disclaimer.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: isDark ? Colors.black.withValues(alpha: 0.25) : Colors.white.withValues(alpha: 0.7),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              disclaimer,
                              style: TextStyle(
                                fontSize: 11,
                                fontStyle: FontStyle.italic,
                                color: isDark ? Colors.white70 : Colors.black87,
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Checkbox(
                              value: isSigned,
                              activeColor: accent,
                              onChanged: (val) {
                                setState(() => _dynamicSignatures[id] = val ?? false);
                                _syncNotes();
                              },
                            ),
                            Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  setState(() => _dynamicSignatures[id] = !isSigned);
                                  _syncNotes();
                                },
                                child: Text(
                                  'I have read, understood, and agree to the terms above',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: isSigned ? FontWeight.w600 : FontWeight.normal,
                                    color: isDark ? Colors.white : Colors.black87,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }

              final controller = _dynamicControllers[id];
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: NeumorphicTextField(
                  controller: controller ?? TextEditingController(),
                  labelText: label + (required ? ' *' : ''),
                  hintText: placeholder,
                  maxLines: type == 'textarea' ? 3 : 1,
                  onChanged: (_) => _syncNotes(),
                ),
              );
            }),
            const SizedBox(height: 8),
          ],

          // General / Additional Notes Field
          NeumorphicTextField(
            controller: _notesController,
            labelText: intakeFields.isNotEmpty ? 'Additional Comments or Requests (Optional)' : 'Symptoms or Reason for Visit (Optional)',
            hintText: 'Any other specific instructions, accessibility needs, or inquiries...',
            maxLines: 3,
            onChanged: (_) => _syncNotes(),
          ),
          const SizedBox(height: 20),

          // Privacy note
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.privacy_tip_outlined, size: 20, color: NeumorphicColors.tealPrimary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Your intake and booking details are protected under strict confidentiality standards and shared only with your assigned ${widget.business?.resourceLabel.toLowerCase() ?? "provider"}.',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.white60 : Colors.black54,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

