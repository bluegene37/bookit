import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// Gene - Nov, 22, 2026: Added flutter_map and MapTileConfig imports to verify key-free OpenStreetMap tile configuration
import 'package:flutter_map/flutter_map.dart';
import 'package:bookit/core/constants/map_tile_config.dart';
import 'package:bookit/models/business.dart';
import 'package:bookit/services/business_service.dart';
import 'package:bookit/features/admin/presentation/widgets/location_pin_picker.dart';
import 'package:bookit/features/discovery/presentation/widgets/storefront_directions_card.dart';
import 'package:bookit/features/discovery/presentation/widgets/discovery_map_view.dart';
import 'package:bookit/features/discovery/presentation/home_discovery_screen.dart';

void main() {
  final sampleBusiness = Business.fallback(
    id: 'test-biz-map-1',
    name: 'Metropolitan Dental Care',
  ).copyWith(
    address: '450 Sutter St, Suite 800',
    city: 'San Francisco',
    latitude: 37.7879,
    longitude: -122.4074,
  );

  group('Map & Geolocation Feature Tests', () {
    testWidgets('LocationPinPicker renders interactive map canvas and address preview', (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 600));

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: LocationPinPicker(
                initialLatitude: 37.7879,
                initialLongitude: -122.4074,
                label: 'Clinic Map Location',
                height: 250,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Clinic Map Location'), findsOneWidget);
      expect(find.text('Tap map to set pin'), findsOneWidget);
      expect(find.byType(LocationPinPicker), findsOneWidget);
    });

    testWidgets('StorefrontDirectionsCard renders map preview and navigation action buttons', (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 600));

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: StorefrontDirectionsCard(business: sampleBusiness),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Location & Directions'), findsOneWidget);
      expect(find.textContaining('450 Sutter St'), findsOneWidget);
      expect(find.text('Get Directions'), findsOneWidget);
      expect(find.text('Copy'), findsOneWidget);

      // Verify Copy button taps and shows snackbar
      await tester.tap(find.text('Copy'));
      await tester.pump();
      expect(find.text('Clinic address copied to clipboard!'), findsOneWidget);
    });

    testWidgets('HomeDiscoveryScreen segmented toggle switches between List and Map views', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1024, 768));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            businessListProvider.overrideWith((ref) async => [sampleBusiness]),
          ],
          child: const MaterialApp(
            home: HomeDiscoveryScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Initially on List view
      expect(find.text('List'), findsOneWidget);
      expect(find.text('Map'), findsOneWidget);
      expect(find.text('Metropolitan Dental Care'), findsOneWidget);
      expect(find.byType(DiscoveryMapView), findsNothing);

      // Tap on Map toggle
      await tester.tap(find.text('Map'));
      await tester.pumpAndSettle();

      // Now DiscoveryMapView is active
      expect(find.byType(DiscoveryMapView), findsOneWidget);
    });

    // Gene - Nov, 22, 2026: Verify all map widgets use zero-API-key OpenStreetMap tiles, adaptive dark-mode filtering, and ODbL attribution
    testWidgets('All map widgets use free zero-key OpenStreetMap tiles in light and dark themes', (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 600));

      void assertFreeOsmTileLayer(TileLayer tileLayer, {required bool expectDark}) {
        final url = tileLayer.urlTemplate ?? '';
        expect(url, equals(MapTileConfig.tileUrlTemplate));
        expect(url, equals('https://tile.openstreetmap.org/{z}/{x}/{y}.png'));
        expect(url.toLowerCase(), isNot(contains('cartocdn')));
        expect(url.toLowerCase(), isNot(contains('key=')));
        expect(url.toLowerCase(), isNot(contains('apikey')));
        expect(tileLayer.subdomains, isEmpty);
        if (expectDark) {
          expect(tileLayer.tileBuilder, isNotNull);
        } else {
          expect(tileLayer.tileBuilder, isNull);
        }
      }

      final widgetsToVerify = <Widget>[
        LocationPinPicker(
          initialLatitude: 37.7879,
          initialLongitude: -122.4074,
          height: 250,
        ),
        SingleChildScrollView(
          child: StorefrontDirectionsCard(business: sampleBusiness),
        ),
        DiscoveryMapView(businesses: [sampleBusiness]),
      ];

      for (final isDark in [false, true]) {
        for (final targetWidget in widgetsToVerify) {
          await tester.pumpWidget(
            ProviderScope(
              child: MaterialApp(
                theme: isDark ? ThemeData.dark() : ThemeData.light(),
                home: Scaffold(body: targetWidget),
              ),
            ),
          );
          await tester.pumpAndSettle();

          final tileLayer = tester.widget<TileLayer>(find.byType(TileLayer));
          assertFreeOsmTileLayer(tileLayer, expectDark: isDark);
          expect(find.text(MapTileConfig.attributionText), findsOneWidget);
        }
      }
    });
  });
}
