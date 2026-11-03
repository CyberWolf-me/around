import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/tasting_flight_engine.dart';
import '../../../data/services/haptic_service.dart';

/// Card widget showcasing an artisan tasting flight, cupping scores, and flavor note stepper.
class TastingFlightCardWidget extends StatelessWidget {
  final TastingFlight flight;
  final Map<String, TastingLog> userLogs;
  final String locale;
  final ValueChanged<TastingStop>? onStopTap;
  final ValueChanged<TastingStop>? onLogCuppingTap;
  final VoidCallback? onCertificateOrShare;

  const TastingFlightCardWidget({
    super.key,
    required this.flight,
    this.userLogs = const {},
    this.locale = 'en',
    this.onStopTap,
    this.onLogCuppingTap,
    this.onCertificateOrShare,
  });

  Color _parseAccentColor(String hex) {
    try {
      final clean = hex.replaceAll('#', '');
      return Color(int.parse('FF$clean', radix: 16));
    } catch (_) {
      return AppColors.cobalt;
    }
  }

  @override
  Widget build(BuildContext context) {
    final engine = TastingFlightEngine();
    final progress = engine.calculateProgress(flight, userLogs);
    final accentColor = _parseAccentColor(flight.accentColorHex);
    final isCompleted = progress.isCompleted;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isCompleted ? accentColor.withValues(alpha: 0.6) : AppColors.borderSubtle,
          width: isCompleted ? 2.0 : 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: isCompleted
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
          // Header: Category Icon, Title, and Completion Status
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: accentColor.withValues(alpha: 0.15),
                  border: Border.all(color: accentColor, width: 2),
                ),
                child: Icon(
                  flight.category.toLowerCase() == 'tea'
                      ? Icons.emoji_food_beverage_rounded
                      : Icons.local_cafe_rounded,
                  color: accentColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      flight.title,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      flight.curatorTitle,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
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
                  color: isCompleted
                      ? accentColor.withValues(alpha: 0.15)
                      : AppColors.surfaceWarm,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isCompleted ? accentColor : AppColors.borderSubtle,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isCompleted ? Icons.verified_rounded : Icons.star_rounded,
                      size: 14,
                      color: isCompleted ? accentColor : AppColors.butter,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isCompleted
                          ? '+${flight.xpReward} XP'
                          : progress.averageCuppingScore > 0
                              ? '${progress.averageCuppingScore} / 10'
                              : '${(progress.completionPercentage * 100).toInt()}%',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: isCompleted ? accentColor : AppColors.ink2,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Progress Bar
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
            engine.formatFlightProgressLabel(progress, flight.requiredStopsCount, locale),
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: isCompleted ? accentColor : AppColors.ink3,
            ),
          ),

          const SizedBox(height: 14),

          // Stop Stepper List
          ...flight.stops.map((stop) {
            final log = userLogs[stop.id] ?? userLogs[stop.placeId];
            final isLogged = log != null;

            return InkWell(
              onTap: () {
                HapticService.selection();
                onStopTap?.call(stop);
              },
              borderRadius: BorderRadius.circular(10),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 2),
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isLogged
                            ? accentColor.withValues(alpha: 0.2)
                            : AppColors.surfaceWarm,
                        border: Border.all(
                          color: isLogged ? accentColor : AppColors.borderSubtle,
                          width: 1.5,
                        ),
                      ),
                      child: Icon(
                        isLogged ? Icons.check_rounded : Icons.radio_button_unchecked,
                        size: 13,
                        color: isLogged ? accentColor : AppColors.ink3,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            stop.itemTitle,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: isLogged ? FontWeight.w600 : FontWeight.w500,
                              color: isLogged ? AppColors.ink : AppColors.ink2,
                            ),
                          ),
                          Text(
                            '${stop.venueName} • ${stop.district}',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              color: AppColors.ink3,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Wrap(
                            spacing: 4,
                            runSpacing: 4,
                            children: stop.flavorNotes.map((note) {
                              final isSelected = log?.selectedFlavorNotes.contains(note) ?? false;
                              return Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? accentColor.withValues(alpha: 0.15)
                                      : AppColors.surfaceWarm,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: isSelected ? accentColor : AppColors.borderHairline,
                                  ),
                                ),
                                child: Text(
                                  note,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 10,
                                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                                    color: isSelected ? accentColor : AppColors.ink2,
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                    if (isLogged)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceWarm,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${log.rating}★',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.ink,
                          ),
                        ),
                      )
                    else
                      IconButton(
                        icon: const Icon(Icons.rate_review_outlined, size: 18),
                        color: accentColor,
                        tooltip: 'Log cupping score',
                        onPressed: () {
                          HapticService.light();
                          onLogCuppingTap?.call(stop);
                        },
                      ),
                  ],
                ),
              ),
            );
          }),

          const SizedBox(height: 10),

          // Action Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                HapticService.light();
                onCertificateOrShare?.call();
              },
              icon: Icon(
                isCompleted ? Icons.workspace_premium_rounded : Icons.explore_rounded,
                size: 16,
              ),
              label: Text(
                isCompleted
                    ? _getCertificateLabel(locale)
                    : _getExploreLabel(locale),
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: isCompleted ? accentColor : AppColors.orange,
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

  String _getCertificateLabel(String lang) {
    switch (lang) {
      case 'uz':
        return 'Sertifikatni ko‘rish';
      case 'ru':
        return 'Посмотреть сертификат';
      case 'en':
      default:
        return 'View Cupping Certificate';
    }
  }

  String _getExploreLabel(String lang) {
    switch (lang) {
      case 'uz':
        return 'Keyingi ta\'mni tatib ko‘rish';
      case 'ru':
        return 'Исследовать следующий вкус';
      case 'en':
      default:
        return 'Explore Next Tasting';
    }
  }
}
