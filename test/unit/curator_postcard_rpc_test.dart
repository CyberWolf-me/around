import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:around_app/data/repositories/curator_postcard_repository.dart';

void main() {
  group('P27-04: Curator Postcards SQL Migration & RPC Repository Tests', () {
    test('SQL migration 00018 exists and defines schema, RLS, and share RPC', () {
      final migrationFile = File('supabase/migrations/00018_curator_postcards_and_viral_telemetry.sql');
      expect(migrationFile.existsSync(), isTrue, reason: 'Migration 00018 must exist');

      final content = migrationFile.readAsStringSync();

      // Schema checks
      expect(content, contains('CREATE TABLE IF NOT EXISTS public.postcard_shares'));
      expect(content, contains('user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE'));
      expect(content, contains('place_id TEXT NOT NULL'));
      expect(content, contains('share_channel TEXT NOT NULL DEFAULT \'telegram\''));

      // Indexes
      expect(content, contains('CREATE INDEX IF NOT EXISTS idx_postcard_shares_user'));
      expect(content, contains('CREATE INDEX IF NOT EXISTS idx_postcard_shares_place'));
      expect(content, contains('CREATE INDEX IF NOT EXISTS idx_postcard_shares_created_at'));

      // RLS
      expect(content, contains('ALTER TABLE public.postcard_shares ENABLE ROW LEVEL SECURITY;'));
      expect(content, contains('CREATE POLICY postcard_shares_read'));
      expect(content, contains('CREATE POLICY postcard_shares_insert'));
      expect(content, contains('WITH CHECK (auth.uid() = user_id)'));

      // RPC & Security Invariant Rule C
      expect(content, contains('CREATE OR REPLACE FUNCTION public.record_postcard_share'));
      expect(content, contains('SECURITY DEFINER'));
      expect(content, contains('v_uid := auth.uid();'));
      expect(content, contains('IF v_uid IS NULL THEN'));
      expect(content, contains('v_xp_awarded INTEGER := 25;'));
      expect(content, contains('INSERT INTO public.postcard_shares'));
      expect(content, contains('UPDATE public.profiles'));

      // Grants
      expect(content, contains('GRANT EXECUTE ON FUNCTION public.record_postcard_share(TEXT, TEXT, TEXT, TEXT, TEXT, TEXT) TO authenticated;'));
    });

    test('CuratorPostcardRepository records share locally when offline or unauthenticated', () async {
      final repo = CuratorPostcardRepository();
      final res = await repo.recordPostcardShare(
        placeId: 'place_breadly',
        routeId: 'mirabad_coffee_crawl',
        shareChannel: 'telegram',
        receiptNumber: 'REC-MIR-2026-774',
        theme: 'paper',
        aspectRatio: '9:16',
      );

      expect(res['success'], isTrue);
      expect(res['offline'], isTrue);
      expect(res['place_id'], equals('place_breadly'));
      expect(res['share_channel'], equals('telegram'));
      expect(res['xp_awarded'], equals(25));
    });

    test('CuratorPostcardRepository rejects empty placeId', () async {
      final repo = CuratorPostcardRepository();
      final res = await repo.recordPostcardShare(placeId: '   ');

      expect(res['success'], isFalse);
      expect(res['error'], contains('Place ID cannot be empty'));
    });

    test('CuratorPostcardRepository handles getRecentPostcardShares when offline', () async {
      final repo = CuratorPostcardRepository();
      final shares = await repo.getRecentPostcardShares();

      expect(shares, isEmpty);
    });

    test('Riverpod provider initializes CuratorPostcardRepository cleanly', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final repo = container.read(curatorPostcardRepositoryProvider);
      expect(repo, isA<CuratorPostcardRepository>());
    });
  });
}
