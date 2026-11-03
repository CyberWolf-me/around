import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:around_app/core/services/chaykhana_ritual_engine.dart';

void main() {
  group('ChaykhanaRitualEngine Unit Tests', () {
    late ChaykhanaRitualEngine engine;

    setUp(() {
      engine = ChaykhanaRitualEngine();
    });

    test('getAllVenues returns curated catalog of Tashkent chaykhanas', () {
      final venues = engine.getAllVenues();
      expect(venues.length, equals(3));

      final chorsu = venues.first;
      expect(chorsu.id, equals('chaykhana-chorsu-chinor'));
      expect(chorsu.district, equals('Shaykhontohur'));
      expect(chorsu.chaykhanaUstoName, equals('Usto Bobomurod Choychi'));
      expect(chorsu.signatureBlends.length, equals(1));
      expect(chorsu.signatureBlends.first.name, contains('Kok-Choy'));
    });

    test('getKaytarishSteps returns the canonical 3-step aeration ritual', () {
      final steps = engine.getKaytarishSteps();
      expect(steps.length, equals(3));

      expect(steps[0].stepNumber, equals(1));
      expect(steps[0].nameUz, equals('Loy'));
      expect(steps[0].oxygenationPercent, equals(33));

      expect(steps[1].stepNumber, equals(2));
      expect(steps[1].nameUz, equals('Moy'));
      expect(steps[1].oxygenationPercent, equals(66));

      expect(steps[2].stepNumber, equals(3));
      expect(steps[2].nameUz, equals('Choy'));
      expect(steps[2].oxygenationPercent, equals(100));
    });

    test('formatKaytarishProverb provides accurate trilingual folk wisdom', () {
      expect(
        engine.formatKaytarishProverb(locale: 'en'),
        equals('First is mud, second is oil, third is tea'),
      );
      expect(
        engine.formatKaytarishProverb(locale: 'uz'),
        equals('Birinchi loy, ikkinchi moy, uchinchi choy'),
      );
      expect(
        engine.formatKaytarishProverb(locale: 'ru'),
        equals('Первая — глина, вторая — масло, третья — чай'),
      );
    });

    test('formatTapchanStatus formats capacity and availability accurately', () {
      // Partial availability
      expect(
        engine.formatTapchanStatus(4, 12, locale: 'en'),
        equals('4 tapchans free (of 12)'),
      );
      expect(
        engine.formatTapchanStatus(4, 12, locale: 'uz'),
        equals('4 ta tapchan bo\'sh (jami 12)'),
      );
      expect(
        engine.formatTapchanStatus(4, 12, locale: 'ru'),
        equals('4 тапчанов свободно (из 12)'),
      );

      // Full capacity
      expect(
        engine.formatTapchanStatus(0, 12, locale: 'en'),
        equals('All Tapchans Full'),
      );
      expect(
        engine.formatTapchanStatus(0, 12, locale: 'uz'),
        equals('Barcha tapchanlar band'),
      );
    });

    test('JSON serialization roundtrips TeaBlend and ChaykhanaVenue cleanly', () {
      final venue = ChaykhanaRitualEngine.defaultVenues.first;
      final json = venue.toJson();
      final restored = ChaykhanaVenue.fromJson(json);

      expect(restored.id, equals(venue.id));
      expect(restored.name, equals(venue.name));
      expect(restored.availableTapchans, equals(venue.availableTapchans));
      expect(restored.signatureBlends.length, equals(venue.signatureBlends.length));
      expect(restored.signatureBlends.first.teaType, equals('Green'));
    });

    test('chaykhanaRitualEngineProvider initializes cleanly in ProviderContainer', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final providedEngine = container.read(chaykhanaRitualEngineProvider);
      expect(providedEngine, isNotNull);
      expect(providedEngine.getAllVenues().length, equals(3));
    });
  });
}
