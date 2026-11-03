// Gene - Nov, 03, 2026: Step 3 - Client Intake Form for clinical symptoms and special requests
import 'package:flutter/material.dart';
import '../../../../core/theme/neumorphic_colors.dart';
import '../../../../core/widgets/neumorphic_text_field.dart';
import '../../../../models/service_item.dart';

class ClientIntakeStep extends StatefulWidget {
  final ServiceItem? service;
  final String initialNotes;
  final ValueChanged<String> onNotesChanged;

  const ClientIntakeStep({
    super.key,
    required this.service,
    required this.initialNotes,
    required this.onNotesChanged,
  });

  @override
  State<ClientIntakeStep> createState() => _ClientIntakeStepState();
}

class _ClientIntakeStepState extends State<ClientIntakeStep> {
  late TextEditingController _notesController;

  @override
  void initState() {
    super.initState();
    _notesController = TextEditingController(text: widget.initialNotes);
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Patient Intake & Visit Notes',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: isDark ? NeumorphicColors.darkTextPrimary : NeumorphicColors.lightTextPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Help the clinic prepare for your visit by sharing symptoms, medical background, or preferences.',
            style: TextStyle(
              fontSize: 13,
              color: isDark ? NeumorphicColors.darkTextSecondary : NeumorphicColors.lightTextSecondary,
            ),
          ),
          const SizedBox(height: 20),

          NeumorphicTextField(
            controller: _notesController,
            labelText: 'Symptoms or Reason for Visit (Optional)',
            hintText: 'e.g., Tooth sensitivity on upper molar, routine dental checkup, or post-surgery care...',
            maxLines: 4,
            onChanged: widget.onNotesChanged,
          ),
          const SizedBox(height: 20),

          // Medical guidelines note
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
                    'Your medical and booking details are strictly protected under clinical privacy standards and will only be shared with your attending practitioner.',
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
