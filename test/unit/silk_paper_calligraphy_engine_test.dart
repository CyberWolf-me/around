import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:around_app/core/services/silk_paper_calligraphy_engine.dart';

void main() {
  group('SilkPaperCalligraphyEngine Unit Tests (P47-01)', () {
    late SilkPaperCalligraphyEngine engine;

    setUp(() {
      engine = SilkPaperCalligraphyEngine();
    });

    test('PaperCraftStage provides 4 canonical stages with durations and descriptions', () {
      expect(PaperCraftStage.values.length, equals(4));

      final soaking = PaperCraftStage.soaking;
      expect(soaking.stepNumber, equals(1));
      expect(soaking.durationHours, equals(12));
      expect(soaking.localizedName('uz'), contains('ivitish'));
      expect(soaking.localizedName('ru'), contains('Вымачивание'));
      expect(soaking.localizedName('en'), contains('Soaking'));

      final burnishing = PaperCraftStage.burnishing;
      expect(burnishing.stepNumber, equals(4));
      expect(burnishing.localizedName('uz'), contains('Aqiq tosh'));

      final totalHours = engine.estimateTotalCraftingHours();
      expect(totalHours, equals(12 + 8 + 24 + 1));
    });

    test('CalligraphyScript provides script taxonomy and fromId parsing', () {
      expect(CalligraphyScript.values.length, equals(4));

      expect(CalligraphyScript.nastaliq.id, equals('nastaliq'));
      expect(CalligraphyScript.nastaliq.localizedName('uz'), contains('Kelin xati'));
      expect(CalligraphyScript.nastaliq.localizedName('en'), contains('Nasta\'liq'));

      expect(CalligraphyScript.fromId('thuluth'), equals(CalligraphyScript.thuluth));
      expect(CalligraphyScript.fromId('kufic'), equals(CalligraphyScript.kufic));
      expect(CalligraphyScript.fromId('diwani'), equals(CalligraphyScript.diwani));
      expect(CalligraphyScript.fromId('unknown'), equals(CalligraphyScript.nastaliq));
    });

    test('defaultAteliers includes curated Tashkent manuscript guilds', () {
      expect(engine.ateliers.length, equals(3));

      final chorsu = engine.findAtelierById('atelier-chorsu-mulberry');
      expect(chorsu, isNotNull);
      expect(chorsu!.masterName, contains('Usto Mirzo Bobo'));
      expect(chorsu.mulberryVariety, contains('White Mulberry'));
      expect(chorsu.supportedScripts, contains(CalligraphyScript.nastaliq));

      final hastImam = engine.findAtelierById('atelier-hast-imam-calligraphy');
      expect(hastImam, isNotNull);
      expect(hastImam!.burnishStoneType, contains('Chalcedony'));
    });

    test('SilkPaperAtelier JSON serialization roundtrips accurately', () {
      final atelier = engine.ateliers.first;
      final json = atelier.toJson();
      final roundtrip = SilkPaperAtelier.fromJson(json);

      expect(roundtrip.id, equals(atelier.id));
      expect(roundtrip.name, equals(atelier.name));
      expect(roundtrip.district, equals(atelier.district));
      expect(roundtrip.supportedScripts.length, equals(atelier.supportedScripts.length));
      expect(roundtrip.workshopPriceUzs, equals(atelier.workshopPriceUzs));
      expect(roundtrip.availableMasterclasses, equals(atelier.availableMasterclasses));
    });

    test('calculateBurnishSmoothness calculates glass-like finish percentages', () {
      expect(engine.calculateBurnishSmoothness(0), equals(0.0));
      expect(engine.calculateBurnishSmoothness(-5), equals(0.0));
      expect(engine.calculateBurnishSmoothness(15), equals(50.0));
      expect(engine.calculateBurnishSmoothness(30), equals(100.0));
      expect(engine.calculateBurnishSmoothness(45), equals(100.0));
    });

    test('filterAteliersByScript isolates ateliers instructing specific styles', () {
      final diwaniStudios = engine.filterAteliersByScript(CalligraphyScript.diwani);
      expect(diwaniStudios.length, equals(2));
      expect(diwaniStudios.map((a) => a.id), contains('atelier-hast-imam-calligraphy'));
      expect(diwaniStudios.map((a) => a.id), contains('atelier-navoiy-literature'));

      final kuficStudios = engine.filterAteliersByScript(CalligraphyScript.kufic);
      expect(kuficStudios.length, equals(2));
    });

    test('reserveMasterclass awards +35 Explorer XP and isMasterclassAvailable works', () {
      final chorsu = engine.findAtelierById('atelier-chorsu-mulberry')!;
      expect(engine.isMasterclassAvailable(chorsu), isTrue);

      final reservation = engine.reserveMasterclass(
        chorsu.id,
        CalligraphyScript.nastaliq,
      );

      expect(reservation.atelierId, equals(chorsu.id));
      expect(reservation.script, equals(CalligraphyScript.nastaliq));
      expect(reservation.xpEarned, equals(35));
      expect(reservation.status, equals('confirmed'));
    });

    test('silkPaperCalligraphyEngineProvider initializes in ProviderContainer cleanly', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final providedEngine = container.read(silkPaperCalligraphyEngineProvider);
      expect(providedEngine, isNotNull);
      expect(providedEngine.ateliers.length, equals(3));
    });
  });
}
