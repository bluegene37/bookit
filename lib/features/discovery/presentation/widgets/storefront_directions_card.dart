// Gene - Nov 06, 2026: Implemented StorefrontDirectionsCard with interactive map preview, directions launcher, and clipboard copy
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' hide Path;
import 'package:url_launcher/url_launcher.dart';
import 'package:bookit/core/theme/neumorphic_colors.dart';
import 'package:bookit/core/widgets/neumorphic_container.dart';
import 'package:bookit/core/widgets/neumorphic_button.dart';
import 'package:bookit/models/business.dart';

class StorefrontDirectionsCard extends StatelessWidget {
  final Business business;

  const StorefrontDirectionsCard({super.key, required this.business});

  Future<void> _openDirections(BuildContext context, double lat, double lng, String address) async {
    final destination = '$lat,$lng';
    final googleMapsUrl = Uri.parse('https://www.google.com/maps/dir/?api=1&destination=$destination');
    final appleMapsUrl = Uri.parse('https://maps.apple.com/?daddr=$destination');

    try {
      if (await canLaunchUrl(googleMapsUrl)) {
        await launchUrl(googleMapsUrl, mode: LaunchMode.externalApplication);
      } else if (await canLaunchUrl(appleMapsUrl)) {
        await launchUrl(appleMapsUrl, mode: LaunchMode.externalApplication);
      } else {
        await launchUrl(googleMapsUrl, mode: LaunchMode.platformDefault);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open map navigation: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _copyAddress(BuildContext context, String fullAddress) {
    Clipboard.setData(ClipboardData(text: fullAddress));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: const [
            Icon(Icons.check_circle, color: Colors.white, size: 16),
            SizedBox(width: 8),
            Text('Clinic address copied to clipboard!'),
          ],
        ),
        backgroundColor: NeumorphicColors.tealPrimary,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? NeumorphicColors.tealLight : NeumorphicColors.tealPrimary;

    final lat = business.latitude ?? 37.7749;
    final lng = business.longitude ?? -122.4194;
    final position = LatLng(lat, lng);
    final fullAddress = '${business.address ?? 'Address on file'}${business.city != null ? ', ${business.city}' : ''}';

    final tileUrl = isDark
        ? 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}@2x.png'
        : 'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}@2x.png';

    return NeumorphicContainer(
      borderRadius: 20.0,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.location_on_outlined, color: accent, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Location & Directions',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: isDark ? NeumorphicColors.darkTextPrimary : NeumorphicColors.lightTextPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      fullAddress,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? NeumorphicColors.darkTextSecondary : NeumorphicColors.lightTextSecondary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Map Viewport Preview
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: SizedBox(
              height: 170,
              child: FlutterMap(
                options: MapOptions(
                  initialCenter: position,
                  initialZoom: 15.0,
                  interactionOptions: const InteractionOptions(
                    flags: InteractiveFlag.pinchZoom | InteractiveFlag.drag,
                  ),
                ),
                children: [
                  TileLayer(
                    urlTemplate: tileUrl,
                    subdomains: const ['a', 'b', 'c', 'd'],
                    userAgentPackageName: 'com.bookit.app',
                  ),
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: position,
                        width: 44,
                        height: 44,
                        alignment: Alignment.topCenter,
                        child: _DirectionsPinMarker(accent: accent, businessName: business.name),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Action Buttons: Get Directions & Copy Address
          /*
          // Gene - Nov, 06, 2026: Single-row action buttons overflowed horizontally on 320px/375px at 1.5x text scale
          Row(
            children: [
              Expanded(
                child: NeumorphicButton(
                  isPrimary: true,
                  onPressed: () => _openDirections(context, lat, lng, fullAddress),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.directions, size: 16, color: Colors.white),
                      SizedBox(width: 8),
                      Text(
                        'Get Directions',
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              NeumorphicButton(
                onPressed: () => _copyAddress(context, fullAddress),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Row(
                  children: [
                    Icon(Icons.copy_rounded, size: 16, color: accent),
                    const SizedBox(width: 6),
                    Text(
                      'Copy',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: accent),
                    ),
                  ],
                ),
              ),
            ],
          ),
          */
          // Gene - Nov, 14, 2026: Responsive LayoutBuilder stacks action buttons under narrow/1.5x viewports with Flexible ellipsis labels
          LayoutBuilder(
            builder: (context, constraints) {
              final textScale = MediaQuery.textScalerOf(context).scale(1.0);
              final stackActions = constraints.maxWidth < 330 * textScale;
              final directionsBtn = NeumorphicButton(
                isPrimary: true,
                onPressed: () => _openDirections(context, lat, lng, fullAddress),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.directions, size: 16, color: Colors.white),
                    SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        'Get Directions',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              );
              final copyBtn = NeumorphicButton(
                onPressed: () => _copyAddress(context, fullAddress),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.copy_rounded, size: 16, color: accent),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        'Copy',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: accent),
                      ),
                    ),
                  ],
                ),
              );
              if (stackActions) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    directionsBtn,
                    const SizedBox(height: 10),
                    copyBtn,
                  ],
                );
              }
              return Row(
                children: [
                  Expanded(child: directionsBtn),
                  const SizedBox(width: 10),
                  copyBtn,
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _DirectionsPinMarker extends StatelessWidget {
  final Color accent;
  final String businessName;

  const _DirectionsPinMarker({required this.accent, required this.businessName});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: accent,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: accent.withValues(alpha: 0.5),
                blurRadius: 8,
                spreadRadius: 2,
              ),
            ],
          ),
          child: const Icon(Icons.storefront_rounded, size: 18, color: Colors.white),
        ),
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            color: accent,
            shape: BoxShape.circle,
          ),
        ),
      ],
    );
  }
}
