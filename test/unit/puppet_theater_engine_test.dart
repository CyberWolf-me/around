import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:around_app/core/services/puppet_theater_engine.dart';

void main() {
  group('P49-01: PuppetTheaterEngine Unit Tests', () {
    late PuppetTheaterEngine engine;

    setUp(() {
      engine = PuppetTheaterEngine();
    });

    test('initializes with default stages including Uzbekistan State Puppet Theater', () {
      expect(engine.stages, isNotEmpty);
      expect(engine.stages.length, equals(3));

      final stateTheater = engine.stages.first;
      expect(stateTheater.id, equals('theater-state-puppet-kosmonavtlar'));
      expect(stateTheater.name, contains('State Puppet'));
      expect(stateTheater.foundedYear, equals(1939));
      expect(stateTheater.availableSeats, equals(48));
      expect(stateTheater.repertoire.length, equals(2));
      expect(stateTheater.signatureFigures.length, equals(2));
    });

    test('findStageById retrieves matching stage and returns null for unknown ID', () {
      final stage = engine.findStageById('atelier-old-city-chodir');
      expect(stage, isNotNull);
      expect(stage!.chiefMaster, contains('Ikrom'));

      final nonExistent = engine.findStageById('non-existent-stage');
      expect(nonExistent, isNull);
    });

    test('filterByPuppetType returns stages offering corresponding puppetry format', () {
      final gloveStages = engine.filterByPuppetType(PuppetType.chodirJamol);
      expect(gloveStages.length, greaterThanOrEqualTo(2));

      final marionetteStages = engine.filterByPuppetType(PuppetType.chodirXayol);
      expect(marionetteStages.length, greaterThanOrEqualTo(2));
    });

    test('PuppetType localizedName supports uz, ru, and en', () {
      const type = PuppetType.chodirJamol;
      expect(type.localizedName('en'), contains('Glove'));
      expect(type.localizedName('uz'), contains('Qo\'lqop'));
      expect(type.localizedName('ru'), contains('Перчаточная'));
      expect(type.localizedName('fr'), contains('Glove')); // default en

      expect(PuppetType.fromId('chodir_xayol'), equals(PuppetType.chodirXayol));
      expect(PuppetType.fromId('unknown'), equals(PuppetType.chodirXayol));
    });

    test('CarvingWood attributes and localizedName are correct', () {
      const chinor = CarvingWood.chinor;
      expect(chinor.hardnessMohs, equals(3.5));
      expect(chinor.localizedName('uz'), contains('Chinor'));
      expect(chinor.localizedName('ru'), contains('Чинара'));

      const apricot = CarvingWood.apricot;
      expect(apricot.hardnessMohs, equals(4.5));
      expect(CarvingWood.fromId('apricot'), equals(CarvingWood.apricot));
      expect(CarvingWood.fromId('unknown'), equals(CarvingWood.chinor));
    });

    test('MarionetteFigure and PuppetPerformance localized fields function as expected', () {
      final stateTheater = engine.stages.first;
      final polvon = stateTheater.signatureFigures.first;
      expect(polvon.localizedName('uz'), equals('Polvon Kachal'));
      expect(polvon.localizedName('ru'), equals('Палван Качал'));
      expect(polvon.stringsCount, equals(0)); // glove puppet

      final farhod = stateTheater.signatureFigures[1];
      expect(farhod.stringsCount, equals(10)); // marionette

      final show = stateTheater.repertoire.first;
      expect(show.localizedTitle('uz'), contains('Polvon Kachalning'));
      expect(show.ticketPriceUzs, equals(35000));
    });

    test('calculateStringTension clamps and varies tension by controller tilt angle', () {
      final tensionNeutral = engine.calculateStringTension(stringIndex: 0, tiltAngleDegrees: 0);
      expect(tensionNeutral, equals(0.5));

      final tensionTiltedPositive = engine.calculateStringTension(stringIndex: 0, tiltAngleDegrees: 45);
      expect(tensionTiltedPositive, equals(1.0));

      final tensionTiltedNegative = engine.calculateStringTension(stringIndex: 1, tiltAngleDegrees: 45);
      expect(tensionTiltedNegative, equals(0.0));

      // Over-tilt clamping
      final overTilted = engine.calculateStringTension(stringIndex: 0, tiltAngleDegrees: 90);
      expect(overTilted, equals(1.0));
    });

    test('reserveTickets creates reservation and awards +35 Explorer XP', () {
      final reservation = engine.reserveTickets(
        stageId: 'theater-state-puppet-kosmonavtlar',
        performanceId: 'show-simurgh-legend',
        seatsCount: 2,
      );

      expect(reservation.stageId, equals('theater-state-puppet-kosmonavtlar'));
      expect(reservation.performanceId, equals('show-simurgh-legend'));
      expect(reservation.seatsCount, equals(2));
      expect(reservation.xpEarned, equals(35));
      expect(reservation.status, equals('confirmed'));
      expect(reservation.reservedAt, isNotNull);
    });

    test('PuppetTheaterStage.toJson serializes attributes correctly', () {
      final stage = engine.stages.first;
      final json = stage.toJson();

      expect(json['id'], equals('theater-state-puppet-kosmonavtlar'));
      expect(json['name'], contains('State Puppet'));
      expect(json['founded_year'], equals(1939));
      expect(json['repertoire_count'], equals(2));
      expect(json['figures_count'], equals(2));
    });

    test('puppetTheaterEngineProvider resolves correctly in ProviderContainer', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final resolvedEngine = container.read(puppetTheaterEngineProvider);
      expect(resolvedEngine, isNotNull);
      expect(resolvedEngine.stages.length, equals(3));
    });
  });
}
