import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:bookit/services/location_geocoding_service.dart';

class _MockHttpClient extends http.BaseClient {
  final Future<http.Response> Function(http.Request request) handler;
  _MockHttpClient(this.handler);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final req = request as http.Request;
    final res = await handler(req);
    return http.StreamedResponse(
      Stream.value(res.bodyBytes),
      res.statusCode,
      headers: res.headers,
    );
  }
}

void main() {
  group('LocationGeocodingService Unit Tests', () {
    test('searchAddress parses Nominatim JSON response correctly', () async {
      final mockClient = _MockHttpClient((req) async {
        expect(req.url.host, equals('nominatim.openstreetmap.org'));
        expect(req.url.path, equals('/search'));

        final sampleJson = [
          {
            'lat': '37.7879',
            'lon': '-122.4074',
            'display_name': '450 Sutter St, San Francisco, CA 94108, USA',
            'address': {
              'house_number': '450',
              'road': 'Sutter St',
              'city': 'San Francisco',
              'state': 'California',
              'postcode': '94108',
              'country': 'United States',
            },
          }
        ];

        return http.Response(jsonEncode(sampleJson), 200, headers: {'content-type': 'application/json'});
      });

      final service = LocationGeocodingService(client: mockClient);
      final results = await service.searchAddress('450 Sutter St');

      expect(results.length, equals(1));
      expect(results.first.latitude, equals(37.7879));
      expect(results.first.longitude, equals(-122.4074));
      expect(results.first.city, equals('San Francisco'));
      expect(results.first.formattedAddress, contains('450 Sutter St'));
    });

    test('reverseGeocode parses coordinates into street and city', () async {
      final mockClient = _MockHttpClient((req) async {
        expect(req.url.path, equals('/reverse'));

        final sampleJson = {
          'lat': '40.7580',
          'lon': '-73.9855',
          'display_name': 'Times Square, Manhattan, New York, USA',
          'address': {
            'road': 'Broadway',
            'city': 'New York',
            'state': 'New York',
            'country': 'United States',
          },
        };

        return http.Response(jsonEncode(sampleJson), 200, headers: {'content-type': 'application/json'});
      });

      final service = LocationGeocodingService(client: mockClient);
      final result = await service.reverseGeocode(40.7580, -73.9855);

      expect(result, isNotNull);
      expect(result!.city, equals('New York'));
      expect(result.latitude, equals(40.7580));
      expect(result.longitude, equals(-73.9855));
    });

    test('searchAddress caches results to avoid redundant network calls', () async {
      int requestCount = 0;
      final mockClient = _MockHttpClient((req) async {
        requestCount++;
        return http.Response(
          jsonEncode([
            {
              'lat': '34.0522',
              'lon': '-118.2437',
              'display_name': 'Los Angeles, CA',
              'address': {'city': 'Los Angeles'},
            }
          ]),
          200,
        );
      });

      final service = LocationGeocodingService(client: mockClient);
      await service.searchAddress('Los Angeles');
      await service.searchAddress('Los Angeles'); // Second call should hit cache

      expect(requestCount, equals(1));
    });

    test('Fallback search returns coordinates when network fails', () async {
      final mockClient = _MockHttpClient((req) async {
        throw Exception('Network offline');
      });

      final service = LocationGeocodingService(client: mockClient);
      final results = await service.searchAddress('San Francisco');

      expect(results.isNotEmpty, isTrue);
      expect(results.first.city, equals('San Francisco'));
      expect(results.first.latitude, closeTo(37.78, 0.1));
    });
  });
}
