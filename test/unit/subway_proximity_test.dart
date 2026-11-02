import 'package:flutter_test/flutter_test.dart';
import 'package:around_app/core/services/subway_proximity_engine.dart';

void main() {
  group('P22-01: SubwayProximityEngine Unit Tests', () {
    test('contains comprehensive registry across 3 active Tashkent metro lines', () {
      expect(SubwayProximityEngine.stations.length, greaterThanOrEqualTo(25));

      final chilonzorStations = SubwayProximityEngine.getStationsForLine(SubwayLine.chilonzor);
      final ozbekistonStations = SubwayProximityEngine.getStationsForLine(SubwayLine.ozbekiston);
      final yunusobodStations = SubwayProximityEngine.getStationsForLine(SubwayLine.yunusobod);

      expect(chilonzorStations, isNotEmpty);
      expect(ozbekistonStations, isNotEmpty);
      expect(yunusobodStations, isNotEmpty);

      // Verify line badge colors
      expect(SubwayLine.chilonzor.colorHex, equals(0xFFE53935));
      expect(SubwayLine.ozbekiston.colorHex, equals(0xFF1E88E5));
      expect(SubwayLine.yunusobod.colorHex, equals(0xFF43A047));
    });

    test('getStationById returns accurate station metadata and handles missing ids', () {
      final oybek = SubwayProximityEngine.getStationById('oybek');
      expect(oybek, isNotNull);
      expect(oybek!.nameUz, equals('Oybek'));
      expect(oybek.nameRu, equals('Ойбек'));
      expect(oybek.nameEn, equals('Oybek'));
      expect(oybek.line, equals(SubwayLine.ozbekiston));
      expect(oybek.transferStationId, equals('ming_orik'));

      final missing = SubwayProximityEngine.getStationById('non_existent_station');
      expect(missing, isNull);
    });

    test('findClosestStation accurately identifies nearest metro station for Breadly (Mirabad)', () {
      // Breadly Bakery coordinates: ~41.2995, 69.2810 (Near Oybek & Ming O'rik)
      final match = SubwayProximityEngine.findClosestStation(41.2995, 69.2810);

      expect(match.station.id, anyOf(equals('ming_orik'), equals('oybek')));
      expect(match.distanceMeters, lessThan(300));
      expect(match.walkingMinutes, lessThanOrEqualTo(4));
    });

    test('findClosestStation accurately identifies Chorsu station for Old City coordinates', () {
      // Chorsu Bazaar area: ~41.3265, 69.2370
      final match = SubwayProximityEngine.findClosestStation(41.3265, 69.2370);

      expect(match.station.id, equals('chorsu'));
      expect(match.distanceMeters, lessThan(100));
      expect(match.walkingMinutes, lessThanOrEqualTo(2));
    });

    test('findStationsWithinRadius returns ordered matches within distance threshold', () {
      // Amir Timur Square: ~41.3130, 69.2798
      final matches = SubwayProximityEngine.findStationsWithinRadius(
        41.3130,
        69.2798,
        maxRadiusMeters: 1500,
      );

      expect(matches, isNotEmpty);
      expect(matches.first.station.id, equals('amir_temur_xiyoboni'));
      expect(matches.first.distanceMeters, lessThan(50));

      // Must be sorted ascending by distance
      for (int i = 0; i < matches.length - 1; i++) {
        expect(matches[i].distanceMeters, lessThanOrEqualTo(matches[i + 1].distanceMeters));
      }
    });

    test('getFormattedBadge renders localized badge text for all 3 languages', () {
      final station = SubwayProximityEngine.getStationById('kosmonavtlar')!;
      final match = SubwayProximityMatch(
        station: station,
        distanceMeters: 350,
        walkingMinutes: 4,
      );

      final uzBadge = match.getFormattedBadge(lang: 'uz');
      final ruBadge = match.getFormattedBadge(lang: 'ru');
      final enBadge = match.getFormattedBadge(lang: 'en');

      expect(uzBadge, equals('🚇 Kosmonavtlar • 350 m (4 daqiqa piyoda)'));
      expect(ruBadge, equals('🚇 Космонавтов • 350 м (4 мин пешком)'));
      expect(enBadge, equals('🚇 Kosmonavtlar • 350m (4 min walk)'));
    });

    test('calculateWalkingMinutes clamps short distances to minimum 1 minute', () {
      expect(SubwayProximityEngine.calculateWalkingMinutes(20), equals(1));
      expect(SubwayProximityEngine.calculateWalkingMinutes(80), equals(1));
      expect(SubwayProximityEngine.calculateWalkingMinutes(240), equals(3));
      expect(SubwayProximityEngine.calculateWalkingMinutes(800), equals(10));
    });
  });
}
