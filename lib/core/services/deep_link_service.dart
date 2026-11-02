import 'package:flutter/services.dart';
import '../../core/services/app_logger.dart';

/// Handles deep link generation, universal URL resolution, and clipboard sharing
/// for Tashkent venues and community drops.
class DeepLinkService {
  static const String customScheme = 'around';
  static const String canonicalWebDomain = 'around.tashkent.app';
  static const List<String> supportedDomains = [
    'around.tashkent.app',
    'around.app',
    'around-discovery.web.app',
  ];

  /// Builds a canonical deep link URI for a venue.
  static String buildPlaceUri(String placeSlugOrId, {bool web = true}) {
    final cleanSlug = Uri.encodeComponent(placeSlugOrId.trim());
    if (web) {
      return 'https://$canonicalWebDomain/places/$cleanSlug';
    }
    return '$customScheme://places/$cleanSlug';
  }

  /// Builds a canonical deep link URI for an experience drop.
  static String buildDropUri(String dropId, {bool web = true}) {
    final cleanId = Uri.encodeComponent(dropId.trim());
    if (web) {
      return 'https://$canonicalWebDomain/drops/$cleanId';
    }
    return '$customScheme://drops/$cleanId';
  }

  /// Builds a canonical deep link URI for a user's Tashkent Taste Passport.
  static String buildPassportUri(String username, {bool web = true}) {
    final clean = Uri.encodeComponent(username.trim().replaceAll('@', ''));
    if (web) {
      return 'https://$canonicalWebDomain/passport/$clean';
    }
    return '$customScheme://passport/$clean';
  }

  /// Builds a canonical deep link URI for a friend invite link.
  static String buildInviteUri(String inviteCode, {bool web = true}) {
    final clean = Uri.encodeComponent(inviteCode.trim());
    if (web) {
      return 'https://$canonicalWebDomain/invite/$clean';
    }
    return '$customScheme://invite/$clean';
  }

  /// Resolves an incoming URI (custom scheme or universal link) into an internal app route.
  static String? resolveRouteFromUri(Uri uri) {
    try {
      // 1. Custom app scheme: around://places/:id or around://drops/:id
      if (uri.scheme.toLowerCase() == customScheme) {
        final host = uri.host.toLowerCase();
        final pathSegments = uri.pathSegments;

        if (host == 'places') {
          final id = pathSegments.isNotEmpty ? pathSegments.first : '';
          return id.isNotEmpty ? '/places/$id' : '/explore';
        }

        if (host == 'drops') {
          final id = pathSegments.isNotEmpty ? pathSegments.first : '';
          return id.isNotEmpty ? '/drops/$id' : '/feed';
        }

        if (host == 'passport') {
          final id = pathSegments.isNotEmpty ? pathSegments.first : '';
          return id.isNotEmpty ? '/passport/$id' : '/profile';
        }

        if (host == 'invite') {
          final id = pathSegments.isNotEmpty ? pathSegments.first : '';
          return id.isNotEmpty ? '/invite/$id' : '/feed';
        }

        if (pathSegments.isNotEmpty) {
          final section = pathSegments.first.toLowerCase();
          final id = pathSegments.length > 1 ? pathSegments[1] : '';
          if (section == 'places' && id.isNotEmpty) return '/places/$id';
          if (section == 'drops' && id.isNotEmpty) return '/drops/$id';
          if (section == 'passport' && id.isNotEmpty) return '/passport/$id';
          if (section == 'invite' && id.isNotEmpty) return '/invite/$id';
        }
      }

      // 2. HTTP / HTTPS Universal Link: https://around.tashkent.app/places/:id
      if (uri.scheme == 'http' || uri.scheme == 'https') {
        final domain = uri.host.toLowerCase();
        if (supportedDomains.contains(domain)) {
          final segments = uri.pathSegments;
          if (segments.isNotEmpty) {
            final section = segments.first.toLowerCase();
            final id = segments.length > 1 ? segments[1] : '';
            if (section == 'places' && id.isNotEmpty) return '/places/$id';
            if (section == 'drops' && id.isNotEmpty) return '/drops/$id';
            if (section == 'passport' && id.isNotEmpty) return '/passport/$id';
            if (section == 'invite' && id.isNotEmpty) return '/invite/$id';
            if (section == 'feed' || section == 'explore' || section == 'saved' || section == 'settings' || section == 'profile') {
              return '/$section';
            }
          }
        }
      }
    } catch (e) {
      AppLogger.warn('DeepLinkService', 'Error resolving deep link URI: $uri', e);
    }
    return null;
  }

  /// Copies a venue share link to system clipboard.
  static Future<String> copyPlaceShareLink(String placeSlugOrId) async {
    final link = buildPlaceUri(placeSlugOrId, web: true);
    await Clipboard.setData(ClipboardData(text: link));
    return link;
  }

  /// Copies a drop share link to system clipboard.
  static Future<String> copyDropShareLink(String dropId) async {
    final link = buildDropUri(dropId, web: true);
    await Clipboard.setData(ClipboardData(text: link));
    return link;
  }

  /// Copies a taste passport link to system clipboard.
  static Future<String> copyPassportShareLink(String username) async {
    final link = buildPassportUri(username, web: true);
    await Clipboard.setData(ClipboardData(text: link));
    return link;
  }

  /// Copies a friend invite link to system clipboard.
  static Future<String> copyInviteShareLink(String inviteCode) async {
    final link = buildInviteUri(inviteCode, web: true);
    await Clipboard.setData(ClipboardData(text: link));
    return link;
  }
}
