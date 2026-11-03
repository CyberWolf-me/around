import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:around_app/data/repositories/architectural_badge_repository.dart';

void main() {
  group('P41-04: Architectural Badges Schema, RPC & Repository Tests', () {
    test('migration 00032_architectural_badges.sql is syntactically hardened', () {
      final migrationFile = File('supabase/migrations/00032_architectural_badges.sql');
      expect(migrationFile.existsSync(), isTrue, reason: 'Migration file must exist');

      final sql = migrationFile.readAsStringSync();

      // Schema verification
      expect(sql, contains('CREATE TABLE IF NOT EXISTS public.architectural_quests'));
      expect(sql, contains('CREATE TABLE IF NOT EXISTS public.architectural_quest_stops'));
      expect(sql, contains('CREATE TABLE IF NOT EXISTS public.user_quest_visits'));
      expect(sql, contains('CREATE TABLE IF NOT EXISTS public.user_unlocked_badges'));

      // Row-Level Security
      expect(sql, contains('ALTER TABLE public.architectural_quests ENABLE ROW LEVEL SECURITY;'));
      expect(sql, contains('ALTER TABLE public.architectural_quest_stops ENABLE ROW LEVEL SECURITY;'));
      expect(sql, contains('ALTER TABLE public.user_quest_visits ENABLE ROW LEVEL SECURITY;'));
      expect(sql, contains('ALTER TABLE public.user_unlocked_badges ENABLE ROW LEVEL SECURITY;'));

      // Dual-layer privacy invariant (Rule C & Security mandate)
      expect(sql, contains('hide_visits_history'));
      expect(sql, contains('auth.uid() = user_id'));

      // RPC signature & security definer
      expect(sql, contains('CREATE OR REPLACE FUNCTION public.record_quest_stop_visit'));
      expect(sql, contains('SECURITY DEFINER'));
      expect(sql, contains('auth.uid()'));
      expect(sql, contains('badge_unlocked_now'));
    });

    test('ArchitecturalBadgeRepository returns default quests in offline fallback', () async {
      final repository = ArchitecturalBadgeRepository();
      final quests = await repository.getQuests();

      expect(quests, isNotEmpty);
      expect(quests.length, greaterThanOrEqualTo(3));
      expect(quests.first.slug, equals('tashkent-modernism'));
      expect(quests.first.stops.length, equals(3));
    });

    test('ArchitecturalBadgeRepository returns visited stops and records offline visit', () async {
      final repository = ArchitecturalBadgeRepository();

      final visited = await repository.getUserVisitedStops();
      expect(visited, isNotEmpty);
      expect(visited, contains('hotel-uzbekistan'));

      final result = await repository.recordStopVisit(
        'tashkent-modernism',
        'hotel-uzbekistan',
      );
      expect(result.success, isTrue);
      expect(result.questSlug, equals('tashkent-modernism'));
      expect(result.stopKey, equals('hotel-uzbekistan'));
    });

    test('QuestVisitResult parses map responses cleanly', () {
      final map = {
        'success': true,
        'quest_slug': 'tashkent-modernism',
        'stop_key': 'tashkent-circus',
        'visited_count': 3,
        'required_stops': 3,
        'is_completed': true,
        'badge_unlocked_now': true,
        'badge_name': 'Modernist Connoisseur',
        'xp_awarded': 50,
      };

      final parsed = QuestVisitResult.fromMap(map);
      expect(parsed.success, isTrue);
      expect(parsed.isCompleted, isTrue);
      expect(parsed.badgeUnlockedNow, isTrue);
      expect(parsed.xpAwarded, equals(50));
      expect(parsed.badgeName, equals('Modernist Connoisseur'));
    });

    test('Riverpod providers initialize repository and future providers cleanly', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final repo = container.read(architecturalBadgeRepositoryProvider);
      expect(repo, isA<ArchitecturalBadgeRepository>());

      final quests = await container.read(architecturalQuestsProvider.future);
      expect(quests.length, greaterThanOrEqualTo(3));

      final visited = await container.read(userQuestVisitedStopsProvider.future);
      expect(visited, isNotEmpty);
    });
  });
}
