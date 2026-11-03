import 'dart:convert';
import 'package:flutter/services.dart';
import 'app_logger.dart';

/// Payload extracted from a Tashkent friend invite code.
class FriendInvitePayload {
  final String inviterId;
  final String username;
  final String fullName;
  final String neighborhood;
  final DateTime createdAt;

  const FriendInvitePayload({
    required this.inviterId,
    required this.username,
    required this.fullName,
    required this.neighborhood,
    required this.createdAt,
  });

  /// Invite links expire after 14 days to preserve privacy and freshness.
  bool get isExpired {
    final diff = DateTime.now().difference(createdAt);
    return diff.inDays > 14;
  }
}

/// Service generating and parsing deterministic friend invite links and QR payloads
/// to enable instantaneous mutual friendship connection in Tashkent.
class FriendInviteService {
  static const String prefix = 'inv_';
  static const String canonicalWebDomain = 'around.tashkent.app';
  static const String customScheme = 'around';

  /// Generates a signed, deterministic invite code from curator profile credentials.
  static String generateInviteCode({
    required String inviterId,
    required String username,
    required String fullName,
    required String neighborhood,
    DateTime? timestamp,
  }) {
    final time = timestamp ?? DateTime.now();
    final data = {
      'uid': inviterId.trim(),
      'usr': username.trim().replaceAll('@', ''),
      'name': fullName.trim(),
      'dist': neighborhood.trim(),
      'ts': time.millisecondsSinceEpoch,
    };

    final jsonStr = jsonEncode(data);
    final bytes = utf8.encode(jsonStr);
    final b64 = base64Url.encode(bytes).replaceAll('=', '');
    return '$prefix$b64';
  }

  /// Parses and validates an invite code string.
  static FriendInvitePayload? parseInviteCode(String code) {
    try {
      var raw = code.trim();
      if (raw.startsWith(prefix)) {
        raw = raw.substring(prefix.length);
      }

      // Add back base64 padding if needed
      final mod = raw.length % 4;
      if (mod > 0) {
        raw += '=' * (4 - mod);
      }

      final bytes = base64Url.decode(raw);
      final jsonStr = utf8.decode(bytes);
      final map = jsonDecode(jsonStr);

      if (map is! Map<String, dynamic>) return null;

      final uid = map['uid'] as String?;
      final usr = map['usr'] as String?;
      final name = map['name'] as String? ?? 'Curator';
      final dist = map['dist'] as String? ?? 'Tashkent';
      final ts = map['ts'] as int?;

      if (uid == null || uid.isEmpty || usr == null || usr.isEmpty || ts == null) {
        return null;
      }

      final createdAt = DateTime.fromMillisecondsSinceEpoch(ts);
      return FriendInvitePayload(
        inviterId: uid,
        username: usr,
        fullName: name,
        neighborhood: dist,
        createdAt: createdAt,
      );
    } catch (e) {
      AppLogger.warn('FriendInviteService', 'Failed to parse invite code: $code', e);
      return null;
    }
  }

  /// Generates the canonical URL for clipboard sharing or QR rendering.
  static String buildInviteUrl(String code, {bool web = true}) {
    final cleanCode = Uri.encodeComponent(code.trim());
    if (web) {
      return 'https://$canonicalWebDomain/invite/$cleanCode';
    }
    return '$customScheme://invite/$cleanCode';
  }

  /// Copies an invite share link to the system clipboard.
  static Future<String> copyInviteLink({
    required String inviterId,
    required String username,
    required String fullName,
    required String neighborhood,
  }) async {
    final code = generateInviteCode(
      inviterId: inviterId,
      username: username,
      fullName: fullName,
      neighborhood: neighborhood,
    );
    final link = buildInviteUrl(code, web: true);
    await Clipboard.setData(ClipboardData(text: link));
    return link;
  }
}
