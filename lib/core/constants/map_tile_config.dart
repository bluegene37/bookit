// Gene - Nov, 22, 2026: Shared zero-API-key OpenStreetMap tile layer, dark mode filter, and attribution configuration
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';

class MapTileConfig {
  MapTileConfig._();

  static const String tileUrlTemplate =
      'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
  static const String userAgentPackageName = 'com.bookit.app';
  static const int maxNativeZoom = 19;
  static const String attributionText = '© OpenStreetMap';

  static Color backgroundColor(bool isDark) =>
      isDark ? const Color(0xFF141923) : const Color(0xFFE8ECEF);

  static TileLayer buildTileLayer({required bool isDark}) {
    return TileLayer(
      urlTemplate: tileUrlTemplate,
      subdomains: const [],
      maxNativeZoom: maxNativeZoom,
      userAgentPackageName: userAgentPackageName,
      tileBuilder: isDark ? darkModeTileBuilder : null,
    );
  }

  static Widget buildAttribution({
    required bool isDark,
    Alignment alignment = Alignment.bottomRight,
    EdgeInsets padding = const EdgeInsets.all(6),
  }) {
    return IgnorePointer(
      child: Align(
        alignment: alignment,
        child: Padding(
          padding: padding,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.black.withValues(alpha: 0.55)
                  : Colors.white.withValues(alpha: 0.82),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              attributionText,
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.white70 : Colors.black54,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
