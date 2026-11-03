import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:around_app/core/services/metro_stamp_engine.dart';

void main() {
  group('P39-01: MetroStampEngine Unit Tests', () {
    test('serializes and deserializes MetroStation and MetroStamp accurately', () {
      const station = MetroStation(
        id: 'kosmonavtlar',
        name: 'Kosmonavtlar',
        line: MetroLine.uzbekistan,
        latitude: 41.3094,
        longitude: 69.2678,
        district: 'Yakkasaray',
        stampMotif: 'Cosmos Blue Medallion',
        stampColorHex: '#1E88E5',
        xpBonus: 25,
      );

      final json = station.toJson();
      expect(json['id'], equals('kosmonavtlar'));
      expect(json['line'], equals('uzbekistan'));
      expect(json['xp_bonus'], equals(25));

      final restored = MetroStation.fromJson(json);
      expect(restored.id, equals(station.id));
      expect(restored.name, equals('Kosmonavtlar'));
      expect(restored.line, equals(MetroLine.uzbekistan));

      final now = DateTime(2026, 11, 3, 20, 15);
      final stamp = MetroStamp(
        stationId: 'kosmonavtlar',
        stationName: 'Kosmonavtlar',
        line: MetroLine.uzbekistan,
        stampMotif: 'Cosmos Blue Medallion',
        stampColorHex: '#1E88E5',
        claimedAt: now,
      );

      final stampJson = stamp.toJson();
      expect(stampJson['station_id'], equals('kosmonavtlar'));
      final restoredStamp = MetroStamp.fromJson(stampJson);
      expect(restoredStamp.stationId, equals('kosmonavtlar'));
      expect(restoredStamp.line, equals(MetroLine.uzbekistan));
    });

    test('canonical stations list has valid stations across all 3 lines', () {
      final engine = MetroStampEngine();
      final all = MetroStampEngine.canonicalStations;

      expect(all.length, equals(12));

      final chilanzar = engine.getStationsByLine(MetroLine.chilanzar);
      final uzbekistan = engine.getStationsByLine(MetroLine.uzbekistan);
      final yunusabad = engine.getStationsByLine(MetroLine.yunusabad);

      expect(chilanzar.length, equals(4));
      expect(uzbekistan.length, equals(4));
      expect(yunusabad.length, equals(4));
    });

    test('calculates line completion progress accurately', () {
      final engine = MetroStampEngine();

      // Empty claimed set
      final emptyProg = engine.calculateLineProgress(MetroLine.uzbekistan, {});
      expect(emptyProg.totalStations, equals(4));
      expect(emptyProg.claimedStations, equals(0));
      expect(emptyProg.completionPercentage, equals(0.0));
      expect(emptyProg.isCompleted, isFalse);

      // Partial claimed set
      final partialProg = engine.calculateLineProgress(
        MetroLine.uzbekistan,
        {'kosmonavtlar', 'chorsu'},
      );
      expect(partialProg.claimedStations, equals(2));
      expect(partialProg.completionPercentage, equals(50.0));
      expect(partialProg.isCompleted, isFalse);

      // Full claimed set
      final fullProg = engine.calculateLineProgress(
        MetroLine.uzbekistan,
        {'kosmonavtlar', 'chorsu', 'alisher_navoiy', 'oybek'},
      );
      expect(fullProg.claimedStations, equals(4));
      expect(fullProg.completionPercentage, equals(100.0));
      expect(fullProg.isCompleted, isTrue);
      expect(fullProg.badgeTitle, equals('Turquoise Line Wayfarer'));
    });

    test('detects closest metro station within 600m threshold', () {
      final engine = MetroStampEngine();

      // Point right at Kosmonavtlar (approx 50m away)
      final nearby = engine.findNearbyStation(41.3096, 69.2679);
      expect(nearby, isNotNull);
      expect(nearby!.id, equals('kosmonavtlar'));

      // Point in the middle of nowhere / outskirts of Tashkent (> 5km away)
      final farAway = engine.findNearbyStation(41.2000, 69.1000);
      expect(farAway, isNull);
    });

    test('formats localized line names across Uzbek, Russian, and English', () {
      final engine = MetroStampEngine();

      expect(engine.localizedLineName(MetroLine.chilanzar, locale: 'en'), equals('Chilanzar Line'));
      expect(engine.localizedLineName(MetroLine.chilanzar, locale: 'uz'), equals('Chilonzor yo\'li'));
      expect(engine.localizedLineName(MetroLine.chilanzar, locale: 'ru'), equals('Чиланзарская линия'));

      expect(engine.localizedLineName(MetroLine.uzbekistan, locale: 'uz'), equals('O\'zbekiston yo\'li'));
      expect(engine.localizedLineName(MetroLine.yunusabad, locale: 'ru'), equals('Юнусабадская линия'));
    });

    test('Riverpod provider initializes MetroStampEngine cleanly', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final engine = container.read(metroStampEngineProvider);
      expect(engine, isA<MetroStampEngine>());
    });
  });
}
