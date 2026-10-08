import 'package:flutter_test/flutter_test.dart';
import 'package:metal_recycling_app/core/constants/app_constants.dart';
import 'package:metal_recycling_app/models/service_model.dart';
import 'package:metal_recycling_app/services/location_service.dart';

void main() {
  group('TC03 - Metal Category Selection & Metadata Verification', () {
    test('TC03.1: Verify core metal categories (Copper, Aluminium, Steel) exist with valid pricing', () {
      final metals = AppConstants.metalCategories;
      final names = metals.map((m) => m.name.toLowerCase()).toList();

      expect(names.contains('copper'), isTrue);
      expect(names.contains('aluminium'), isTrue);
      expect(names.contains('steel'), isTrue);

      for (var metal in metals) {
        expect(metal.estimatedPricePerKg, greaterThan(0.0));
        expect(metal.symbol.isNotEmpty, isTrue);
        expect(metal.environmentalImpact.isNotEmpty, isTrue);
      }
    });
  });

  group('TC04 - Recycling Service Discovery Filtering', () {
    final sampleServices = [
      const ServiceModel(
        serviceId: 's1',
        name: 'Copper King Recyclers',
        lat: 37.77,
        lng: -122.42,
        acceptedMetals: ['Copper', 'Brass'],
      ),
      const ServiceModel(
        serviceId: 's2',
        name: 'All-Alloy Steel & Metal Yard',
        lat: 37.78,
        lng: -122.41,
        acceptedMetals: ['Aluminium', 'Steel'],
      ),
      const ServiceModel(
        serviceId: 's3',
        name: 'Universal Scrap Foundry',
        lat: 37.76,
        lng: -122.43,
        acceptedMetals: ['Copper', 'Aluminium', 'Steel', 'Lead'],
      ),
    ];

    test('TC04.1: Filter services by metal category returns matching services', () {
      final copperServices = sampleServices.where(
        (s) => s.acceptedMetals.any((m) => m.toLowerCase() == 'copper'),
      ).toList();

      expect(copperServices.length, 2);
      expect(copperServices.map((s) => s.serviceId), containsAll(['s1', 's3']));
    });

    test('TC04.2: Filter services by Steel returns matching facilities', () {
      final steelServices = sampleServices.where(
        (s) => s.acceptedMetals.any((m) => m.toLowerCase() == 'steel'),
      ).toList();

      expect(steelServices.length, 2);
      expect(steelServices.map((s) => s.serviceId), containsAll(['s2', 's3']));
    });
  });

  group('TC05 - Location Service Distance Calculation', () {
    test('TC05.1: calculateDistance calculates accurate geodesic distance between coordinates', () {
      final locationService = LocationService();

      // Distance from SF (37.7749, -122.4194) to Oakland (37.8044, -122.2712) ~ 13.5 km
      final distance = locationService.calculateDistance(
        startLatitude: 37.7749,
        startLongitude: -122.4194,
        endLatitude: 37.8044,
        endLongitude: -122.2712,
      );

      expect(distance, greaterThan(12000)); // > 12km
      expect(distance, lessThan(16000));    // < 16km
    });
  });
}
