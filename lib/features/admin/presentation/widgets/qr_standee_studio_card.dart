// Gene - Nov, 05, 2026: Storefront QR Standee Studio widget for generating print-ready counter acrylics and door posters
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../../core/theme/neumorphic_colors.dart';
import '../../../../core/widgets/neumorphic_container.dart';
import '../../../../core/widgets/neumorphic_button.dart';
import '../../../../core/widgets/neumorphic_text_field.dart';
import '../../../../models/business.dart';

enum StandeeFormat {
  deskStandee,
  doorPoster;

  String get label {
    switch (this) {
      case StandeeFormat.deskStandee:
        return 'Acrylic Desk Standee (A5)';
      case StandeeFormat.doorPoster:
        return 'Storefront Door Poster (A4)';
    }
  }

  String get dimensions {
    switch (this) {
      case StandeeFormat.deskStandee:
        return 'A5 • 148 × 210 mm (5.8 × 8.3 in)';
      case StandeeFormat.doorPoster:
        return 'A4 • 210 × 297 mm (8.3 × 11.7 in)';
    }
  }

  String get printButtonLabel {
    switch (this) {
      case StandeeFormat.deskStandee:
        return 'Print Standee';
      case StandeeFormat.doorPoster:
        return 'Print Poster';
    }
  }
}

class QrStandeeStudioCard extends StatefulWidget {
  final Business business;

  const QrStandeeStudioCard({
    super.key,
    required this.business,
  });

  @override
  State<QrStandeeStudioCard> createState() => _QrStandeeStudioCardState();
}

class _QrStandeeStudioCardState extends State<QrStandeeStudioCard> {
  static const List<String> _headlinePresets = [
    'Scan to Book in 30 Seconds',
    "Walk-Ins Welcome — Check Today's Openings",
    'Reserve Your Spot Now',
  ];

  late String _headline;
  late TextEditingController _customHeadlineController;
  StandeeFormat _format = StandeeFormat.deskStandee;

  String get _bookingUrl =>
      'https://bookit.app/book/${widget.business.id}?ref=storefront_qr';

  @override
  void initState() {
    super.initState();
    _headline = _headlinePresets.first;
    _customHeadlineController = TextEditingController(text: _headline);
  }

  @override
  void dispose() {
    _customHeadlineController.dispose();
    super.dispose();
  }

