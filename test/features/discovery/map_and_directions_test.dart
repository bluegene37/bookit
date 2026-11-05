import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
  });
}
