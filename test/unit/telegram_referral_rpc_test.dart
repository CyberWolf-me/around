import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:around_app/core/services/telegram_deep_link_engine.dart';
import 'package:around_app/data/repositories/telegram_referral_repository.dart';

void main() {
  group('P29-04: Telegram Referral SQL Migration & RPC Repository Tests', () {
    test('SQL migration 00020 exists and defines schema, RLS, and launch RPC', () {
      final migrationFile = File('supabase/migrations/00020_referral_deep_links_and_launch_telemetry.sql');
      expect(migrationFile.existsSync(), isTrue, reason: 'Migration 00020 must exist');

      final content = migrationFile.readAsStringSync();

      // Schema checks
      expect(content, contains('CREATE TABLE IF NOT EXISTS public.referral_launches'));
      expect(content, contains('visitor_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE'));
      expect(content, contains('referrer_handle TEXT NOT NULL'));
      expect(content, contains('target_type TEXT NOT NULL'));

      // Indexes
      expect(content, contains('CREATE INDEX IF NOT EXISTS idx_referral_launches_visitor'));
      expect(content, contains('CREATE INDEX IF NOT EXISTS idx_referral_launches_referrer'));
      expect(content, contains('CREATE INDEX IF NOT EXISTS idx_referral_launches_launched_at'));

      // RLS
      expect(content, contains('ALTER TABLE public.referral_launches ENABLE ROW LEVEL SECURITY;'));
      expect(content, contains('CREATE POLICY referral_launches_read'));
      expect(content, contains('CREATE POLICY referral_launches_insert'));
      expect(content, contains('WITH CHECK (auth.uid() = visitor_id)'));

      // RPC & Security Invariant Rule C
      expect(content, contains('CREATE OR REPLACE FUNCTION public.record_telegram_launch'));
      expect(content, contains('SECURITY DEFINER'));
      expect(content, contains('v_uid := auth.uid();'));
      expect(content, contains('IF v_uid IS NULL THEN'));
      expect(content, contains('INSERT INTO public.referral_launches'));
      expect(content, contains('UPDATE public.profiles'));

      // Grants
      expect(content, contains('GRANT EXECUTE ON FUNCTION public.record_telegram_launch(TEXT, TEXT, TEXT) TO authenticated;'));
    });

    test('TelegramReferralRepository records launch locally when offline or unauthenticated', () async {
      final repo = TelegramReferralRepository();
      final res = await repo.recordTelegramLaunch(
        referrerHandle: 'kamila_tashkent',
        targetType: TelegramDeepLinkType.route,
        resourceId: 'mirabad_coffee_crawl',
      );

      expect(res['success'], isTrue);
      expect(res['offline'], isTrue);
      expect(res['referrer_handle'], equals('kamila_tashkent'));
      expect(res['target_type'], equals('route'));
      expect(res['resource_id'], equals('mirabad_coffee_crawl'));
      expect(res['xp_awarded'], equals(10));
    });

    test('TelegramReferralRepository handles empty referrer gracefully', () async {
      final repo = TelegramReferralRepository();
      final res = await repo.recordTelegramLaunch(
        referrerHandle: '',
        targetType: TelegramDeepLinkType.postcard,
        resourceId: 'REC-MIR-2026-774',
      );

      expect(res['success'], isTrue);
      expect(res['referrer_handle'], equals('direct'));
      expect(res['xp_awarded'], equals(0));
    });

    test('TelegramReferralRepository handles getReferralLaunches when offline', () async {
      final repo = TelegramReferralRepository();
      final launches = await repo.getReferralLaunches();

      expect(launches, isEmpty);
    });

    test('Riverpod provider initializes TelegramReferralRepository cleanly', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final repo = container.read(telegramReferralRepositoryProvider);
      expect(repo, isA<TelegramReferralRepository>());
    });
  });
}
