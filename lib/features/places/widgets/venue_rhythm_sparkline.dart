import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/place_model.dart';
import '../../../data/models/post_model.dart';
import '../../../data/services/haptic_service.dart';

class VenueRhythmSparkline extends StatefulWidget {
  final PlaceModel place;
  final List<PostModel> drops;
  final DateTime? now;

  const VenueRhythmSparkline({
    super.key,
    required this.place,
    required this.drops,
    this.now,
  });

  @override
  State<VenueRhythmSparkline> createState() => _VenueRhythmSparklineState();
}

class _VenueRhythmSparklineState extends State<VenueRhythmSparkline> {
  int? _selectedHour;

  DateTime get _currentDateTime => widget.now ?? DateTime.now();

  /// Computes 24-hour activity distribution combining actual drops and atmosphere priors.
  List<double> get _hourlyDistribution {
    final distribution = List<double>.filled(24, 0.0);

    // 1. Atmosphere base priors based on tags and venue category
    final lowerTags = widget.place.tags.map((t) => t.toLowerCase()).toSet();
    final isCoffee = widget.place.category.toLowerCase().contains('coffee') ||
        lowerTags.contains('coffee') ||
        lowerTags.contains('breakfast');
    final isNight = widget.place.category.toLowerCase().contains('night') ||
        widget.place.category.toLowerCase().contains('bar') ||
        lowerTags.contains('cocktails') ||
        lowerTags.contains('sunset');
    final isCulture = lowerTags.contains('culture') || lowerTags.contains('heritage');

    for (int h = 0; h < 24; h++) {
      if (h < 7) {
        distribution[h] = 0.05;
      } else if (h >= 8 && h <= 11) {
        distribution[h] = isCoffee ? 0.85 : 0.35;
      } else if (h >= 12 && h <= 15) {
        distribution[h] = isCulture ? 0.75 : 0.55;
      } else if (h >= 16 && h <= 18) {
        distribution[h] = 0.60;
      } else if (h >= 19 && h <= 22) {
        distribution[h] = isNight ? 0.95 : 0.70;
      } else {
        distribution[h] = isNight ? 0.40 : 0.15;
      }
    }

    // 2. Weight in real drop timestamps
    if (widget.drops.isNotEmpty) {
      for (final drop in widget.drops) {
        final dropHour = drop.createdAt.hour;
        distribution[dropHour] = (distribution[dropHour] + 0.6).clamp(0.0, 2.0);
      }
    }

    // Normalize to 0.0 - 1.0 range
    final maxVal = distribution.reduce((a, b) => a > b ? a : b);
    if (maxVal > 0) {
      for (int i = 0; i < 24; i++) {
        distribution[i] = (distribution[i] / maxVal).clamp(0.08, 1.0);
      }
    }

    return distribution;
  }

  /// Finds the 3-hour window with peak activity.
  String get _peakWindowLabel {
    final distribution = _hourlyDistribution;
    int bestStart = 8;
    double maxWindowSum = 0;

    for (int h = 7; h <= 21; h++) {
      final windowSum = distribution[h] + distribution[(h + 1) % 24] + distribution[(h + 2) % 24];
      if (windowSum > maxWindowSum) {
        maxWindowSum = windowSum;
        bestStart = h;
      }
    }

    final endHour = (bestStart + 3) % 24;
    final startStr = '${bestStart.toString().padLeft(2, '0')}:00';
    final endStr = '${endHour.toString().padLeft(2, '0')}:00';
    return '$startStr – $endStr';
  }

  @override
  Widget build(BuildContext context) {
    final distribution = _hourlyDistribution;
    final currentHour = _currentDateTime.hour;
    final activeHour = _selectedHour ?? currentHour;
    final activeDensity = (distribution[activeHour] * 100).round();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.borderSubtle, width: 1.0),
        boxShadow: const [AppColors.shadowCard],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    const Icon(Icons.waves_rounded, size: 16, color: AppColors.orange),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        'VENUE RHYTHM',
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
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.orangeSubtle,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Peak: $_peakWindowLabel',
                  style: GoogleFonts.spaceMono(
                    fontSize: 9.5,
                    fontWeight: FontWeight.bold,
                    color: AppColors.orange,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Expanded(
                child: Text(
                  '24-Hour Atmosphere Rhythm',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.bricolageGrotesque(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${activeHour.toString().padLeft(2, '0')}:00 · $activeDensity% vibe',
                style: GoogleFonts.spaceMono(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.ink2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // 24-hour vertical sparkline bars
          SizedBox(
            height: 48,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(24, (h) {
                final heightFraction = distribution[h];
                final isCurrent = h == currentHour;
                final isSelected = h == activeHour;

                Color barColor;
                if (isSelected) {
                  barColor = AppColors.orange;
                } else if (isCurrent) {
                  barColor = AppColors.butter;
                } else if (heightFraction > 0.7) {
                  barColor = AppColors.ink2;
                } else {
                  barColor = AppColors.paper3;
                }

                return Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      HapticService.selection();
                      setState(() {
                        _selectedHour = h;
                      });
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 1.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            height: (heightFraction * 44).clamp(6.0, 44.0),
                            decoration: BoxDecoration(
                              color: barColor,
                              borderRadius: BorderRadius.circular(2.5),
                              border: isCurrent
                                  ? Border.all(color: AppColors.ink, width: 1.0)
                                  : null,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 6),
          // Hour markers
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('00:00', style: GoogleFonts.spaceMono(fontSize: 9, color: AppColors.ink3)),
              Text('06:00', style: GoogleFonts.spaceMono(fontSize: 9, color: AppColors.ink3)),
              Text('12:00', style: GoogleFonts.spaceMono(fontSize: 9, color: AppColors.ink3)),
              Text('18:00', style: GoogleFonts.spaceMono(fontSize: 9, color: AppColors.ink3)),
              Text('23:00', style: GoogleFonts.spaceMono(fontSize: 9, color: AppColors.ink3)),
            ],
          ),
        ],
      ),
    );
  }
}
