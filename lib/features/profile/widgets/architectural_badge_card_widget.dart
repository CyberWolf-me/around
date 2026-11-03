import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/architectural_badge_engine.dart';
import '../../../data/services/haptic_service.dart';

/// Card widget showcasing an architectural quest, its unlockable badge, and landmark stops.
class ArchitecturalBadgeCardWidget extends StatelessWidget {
  final ArchitecturalQuest quest;
  final Set<String> visitedPlaceOrStopIds;
  final String locale;
  final ValueChanged<QuestStop>? onStopTap;
  final VoidCallback? onClaimOrShare;
  final ValueChanged<QuestStop>? onViewFactTap;

  const ArchitecturalBadgeCardWidget({
    super.key,
    required this.quest,
    this.visitedPlaceOrStopIds = const {},
    this.locale = 'en',
    this.onStopTap,
    this.onClaimOrShare,
    this.onViewFactTap,
  });

  Color _parseAccentColor(String hex) {
    try {
      final clean = hex.replaceAll('#', '');
      return Color(int.parse('FF$clean', radix: 16));
    } catch (_) {
      return AppColors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    final engine = ArchitecturalBadgeEngine();
    final progress = engine.calculateProgress(quest, visitedPlaceOrStopIds);
    final accentColor = _parseAccentColor(quest.badgeAccentColorHex);
    final isUnlocked = progress.isCompleted;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isUnlocked ? accentColor.withValues(alpha: 0.6) : AppColors.borderSubtle,
          width: isUnlocked ? 2.0 : 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: isUnlocked
                ? accentColor.withValues(alpha: 0.12)
                : Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header Row: Badge Icon, Title, and Unlock Status Chip
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: accentColor.withValues(alpha: 0.15),
                  border: Border.all(color: accentColor, width: 2),
                ),
                child: Icon(
                  isUnlocked ? Icons.verified_rounded : Icons.account_balance_rounded,
                  color: accentColor,
                  size: 26,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      quest.badgeName,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      quest.title,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppColors.ink3,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isUnlocked
                      ? accentColor.withValues(alpha: 0.15)
                      : AppColors.surfaceWarm,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isUnlocked ? accentColor : AppColors.borderSubtle,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isUnlocked ? Icons.check_circle_rounded : Icons.lock_outline_rounded,
                      size: 14,
                      color: isUnlocked ? accentColor : AppColors.ink3,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isUnlocked
                          ? '+${quest.xpReward} XP'
                          : '${(progress.completionPercentage * 100).toInt()}%',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: isUnlocked ? accentColor : AppColors.ink2,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Progress Bar and localized counter
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress.completionPercentage,
              minHeight: 6,
              backgroundColor: AppColors.surfaceWarm,
              valueColor: AlwaysStoppedAnimation<Color>(accentColor),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            engine.formatProgressLabel(progress, quest.requiredStopsCount, locale),
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: isUnlocked ? accentColor : AppColors.ink3,
            ),
          ),

          const SizedBox(height: 14),

          // Landmark Stop Stepper Checklist
          ...quest.stops.map((stop) {
            final isVisited = progress.visitedStopIds.contains(stop.id);

            return InkWell(
              onTap: () {
                HapticService.selection();
                onStopTap?.call(stop);
              },
              borderRadius: BorderRadius.circular(10),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                child: Row(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isVisited
                            ? accentColor.withValues(alpha: 0.2)
                            : AppColors.surfaceWarm,
                        border: Border.all(
                          color: isVisited ? accentColor : AppColors.borderSubtle,
                          width: 1.5,
                        ),
                      ),
                      child: Icon(
                        isVisited ? Icons.check_rounded : Icons.circle_outlined,
                        size: 14,
                        color: isVisited ? accentColor : AppColors.ink3,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            stop.name,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: isVisited ? FontWeight.w600 : FontWeight.w500,
                              color: isVisited ? AppColors.ink : AppColors.ink2,
                            ),
                          ),
                          Text(
                            '${stop.district} • ${stop.architecturalStyle}${stop.yearBuilt != null ? ' (${stop.yearBuilt})' : ''}',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              color: AppColors.ink3,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.info_outline_rounded, size: 18),
                      color: AppColors.ink3,
                      tooltip: 'Architectural fact',
                      onPressed: () {
                        HapticService.light();
                        onViewFactTap?.call(stop);
                      },
                    ),
                  ],
                ),
              ),
            );
          }),

          const SizedBox(height: 10),

          // Action Button: Share Badge (if unlocked) or View Details
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                HapticService.light();
                onClaimOrShare?.call();
              },
              icon: Icon(
                isUnlocked ? Icons.share_rounded : Icons.explore_rounded,
                size: 16,
              ),
              label: Text(
                isUnlocked
                    ? _getShareButtonLabel(locale)
                    : _getExploreButtonLabel(locale),
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: isUnlocked ? accentColor : AppColors.orange,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getShareButtonLabel(String lang) {
    switch (lang) {
      case 'uz':
        return 'Nishonni ulashish';
      case 'ru':
        return 'Поделиться бейджем';
      case 'en':
      default:
        return 'Share Badge';
    }
  }

  String _getExploreButtonLabel(String lang) {
    switch (lang) {
      case 'uz':
        return 'Keyingi lokatsiyani kashf qilish';
      case 'ru':
        return 'Исследовать следующую локацию';
      case 'en':
      default:
        return 'Explore Next Landmark';
    }
  }
}
