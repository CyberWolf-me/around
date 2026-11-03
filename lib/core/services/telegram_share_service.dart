import 'dart:async';
import 'package:url_launcher/url_launcher.dart';
import 'analytics_service.dart';
import 'app_logger.dart';
import 'friend_invite_service.dart';

/// Type definition for URL launcher delegate, enabling deterministic unit testing.
typedef UrlLaunchDelegate = Future<bool> Function(Uri uri, {LaunchMode mode});

/// Service managing deep-linked native and web Telegram shares for Tashkent discovery,
/// friend invites, and Taste Passport viral loops.
class TelegramShareService {
  static const String webBaseUrl = 'https://t.me/share/url';
  static const String nativeScheme = 'tg';
  static const String nativeHost = 'msg_url';

  /// Constructs a valid Telegram share URI with percent-encoded URL and prefilled text.
  /// When [useNativeProtocol] is true, generates `tg://msg_url?url=...&text=...`.
  /// Otherwise generates the universal HTTPS link `https://t.me/share/url?url=...&text=...`.
  static Uri buildShareUri({
    required String url,
    required String text,
    bool useNativeProtocol = false,
  }) {
    final queryParameters = <String, String>{
      'url': url,
      'text': text,
    };

    if (useNativeProtocol) {
      return Uri(
        scheme: nativeScheme,
        host: nativeHost,
        queryParameters: queryParameters,
      );
    }

    return Uri.https('t.me', '/share/url', queryParameters);
  }

  /// Builds a conversational Telegram invite message tailored for Tashkent friend connections.
  static String buildInviteMessage({
    required String fullName,
    required String neighborhood,
    required String inviteUrl,
  }) {
    return '👋 Hey! Join me on Around Tashkent — the social discovery network where friends share authentic places, not anonymous reviews.\n\nConnect with me in $neighborhood to see each other\'s favorite cafes, bakeries, and evening spots:\n\n$inviteUrl';
  }

  /// Builds a shareable Telegram message for a curator's Tashkent Taste Passport.
  static String buildPassportMessage({
    required String fullName,
    required String username,
    required String neighborhood,
    int placeCount = 0,
    required String passportUrl,
  }) {
    final placesText = placeCount > 0 ? '$placeCount curated venues' : 'favorite local spots';
    return '🇺🇿 Check out my Tashkent Taste Passport on Around!\n\nI\'ve curated $placesText across $neighborhood (@$username). Explore my recommendations and see where to go next:\n\n$passportUrl';
  }

  /// Builds a Telegram share message for a specific Tashkent venue recommendation.
  static String buildVenueShareMessage({
    required String venueName,
    required String neighborhood,
    required String curatorName,
    required String venueUrl,
  }) {
    return '📍 Discovered $venueName in $neighborhood on Around Tashkent!\n\nCurated by $curatorName. Check out photos, ratings, and friend notes:\n\n$venueUrl';
  }

  /// Launches the Telegram share flow.
  /// Attempts the native `tg://` protocol first for seamless app-to-app transition.
  /// Falls back to universal `https://t.me/share/url` if the native client is not installed.
  static Future<bool> launchShare({
    required String url,
    required String text,
    UrlLaunchDelegate? launcher,
  }) async {
    final delegate = launcher ?? launchUrl;

    final nativeUri = buildShareUri(
      url: url,
      text: text,
      useNativeProtocol: true,
    );

    final webUri = buildShareUri(
      url: url,
      text: text,
      useNativeProtocol: false,
    );

    try {
      // 1. Attempt native Telegram app protocol
      final launched = await delegate(
        nativeUri,
        mode: LaunchMode.externalApplication,
      );

      if (launched) {
        AppLogger.info('TelegramShareService', 'Launched Telegram via native protocol: $nativeUri');
        _trackShare(url);
        return true;
      }
    } catch (e) {
      AppLogger.info('TelegramShareService', 'Native Telegram protocol failed, falling back to web: $e');
    }

    try {
      // 2. Fall back to universal HTTPS web link
      final launchedWeb = await delegate(
        webUri,
        mode: LaunchMode.externalApplication,
      );

      if (launchedWeb) {
        AppLogger.info('TelegramShareService', 'Launched Telegram via web URL: $webUri');
        _trackShare(url);
        return true;
      }
    } catch (e) {
      AppLogger.warn('TelegramShareService', 'Failed to launch Telegram share: $webUri', e);
    }

    return false;
  }

  /// One-tap helper to share a friend invite directly to Telegram.
  static Future<bool> shareInviteToTelegram({
    required String inviterId,
    required String username,
    required String fullName,
    required String neighborhood,
    UrlLaunchDelegate? launcher,
  }) async {
    final code = FriendInviteService.generateInviteCode(
      inviterId: inviterId,
      username: username,
      fullName: fullName,
      neighborhood: neighborhood,
    );

    final inviteUrl = FriendInviteService.buildInviteUrl(code, web: true);
    final text = buildInviteMessage(
      fullName: fullName,
      neighborhood: neighborhood,
      inviteUrl: inviteUrl,
    );

    return launchShare(
      url: inviteUrl,
      text: text,
      launcher: launcher,
    );
  }

  /// One-tap helper to share a user's Taste Passport to Telegram.
  static Future<bool> sharePassportToTelegram({
    required String fullName,
    required String username,
    required String neighborhood,
    int placeCount = 0,
    UrlLaunchDelegate? launcher,
  }) async {
    final passportUrl = 'https://around.tashkent.app/u/$username/passport';
    final text = buildPassportMessage(
      fullName: fullName,
      username: username,
      neighborhood: neighborhood,
      placeCount: placeCount,
      passportUrl: passportUrl,
    );

    return launchShare(
      url: passportUrl,
      text: text,
      launcher: launcher,
    );
  }

  static void _trackShare(String url) {
    AnalyticsService.instance.track(
      AnalyticsEvent.friendRequestSent,
      {
        'method': 'telegram_share',
        'target_url': url,
      },
    );
  }
}
