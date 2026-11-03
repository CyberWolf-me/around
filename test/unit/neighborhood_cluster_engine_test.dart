import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:around_app/core/services/neighborhood_cluster_engine.dart';

void main() {
  group('P37-01: NeighborhoodClusterEngine Unit Tests', () {
    late NeighborhoodClusterEngine engine;

    setUp(() {
      engine = NeighborhoodClusterEngine();
    });

    test('serializes and deserializes SpatialDropPoint and NeighborhoodCluster', () {
      final drop = SpatialDropPoint(
        id: 'dp-1',
        latitude: 41.3111,
        longitude: 69.2405,
        placeName: 'Breadly Bakery',
        district: 'Mirabad',
        createdAt: DateTime(2026, 11, 3, 12, 0),
      );

      final json = drop.toJson();
      final parsed = SpatialDropPoint.fromJson(json);

      expect(parsed.id, equals('dp-1'));
      expect(parsed.placeName, equals('Breadly Bakery'));
      expect(parsed.district, equals('Mirabad'));
      expect(parsed.latitude, equals(41.3111));

      const cluster = NeighborhoodCluster(
        id: 'cl-1',
        centroidLat: 41.3111,
        centroidLng: 69.2405,
        district: 'Mirabad',
        intensity: ClusterIntensity.buzzing,
        dropsCount: 8,
        venueNames: ['Breadly Bakery', 'Bon!'],
        primaryVenueName: 'Breadly Bakery',
      );

      final cJson = cluster.toJson();
      final cParsed = NeighborhoodCluster.fromJson(cJson);

      expect(cParsed.id, equals('cl-1'));
      expect(cParsed.intensity, equals(ClusterIntensity.buzzing));
      expect(cParsed.dropsCount, equals(8));
      expect(cParsed.venueNames, contains('Bon!'));
    });

    test('categorizes cluster heat intensity accurately', () {
      expect(engine.calculateIntensity(1), equals(ClusterIntensity.serene));
      expect(engine.calculateIntensity(2), equals(ClusterIntensity.serene));
      expect(engine.calculateIntensity(3), equals(ClusterIntensity.lively));
      expect(engine.calculateIntensity(5), equals(ClusterIntensity.lively));
      expect(engine.calculateIntensity(6), equals(ClusterIntensity.buzzing));
      expect(engine.calculateIntensity(10), equals(ClusterIntensity.buzzing));
      expect(engine.calculateIntensity(11), equals(ClusterIntensity.peak));
      expect(engine.calculateIntensity(25), equals(ClusterIntensity.peak));
    });

    test('clusters nearby points and calculates obfuscated centroid', () {
      final now = DateTime.now();
      final nearbyDrops = [
        SpatialDropPoint(
          id: '1',
          latitude: 41.3110,
          longitude: 69.2405,
          placeName: 'Breadly Bakery',
          district: 'Mirabad',
          createdAt: now,
        ),
        SpatialDropPoint(
          id: '2',
          latitude: 41.3112,
          longitude: 69.2406,
          placeName: 'Breadly Bakery',
          district: 'Mirabad',
          createdAt: now,
        ),
        SpatialDropPoint(
          id: '3',
          latitude: 41.3111,
          longitude: 69.2404,
          placeName: 'Ecocafe',
          district: 'Mirabad',
          createdAt: now,
        ),
      ];

      final clusters = engine.clusterDrops(nearbyDrops);
      expect(clusters.length, equals(1));
      expect(clusters[0].dropsCount, equals(3));
      expect(clusters[0].intensity, equals(ClusterIntensity.lively));
      expect(clusters[0].district, equals('Mirabad'));
      expect(clusters[0].venueNames.length, equals(2));
      expect(clusters[0].centroidLat, closeTo(41.3111, 0.001));
    });

    test('separates distant drops into distinct clusters sorted by density', () {
      final now = DateTime.now();
      final drops = [
        // Mirabad cluster (2 drops)
        SpatialDropPoint(
          id: 'm1',
          latitude: 41.3110,
          longitude: 69.2405,
          placeName: 'Breadly Bakery',
          district: 'Mirabad',
          createdAt: now,
        ),
        SpatialDropPoint(
          id: 'm2',
          latitude: 41.3111,
          longitude: 69.2406,
          placeName: 'Breadly Bakery',
          district: 'Mirabad',
          createdAt: now,
        ),
        // Chorsu cluster (3 drops) - distant in Shaikhontokhur
        SpatialDropPoint(
          id: 'c1',
          latitude: 41.3275,
          longitude: 69.2340,
          placeName: 'Chorsu Bazaar',
          district: 'Shaikhontokhur',
          createdAt: now,
        ),
        SpatialDropPoint(
          id: 'c2',
          latitude: 41.3276,
          longitude: 69.2341,
          placeName: 'Kukeldash',
          district: 'Shaikhontokhur',
          createdAt: now,
        ),
        SpatialDropPoint(
          id: 'c3',
          latitude: 41.3274,
          longitude: 69.2339,
          placeName: 'Chorsu Plov',
          district: 'Shaikhontokhur',
          createdAt: now,
        ),
      ];

      final clusters = engine.clusterDrops(drops);
      expect(clusters.length, equals(2));
      // First cluster must be the hotter one (Chorsu with 3 drops)
      expect(clusters[0].district, equals('Shaikhontokhur'));
      expect(clusters[0].dropsCount, equals(3));
      expect(clusters[0].intensity, equals(ClusterIntensity.lively));

      // Second cluster is Mirabad with 2 drops
      expect(clusters[1].district, equals('Mirabad'));
      expect(clusters[1].dropsCount, equals(2));
      expect(clusters[1].intensity, equals(ClusterIntensity.serene));
    });

    test('formats localized intensity labels and summaries across EN, UZ, and RU', () {
      const cluster = NeighborhoodCluster(
        id: 'c-test',
        centroidLat: 41.3111,
        centroidLng: 69.2405,
        district: 'Mirabad',
        intensity: ClusterIntensity.buzzing,
        dropsCount: 7,
        venueNames: ['Breadly Bakery'],
        primaryVenueName: 'Breadly Bakery',
      );

      expect(cluster.localizedIntensityLabel(locale: 'en'), equals('Buzzing Hotspot'));
      expect(cluster.localizedIntensityLabel(locale: 'uz'), equals('Qaynoq Nuqta'));
      expect(cluster.localizedIntensityLabel(locale: 'ru'), equals('Бурлящая точка'));

      expect(
        cluster.localizedSummary(locale: 'en'),
        equals('7 drops across Breadly Bakery & nearby'),
      );
      expect(
        cluster.localizedSummary(locale: 'uz'),
        equals('Breadly Bakery va yaqinida 7 ta drop'),
      );
      expect(
        cluster.localizedSummary(locale: 'ru'),
        equals('7 дроп(ов) в районе Breadly Bakery и рядом'),
      );
    });

    test('Riverpod provider initializes NeighborhoodClusterEngine cleanly', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final service = container.read(neighborhoodClusterEngineProvider);
      expect(service, isA<NeighborhoodClusterEngine>());
    });
  });
}
