import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:around_app/core/services/tasting_flight_engine.dart';

void main() {
  group('TastingFlightEngine Unit Tests', () {
    late TastingFlightEngine engine;

    setUp(() {
      engine = TastingFlightEngine();
    });

    test('getAllFlights returns curated catalog of Tashkent tasting flights', () {
      final flights = engine.getAllFlights();
      expect(flights.length, greaterThanOrEqualTo(2));

      final coffeeFlight = engine.getFlightById('flight-specialty-coffee');
      expect(coffeeFlight, isNotNull);
      expect(coffeeFlight!.category, equals('Coffee'));
      expect(coffeeFlight.stops.length, equals(3));
      expect(coffeeFlight.stops.first.venueName, equals('Breadly Bakery & Roastery'));
      expect(coffeeFlight.stops.first.flavorNotes, contains('Bergamot'));

      final teaFlight = engine.getFlightById('tashkent-tea-master-trail');
      expect(teaFlight, isNotNull);
      expect(teaFlight!.category, equals('Tea'));
      expect(teaFlight.stops.length, equals(2));
      expect(teaFlight.stops.first.itemTitle, contains('Kok Choy'));
    });

    test('calculateProgress evaluates empty, partial, and completed flights with scores', () {
      final flight = engine.getFlightById('flight-specialty-coffee')!;

      // 0 logs
      final progressEmpty = engine.calculateProgress(flight, {});
      expect(progressEmpty.completedStopIds, isEmpty);
      expect(progressEmpty.isCompleted, isFalse);
      expect(progressEmpty.completionPercentage, equals(0.0));
      expect(progressEmpty.averageCuppingScore, equals(0.0));
      expect(progressEmpty.remainingStops, equals(3));

      // 1 log
      final log1 = TastingLog(
        stopId: 'stop-breadly-cupping',
        rating: 9.2,
        selectedFlavorNotes: const ['Bergamot', 'Dried Peach'],
        tastingNotes: 'Bright acidity and floral fragrance.',
        loggedAt: DateTime.now(),
      );

      final progress1 = engine.calculateProgress(flight, {
        'stop-breadly-cupping': log1,
      });
      expect(progress1.completedStopIds.length, equals(1));
      expect(progress1.isCompleted, isFalse);
      expect(progress1.completionPercentage, closeTo(0.33, 0.01));
      expect(progress1.averageCuppingScore, equals(9.2));
      expect(progress1.allFlavorNotes, contains('Bergamot'));

      // All 3 logs
      final log2 = TastingLog(
        stopId: 'stop-bb-anaerobic',
        rating: 8.8,
        selectedFlavorNotes: const ['Red Currant', 'Dark Cacao'],
        loggedAt: DateTime.now(),
      );
      final log3 = TastingLog(
        stopId: 'stop-paul-bistro',
        rating: 9.0,
        selectedFlavorNotes: const ['Roasted Hazelnut'],
        loggedAt: DateTime.now(),
      );

      final progressFull = engine.calculateProgress(flight, {
        'stop-breadly-cupping': log1,
        'stop-bb-anaerobic': log2,
        'stop-paul-bistro': log3,
      });

      expect(progressFull.completedStopIds.length, equals(3));
      expect(progressFull.isCompleted, isTrue);
      expect(progressFull.completionPercentage, equals(1.0));
      expect(progressFull.averageCuppingScore, equals(9.0));
      expect(progressFull.remainingStops, equals(0));
    });

    test('isFlightCompleted and calculateTotalFlightXp calculate certificates correctly', () {
      final flights = engine.getAllFlights();
      final teaFlight = engine.getFlightById('flight-chaykhana-tea')!;

      final logs = {
        'stop-chorsu-chaykhana': TastingLog(
          stopId: 'stop-chorsu-chaykhana',
          rating: 9.5,
          selectedFlavorNotes: const ['Wild Thyme'],
          loggedAt: DateTime.now(),
        ),
        'stop-blue-domes-tea': TastingLog(
          stopId: 'stop-blue-domes-tea',
          rating: 9.1,
          selectedFlavorNotes: const ['Zarafshan Saffron'],
          loggedAt: DateTime.now(),
        ),
      };

      expect(engine.isFlightCompleted(teaFlight, logs), isTrue);

      final totalXp = engine.calculateTotalFlightXp(flights, logs);
      expect(totalXp, equals(50));
    });

    test('formatFlightProgressLabel returns trilingual messages', () {
      final flight = engine.getFlightById('flight-specialty-coffee')!;
      final partial = engine.calculateProgress(flight, {
        'stop-breadly-cupping': TastingLog(
          stopId: 'stop-breadly-cupping',
          rating: 8.5,
          selectedFlavorNotes: const ['Bergamot'],
          loggedAt: DateTime.now(),
        ),
      });

      final completed = engine.calculateProgress(flight, {
        'stop-breadly-cupping': TastingLog(
          stopId: 'stop-breadly-cupping',
          rating: 8.5,
          selectedFlavorNotes: const [],
          loggedAt: DateTime.now(),
        ),
        'stop-bb-anaerobic': TastingLog(
          stopId: 'stop-bb-anaerobic',
          rating: 8.5,
          selectedFlavorNotes: const [],
          loggedAt: DateTime.now(),
        ),
        'stop-paul-bistro': TastingLog(
          stopId: 'stop-paul-bistro',
          rating: 8.5,
          selectedFlavorNotes: const [],
          loggedAt: DateTime.now(),
        ),
      });

      // Partial
      expect(
        engine.formatFlightProgressLabel(partial, 3, 'en'),
        equals('1 of 3 tastings logged'),
      );
      expect(
        engine.formatFlightProgressLabel(partial, 3, 'uz'),
        equals('1/3 degustatsiya bajarildi'),
      );
      expect(
        engine.formatFlightProgressLabel(partial, 3, 'ru'),
        equals('Оценено 1 из 3 дегустаций'),
      );

      // Completed
      expect(
        engine.formatFlightProgressLabel(completed, 3, 'en'),
        contains('Flight Completed! Cupping Certificate Unlocked'),
      );
      expect(
        engine.formatFlightProgressLabel(completed, 3, 'uz'),
        contains('Tasting yakunlandi! Sertifikat ochildi'),
      );
      expect(
        engine.formatFlightProgressLabel(completed, 3, 'ru'),
        contains('Дегустация завершена! Сертификат открыт'),
      );
    });

    test('JSON serialization roundtrips TastingStop, TastingFlight, and TastingLog', () {
      final flight = engine.getFlightById('flight-specialty-coffee')!;
      final flightJson = flight.toJson();
      final restoredFlight = TastingFlight.fromJson(flightJson);

      expect(restoredFlight.id, equals(flight.id));
      expect(restoredFlight.stops.length, equals(flight.stops.length));
      expect(restoredFlight.stops.first.venueName, equals('Breadly Bakery & Roastery'));

      final log = TastingLog(
        stopId: 'stop-breadly-cupping',
        rating: 9.4,
        selectedFlavorNotes: const ['Bergamot', 'Wild Jasmine'],
        tastingNotes: 'Excellent roast curve.',
        loggedAt: DateTime.now(),
      );
      final logJson = log.toJson();
      final restoredLog = TastingLog.fromJson(logJson);

      expect(restoredLog.stopId, equals(log.stopId));
      expect(restoredLog.rating, equals(log.rating));
      expect(restoredLog.selectedFlavorNotes, equals(log.selectedFlavorNotes));
      expect(restoredLog.tastingNotes, equals(log.tastingNotes));
    });

    test('tastingFlightEngineProvider initializes cleanly in ProviderContainer', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final providedEngine = container.read(tastingFlightEngineProvider);
      expect(providedEngine, isA<TastingFlightEngine>());
      expect(providedEngine.getAllFlights().length, greaterThanOrEqualTo(2));
    });
  });
}
