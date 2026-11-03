import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/season_ceremony_engine.dart';
import '../../../data/services/haptic_service.dart';

/// Interactive Season Wrap-up & Crown Ceremony Dialog (`P30-02`).
/// Displays end-of-season placement, district championship crowns,
/// celebration statistics, and triggers celebratory haptics.
class SeasonCeremonyDialog extends StatelessWidget {
  final SeasonWrapupReport report;
  final String languageCode;
  final VoidCallback? onClaimCelebration;
  final VoidCallback? onDismiss;

  const SeasonCeremonyDialog({
    super.key,
    required this.report,
    this.languageCode = 'en',
    this.onClaimCelebration,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final lang = languageCode.toLowerCase();
    final headline = SeasonCeremonyEngine.getLocalizedCelebrationHeadline(report, lang);
    final laurelName = SeasonCeremonyEngine.getLocalizedLaurelName(report.laurelTier, lang);

    String seasonWrapupLabel;
    String placesLabel;
    String districtLabel;
    String claimBtnLabel;

    switch (lang) {
      case 'uz':
        seasonWrapupLabel = 'MAVSUM YAKUNI';
        placesLabel = 'Kashf etilgan joylar';
        districtLabel = 'Asosiy tuman';
        claimBtnLabel = 'Mukofotni Qabul Qilish (+${report.bonusXpAwarded} XP)';
        break;
      case 'ru':
        seasonWrapupLabel = 'ИТОГИ СЕЗОНА';
        placesLabel = 'Посещено мест';
        districtLabel = 'Основной район';
        claimBtnLabel = 'Забрать Награду (+${report.bonusXpAwarded} XP)';
        break;
      case 'en':
      default:
        seasonWrapupLabel = 'SEASON WRAP-UP';
        placesLabel = 'Places Visited';
        districtLabel = 'Top District';
        claimBtnLabel = 'Claim Reward (+${report.bonusXpAwarded} XP)';
        break;
    }

    return Dialog(
      key: const Key('season_ceremony_dialog'),
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.cardSurface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: report.isChampion ? AppColors.butter : AppColors.borderSubtle,
            width: report.isChampion ? 2.0 : 1.2,
          ),
          boxShadow: const [AppColors.shadowCard],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Crown / Laurel Hero Icon
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: report.isChampion ? AppColors.butterSubtle : AppColors.orangeSubtle,
                shape: BoxShape.circle,
                border: Border.all(
                  color: report.isChampion ? AppColors.butter : AppColors.orange,
                  width: 2.0,
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                report.laurelTier.badgeIcon,
                style: const TextStyle(fontSize: 32),
              ),
            ),
            const SizedBox(height: 14),

            // Season Tag
            Text(
              '$seasonWrapupLabel · ${report.seasonId}',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: AppColors.orange,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 6),

            // Celebration Headline
            Text(
              headline,
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 12),

            // Laurel Badge Pill
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: report.isChampion ? AppColors.butterSubtle : AppColors.paper2,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: report.isChampion ? AppColors.butter : AppColors.borderSubtle,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(report.laurelTier.badgeIcon, style: const TextStyle(fontSize: 14)),
                  const SizedBox(width: 6),
                  Text(
                    laurelName,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: AppColors.ink,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Metrics Summary Grid
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surfaceWarm,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.borderSubtle),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildMetricCell(
                    value: '${report.totalSeasonXp} XP',
                    label: 'Seasonal XP',
                  ),
                  Container(width: 1, height: 32, color: AppColors.paper3),
                  _buildMetricCell(
                    value: '${report.totalPlacesVisited}',
                    label: placesLabel,
                  ),
                  Container(width: 1, height: 32, color: AppColors.paper3),
                  _buildMetricCell(
                    value: '${report.topDistrict} (#${report.districtRank})',
                    label: districtLabel,
                  ),
                ],
              ),
            ),

            if (report.crownsAwarded > 0) ...[
              const SizedBox(height: 14),
              Container(
                key: const Key('crown_awarded_banner'),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.butterSubtle,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.butter),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('👑', style: TextStyle(fontSize: 16)),
                    const SizedBox(width: 8),
                    Text(
                      lang == 'uz'
                        ? '+1 Shahar Toji berildi!'
                        : (lang == 'ru' ? '+1 Городская Корона вручена!' : '+1 City Crown Awarded!'),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 20),

            // Action Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                key: const Key('claim_ceremony_btn'),
                onPressed: () {
                  HapticService.success();
                  onClaimCelebration?.call();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.orange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  claimBtnLabel,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCell({required String value, required String label}) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: AppColors.ink,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 10,
            color: AppColors.ink3,
          ),
        ),
      ],
    );
  }
}
