import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/season_trophy_engine.dart';
import '../../../data/services/haptic_service.dart';

/// Interactive Season Trophy Wall Widget (`P28-02`).
/// Displays current monthly challenges, individual progress rings,
/// earned seasonal trophy tier (Bronze, Silver, Gold), and countdown to season close.
class SeasonTrophyCard extends StatelessWidget {
  final CuratorSeason? customSeason;
  final int districtCount;
  final int metroCount;
  final int weekendCount;
  final String languageCode;
  final VoidCallback? onClaimTrophy;

  const SeasonTrophyCard({
    super.key,
    this.customSeason,
    this.districtCount = 0,
    this.metroCount = 0,
    this.weekendCount = 0,
    this.languageCode = 'en',
    this.onClaimTrophy,
  });

  @override
  Widget build(BuildContext context) {
    final season = customSeason ??
        SeasonTrophyEngine.getCurrentSeason(
          districtCount: districtCount,
          metroCount: metroCount,
          weekendCount: weekendCount,
        );

    final lang = languageCode.toLowerCase();
    final daysRemaining = season.daysRemaining;

    String daysLabel;
    switch (lang) {
      case 'uz':
        daysLabel = '$daysRemaining kun qoldi';
        break;
      case 'ru':
        daysLabel = 'Осталось $daysRemaining дн.';
        break;
      case 'en':
      default:
        daysLabel = '$daysRemaining days left';
        break;
    }

    String seasonBadge;
    switch (lang) {
      case 'uz':
        seasonBadge = 'OYLIK MAVSUM';
        break;
      case 'ru':
        seasonBadge = 'СЕЗОН МЕСЯЦА';
        break;
      case 'en':
      default:
        seasonBadge = 'MONTHLY SEASON';
        break;
    }

    return Container(
      key: const Key('season_trophy_card'),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderSubtle),
        boxShadow: const [AppColors.shadowCard],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.orangeSubtle,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text('🏆', style: TextStyle(fontSize: 20)),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        seasonBadge,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: AppColors.orange,
                          letterSpacing: 1.0,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        season.getLocalizedTitle(lang),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppColors.ink,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              // Days remaining pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.paper2,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.borderSubtle),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('⏳', style: TextStyle(fontSize: 11)),
                    const SizedBox(width: 4),
                    Text(
                      daysLabel,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink2,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Challenge Progression Items
          ...season.challenges.map((challenge) {
            return _buildChallengeItem(challenge, lang);
          }),

          const SizedBox(height: 14),

          // Overall Trophy Tier Banner
          _buildTrophyStatusBanner(context, season, lang),
        ],
      ),
    );
  }

  Widget _buildChallengeItem(SeasonalChallenge challenge, String lang) {
    final isDone = challenge.isCompleted;

    return Container(
      key: Key('challenge_item_${challenge.id}'),
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDone ? AppColors.mintSubtle : AppColors.surfaceWarm,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDone ? AppColors.mint : AppColors.borderSubtle,
          width: isDone ? 1.5 : 1.0,
        ),
      ),
      child: Row(
        children: [
          // Emoji Icon
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.cardSurface,
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: Text(challenge.icon, style: const TextStyle(fontSize: 18)),
          ),
          const SizedBox(width: 12),
          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      challenge.getLocalizedTitle(lang),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink,
                      ),
                    ),
                    Text(
                      '${challenge.currentCount}/${challenge.targetCount}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: isDone ? AppColors.mint : AppColors.ink2,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  challenge.getLocalizedDescription(lang),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    color: AppColors.ink3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                // Progress Bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: challenge.progressPercentage,
                    backgroundColor: AppColors.paper3,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isDone ? AppColors.mint : AppColors.orange,
                    ),
                    minHeight: 4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          // Reward Pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.orangeSubtle,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              '+${challenge.xpReward} XP',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: AppColors.orange,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrophyStatusBanner(BuildContext context, CuratorSeason season, String lang) {
    final tier = season.earnedTrophyTier;
    final hasTier = tier != null;

    String bannerTitle;
    if (hasTier) {
      final tierName = SeasonTrophyEngine.getLocalizedTierName(tier, lang);
      switch (lang) {
        case 'uz':
          bannerTitle = '$tierName Qulfdan Chiqdi!';
          break;
        case 'ru':
          bannerTitle = '$tierName Разблокирован!';
          break;
        case 'en':
        default:
          bannerTitle = '$tierName Unlocked!';
          break;
      }
    } else {
      switch (lang) {
        case 'uz':
          bannerTitle = 'Birinchi Kubok Sari Harakat Qiling';
          break;
        case 'ru':
          bannerTitle = 'Завершите вызовы для трофея';
          break;
        case 'en':
        default:
          bannerTitle = 'Complete challenges to earn trophies';
          break;
      }
    }

    return Container(
      key: const Key('trophy_status_banner'),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: hasTier ? AppColors.butterSubtle : AppColors.paper2,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: hasTier ? AppColors.butter : AppColors.borderSubtle,
          width: 1.2,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Text(
                hasTier ? tier.emoji : '🎯',
                style: const TextStyle(fontSize: 22),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    bannerTitle,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${season.totalXpEarned} / ${season.totalXpAvailable} XP',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink2,
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (hasTier)
            ElevatedButton(
              key: const Key('claim_trophy_button'),
              onPressed: () {
                HapticService.success();
                onClaimTrophy?.call();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.orange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 0,
              ),
              child: Text(
                lang == 'uz' ? 'Qabul Qilish' : (lang == 'ru' ? 'Получить' : 'Claim'),
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
