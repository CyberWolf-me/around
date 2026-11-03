import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:around_app/core/services/neighborhood_cluster_engine.dart';
import 'package:around_app/data/repositories/neighborhood_cluster_repository.dart';

void main() {
  group('P37-04: Neighborhood Drop Clusters RPC & Repository Tests', () {
    test('migration 00028_neighborhood_drop_clusters.sql is syntactically hardened', () {
      final file = File('supabase/migrations/00028_neighborhood_drop_clusters.sql');
      expect(file.existsSync(), isTrue);

      final sql = file.readAsStringSync();
      expect(sql, contains('CREATE OR REPLACE FUNCTION public.get_neighborhood_drop_clusters'));
      expect(sql, contains('SECURITY DEFINER'));
      expect(sql, contains('SET search_path = public, extensions'));
      expect(sql, contains('GRANT EXECUTE ON FUNCTION public.get_neighborhood_drop_clusters(TEXT, NUMERIC) TO authenticated, anon;'));
      expect(sql, contains('hide_visits_history, false) = false'));
      expect(sql, contains('po.privacy = \'public\''));
      expect(sql, contains('ROUND(AVG(raw_lat)::numeric, 4)'));
    });

    test('NeighborhoodClusterRepository returns rich offline seed clusters when Supabase is uninitialized', () async {
      final repo = NeighborhoodClusterRepository();
      final allClusters = await repo.getNeighborhoodClusters();

      expect(allClusters, isNotEmpty);
      expect(allClusters.length, equals(5));

      final peakCluster = allClusters.firstWhere(
        (c) => c.intensity == ClusterIntensity.peak,
      );
      expect(peakCluster.district, equals('Mirabad'));
      expect(peakCluster.primaryVenueName, contains('Breadly'));
      expect(peakCluster.dropsCount, equals(14));
      expect(peakCluster.venueNames.length, greaterThanOrEqualTo(2));
    });

    test('NeighborhoodClusterRepository filters clusters by district in offline fallback', () async {
      final repo = NeighborhoodClusterRepository();

      final mirabadClusters = await repo.getNeighborhoodClusters(district: 'Mirabad');
      expect(mirabadClusters.length, equals(1));
      expect(mirabadClusters.first.district, equals('Mirabad'));
      expect(mirabadClusters.first.intensity, equals(ClusterIntensity.peak));

      final shaykhontohurClusters = await repo.getNeighborhoodClusters(district: 'Shaykhontohur');
      expect(shaykhontohurClusters.length, equals(1));
      expect(shaykhontohurClusters.first.primaryVenueName, contains('Chorsu'));

      final nonExistent = await repo.getNeighborhoodClusters(district: 'NonExistent');
      expect(nonExistent, isEmpty);
    });

    test('Riverpod providers initialize NeighborhoodClusterRepository cleanly', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final repo = container.read(neighborhoodClusterRepositoryProvider);
      expect(repo, isA<NeighborhoodClusterRepository>());

      final clustersAsync = await container.read(neighborhoodClustersProvider('Mirabad').future);
      expect(clustersAsync, isA<List<NeighborhoodCluster>>());
      expect(clustersAsync, isNotEmpty);
      expect(clustersAsync.first.district, equals('Mirabad'));
    });
  });
}
