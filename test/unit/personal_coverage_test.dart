import 'package:flutter_test/flutter_test.dart';
import 'package:around_app/core/services/personal_coverage_engine.dart';
import 'package:around_app/data/models/place_model.dart';

void main() {
  group('P24-01: PersonalCoverageEngine Unit Tests', () {
    final mockPlaces = [
      const PlaceModel(
        id: 'place_breadly',
        slug: 'breadly-bakery',
        name: 'Breadly Bakery',
        category: 'Bakery',
        streetAddress: 'Mirabad',
        district: 'Mirabad',
        latitude: 41.2996,
        longitude: 69.2748,
        heroImageUrl: '',
      ),
      const PlaceModel(
        id: 'place_ecorn',
        slug: 'ecorn-bistro',
        name: 'Ecorn Bistro',
        category: 'Café',
        streetAddress: 'Mirabad',
        district: 'Mirabad',
        latitude: 41.2990,
        longitude: 69.2750,
        heroImageUrl: '',
      ),
      const PlaceModel(
        id: 'place_bnb',
        slug: 'bnb-coffee',
        name: 'B&B Coffee House',
        category: 'Café',
        streetAddress: 'Yakkasaray',
        district: 'Yakkasaray',
        latitude: 41.2918,
        longitude: 69.2619,
        heroImageUrl: '',
      ),
      const PlaceModel(
        id: 'place_chorsu',
        slug: 'chorsu-bazaar',
        name: 'Chorsu Traditional Market',
        category: 'Market',
        streetAddress: 'Old City',
        district: 'Old City',
        latitude: 41.3267,
        longitude: 69.2375,
        heroImageUrl: '',
      ),
    ];

    test('empty visited set yields 0% overall coverage and identifies unexplored districts', () {
      final report = PersonalCoverageEngine.calculateCoverage(
        visitedPlaceIds: {},
        catalogPlaces: mockPlaces,
      );

      expect(report.totalVisited, equals(0));
      expect(report.totalPlaces, equals(4));
      expect(report.overallPercentage, equals(0));
      expect(report.overallFraction, equals(0.0));
      expect(report.districts.length, equals(5));

      final mirabad = report.districts['Mirabad']!;
      expect(mirabad.visitedCount, equals(0));
      expect(mirabad.totalPlaces, equals(2));
      expect(mirabad.coveragePercent, equals(0));
      expect(mirabad.statusLevel, equals('unexplored'));
      expect(mirabad.localizedStatus('en'), contains('Unexplored'));
    });

    test('visiting places updates district coverage fractions and mastered status', () {
      // Visit both Mirabad places -> 100% Mirabad coverage
      final report = PersonalCoverageEngine.calculateCoverage(
        visitedPlaceIds: {'place_breadly', 'place_ecorn'},
        catalogPlaces: mockPlaces,
      );

      expect(report.totalVisited, equals(2));
      expect(report.overallPercentage, equals(50)); // 2 / 4 = 50%

      final mirabad = report.districts['Mirabad']!;
      expect(mirabad.visitedCount, equals(2));
      expect(mirabad.coveragePercent, equals(100));
      expect(mirabad.statusLevel, equals('mastered'));
      expect(mirabad.localizedStatus('uz'), contains('O‘zlashtirilgan'));
      expect(mirabad.localizedStatus('ru'), contains('Освоено'));
    });

    test('identifies least explored district and recommends an unvisited place', () {
      final report = PersonalCoverageEngine.calculateCoverage(
        visitedPlaceIds: {'place_breadly', 'place_ecorn'}, // Visited Mirabad only
        catalogPlaces: mockPlaces,
      );

      expect(report.mostExploredDistrict?.district, equals('Mirabad'));
      expect(report.leastExploredDistrict, isNotNull);
      expect(report.recommendedPlaceId, isNotNull);
      expect(
        report.recommendedPlaceId,
        anyOf(equals('place_bnb'), equals('place_chorsu')),
      );
    });

    test('formattedCityScore localizes across all 3 languages', () {
      final report = PersonalCoverageEngine.calculateCoverage(
        visitedPlaceIds: {'place_breadly'},
        catalogPlaces: mockPlaces,
      );

      expect(report.formattedCityScore('uz'), contains('Toshkentning 25% qismi'));
      expect(report.formattedCityScore('ru'), contains('Исследовано 25% Ташкента'));
      expect(report.formattedCityScore('en'), contains('25% of Tashkent Explored'));
    });

    test('resolves canonical catalog by default when no catalog override is provided', () {
      final report = PersonalCoverageEngine.calculateCoverage(
        visitedPlaceIds: {'breadly'}, // 1 canonical place from the 50-venue dataset
      );

      expect(report.totalPlaces, greaterThanOrEqualTo(50));
      expect(report.totalVisited, greaterThanOrEqualTo(1));
      expect(report.districts['Mirabad']?.visitedCount, greaterThanOrEqualTo(1));
    });
  });
}
