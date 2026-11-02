import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/curator_recommendation_engine.dart';
import '../../../data/repositories/profiles_repository.dart';
import '../../../data/services/haptic_service.dart';

/// Modal bottom sheet for coordinating mutual coffee meetups with a matched curator (`P21-01`).
/// Dynamically formats a personalized invitation message based on taste compatibility
/// and shared Tashkent venues, pre-populating direct Telegram chat (`t.me/<handle>`).
class CuratorCoffeePingSheet extends StatelessWidget {
  final CommunityMember member;
  final TasteOverlapMatch match;
  final String topVenueName;
  final String languageCode;
  final void Function(String url)? onLaunchOverride;

  const CuratorCoffeePingSheet({
    super.key,
    required this.member,
    required this.match,
    required this.topVenueName,
    this.languageCode = 'en',
    this.onLaunchOverride,
  });

  /// Presents the Coffee Ping bottom sheet with haptic feedback.
  static Future<void> show({
    required BuildContext context,
    required CommunityMember member,
    required TasteOverlapMatch match,
    String? topVenueName,
    String languageCode = 'en',
    void Function(String url)? onLaunchOverride,
  }) {
    HapticService.selection();
    final venueName = topVenueName ??
        (match.sharedPlaces.isNotEmpty
            ? match.sharedPlaces.first.replaceAll('place_', '').replaceAll('_', ' ')
            : 'Tashkent specialty spots');

    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => CuratorCoffeePingSheet(
        member: member,
        match: match,
        topVenueName: venueName,
        languageCode: languageCode,
        onLaunchOverride: onLaunchOverride,
      ),
    );
  }

  /// Generates personalized conversational coffee invitation message.
  static String buildInviteMessage({
    required String curatorName,
    required int matchPercent,
    required String venueName,
    String lang = 'en',
  }) {
    final firstName = curatorName.split(' ').first;
    switch (lang.toLowerCase()) {
      case 'uz':
        return 'Salom $firstName! Around ilovasida ko\'rdimki, bizning didimiz $matchPercent% mos tusharkan ($venueName). Bu hafta birga qahva ichishga nima deysiz?';
      case 'ru':
        return 'Привет, $firstName! В Around увидел(а), что у нас совпадение вкусов $matchPercent% ($venueName). Давай выпьем кофе на этой неделе?';
      case 'en':
      default:
        return 'Hey $firstName! Saw on Around that we\'re a $matchPercent% taste match (both love $venueName). Want to grab coffee sometime this week?';
    }
  }

  /// Generates direct Telegram chat URI for the curator's username or handle.
  static Uri buildTelegramUri({
    required String handle,
    required String message,
  }) {
    final cleanHandle = handle.replaceAll('@', '').trim();
    return Uri.https('t.me', '/$cleanHandle', {'text': message});
  }

  @override
  Widget build(BuildContext context) {
    final inviteMessage = buildInviteMessage(
      curatorName: member.name,
      matchPercent: match.compatibilityPercent,
      venueName: topVenueName,
      lang: languageCode,
    );

    final telegramUri = buildTelegramUri(
      handle: member.handle,
      message: inviteMessage,
    );

    return SafeArea(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.paper,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.borderSubtle, width: 1.5),
          boxShadow: const [AppColors.shadowFloating],
        ),
        padding: const EdgeInsets.all(22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(
                  color: AppColors.inkLight.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Header Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: AppColors.orangeSubtle,
                          shape: BoxShape.circle,
                        ),
                        child: const Text('☕', style: TextStyle(fontSize: 16)),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          'COFFEE MEETUP PING',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.spaceMono(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                            color: AppColors.orange,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.mintSubtle,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${match.compatibilityPercent}% MATCH',
                    style: GoogleFonts.spaceMono(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: AppColors.mint,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Curator Profile Summary
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.paper2,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.borderSubtle),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: AppColors.orange,
                    child: Text(
                      member.initials,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          member.name,
                          style: GoogleFonts.bricolageGrotesque(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.ink,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '@${member.handle} · ${member.neighborhood}',
                          style: GoogleFonts.instrumentSans(fontSize: 11.5, color: AppColors.ink3),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.paper,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.borderHairline),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('📍', style: TextStyle(fontSize: 10)),
                        const SizedBox(width: 4),
                        Text(
                          topVenueName,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: AppColors.ink,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Message Preview Box
            Text(
              'Personalized Invitation Preview:',
              style: GoogleFonts.spaceMono(fontSize: 9.5, color: AppColors.ink3),
            ),
            const SizedBox(height: 6),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.paper2,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.borderSubtle),
              ),
              child: Text(
                inviteMessage,
                style: GoogleFonts.instrumentSans(
                  fontSize: 13,
                  color: AppColors.ink,
                  height: 1.35,
                ),
              ),
            ),
            const SizedBox(height: 18),

            // Action Buttons Row
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    key: const Key('btn_copy_coffee_invite'),
                    onPressed: () async {
                      HapticService.selection();
                      await Clipboard.setData(ClipboardData(text: inviteMessage));
                      if (context.mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Coffee invite copied to clipboard!')),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.paper2,
                      foregroundColor: AppColors.ink,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: const BorderSide(color: AppColors.borderSubtle),
                      ),
                    ),
                    child: Text(
                      'Copy Text',
                      style: GoogleFonts.bricolageGrotesque(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    key: const Key('btn_telegram_coffee_invite'),
                    onPressed: () async {
                      HapticService.medium();
                      if (onLaunchOverride != null) {
                        onLaunchOverride!(telegramUri.toString());
                      } else {
                        try {
                          await launchUrl(telegramUri, mode: LaunchMode.externalApplication);
                        } catch (_) {}
                      }
                      if (context.mounted) {
                        Navigator.pop(context);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.orange,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.send_rounded, size: 14, color: Colors.white),
                        const SizedBox(width: 6),
                        Text(
                          'Invite on TG',
                          style: GoogleFonts.bricolageGrotesque(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
