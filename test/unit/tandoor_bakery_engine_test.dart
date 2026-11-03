import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:around_app/core/services/tandoor_bakery_engine.dart';

void main() {
  group('TandoorBakeryEngine Unit Tests (P48-01)', () {
    late TandoorBakeryEngine engine;

    setUp(() {
      engine = TandoorBakeryEngine();
    });

    test('BreadVariety provides bread taxonomy and fromId parsing', () {
      expect(BreadVariety.values.length, equals(4));

      final obiNon = BreadVariety.obiNon;
      expect(obiNon.id, equals('obi_non'));
      expect(obiNon.defaultPriceUzs, equals(4000));
      expect(obiNon.optimalOvenTempCelsius, equals(280));
      expect(obiNon.localizedName('uz'), contains('Obi non'));
      expect(obiNon.localizedName('ru'), contains('Оби нон'));
      expect(obiNon.localizedName('en'), contains('Obi Non'));

      final patir = BreadVariety.patir;
      expect(patir.optimalOvenTempCelsius, equals(300));
      expect(patir.defaultPriceUzs, equals(8000));

      final shirmoy = BreadVariety.shirmoy;
      expect(shirmoy.defaultPriceUzs, equals(12000));

      expect(BreadVariety.fromId('patir'), equals(BreadVariety.patir));
      expect(BreadVariety.fromId('shirmoy'), equals(BreadVariety.shirmoy));
      expect(BreadVariety.fromId('jizzali'), equals(BreadVariety.jizzali));
      expect(BreadVariety.fromId('unknown'), equals(BreadVariety.obiNon));
    });

    test('ChekichPattern provides sacred geometric bread stamp taxonomy', () {
      expect(ChekichPattern.values.length, equals(3));

      expect(ChekichPattern.sunburst.id, equals('sunburst'));
      expect(ChekichPattern.sunburst.localizedName('uz'), contains('Quyosh'));
      expect(ChekichPattern.sunburst.localizedName('ru'), contains('Солнечные'));

      expect(ChekichPattern.fromId('rosette'), equals(ChekichPattern.rosette));
      expect(ChekichPattern.fromId('octagon'), equals(ChekichPattern.octagon));
      expect(ChekichPattern.fromId('invalid'), equals(ChekichPattern.sunburst));
    });

    test('defaultBakeries includes curated Tashkent neighborhood bakeries', () {
      expect(engine.bakeries.length, equals(3));

      final chorsu = engine.findBakeryById('bakery-chorsu-kattabog');
      expect(chorsu, isNotNull);
      expect(chorsu!.headBaker, contains('Usto Shuhrat'));
      expect(chorsu.tandoorClayOrigin, contains('Rishtan'));
      expect(chorsu.signatureBreads, contains(BreadVariety.obiNon));

      final chigatoy = engine.findBakeryById('bakery-chigatoy-shirmoy');
      expect(chigatoy, isNotNull);
      expect(chigatoy!.signatureBreads, contains(BreadVariety.shirmoy));
    });

    test('TandoorBakeryVenue JSON serialization roundtrips accurately', () {
      final bakery = engine.bakeries.first;
      final json = bakery.toJson();
      final roundtrip = TandoorBakeryVenue.fromJson(json);

      expect(roundtrip.id, equals(bakery.id));
      expect(roundtrip.name, equals(bakery.name));
      expect(roundtrip.district, equals(bakery.district));
      expect(roundtrip.currentBatchHotLoaves, equals(bakery.currentBatchHotLoaves));
      expect(roundtrip.nextBatchMinutes, equals(bakery.nextBatchMinutes));
      expect(roundtrip.signatureBreads.length, equals(bakery.signatureBreads.length));
      expect(roundtrip.favoriteChekich, equals(bakery.favoriteChekich));
    });

    test('calculateFreshnessGrade evaluates trilingual freshness tiers based on elapsed minutes', () {
      // Piping hot (<= 15 min)
      expect(engine.calculateFreshnessGrade(5, 'en'), contains('Piping Hot'));
      expect(engine.calculateFreshnessGrade(10, 'uz'), contains('Tandirdan uzilgan'));
      expect(engine.calculateFreshnessGrade(12, 'ru'), contains('С пылу с жару'));

      // Warm & fragrant (16 - 45 min)
      expect(engine.calculateFreshnessGrade(25, 'en'), contains('Warm & Fragrant'));
      expect(engine.calculateFreshnessGrade(30, 'uz'), contains('Iliq'));
      expect(engine.calculateFreshnessGrade(40, 'ru'), contains('Теплый'));

      // Ambient fresh (45+ min)
      expect(engine.calculateFreshnessGrade(55, 'en'), contains('Fresh Daily Loaf'));
      expect(engine.calculateFreshnessGrade(60, 'uz'), contains('Yangi tandir noni'));
      expect(engine.calculateFreshnessGrade(70, 'ru'), contains('Свежий хлеб'));
    });

    test('filterBakeriesByVariety returns bakeries providing specific bread', () {
      final shirmoyBakeries = engine.filterBakeriesByVariety(BreadVariety.shirmoy);
      expect(shirmoyBakeries.length, equals(1));
      expect(shirmoyBakeries.first.id, equals('bakery-chigatoy-shirmoy'));

      final obiNonBakeries = engine.filterBakeriesByVariety(BreadVariety.obiNon);
      expect(obiNonBakeries.length, equals(2));
    });

    test('reserveLoaves awards +30 Explorer XP and isBatchReady works', () {
      final chorsu = engine.findBakeryById('bakery-chorsu-kattabog')!;
      expect(engine.isBatchReady(chorsu), isTrue);

      final reservation = engine.reserveLoaves(
        chorsu.id,
        BreadVariety.obiNon,
        4,
      );

      expect(reservation.bakeryId, equals(chorsu.id));
      expect(reservation.variety, equals(BreadVariety.obiNon));
      expect(reservation.loavesCount, equals(4));
      expect(reservation.xpEarned, equals(30));
      expect(reservation.status, equals('confirmed'));
    });

    test('tandoorBakeryEngineProvider initializes in ProviderContainer cleanly', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final providedEngine = container.read(tandoorBakeryEngineProvider);
      expect(providedEngine, isNotNull);
      expect(providedEngine.bakeries.length, equals(3));
    });
  });
}
