// Gene - Nov 06, 2026: Implemented DiscoveryMapView with interactive OpenStreetMap, clinic pin markers, auto-fit camera bounds, and floating bottom preview card
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' hide Path;
import 'package:go_router/go_router.dart';
import 'package:bookit/core/theme/neumorphic_colors.dart';
import 'package:bookit/core/widgets/neumorphic_container.dart';
import 'package:bookit/core/widgets/safe_network_image.dart';
import 'package:bookit/models/business.dart';
import 'package:bookit/services/location_geocoding_service.dart';

final isDiscoveryMapViewProvider = StateProvider<bool>((ref) => false);
final selectedDiscoveryBusinessProvider = StateProvider<Business?>((ref) => null);

class DiscoveryMapView extends ConsumerStatefulWidget {
  final List<Business> businesses;

  const DiscoveryMapView({super.key, required this.businesses});

  @override
  ConsumerState<DiscoveryMapView> createState() => _DiscoveryMapViewState();
}

class _DiscoveryMapViewState extends ConsumerState<DiscoveryMapView> {
  late final MapController _mapController;
  bool _isLocating = false;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
  }

  LatLngBounds _calculateBounds() {
    if (widget.businesses.isEmpty) {
      return LatLngBounds(
        const LatLng(37.70, -122.52),
        const LatLng(37.82, -122.35),
      );
    }

    double minLat = 90.0, maxLat = -90.0;
    double minLng = 180.0, maxLng = -180.0;

    for (final b in widget.businesses) {
      final lat = b.latitude ?? 37.7749;
      final lng = b.longitude ?? -122.4194;
      if (lat < minLat) minLat = lat;
      if (lat > maxLat) maxLat = lat;
      if (lng < minLng) minLng = lng;
      if (lng > maxLng) maxLng = lng;
    }

    // Add padding margin if single point
    if (minLat == maxLat && minLng == maxLng) {
      minLat -= 0.02;
      maxLat += 0.02;
      minLng -= 0.02;
      maxLng += 0.02;
    }

    return LatLngBounds(LatLng(minLat, minLng), LatLng(maxLat, maxLng));
  }

  void _fitAllPins() {
    try {
      final bounds = _calculateBounds();
      _mapController.fitCamera(
        CameraFit.bounds(
          bounds: bounds,
          padding: const EdgeInsets.all(50),
        ),
      );
    } catch (_) {}
  }

  Future<void> _locateUser() async {
    setState(() => _isLocating = true);
    final geocoder = ref.read(locationGeocodingServiceProvider);
    final loc = await geocoder.getCurrentLocation();
    if (mounted) {
      setState(() => _isLocating = false);
      if (loc != null) {
        _mapController.move(LatLng(loc.latitude, loc.longitude), 14.5);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not detect GPS location. Please check browser permissions.'),
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
    final selectedBusiness = ref.watch(selectedDiscoveryBusinessProvider);

    final tileUrl = isDark
        ? 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}@2x.png'
        : 'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}@2x.png';

    final initialCenter = widget.businesses.isNotEmpty
        ? LatLng(widget.businesses.first.latitude ?? 37.7749, widget.businesses.first.longitude ?? -122.4194)
        : const LatLng(37.7749, -122.4194);

    return Stack(
      children: [
        // Full Interactive OpenStreetMap Canvas
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: initialCenter,
            initialZoom: 13.0,
            interactionOptions: const InteractionOptions(flags: InteractiveFlag.all),
            onTap: (tapPos, point) {
              if (selectedBusiness != null) {
                ref.read(selectedDiscoveryBusinessProvider.notifier).state = null;
              }
            },
          ),
          children: [
            TileLayer(
              urlTemplate: tileUrl,
              subdomains: const ['a', 'b', 'c', 'd'],
              userAgentPackageName: 'com.bookit.app',
            ),
            MarkerLayer(
              markers: widget.businesses.map((biz) {
                final isSelected = selectedBusiness?.id == biz.id;
                final pos = LatLng(biz.latitude ?? 37.7749, biz.longitude ?? -122.4194);
                return Marker(
                  point: pos,
                  width: isSelected ? 56 : 46,
                  height: isSelected ? 56 : 46,
                  alignment: Alignment.topCenter,
                  child: GestureDetector(
                    onTap: () {
                      ref.read(selectedDiscoveryBusinessProvider.notifier).state = biz;
                      _mapController.move(pos, 15.0);
                    },
                    child: _DiscoveryPin(
                      accent: accent,
                      isSelected: isSelected,
                      name: biz.name,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),

        // Floating Map Controls: "Locate Me" & "Fit All"
        Positioned(
          top: 16,
          right: 16,
          child: Column(
            children: [
              _MapControlButton(
                icon: Icons.my_location,
                tooltip: 'Locate Me',
                isLoading: _isLocating,
                onTap: _locateUser,
                isDark: isDark,
                accent: accent,
              ),
              const SizedBox(height: 8),
              _MapControlButton(
                icon: Icons.crop_free_rounded,
                tooltip: 'Fit All Clinics',
                onTap: _fitAllPins,
                isDark: isDark,
                accent: accent,
              ),
            ],
          ),
        ),

        // Floating Bottom Preview Card when a clinic pin is selected
        if (selectedBusiness != null)
          Positioned(
            left: 16,
            right: 16,
            bottom: 24,
            child: _ClinicMapPreviewCard(
              business: selectedBusiness,
              accent: accent,
              isDark: isDark,
              onClose: () {
                ref.read(selectedDiscoveryBusinessProvider.notifier).state = null;
              },
            ),
          ),
      ],
    );
  }
}

class _MapControlButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final bool isLoading;
  final bool isDark;
  final Color accent;

  const _MapControlButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.isLoading = false,
    required this.isDark,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Tooltip(
        message: tooltip,
        child: InkWell(
          onTap: isLoading ? null : onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E2330).withValues(alpha: 0.92) : Colors.white.withValues(alpha: 0.92),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: isLoading
                  ? SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: accent),
                    )
                  : Icon(icon, size: 20, color: accent),
            ),
          ),
        ),
      ),
    );
  }
}

