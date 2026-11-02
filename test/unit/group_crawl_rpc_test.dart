import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:around_app/data/repositories/group_crawl_repository.dart';

void main() {
  group('P26-04: Group Crawl SQL Migration & RPC Repository Tests', () {
    test('SQL migration 00017 exists and defines schema, RLS, and join/update RPC', () {
      final migrationFile = File('supabase/migrations/00017_group_crawl_sessions_and_live_beacons.sql');
      expect(migrationFile.existsSync(), isTrue, reason: 'Migration 00017 must exist');

      final content = migrationFile.readAsStringSync();

      // Schema
      expect(content, contains('CREATE TABLE IF NOT EXISTS public.group_crawl_sessions'));
      expect(content, contains('CREATE TABLE IF NOT EXISTS public.group_crawl_participants'));
      expect(content, contains('CONSTRAINT unique_session_participant UNIQUE(session_code, user_id)'));

      // Indexes
      expect(content, contains('CREATE INDEX IF NOT EXISTS idx_crawl_sessions_host'));
      expect(content, contains('CREATE INDEX IF NOT EXISTS idx_crawl_participants_session'));
      expect(content, contains('CREATE INDEX IF NOT EXISTS idx_crawl_participants_user'));

      // RLS
      expect(content, contains('ALTER TABLE public.group_crawl_sessions ENABLE ROW LEVEL SECURITY;'));
      expect(content, contains('ALTER TABLE public.group_crawl_participants ENABLE ROW LEVEL SECURITY;'));
      expect(content, contains('CREATE POLICY group_crawl_sessions_read'));
      expect(content, contains('CREATE POLICY group_crawl_participants_read'));

      // RPC & Security Invariant Rule C
      expect(content, contains('CREATE OR REPLACE FUNCTION public.join_or_update_group_crawl'));
      expect(content, contains('SECURITY DEFINER'));
      expect(content, contains('v_uid := auth.uid();'));
      expect(content, contains('IF v_uid IS NULL THEN'));
      expect(content, contains('INSERT INTO public.group_crawl_participants'));

      // Grants
      expect(content, contains('GRANT EXECUTE ON FUNCTION public.join_or_update_group_crawl(TEXT, TEXT) TO authenticated;'));
    });

    test('GroupCrawlRepository creates session locally when offline', () async {
      final repo = GroupCrawlRepository();
      final session = await repo.createSessionRemote(
        routeId: 'mirabad_coffee_crawl',
        routeTitle: 'Mirabad Specialty Coffee Crawl',
        hostUserId: 'user_kamila',
        hostName: 'Kamila',
        hostInitials: 'KR',
      );

      expect(session, isNotNull);
      expect(session?.routeId, equals('mirabad_coffee_crawl'));
      expect(session?.hostUserId, equals('user_kamila'));
      expect(session?.participants.length, equals(1));
      expect(session?.squadBonusXp, equals(200));
    });

    test('GroupCrawlRepository joinOrUpdateSession handles unauthenticated gracefully', () async {
      final repo = GroupCrawlRepository();
      final res = await repo.joinOrUpdateSession(sessionCode: 'CR-MRB-77');

      expect(res, isNull);
    });

    test('Riverpod groupCrawlRepositoryProvider and activeGroupCrawlProvider integrate seamlessly', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final repo = container.read(groupCrawlRepositoryProvider);
      expect(repo, isNotNull);

      final active = container.read(activeGroupCrawlProvider);
      expect(active, isNull);

      container.read(activeGroupCrawlProvider.notifier).setSession(null);
    });
  });
}
