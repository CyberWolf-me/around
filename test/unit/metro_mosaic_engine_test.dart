import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:around_app/core/services/metro_mosaic_engine.dart';

void main() {
  group('MetroMosaicEngine Unit Tests (P46-01)', () {
    late MetroMosaicEngine engine;

    setUp(() {
      engine = MetroMosaicEngine();
    });

    test('MetroLine taxonomy provides expected attributes and fromId parsing', () {
      expect(MetroLine.chilanzar.colorHex, equals('#E53935'));
      expect(MetroLine.chilanzar.openingYear, equals(1977));
      expect(MetroLine.uzbekistan.colorHex, equals('#1E88E5'));
      expect(MetroLine.uzbekistan.openingYear, equals(1984));
      expect(MetroLine.yunusabad.colorHex, equals('#43A047'));
      expect(MetroLine.circle.colorHex, equals('#FBC02D'));

      expect(MetroLine.fromId('chilanzar'), equals(MetroLine.chilanzar));
      expect(MetroLine.fromId('uzbekistan'), equals(MetroLine.uzbekistan));
      expect(MetroLine.fromId('yunusabad'), equals(MetroLine.yunusabad));
      expect(MetroLine.fromId('unknown_id'), equals(MetroLine.uzbekistan));
    });

    test('defaultStations includes canonical Tashkent architectural stations', () {
      expect(engine.stations.length, greaterThanOrEqualTo(6));

      final kosmonavtlar = engine.findStationById('kosmonavtlar');
      expect(kosmonavtlar, isNotNull);
      expect(kosmonavtlar!.nameEn, equals('Cosmonauts'));
      expect(kosmonavtlar.architect, equals('S. Sultonov'));
      expect(kosmonavtlar.mosaicArtist, equals('Arnold Gan'));
      expect(kosmonavtlar.line, equals(MetroLine.uzbekistan));

      final navoiy = engine.findStationById('alisher_navoiy');
      expect(navoiy, isNotNull);
      expect(navoiy!.mosaicArtist, equals('Chinghiz Akhmarov'));
      expect(navoiy.stampPoints, equals(30));

      final pakhtakor = engine.findStationById('pakhtakor');
      expect(pakhtakor, isNotNull);
      expect(pakhtakor!.line, equals(MetroLine.chilanzar));
      expect(pakhtakor.architecturalStyle, contains('Cotton Blossom'));
    });

    test('MetroStationModel localized getters provide correct translations', () {
      final station = engine.findStationById('kosmonavtlar')!;
      expect(station.localizedName('uz'), equals('Kosmonavtlar'));
      expect(station.localizedName('ru'), equals('Космонавтов'));
      expect(station.localizedName('en'), equals('Cosmonauts'));

      expect(station.localizedAudioSnippet('uz'), contains('koinotga sayohat'));
      expect(station.localizedAudioSnippet('ru'), contains('открытый космос'));
      expect(station.localizedAudioSnippet('en'), contains('deep cosmos'));
    });

    test('MetroStationModel and MetroVisitStamp JSON serialization roundtrips', () {
      final station = engine.findStationById('bodomzor')!;
      final json = station.toJson();
      final roundtrip = MetroStationModel.fromJson(json);

      expect(roundtrip.id, equals('bodomzor'));
      expect(roundtrip.nameEn, equals('Bodomzor'));
      expect(roundtrip.line, equals(MetroLine.yunusabad));
      expect(roundtrip.openingYear, equals(2001));
      expect(roundtrip.stampPoints, equals(30));

      final stamp = engine.collectStamp(
        stationId: 'bodomzor',
        notes: 'Marvelous almond fixtures',
        photoProofUrl: 'https://cdn.around.uz/proofs/bodomzor.jpg',
      );
      final stampJson = stamp.toJson();
      final stampRoundtrip = MetroVisitStamp.fromJson(stampJson);

      expect(stampRoundtrip.stationId, equals('bodomzor'));
      expect(stampRoundtrip.notes, equals('Marvelous almond fixtures'));
      expect(stampRoundtrip.photoProofUrl, equals('https://cdn.around.uz/proofs/bodomzor.jpg'));
      expect(stampRoundtrip.pointsEarned, equals(30));
    });

    test('getStationsByLine filters stations cleanly', () {
      final chilanzarStations = engine.getStationsByLine(MetroLine.chilanzar);
      expect(chilanzarStations, isNotEmpty);
      expect(chilanzarStations.every((s) => s.line == MetroLine.chilanzar), isTrue);

      final uzbekistanStations = engine.getStationsByLine(MetroLine.uzbekistan);
      expect(uzbekistanStations.length, greaterThanOrEqualTo(3));
      expect(uzbekistanStations.every((s) => s.line == MetroLine.uzbekistan), isTrue);
    });

    test('isNearStation detects proximity within 500m threshold accurately', () {
      final kosmonavtlar = engine.findStationById('kosmonavtlar')!;
      // Exact coordinates of Kosmonavtlar: 41.3094, 69.2625
      final isNearExact = engine.isNearStation(41.3094, 69.2625, kosmonavtlar);
      expect(isNearExact, isTrue);

      // 100 meters away
      final isNear100m = engine.isNearStation(41.3098, 69.2628, kosmonavtlar);
      expect(isNear100m, isTrue);

      // Far location (e.g. 5km away in Chilanzar district)
      final isFarAway = engine.isNearStation(41.2800, 69.2000, kosmonavtlar);
      expect(isFarAway, isFalse);
    });

    test('calculateLineExploration and calculateOverallExploration compute stats properly', () {
      final chilanzarTotal = engine.getStationsByLine(MetroLine.chilanzar).length;
      final visitedChilanzar = ['pakhtakor'];

      final badgePartial = engine.calculateLineExploration(MetroLine.chilanzar, visitedChilanzar);
      expect(badgePartial.stationsVisited, equals(1));
      expect(badgePartial.totalStations, equals(chilanzarTotal));
      expect(badgePartial.isUnlocked, isFalse);
      expect(badgePartial.completionPercent, closeTo((1.0 / chilanzarTotal) * 100, 0.01));

      // Mark all Chilanzar stations visited
      final allChilanzarIds = engine.getStationsByLine(MetroLine.chilanzar).map((s) => s.id).toList();
      final badgeFull = engine.calculateLineExploration(MetroLine.chilanzar, allChilanzarIds);
      expect(badgeFull.isUnlocked, isTrue);
      expect(badgeFull.completionPercent, equals(100.0));
      expect(badgeFull.localizedBadgeTitle('en'), contains('Master Explorer'));

      // Overall telemetry
      final overall = engine.calculateOverallExploration(allChilanzarIds);
      expect(overall['visited_count'], equals(allChilanzarIds.length));
      expect(overall['total_xp_earned'], equals(allChilanzarIds.length * 30));
      expect(overall['all_lines_unlocked'], isFalse);
    });

    test('metroMosaicEngineProvider initializes in ProviderContainer cleanly', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final providedEngine = container.read(metroMosaicEngineProvider);
      expect(providedEngine, isNotNull);
      expect(providedEngine.stations.length, greaterThanOrEqualTo(6));
    });
  });
}
