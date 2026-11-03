import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/curator_accolades_engine.dart';
import '../../../core/services/season_trophy_engine.dart';
import '../../../data/services/haptic_service.dart';

class CuratorTrophyCabinet extends StatelessWidget {
  final CuratorAccolades accolades;
  final String locale;
  final VoidCallback? onShare;

  const CuratorTrophyCabinet({
    super.key,
    required this.accolades,
    this.locale = 'en',
    this.onShare,
  });

  void _showTrophyDetails(BuildContext context, CuratorAccoladeTrophy trophy) {
    HapticService.selection();
    final isGold = trophy.tier == CuratorTrophyTier.gold;
    final isSilver = trophy.tier == CuratorTrophyTier.silver;
    final borderColor = isGold
        ? AppColors.butter
        : (isSilver ? const Color(0xFFC0C0C0) : const Color(0xFFCD7F32));

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.paper,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.borderMedium,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Center(
                  child: Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.cardSurface,
                      border: Border.all(color: borderColor, width: 2.5),
                      boxShadow: const [AppColors.shadowCard],
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      trophy.tier.emoji,
                      style: const TextStyle(fontSize: 28),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  trophy.seasonTitle,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${trophy.tier.name.toUpperCase()} TROPHY • ${trophy.seasonId}',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                    color: AppColors.ink3,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.paper2,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.borderSubtle),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Column(
                        children: [
                          Text(
                            '${trophy.completedChallengesCount}',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: AppColors.ink,
                            ),
                          ),
                          Text(
                            locale.startsWith('uz')
                                ? 'Vazifalar'
                                : (locale.startsWith('ru') ? 'Задания' : 'Quests'),
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              color: AppColors.ink3,
                            ),
                          ),
                        ],
                      ),
                      Container(width: 1, height: 24, color: AppColors.borderSubtle),
                      Column(
                        children: [
                          Text(
                            '+${trophy.xpBonus} XP',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: AppColors.orange,
                            ),
                          ),
                          Text(
                            locale.startsWith('uz')
                                ? 'Bonus XP'
                                : (locale.startsWith('ru') ? 'Бонус XP' : 'Bonus XP'),
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              color: AppColors.ink3,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.ink,
                    foregroundColor: AppColors.paper,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    locale.startsWith('uz')
                        ? 'Yopish'
                        : (locale.startsWith('ru') ? 'Закрыть' : 'Close'),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _copyAccoladesShare(BuildContext context) {
    HapticService.selection();
    final engine = CuratorAccoladesEngine();
    final summary = engine.generateShareSummary(accolades, locale: locale);
    Clipboard.setData(ClipboardData(text: summary));

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          locale.startsWith('uz')
              ? '✓ Yutuqlar havolasi nusxalandi'
              : (locale.startsWith('ru')
                  ? '✓ Сводка достижений скопирована'
                  : '✓ Accolades summary copied to clipboard'),
        ),
        backgroundColor: AppColors.ink,
        duration: const Duration(seconds: 3),
      ),
    );

    if (onShare != null) {
      onShare!();
    }
  }

  @override
  Widget build(BuildContext context) {
    final engine = CuratorAccoladesEngine();
    final title = engine.formatMasteryTitle(accolades.masteryTier, locale: locale);
    final score = engine.calculateAccoladesScore(accolades);
    final nextRequirement = engine.getNextTierRequirement(accolades, locale: locale);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderSubtle, width: 1.5),
        boxShadow: const [AppColors.shadowCard],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header: Crown badge & Mastery Title
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          accolades.masteryTier.badgeIcon,
                          style: const TextStyle(fontSize: 18),
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            title,
                            key: const Key('mastery_title_text'),
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: AppColors.ink,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Accolades Honor: $score pts',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.ink3,
                      ),
                    ),
                  ],
                ),
              ),
              // Crowns pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.butterSubtle,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.butter, width: 1.5),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('👑', style: TextStyle(fontSize: 15)),
                    const SizedBox(width: 4),
                    Text(
                      '${accolades.crownsCount}',
                      key: const Key('crown_count_text'),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),
          const Divider(height: 1, color: AppColors.borderHairline),
          const SizedBox(height: 14),

          // Trophies Showcase Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                locale.startsWith('uz')
                    ? 'Mavsumiy Kuboklar'
                    : (locale.startsWith('ru') ? 'Сезонные Трофеи' : 'Seasonal Trophies'),
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink2,
                  letterSpacing: 0.3,
                ),
              ),
              Text(
                '${accolades.trophies.length}',
                key: const Key('trophies_count_text'),
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          if (accolades.trophies.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 14),
              decoration: BoxDecoration(
                color: AppColors.paper2,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.borderSubtle),
              ),
              child: Center(
                child: Text(
                  locale.startsWith('uz')
                      ? 'Hozircha mavsumiy kuboklar yo\'q. Oylik kvestga qo\'shiling!'
                      : (locale.startsWith('ru')
                          ? 'Пока нет сезонных трофеев. Присоединяйтесь к месячному квесту!'
                          : 'No seasonal trophies yet. Join the monthly city quest!'),
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.ink3,
                  ),
                ),
              ),
            )
          else
            SizedBox(
              height: 102,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: accolades.trophies.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (ctx, index) {
                  final trophy = accolades.trophies[index];
                  final isGold = trophy.tier == CuratorTrophyTier.gold;
                  final isSilver = trophy.tier == CuratorTrophyTier.silver;
                  final borderColor = isGold
                      ? AppColors.butter
                      : (isSilver ? const Color(0xFFC0C0C0) : const Color(0xFFCD7F32));

                  return GestureDetector(
                    key: Key('trophy_card_${trophy.id}'),
                    onTap: () => _showTrophyDetails(context, trophy),
                    child: Container(
                      width: 104,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.paper,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: borderColor, width: 1.5),
                        boxShadow: const [AppColors.shadowCard],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            trophy.tier.emoji,
                            style: const TextStyle(fontSize: 24),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            trophy.seasonTitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.ink,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            trophy.seasonId,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: AppColors.ink3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

          // District Laurels Section if available
          if (accolades.laurels.isNotEmpty) ...[
            const SizedBox(height: 14),
            Text(
              locale.startsWith('uz')
                  ? 'Tuman Shon-Sharaflari'
                  : (locale.startsWith('ru') ? 'Лавры Районов' : 'District Laurels'),
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.ink2,
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: accolades.laurels.map((laurel) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.paper2,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.borderSubtle),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(laurel.laurel.badgeIcon, style: const TextStyle(fontSize: 13)),
                      const SizedBox(width: 4),
                      Text(
                        '${laurel.district} #${laurel.rank}',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.ink,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],

          const SizedBox(height: 14),
          // Next rank hint
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.paper2,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(Icons.stars_rounded, size: 16, color: AppColors.orange),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    nextRequirement,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.ink2,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),
          // Share Accolades Button
          OutlinedButton.icon(
            key: const Key('share_accolades_button'),
            onPressed: () => _copyAccoladesShare(context),
            icon: const Icon(Icons.share_outlined, size: 16, color: AppColors.ink),
            label: Text(
              locale.startsWith('uz')
                  ? 'Yutuqlarni Ulashish'
                  : (locale.startsWith('ru') ? 'Поделиться Достижениями' : 'Share Accolades'),
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
              ),
            ),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 11),
              side: const BorderSide(color: AppColors.ink, width: 1.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
