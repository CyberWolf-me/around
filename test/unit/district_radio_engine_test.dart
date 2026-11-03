import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:around_app/core/services/district_radio_engine.dart';

void main() {
  group('DistrictRadioEngine Unit Tests', () {
    late DistrictRadioEngine engine;

    setUp(() {
      engine = DistrictRadioEngine();
    });

    test('getAllStations returns curated catalog of Tashkent district radio stations', () {
      final stations = engine.getAllStations();
      expect(stations.length, equals(4));

      final chorsu = engine.getStationById('station-chorsu-fm');
      expect(chorsu, isNotNull);
      expect(chorsu!.frequencyMhz, equals(88.4));
      expect(chorsu.callsign, equals('CHRS 88.4'));
      expect(chorsu.district, equals('Shaykhontohur'));

      final mirabad = engine.getStationById('station-mirabad-beat');
      expect(mirabad, isNotNull);
      expect(mirabad!.frequencyMhz, equals(94.2));
      expect(mirabad.district, equals('Mirabad'));

      final yunusabad = engine.getStationById('station-yunusabad-rain');
      expect(yunusabad, isNotNull);
      expect(yunusabad!.frequencyMhz, equals(101.6));

      final yakkasaray = engine.getStationById('station-yakkasaray-breeze');
      expect(yakkasaray, isNotNull);
      expect(yakkasaray!.frequencyMhz, equals(107.5));
    });

    test('tuneToFrequency evaluates reception quality, clear signal, and static volume', () {
      // 1. Exact match on Chorsu 88.4
      final exact = engine.tuneToFrequency(88.4);
      expect(exact.lockedStation, isNotNull);
      expect(exact.lockedStation!.id, equals('station-chorsu-fm'));
      expect(exact.signalStrength, equals(1.0));
      expect(exact.isClearReception, isTrue);
      expect(exact.staticNoiseVolume, equals(0.0));

      // 2. Slight drift to 88.5 MHz (+0.1 MHz)
      final slightDrift = engine.tuneToFrequency(88.5);
      expect(slightDrift.lockedStation, isNotNull);
      expect(slightDrift.lockedStation!.id, equals('station-chorsu-fm'));
      expect(slightDrift.signalStrength, closeTo(0.9, 0.05));
      expect(slightDrift.isClearReception, isTrue);
      expect(slightDrift.staticNoiseVolume, closeTo(0.1, 0.05));

      // 3. Significant drift to 89.1 MHz (+0.7 MHz)
      final weakSignal = engine.tuneToFrequency(89.1);
      expect(weakSignal.lockedStation, isNotNull);
      expect(weakSignal.signalStrength, closeTo(0.3, 0.05));
      expect(weakSignal.isClearReception, isFalse);
      expect(weakSignal.staticNoiseVolume, closeTo(0.7, 0.05));

      // 4. Dead zone frequency (91.0 MHz)
      final deadZone = engine.tuneToFrequency(91.0);
      expect(deadZone.lockedStation, isNull);
      expect(deadZone.signalStrength, equals(0.0));
      expect(deadZone.isClearReception, isFalse);
      expect(deadZone.staticNoiseVolume, equals(1.0));
    });

    test('findClosestStation and formatFrequency return expected values', () {
      final closest = engine.findClosestStation(94.5);
      expect(closest.id, equals('station-mirabad-beat'));
      expect(engine.formatFrequency(94.2), equals('94.2 MHz'));
    });

    test('calculateLiveListeners computes dynamic listeners based on hour of day', () {
      final station = engine.getStationById('station-mirabad-beat')!;

      // Evening peak (20:00)
      final eveningCount = engine.calculateLiveListeners(
        station,
        time: DateTime(2026, 11, 3, 20, 0),
      );
      expect(eveningCount, greaterThan(station.baseListeners));

      // Late night dip (03:00)
      final lateNightCount = engine.calculateLiveListeners(
        station,
        time: DateTime(2026, 11, 3, 3, 0),
      );
      expect(lateNightCount, lessThan(station.baseListeners));
    });

    test('formatSessionProgressLabel returns trilingual messages', () {
      // 4 minutes tuned in (needs 6 more)
      expect(
        engine.formatSessionProgressLabel(240, 'en'),
        equals('Listen 6 more mins for +25 XP'),
      );
      expect(
        engine.formatSessionProgressLabel(240, 'uz'),
        equals('+25 XP olish uchun yana 6 daqiqa tinglang'),
      );
      expect(
        engine.formatSessionProgressLabel(240, 'ru'),
        equals('Слушайте еще 6 мин до +25 XP'),
      );

      // 10 minutes reached (+25 XP)
      expect(
        engine.formatSessionProgressLabel(600, 'en'),
        contains('10 minutes tuned in! Earned +25 XP'),
      );
      expect(
        engine.formatSessionProgressLabel(600, 'uz'),
        contains('10 daqiqa tinglandi! +25 XP'),
      );
      expect(
        engine.formatSessionProgressLabel(600, 'ru'),
        contains('10 минут прослушано! Получено +25 XP'),
      );
    });

    test('JSON serialization roundtrips RadioStation cleanly', () {
      final station = engine.getStationById('station-chorsu-fm')!;
      final json = station.toJson();
      final restored = RadioStation.fromJson(json);

      expect(restored.id, equals(station.id));
      expect(restored.frequencyMhz, equals(station.frequencyMhz));
      expect(restored.callsign, equals(station.callsign));
      expect(restored.title, equals(station.title));
      expect(restored.district, equals(station.district));
    });

    test('districtRadioEngineProvider initializes cleanly in ProviderContainer', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final providedEngine = container.read(districtRadioEngineProvider);
      expect(providedEngine, isA<DistrictRadioEngine>());
      expect(providedEngine.getAllStations().length, equals(4));
    });
  });
}
