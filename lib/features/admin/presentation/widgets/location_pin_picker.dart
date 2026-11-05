// Gene - Nov 06, 2026: Implemented LocationPinPicker using flutter_map with CartoDB light/dark tiles and Nominatim reverse geocoding
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' hide Path;
import 'package:bookit/core/theme/neumorphic_colors.dart';
import 'package:bookit/core/widgets/neumorphic_container.dart';
import 'package:bookit/services/location_geocoding_service.dart';

class LocationPinPicker extends ConsumerStatefulWidget {
  final double initialLatitude;
  final double initialLongitude;
  final ValueChanged<GeocodedLocation>? onLocationChanged;
  final double height;
  final bool isInteractive;
  final String? label;

  const LocationPinPicker({
    super.key,
    this.initialLatitude = 37.7749,
    this.initialLongitude = -122.4194,
    this.onLocationChanged,
    this.height = 240,
    this.isInteractive = true,
    this.label,
  });

  @override
  ConsumerState<LocationPinPicker> createState() => LocationPinPickerState();
}

class LocationPinPickerState extends ConsumerState<LocationPinPicker> {
  late final MapController _mapController;
  late LatLng _currentPosition;
  String? _addressPreview;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _currentPosition = LatLng(widget.initialLatitude, widget.initialLongitude);
    _reverseGeocodeInitial();
  }

  Future<void> _reverseGeocodeInitial() async {
    final geocoder = ref.read(locationGeocodingServiceProvider);
    final loc = await geocoder.reverseGeocode(_currentPosition.latitude, _currentPosition.longitude);
    if (mounted && loc != null) {
      setState(() {
        _addressPreview = loc.formattedAddress;
      });
    }
  }

  /// Programmatically move map to a given coordinate (e.g. from address search)
  void moveToLocation(double latitude, double longitude, {String? addressLabel}) {
    final newPos = LatLng(latitude, longitude);
    setState(() {
      _currentPosition = newPos;
      if (addressLabel != null) {
        _addressPreview = addressLabel;
      }
    });
    try {
      _mapController.move(newPos, 15.5);
    } catch (_) {}
  }

  Future<void> _onMapTapped(TapPosition tapPosition, LatLng point) async {
    if (!widget.isInteractive) return;

    setState(() {
      _currentPosition = point;
      _isLoading = true;
    });

    final geocoder = ref.read(locationGeocodingServiceProvider);
    final loc = await geocoder.reverseGeocode(point.latitude, point.longitude);

    if (mounted) {
      setState(() {
        _isLoading = false;
        if (loc != null) {
          _addressPreview = loc.formattedAddress;
        }
      });
      if (loc != null && widget.onLocationChanged != null) {
        widget.onLocationChanged!(loc);
      }
    }
  }

  Future<void> _locateCurrentPosition() async {
    setState(() => _isLoading = true);
    final geocoder = ref.read(locationGeocodingServiceProvider);
    final loc = await geocoder.getCurrentLocation();
    if (mounted) {
      setState(() => _isLoading = false);
      if (loc != null) {
        moveToLocation(loc.latitude, loc.longitude, addressLabel: loc.formattedAddress);
        if (widget.onLocationChanged != null) {
          widget.onLocationChanged!(loc);
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not obtain current GPS location. Please check browser/device permissions.'),
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

    // CartoDB tiles matching BookIt dark / light palettes
    final tileUrl = isDark
        ? 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}@2x.png'
        : 'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}@2x.png';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label != null) ...[
          /*
          // Original unconstrained label Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.label!,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: isDark ? NeumorphicColors.darkTextPrimary : NeumorphicColors.lightTextPrimary,
                ),
              ),
              if (widget.isInteractive)
                Text(
                  'Tap map to set pin',
                  style: TextStyle(
                    fontSize: 11,
                    color: accent,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
          */
          // Gene - Nov 06, 2026: Wrapped location label in Expanded with ellipsis to prevent RenderFlex overflow on constrained widths
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  widget.label!,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: isDark ? NeumorphicColors.darkTextPrimary : NeumorphicColors.lightTextPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (widget.isInteractive) ...[
                const SizedBox(width: 8),
                Text(
                  'Tap map to set pin',
                  style: TextStyle(
                    fontSize: 11,
                    color: accent,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
        ],

        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: NeumorphicContainer(
            height: widget.height,
            padding: EdgeInsets.zero,
            child: Stack(
              children: [
                // Interactive OpenStreetMap Layer
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _currentPosition,
                    initialZoom: 15.0,
                    onTap: widget.isInteractive ? _onMapTapped : null,
                    interactionOptions: InteractionOptions(
                      flags: widget.isInteractive
                          ? InteractiveFlag.all
                          : InteractiveFlag.none,
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
                          point: _currentPosition,
                          width: 44,
                          height: 44,
                          alignment: Alignment.topCenter,
                          child: _PinMarker(accent: accent),
                        ),
                      ],
                    ),
                  ],
                ),

                // Floating "Locate Me" GPS Button
                if (widget.isInteractive)
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _isLoading ? null : _locateCurrentPosition,
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1E2330).withValues(alpha: 0.9) : Colors.white.withValues(alpha: 0.9),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.15),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: _isLoading
                              ? SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: accent),
                                )
                              : Icon(Icons.my_location, size: 18, color: accent),
                        ),
                      ),
                    ),
                  ),

                // Address Preview Bar at Bottom of Map
                if (_addressPreview != null)
                  Positioned(
                    left: 10,
                    right: 10,
                    bottom: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: (isDark ? const Color(0xFF1A1F2C) : Colors.white).withValues(alpha: 0.92),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: accent.withValues(alpha: 0.3)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.place, size: 14, color: accent),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              _addressPreview!,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: isDark ? NeumorphicColors.darkTextPrimary : NeumorphicColors.lightTextPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _PinMarker extends StatelessWidget {
  final Color accent;
  const _PinMarker({required this.accent});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: accent,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: accent.withValues(alpha: 0.4),
                blurRadius: 8,
                spreadRadius: 2,
              ),
            ],
          ),
          child: const Icon(Icons.storefront_rounded, size: 18, color: Colors.white),
        ),
        CustomPaint(
          size: const Size(8, 6),
          painter: _TrianglePainter(accent),
        ),
      ],
    );
  }
}

class _TrianglePainter extends CustomPainter {
  final Color color;
  _TrianglePainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
