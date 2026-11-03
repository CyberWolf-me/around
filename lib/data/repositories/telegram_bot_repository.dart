import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/app_logger.dart';
import '../services/supabase_service.dart';

class TelegramBotRepository {
  /// Records a Telegram bot command interaction via Supabase RPC.
  /// Falls back gracefully when offline or uninitialized.
  Future<Map<String, dynamic>> recordCommandTelemetry({
    required String command,
    required int chatId,
    String languageCode = 'en',
    String? payload,
  }) async {
    final cleanCommand = command.trim().toLowerCase();
    if (cleanCommand.isEmpty) {
      return {'success': false, 'error': 'Command cannot be empty'};
    }

    if (!SupabaseService.isInitialized) {
      return {
        'success': true,
        'offline': true,
        'command': cleanCommand,
        'chat_id': chatId,
        'language': languageCode,
      };
    }

    try {
      final res = await SupabaseService.client.rpc(
        'record_bot_command',
        params: {
          'p_command': cleanCommand,
          'p_telegram_chat_id': chatId,
          'p_language_code': languageCode,
          'p_payload': payload,
        },
      );

      if (res is Map<String, dynamic>) {
        return res;
      }
      return {'success': true, 'data': res};
    } catch (e) {
      AppLogger.warn('TelegramBotRepository', 'Failed to record bot command RPC, falling back', e);
      return {
        'success': false,
        'error': e.toString(),
        'command': cleanCommand,
      };
    }
  }
}

final telegramBotRepositoryProvider = Provider<TelegramBotRepository>((ref) {
  return TelegramBotRepository();
});
