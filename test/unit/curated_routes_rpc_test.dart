import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:around_app/data/repositories/curated_route_repository.dart';

void main() {
  group('P25-04: Curated Routes SQL Migration & Completion Repository Tests', () {
    test('SQL migration 00016 exists and defines schema, RLS, and completion RPC', () {
      final migrationFile = File('supabase/migrations/00016_curated_routes_and_crawl_completions.sql');
      expect(migrationFile.existsSync(), isTrue, reason: 'Migration 00016 must exist');

      final content = migrationFile.readAsStringSync();

      // Table definitions
      expect(content, contains('CREATE TABLE IF NOT EXISTS public.curated_routes'));
      expect(content, contains('CREATE TABLE IF NOT EXISTS public.route_completions'));

      // Constraints & Indexes
      expect(content, contains('CONSTRAINT unique_user_route_completion UNIQUE(user_id, route_id)'));
      expect(content, contains('CREATE INDEX IF NOT EXISTS idx_route_completions_user'));
      expect(content, contains('CREATE INDEX IF NOT EXISTS idx_route_completions_route'));

      // Row-Level Security
      expect(content, contains('ALTER TABLE public.curated_routes ENABLE ROW LEVEL SECURITY;'));
      expect(content, contains('ALTER TABLE public.route_completions ENABLE ROW LEVEL SECURITY;'));
      expect(content, contains('CREATE POLICY curated_routes_read_all ON public.curated_routes'));
      expect(content, contains('CREATE POLICY route_completions_read_owner_or_friends ON public.route_completions'));

      // RPC & Security Rule C caller binding
      expect(content, contains('CREATE OR REPLACE FUNCTION public.complete_curated_route(p_route_id TEXT)'));
      expect(content, contains('SECURITY DEFINER'));
      expect(content, contains('v_uid := auth.uid();'));
      expect(content, contains('IF v_uid IS NULL THEN'));
      expect(content, contains('INSERT INTO public.route_completions'));
      expect(content, contains('UPDATE public.profiles'));
      expect(content, contains('SET curator_xp = curator_xp + v_route.xp_reward'));

      // Seed Routes
      expect(content, contains('mirabad_coffee_crawl'));
      expect(content, contains('chorsu_heritage_trail'));
      expect(content, contains('central_cultural_promenade'));

      // Grants
      expect(content, contains('GRANT EXECUTE ON FUNCTION public.complete_curated_route(TEXT) TO authenticated;'));
    });

    test('CuratedRouteRepository returns default curated routes when offline', () async {
      final repo = CuratedRouteRepository();
      final routes = await repo.getCuratedRoutes();

      expect(routes.length, greaterThanOrEqualTo(3));
      expect(routes.any((r) => r.id == 'mirabad_coffee_crawl'), isTrue);
      expect(routes.any((r) => r.id == 'chorsu_heritage_trail'), isTrue);
      expect(routes.any((r) => r.id == 'central_cultural_promenade'), isTrue);
    });

    test('CuratedRouteRepository handles unauthenticated completion query gracefully', () async {
      final repo = CuratedRouteRepository();
      final completed = await repo.getCompletedRouteIds();

      expect(completed, isEmpty);
    });

    test('Riverpod curatedRouteRepositoryProvider provides singleton', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final repo = container.read(curatedRouteRepositoryProvider);
      expect(repo, isNotNull);

      final completed = await container.read(completedRoutesProvider(null).future);
      expect(completed, isEmpty);
    });
  });
}
