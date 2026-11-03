import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Supported Telegram Mini App deep link target types.
enum TelegramDeepLinkType {
  route,
  postcard,
  season,
  crawl,
  referral,
  unknown;

  String get prefix => name;
}

/// Parsed outcome of a Telegram `startapp` or `start` parameter payload.
class TelegramDeepLinkTarget {
  final TelegramDeepLinkType type;
  final String rawPayload;
  final String resourceId;
  final String? referrerId;
  final String appRoute;

  const TelegramDeepLinkTarget({
    required this.type,
    required this.rawPayload,
    required this.resourceId,
    this.referrerId,
    required this.appRoute,
  });

  bool get isValid => type != TelegramDeepLinkType.unknown && resourceId.isNotEmpty;
}

/// Core computational engine for Telegram Mini App `startapp` parameters
/// and canonical Telegram deep link creation (`P29-01`).
class TelegramDeepLinkEngine {
  static const String botUsername = 'around_tashkent_bot';
  static const String appShortName = 'app';
  static const String defaultBaseUrl = 'https://t.me/$botUsername/$appShortName';

  /// Parses a raw Telegram `startapp` or `start` parameter string.
  /// Example inputs:
  /// - `route_mirabad_coffee_crawl`
  /// - `postcard_REC-MIR-2026-774`
  /// - `season_2026-11`
  /// - `crawl_CR-MRB-77`
  /// - `ref_kamila`
  /// - `route_mirabad_coffee_crawl__ref_kamila` (combined with referral)
  static TelegramDeepLinkTarget parseStartParam(String? raw) {
    if (raw == null) {
      return const TelegramDeepLinkTarget(
        type: TelegramDeepLinkType.unknown,
        rawPayload: '',
        resourceId: '',
        appRoute: '/explore',
      );
    }

    final trimmed = raw.trim();
    if (trimmed.isEmpty) {
      return const TelegramDeepLinkTarget(
        type: TelegramDeepLinkType.unknown,
        rawPayload: '',
        resourceId: '',
        appRoute: '/explore',
      );
    }

    String payload = trimmed;
    String? extractedReferrer;

    // Check for optional referral suffix: "__ref_<user>"
    if (payload.contains('__ref_')) {
      final parts = payload.split('__ref_');
      payload = parts[0];
      if (parts.length > 1 && parts[1].isNotEmpty) {
        extractedReferrer = parts[1];
      }
    }

    if (payload.startsWith('route_')) {
      final id = payload.substring('route_'.length).trim();
      return TelegramDeepLinkTarget(
        type: TelegramDeepLinkType.route,
        rawPayload: trimmed,
        resourceId: id,
        referrerId: extractedReferrer,
        appRoute: id.isNotEmpty ? '/explore/routes/$id' : '/explore',
      );
    }

    if (payload.startsWith('postcard_')) {
      final id = payload.substring('postcard_'.length).trim();
      return TelegramDeepLinkTarget(
        type: TelegramDeepLinkType.postcard,
        rawPayload: trimmed,
        resourceId: id,
        referrerId: extractedReferrer,
        appRoute: id.isNotEmpty ? '/explore/postcards/$id' : '/explore',
      );
    }

    if (payload.startsWith('season_')) {
      final id = payload.substring('season_'.length).trim();
      return TelegramDeepLinkTarget(
        type: TelegramDeepLinkType.season,
        rawPayload: trimmed,
        resourceId: id,
        referrerId: extractedReferrer,
        appRoute: id.isNotEmpty ? '/explore/seasons/$id' : '/explore',
      );
    }

    if (payload.startsWith('crawl_')) {
      final id = payload.substring('crawl_'.length).trim();
      return TelegramDeepLinkTarget(
        type: TelegramDeepLinkType.crawl,
        rawPayload: trimmed,
        resourceId: id,
        referrerId: extractedReferrer,
        appRoute: id.isNotEmpty ? '/explore/crawl/$id' : '/explore',
      );
    }

    if (payload.startsWith('ref_')) {
      final id = payload.substring('ref_'.length).trim();
      return TelegramDeepLinkTarget(
        type: TelegramDeepLinkType.referral,
        rawPayload: trimmed,
        resourceId: id,
        referrerId: id,
        appRoute: '/explore',
      );
    }

    // Fallback for unformatted or unrecognized payloads
    return TelegramDeepLinkTarget(
      type: TelegramDeepLinkType.unknown,
      rawPayload: trimmed,
      resourceId: trimmed,
      referrerId: extractedReferrer,
      appRoute: '/explore',
    );
  }

