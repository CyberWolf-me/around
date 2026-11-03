import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:around_app/core/services/curator_tour_story_engine.dart';
import 'package:around_app/data/repositories/curator_tour_story_repository.dart';

void main() {
  group('P40-04: Curator Tour Stories RPC & Repository Tests', () {
    test('migration 00031_curator_tour_stories.sql is syntactically hardened', () {
      final file = File('supabase/migrations/00031_curator_tour_stories.sql');
      expect(file.existsSync(), isTrue);

      final sql = file.readAsStringSync();
      expect(sql, contains('CREATE TABLE IF NOT EXISTS public.curator_tours'));
      expect(sql, contains('CREATE TABLE IF NOT EXISTS public.tour_stop_stories'));
      expect(sql, contains('ALTER TABLE public.curator_tours ENABLE ROW LEVEL SECURITY;'));
      expect(sql, contains('ALTER TABLE public.tour_stop_stories ENABLE ROW LEVEL SECURITY;'));
      expect(sql, contains('CREATE OR REPLACE FUNCTION public.get_curator_tour_details'));
      expect(sql, contains('SECURITY DEFINER'));
      expect(sql, contains('SET search_path = public, extensions'));
      expect(sql, contains('GRANT EXECUTE ON FUNCTION public.get_curator_tour_details(UUID) TO authenticated, anon;'));
      expect(sql, contains('hide_visits_history, false) = false'));
      expect(sql, contains('auth.uid() = creator_id'));
    });

    test('CuratorTourStoryRepository returns offline tour details when Supabase is uninitialized', () async {
      final repo = CuratorTourStoryRepository();
      final tour = await repo.getCuratorTourDetails('tour-tashkent-modernism');

      expect(tour, isNotNull);
      expect(tour!.title, contains('Modernism'));
      expect(tour.stops.length, equals(2));
      expect(tour.stops.first.chapterIndex, equals(1));
      expect(tour.stops.first.venueName, contains('Kosmonavtlar'));
    });

    test('CuratorTourStoryRepository filters district tours accurately in offline fallback', () async {
      final repo = CuratorTourStoryRepository();

      final allTours = await repo.getDistrictTours();
      expect(allTours.length, equals(2));

      final shaykhontohurTours = await repo.getDistrictTours(district: 'Shaykhontohur');
      expect(shaykhontohurTours.length, equals(1));
      expect(shaykhontohurTours.first.id, equals('tour-chorsu-spice'));
      expect(shaykhontohurTours.first.curatorName, equals('Nodir Usmanov'));
    });

    test('Riverpod providers initialize CuratorTourStoryRepository cleanly', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final repo = container.read(curatorTourStoryRepositoryProvider);
      expect(repo, isA<CuratorTourStoryRepository>());

      final tourAsync = await container.read(curatorTourDetailsProvider('tour-tashkent-modernism').future);
      expect(tourAsync, isA<CuratorTour>());
      expect(tourAsync!.stops.length, equals(2));
    });
  });
}
