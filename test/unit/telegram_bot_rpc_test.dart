import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:around_app/data/repositories/telegram_bot_repository.dart';

void main() {
  group('P32-04: Telegram Bot SQL Migration & Telemetry Repository Tests', () {
    test('SQL migration 00023 exists and defines bot_command_logs and record_bot_command RPC', () {
      final migrationFile = File('supabase/migrations/00023_telegram_bot_telemetry.sql');
      expect(migrationFile.existsSync(), isTrue, reason: 'Migration 00023 must exist');

      final content = migrationFile.readAsStringSync();

      // Schema
      expect(content, contains('CREATE TABLE IF NOT EXISTS public.bot_command_logs'));
      expect(content, contains('telegram_chat_id BIGINT NOT NULL'));
      expect(content, contains('command TEXT NOT NULL'));

      // Indexes
      expect(content, contains('CREATE INDEX IF NOT EXISTS idx_bot_command_chat'));
      expect(content, contains('CREATE INDEX IF NOT EXISTS idx_bot_command_created'));

      // RLS
      expect(content, contains('ALTER TABLE public.bot_command_logs ENABLE ROW LEVEL SECURITY;'));
      expect(content, contains('CREATE POLICY bot_command_logs_user_read'));

      // RPC
      expect(content, contains('CREATE OR REPLACE FUNCTION public.record_bot_command'));
      expect(content, contains('SECURITY DEFINER'));
      expect(content, contains('INSERT INTO public.bot_command_logs'));

      // Permissions
      expect(content, contains('GRANT EXECUTE ON FUNCTION public.record_bot_command(TEXT, BIGINT, TEXT, TEXT) TO anon, authenticated;'));
    });

    test('TelegramBotRepository records command telemetry offline cleanly', () async {
      final repo = TelegramBotRepository();
      final res = await repo.recordCommandTelemetry(
        command: '/start',
        chatId: 123456789,
        languageCode: 'uz',
        payload: 'route_mirabad_coffee_crawl',
      );

      expect(res['success'], isTrue);
      expect(res['offline'], isTrue);
      expect(res['command'], equals('/start'));
      expect(res['chat_id'], equals(123456789));
      expect(res['language'], equals('uz'));
    });

    test('TelegramBotRepository rejects empty command', () async {
      final repo = TelegramBotRepository();
      final res = await repo.recordCommandTelemetry(
        command: '   ',
        chatId: 987654321,
      );

      expect(res['success'], isFalse);
      expect(res['error'], contains('Command cannot be empty'));
    });

    test('Riverpod provider initializes TelegramBotRepository cleanly', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final repo = container.read(telegramBotRepositoryProvider);
      expect(repo, isA<TelegramBotRepository>());
    });
  });
}
