// Gene - Nov, 05, 2026: Added reception QR scanner modal, check-in action sheet, and booking state transitions
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../../core/theme/neumorphic_colors.dart';
import '../../../../core/widgets/neumorphic_container.dart';
import '../../../../core/widgets/neumorphic_button.dart';
import '../../../../models/booking.dart';
import '../../../../services/booking_service.dart';
import 'check_in_action_dialog.dart';

class ReceptionQrScannerModal extends ConsumerStatefulWidget {
  const ReceptionQrScannerModal({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => const ReceptionQrScannerModal(),
    );
  }

  @override
  ConsumerState<ReceptionQrScannerModal> createState() => _ReceptionQrScannerModalState();
}

class _ReceptionQrScannerModalState extends ConsumerState<ReceptionQrScannerModal> {
  final TextEditingController _codeController = TextEditingController();
  MobileScannerController? _scannerController;
  bool _hasProcessed = false;
  String? _errorMessage;

  bool get _isTestMode {
    if (kIsWeb) return false;
    try {
      return Platform.environment.containsKey('FLUTTER_TEST');
    } catch (_) {
      return false;
    }
  }

  @override
  void initState() {
    super.initState();
    if (!_isTestMode) {
      _scannerController = MobileScannerController(
        detectionSpeed: DetectionSpeed.noDuplicates,
        facing: CameraFacing.back,
      );
    }
  }

  @override
  void dispose() {
    _codeController.dispose();
    _scannerController?.dispose();
    super.dispose();
  }

  void _handleCodeDetected(String rawCode) {
    if (_hasProcessed) return;

    final bookings = ref.read(bookingsProvider);
    final matched = _findBookingFromInput(rawCode, bookings);

    if (matched != null) {
      _hasProcessed = true;
      Navigator.of(context).pop();
      CheckInActionDialog.show(context, matched);
    } else {
      setState(() {
        _errorMessage = 'No booking found matching "$rawCode"';
      });
    }
  }

  Booking? _findBookingFromInput(String input, List<Booking> bookings) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) return null;

    // 1. URL parsing (e.g., https://bookit.app/checkin/<bookingId>?token=<token>)
    String? extractedId;
    String? extractedToken;
    try {
      final uri = Uri.tryParse(trimmed);
      if (uri != null && uri.pathSegments.isNotEmpty) {
        final checkinIdx = uri.pathSegments.indexOf('checkin');
        if (checkinIdx != -1 && checkinIdx + 1 < uri.pathSegments.length) {
          extractedId = uri.pathSegments[checkinIdx + 1];
        }
        extractedToken = uri.queryParameters['token'];
      }
    } catch (_) {}

    for (final b in bookings) {
      if (extractedId != null && b.id.toLowerCase() == extractedId.toLowerCase()) {
        return b;
      }
      if (extractedToken != null && b.qrToken != null && b.qrToken!.toLowerCase() == extractedToken.toLowerCase()) {
        return b;
      }
      if (b.id.toLowerCase() == trimmed.toLowerCase()) {
        return b;
      }
      if (b.qrToken != null && b.qrToken!.toLowerCase() == trimmed.toLowerCase()) {
        return b;
      }
    }

    // Fallback fuzzy search: check if raw input contains or is contained in ID or qrToken
    for (final b in bookings) {
      if (b.id.toLowerCase().contains(trimmed.toLowerCase()) ||
          (b.qrToken != null && b.qrToken!.toLowerCase().contains(trimmed.toLowerCase()))) {
        return b;
      }
    }

    return null;
  }

  void _handleManualLookup() {
    final code = _codeController.text.trim();
    if (code.isEmpty) {
      setState(() => _errorMessage = 'Please enter a booking code or pass token');
      return;
    }
    _handleCodeDetected(code);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? NeumorphicColors.tealLight : NeumorphicColors.tealPrimary;
    final textPrimary = isDark ? NeumorphicColors.darkTextPrimary : NeumorphicColors.lightTextPrimary;
    final textSecondary = isDark ? NeumorphicColors.darkTextSecondary : NeumorphicColors.lightTextSecondary;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: SingleChildScrollView(
          child: NeumorphicContainer(
            borderRadius: 24,
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Modal Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.qr_code_scanner_rounded, size: 22, color: accent),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Reception QR Check-In',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: textPrimary,
                            ),
                          ),
                          Text(
                            'Scan Boarding Pass or Enter Code',
                            style: TextStyle(
                              fontSize: 12,
                              color: textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close_rounded, size: 20, color: textSecondary),
                      onPressed: () => Navigator.of(context).pop(),
                      tooltip: 'Close',
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Camera Scanner Viewfinder Box
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    height: 200,
                    color: isDark ? Colors.black45 : Colors.black87,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        if (!_isTestMode && _scannerController != null)
                          MobileScanner(
                            controller: _scannerController,
                            onDetect: (capture) {
                              for (final barcode in capture.barcodes) {
                                final val = barcode.rawValue;
                                if (val != null && val.isNotEmpty) {
                                  _handleCodeDetected(val);
                                  break;
                                }
                              }
                            },
                            errorBuilder: (context, error, child) {
                              return Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.videocam_off_outlined, color: Colors.white54, size: 36),
                                      const SizedBox(height: 8),
                                      const Text(
                                        'Camera feed unavailable',
                                        style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Use manual code entry or USB scanner below.',
                                        style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 11),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          )
                        else
                          Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.qr_code_2_rounded, size: 48, color: accent.withValues(alpha: 0.7)),
                                const SizedBox(height: 8),
                                const Text(
                                  'Ready to scan QR / Barcode',
                                  style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ),

                        // Viewfinder Targeting Frame Overlay
                        Container(
                          width: 130,
                          height: 130,
                          decoration: BoxDecoration(
                            border: Border.all(color: accent, width: 2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 18),

                // Error Message if lookup fails
                if (_errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: NeumorphicColors.error.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: NeumorphicColors.error.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline_rounded, size: 16, color: NeumorphicColors.error),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(fontSize: 12, color: NeumorphicColors.error, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                // Manual Input Fallback (for Desktop Web, USB Barcode Scanners, or Manual Typists)
                Text(
                  'Manual Entry / USB Barcode Scanner',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _codeController,
                        autofocus: true,
                        decoration: InputDecoration(
                          hintText: 'e.g. BK-123456 or booking URL',
                          hintStyle: TextStyle(fontSize: 13, color: textSecondary.withValues(alpha: 0.6)),
                          filled: true,
                          fillColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          prefixIcon: Icon(Icons.keyboard_alt_outlined, size: 18, color: textSecondary),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: isDark ? Colors.white12 : Colors.black12),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: isDark ? Colors.white12 : Colors.black12),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: accent, width: 1.5),
                          ),
                        ),
                        onSubmitted: (_) => _handleManualLookup(),
                      ),
                    ),
                    const SizedBox(width: 10),
                    NeumorphicButton(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      icon: Icons.search_rounded,
                      onPressed: _handleManualLookup,
                      child: const Text('Verify', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