  /// Builds a canonical Telegram Mini App direct link URL.
  static String buildBotUrl({
    required TelegramDeepLinkType type,
    required String resourceId,
    String? referrerId,
    String baseUrl = defaultBaseUrl,
  }) {
    final cleanId = resourceId.trim();
    String param;

    if (type == TelegramDeepLinkType.referral) {
      param = 'ref_$cleanId';
    } else {
      final prefix = type.name;
      param = '${prefix}_$cleanId';
      if (referrerId != null && referrerId.trim().isNotEmpty) {
        param += '__ref_${referrerId.trim()}';
      }
    }

    final encodedParam = Uri.encodeQueryComponent(param);
    return '$baseUrl?startapp=$encodedParam';
  }

  /// Formats attractive localized share text for Telegram chats & channels.
  static String formatShareMessage({
    required TelegramDeepLinkType type,
    required String title,
    required String url,
    String language = 'en',
  }) {
    final lang = language.toLowerCase();

    switch (type) {
      case TelegramDeepLinkType.route:
        switch (lang) {
          case 'uz':
            return '🇺🇿 Toshkent bo‘ylab sayr: "$title" yo‘nalishi Around ilovasida!\n\nBiz bilan birga kashf eting: $url';
          case 'ru':
            return '🇺🇿 Маршрут по Ташкенту: "$title" в приложении Around!\n\nПрисоединяйтесь к прогулке: $url';
          case 'en':
          default:
            return '🇺🇿 Tashkent Walking Route: "$title" on Around!\n\nExplore with us: $url';
        }

      case TelegramDeepLinkType.postcard:
        switch (lang) {
          case 'uz':
            return '☕ Toshkent Madaniy Cheki: "$title"!\n\nTasdiqlangan kashfiyot: $url';
          case 'ru':
            return '☕ Ташкентский Культурный Чек: "$title"!\n\nПроверенное место: $url';
          case 'en':
          default:
            return '☕ Tashkent Cultural Receipt: "$title"!\n\nVerified discovery: $url';
        }

      case TelegramDeepLinkType.season:
        switch (lang) {
          case 'uz':
            return '🏆 Around Oylik Mavsumi: "$title"!\n\nToshkent bo‘ylab kuboklarni qo‘lga kiriting: $url';
          case 'ru':
            return '🏆 Сезон Месяца в Around: "$title"!\n\nЗарабатывайте трофеи в Ташкенте: $url';
          case 'en':
          default:
            return '🏆 Around Monthly Season: "$title"!\n\nEarn trophies across Tashkent: $url';
        }

      case TelegramDeepLinkType.crawl:
        switch (lang) {
          case 'uz':
            return '👥 Birgalikda sayr guruhi: "$title"!\n\nJonli xonaga ulaning: $url';
          case 'ru':
            return '👥 Совместная прогулка: "$title"!\n\nПрисоединяйтесь к комнате: $url';
          case 'en':
          default:
            return '👥 Group Crawl Session: "$title"!\n\nJoin the live room: $url';
        }

      case TelegramDeepLinkType.referral:
      case TelegramDeepLinkType.unknown:
        switch (lang) {
          case 'uz':
            return '🇺🇿 Toshkentning eng yaxshi maskanlarini kashf eting: $url';
          case 'ru':
            return '🇺🇿 Исследуйте лучшие места Ташкента: $url';
          case 'en':
          default:
            return '🇺🇿 Discover Tashkent’s best local spots on Around: $url';
        }
    }
  }
}

final telegramDeepLinkEngineProvider = Provider<TelegramDeepLinkEngine>((ref) {
  return TelegramDeepLinkEngine();
});
