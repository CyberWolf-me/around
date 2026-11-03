import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:around_app/core/services/craft_workshop_engine.dart';

void main() {
  group('CraftWorkshopEngine Unit Tests', () {
    late CraftWorkshopEngine engine;

    setUp(() {
      engine = CraftWorkshopEngine();
    });

    test('getAllStudios returns curated catalog of Tashkent artisan studios', () {
      final studios = engine.getAllStudios();
      expect(studios.length, equals(4));

      final rishtan = studios.first;
      expect(rishtan.id, equals('studio-rishtan-ceramics'));
      expect(rishtan.craftDiscipline, equals('Ceramics'));
      expect(rishtan.masterArtisanName, equals('Usto Alisher Nazirov'));
      expect(rishtan.materials, contains('Ishkor Herbal Ash Glaze'));
      expect(rishtan.masterclasses.length, equals(2));
    });

    test('getStudioById and filterByDiscipline filter properly', () {
      final rishtan = engine.getStudioById('studio-rishtan-ceramics');
      expect(rishtan, isNotNull);
      expect(rishtan!.title, contains('Rishtan Blue Glaze'));

      final missing = engine.getStudioById('non-existent');
      expect(missing, isNull);

      final woodcarving = engine.filterByDiscipline('Woodcarving');
      expect(woodcarving.length, equals(1));
      expect(woodcarving.first.id, equals('studio-chorsu-woodcarving'));

      final allStudios = engine.filterByDiscipline('all');
      expect(allStudios.length, equals(4));
    });

    test('calculateDistanceKm evaluates geodesic distance using Haversine formula', () {
      final rishtan = engine.getStudioById('studio-rishtan-ceramics')!;

      // Coordinates at exact studio location -> distance 0.0 km
      final zeroDist = engine.calculateDistanceKm(rishtan, rishtan.latitude, rishtan.longitude);
      expect(zeroDist, equals(0.0));

      // Coordinates at Amir Timur Square (approx ~3.5 km away)
      final dist = engine.calculateDistanceKm(rishtan, 41.311082, 69.279731);
      expect(dist, greaterThan(2.0));
      expect(dist, lessThan(6.0));
    });

    test('formatPriceUzs formats price in Uzbek Som cleanly', () {
      expect(engine.formatPriceUzs(180000), equals('180 000 UZS'));
      expect(engine.formatPriceUzs(2500000), equals('2 500 000 UZS'));
      expect(engine.formatPriceUzs(50000), equals('50 000 UZS'));
    });

    test('formatReservationStatus provides accurate trilingual messages', () {
      // Reserved
      expect(
        engine.formatReservationStatus(isReserved: true, isFull: false, locale: 'en'),
        equals('Reserved (+40 XP)'),
      );
      expect(
        engine.formatReservationStatus(isReserved: true, isFull: false, locale: 'uz'),
        equals('Band qilingan (+40 XP)'),
      );
      expect(
        engine.formatReservationStatus(isReserved: true, isFull: false, locale: 'ru'),
        equals('Забронировано (+40 XP)'),
      );

      // Full
      expect(
        engine.formatReservationStatus(isReserved: false, isFull: true, locale: 'en'),
        equals('Fully Booked'),
      );
      expect(
        engine.formatReservationStatus(isReserved: false, isFull: true, locale: 'uz'),
        equals('Barcha joylar band'),
      );

      // Available
      expect(
        engine.formatReservationStatus(isReserved: false, isFull: false, locale: 'en'),
        equals('Reserve Seat'),
      );
    });

    test('JSON serialization roundtrips WorkshopMasterclass and CraftStudio cleanly', () {
      final rishtan = CraftWorkshopEngine.defaultStudios.first;
      final json = rishtan.toJson();
      final restored = CraftStudio.fromJson(json);

      expect(restored.id, equals(rishtan.id));
      expect(restored.title, equals(rishtan.title));
      expect(restored.masterclasses.length, equals(rishtan.masterclasses.length));
      expect(restored.materials, equals(rishtan.materials));
      expect(restored.masterclasses.first.availableSeats, equals(2));
      expect(restored.masterclasses[1].isFull, isTrue);
    });

    test('craftWorkshopEngineProvider initializes cleanly in ProviderContainer', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final providedEngine = container.read(craftWorkshopEngineProvider);
      expect(providedEngine, isNotNull);
      expect(providedEngine.getAllStudios().length, equals(4));
    });
  });
}