class _DiscoveryPin extends StatelessWidget {
  final Color accent;
  final bool isSelected;
  final String name;

  const _DiscoveryPin({
    required this.accent,
    required this.isSelected,
    required this.name,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: isSelected ? 1.15 : 1.0,
      duration: const Duration(milliseconds: 200),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: isSelected ? Colors.amber : accent,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: [
                BoxShadow(
                  color: (isSelected ? Colors.amber : accent).withValues(alpha: 0.5),
                  blurRadius: isSelected ? 10 : 6,
                  spreadRadius: isSelected ? 2 : 1,
                ),
              ],
            ),
            child: Icon(
              Icons.medical_services_rounded,
              size: isSelected ? 18 : 15,
              color: isSelected ? Colors.black87 : Colors.white,
            ),
          ),
          Container(
            width: 6,
            height: 4,
            decoration: BoxDecoration(
              color: isSelected ? Colors.amber : accent,
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }
}

class _ClinicMapPreviewCard extends StatelessWidget {
  final Business business;
  final Color accent;
  final bool isDark;
  final VoidCallback onClose;

  const _ClinicMapPreviewCard({
    required this.business,
    required this.accent,
    required this.isDark,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return NeumorphicContainer(
      borderRadius: 20,
      padding: const EdgeInsets.all(14),
      border: Border.all(color: accent.withValues(alpha: 0.4), width: 1.5),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Clinic Thumbnail
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: 70,
                  height: 70,
                  child: SafeNetworkImage(
                    imageUrl: business.bannerUrl ?? '',
                    width: 70,
                    height: 70,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Title, rating, address
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            business.name,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: isDark ? NeumorphicColors.darkTextPrimary : NeumorphicColors.lightTextPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        InkWell(
                          onTap: onClose,
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.all(4),
                            child: Icon(Icons.close, size: 16, color: isDark ? Colors.white54 : Colors.black45),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 13),
                        const SizedBox(width: 3),
                        Text(
                          business.ratingAvg.toStringAsFixed(1),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: isDark ? NeumorphicColors.darkTextPrimary : NeumorphicColors.lightTextPrimary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          business.category,
                          style: TextStyle(fontSize: 11, color: isDark ? Colors.white54 : Colors.black54),
                        ),
                      ],
                    ),
                    if (business.address != null) ...[
                      const SizedBox(height: 3),
                      Text(
                        '${business.address!}, ${business.city ?? ''}',
                        style: TextStyle(fontSize: 11, color: isDark ? Colors.white38 : Colors.black38),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Action row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  business.bookingModel.displayName.split('(').first.trim(),
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: accent),
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => context.push('/business/${business.id}'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: accent,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.calendar_today_rounded, size: 13),
                label: const Text('Book Now', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