  void _copyLink() {
    Clipboard.setData(ClipboardData(text: _bookingUrl));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Booking link copied to clipboard!'),
        backgroundColor: NeumorphicColors.tealPrimary,
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _showPrintDialog() {
    showDialog(
      context: context,
      builder: (ctx) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: SingleChildScrollView(
              child: NeumorphicContainer(
                borderRadius: 24,
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.print_rounded, color: NeumorphicColors.tealPrimary, size: 22),
                          const SizedBox(width: 8),
                          const Text(
                            'Print Preview',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.of(ctx).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: NeumorphicColors.tealPrimary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${_format.label} • ${_format.dimensions}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: NeumorphicColors.tealPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  // Mockup preview inside dialog
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 400),
                    child: SingleChildScrollView(
                      child: _buildPrintableStandee(isPrintPreview: true),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 12),
                      NeumorphicButton(
                        isPrimary: true,
                        height: 44,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        onPressed: () {
                          Navigator.of(ctx).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Sent ${_format.label} to printer!'),
                              backgroundColor: NeumorphicColors.tealPrimary,
                            ),
                          );
                        },
                        child: const Text('Send to Printer'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? NeumorphicColors.darkTextPrimary : NeumorphicColors.lightTextPrimary;
    final textSecondary = isDark ? NeumorphicColors.darkTextSecondary : NeumorphicColors.lightTextSecondary;

    return NeumorphicContainer(
      borderRadius: 20,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              NeumorphicContainer(
                isCircle: true,
                width: 44,
                height: 44,
                child: const Icon(
                  Icons.qr_code_2_rounded,
                  color: NeumorphicColors.tealPrimary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Storefront QR & Marketing Standee',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Turn walk-in foot traffic into confirmed appointments with an acrylic counter standee or door poster with a vector QR code.',
                      style: TextStyle(
                        fontSize: 12,
                        color: textSecondary,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Format Selector (Standee A5 vs Poster A4)
          Text(
            'Select Display Format',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _buildFormatOption(
                  format: StandeeFormat.deskStandee,
                  icon: Icons.desktop_windows_outlined,
                  subtitle: 'Desk / Counter Mockup',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildFormatOption(
                  format: StandeeFormat.doorPoster,
                  icon: Icons.picture_in_picture_rounded,
                  subtitle: 'Storefront Door / Wall',
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Headline Presets
          Text(
            'Standee Headline & Call to Action',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _headlinePresets.map((preset) {
              final isSelected = _headline == preset;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _headline = preset;
                    _customHeadlineController.text = preset;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? NeumorphicColors.tealPrimary
                        : (isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.04)),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? NeumorphicColors.tealPrimary
                          : (isDark ? Colors.white12 : Colors.black12),
                    ),
                  ),
                  child: Text(
                    preset,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected
                          ? Colors.white
                          : (isDark ? Colors.white70 : Colors.black87),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),

          // Custom Headline Input
          NeumorphicTextField(
            controller: _customHeadlineController,
            hintText: 'Customize display headline...',
            prefixIcon: const Icon(Icons.edit_note_rounded, size: 20),
            onChanged: (val) {
              setState(() {
                _headline = val.trim().isEmpty ? _headlinePresets.first : val;
              });
            },
          ),
          const SizedBox(height: 24),

          // Live Acrylic Standee Preview Centerpiece
          Center(
            child: _buildAcrylicDisplayContainer(
              child: _buildPrintableStandee(isPrintPreview: false),
            ),
          ),
          const SizedBox(height: 24),

          // Bottom Actions
          Row(
            children: [
              Expanded(
                child: NeumorphicButton(
                  height: 48,
                  icon: Icons.copy_rounded,
                  onPressed: _copyLink,
                  child: const Text('Copy Link'),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: NeumorphicButton(
                  height: 48,
                  isPrimary: true,
                  icon: Icons.print_rounded,
                  onPressed: _showPrintDialog,
                  child: Text(_format.printButtonLabel),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFormatOption({
    required StandeeFormat format,
    required IconData icon,
    required String subtitle,
  }) {
    final isSelected = _format == format;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? NeumorphicColors.tealLight : NeumorphicColors.tealPrimary;

    return GestureDetector(
      onTap: () => setState(() => _format = format),
      child: NeumorphicContainer(
        borderRadius: 14,
        isInset: isSelected,
        border: isSelected ? Border.all(color: accent, width: 2) : null,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected ? accent : (isDark ? Colors.white60 : Colors.black54),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    format.label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: isSelected ? accent : (isDark ? Colors.white : Colors.black87),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 10,
                      color: isDark ? NeumorphicColors.darkTextSecondary : NeumorphicColors.lightTextSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Wraps the printable card in an acrylic desk stand or poster frame effect
  Widget _buildAcrylicDisplayContainer({required Widget child}) {
    final isDesk = _format == StandeeFormat.deskStandee;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Acrylic glassy body
        Container(
          width: isDesk ? 290 : 310,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.8),
              width: isDesk ? 2.5 : 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
              if (isDesk)
                BoxShadow(
                  color: NeumorphicColors.tealPrimary.withValues(alpha: 0.08),
                  blurRadius: 24,
                  offset: const Offset(0, 4),
                ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: child,
          ),
        ),

        // Acrylic Base (Desk Standee only)
        if (isDesk) ...[
          Container(
            width: 220,
            height: 10,
            margin: const EdgeInsets.only(top: 2),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  Color(0xFFE2E8F0),
                  Color(0xFF94A3B8),
                  Color(0xFFCBD5E1),
                ],
              ),
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(6)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  /// The printable high-contrast white artwork with QR code, business details, and call-to-action
  Widget _buildPrintableStandee({required bool isPrintPreview}) {
    final qrSize = _format == StandeeFormat.deskStandee ? 150.0 : 170.0;
    final business = widget.business;

    return Container(
      color: Colors.white,
      padding: EdgeInsets.symmetric(
        horizontal: 20,
        vertical: _format == StandeeFormat.deskStandee ? 22 : 26,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Business category pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Text(
              business.category.replaceAll('_', ' ').toUpperCase(),
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.0,
                color: Color(0xFF475569),
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Business Name
          Text(
            business.name,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: Color(0xFF0F172A),
              letterSpacing: -0.3,
            ),
          ),
          if (business.address != null && business.address!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              business.address!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 11,
                color: Color(0xFF64748B),
              ),
            ),
          ],
          const SizedBox(height: 14),

          // Decorative divider
          Container(
            width: 48,
            height: 2,
            decoration: BoxDecoration(
              color: NeumorphicColors.tealPrimary,
              borderRadius: BorderRadius.circular(1),
            ),
          ),
          const SizedBox(height: 14),

          // Dynamic Headline
          Text(
            _headline,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: NeumorphicColors.tealPrimary,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 14),

          // QR Code Container
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: QrImageView(
              data: _bookingUrl,
              version: QrVersions.auto,
              size: qrSize,
              backgroundColor: Colors.white,
              eyeStyle: const QrEyeStyle(
                eyeShape: QrEyeShape.square,
                color: Color(0xFF0F172A),
              ),
              dataModuleStyle: const QrDataModuleStyle(
                dataModuleShape: QrDataModuleShape.square,
                color: Color(0xFF0F172A),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Instructions
          const FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.camera_alt_outlined, size: 14, color: Color(0xFF64748B)),
                SizedBox(width: 5),
                Text(
                  'Point camera to scan & book',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF334155),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'bookit.app/book/${business.id}',
            style: const TextStyle(
              fontSize: 10,
              fontFamily: 'monospace',
              color: Color(0xFF94A3B8),
            ),
          ),
          const SizedBox(height: 12),

          // Footer branding
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.verified_outlined, size: 12, color: NeumorphicColors.tealPrimary),
                  SizedBox(width: 4),
                  Text(
                    'Powered by BookIt',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
