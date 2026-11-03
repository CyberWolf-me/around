import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/curated_walk_waypoint_engine.dart';
import '../../../data/services/haptic_service.dart';

/// Vertical progression stepper for a curated walk route across Tashkent.
class CuratedWalkTrailWidget extends StatelessWidget {
  final RouteProgressSummary summary;
  final String locale;
  final void Function(RouteWaypoint waypoint)? onWaypointTap;

  const CuratedWalkTrailWidget({
    super.key,
    required this.summary,
    this.locale = 'en',
    this.onWaypointTap,
  });

  @override
  Widget build(BuildContext context) {
    final engine = CuratedWalkWaypointEngine();
    final progressTitle = engine.formatProgressTitle(summary, locale: locale);

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
          // Header: Route title & District pill
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      summary.routeName,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${summary.district} • $progressTitle',
                      key: const Key('progress_title_text'),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.ink3,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: summary.isCompleted
                      ? AppColors.butterSubtle
                      : AppColors.orangeSubtle,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: summary.isCompleted
                        ? AppColors.butter
                        : AppColors.orange,
                    width: 1.2,
                  ),
                ),
                child: Text(
                  '+${summary.totalXpEarned} XP',
                  key: const Key('total_xp_badge_text'),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    color: summary.isCompleted
                        ? AppColors.ink
                        : AppColors.orange,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: summary.completionPercentage.clamp(0.0, 1.0),
              minHeight: 8,
              backgroundColor: AppColors.paper2,
              valueColor: AlwaysStoppedAnimation<Color>(
                summary.isCompleted ? AppColors.mint : AppColors.orange,
              ),
            ),
          ),

          const SizedBox(height: 18),

          // Waypoints Stepper
          Column(
            children: List.generate(summary.waypointsWithStatus.length, (index) {
              final item = summary.waypointsWithStatus[index];
              final isLast = index == summary.waypointsWithStatus.length - 1;
              final isNextTarget =
                  summary.nextTargetWaypoint?.id == item.waypoint.id;

              return _buildStepperItem(
                context: context,
                item: item,
                isLast: isLast,
                isNextTarget: isNextTarget,
              );
            }),
          ),

          // Completion bonus celebration callout
          if (summary.isCompleted) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.mintSubtle,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.mint, width: 1.2),
              ),
              child: Row(
                children: [
                  const Text('🏆', style: TextStyle(fontSize: 18)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      locale.startsWith('uz')
                          ? 'Tabriklaymiz! Marshrut to\'liq bajarildi (+${summary.completionBonusXp} bonus XP)'
                          : (locale.startsWith('ru')
                              ? 'Поздравляем! Маршрут завершен (+${summary.completionBonusXp} бонусных XP)'
                              : 'Route Completed! +${summary.completionBonusXp} Bonus XP Awarded'),
                      key: const Key('completion_callout_text'),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStepperItem({
    required BuildContext context,
    required WaypointWithStatus item,
    required bool isLast,
    required bool isNextTarget,
  }) {
    Color iconColor;
    IconData iconData;

    if (item.isVisited) {
      iconColor = AppColors.mint;
      iconData = Icons.check_circle_rounded;
    } else if (isNextTarget) {
      iconColor = AppColors.orange;
      iconData = Icons.radio_button_checked_rounded;
    } else {
      iconColor = AppColors.inkLight;
      iconData = Icons.circle_outlined;
    }

    return GestureDetector(
      key: Key('waypoint_item_${item.waypoint.id}'),
      behavior: HitTestBehavior.opaque,
      onTap: () {
        HapticService.selection();
        if (onWaypointTap != null) {
          onWaypointTap!(item.waypoint);
        }
      },
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left: Stepper line and node
            Column(
              children: [
                Icon(iconData, size: 20, color: iconColor),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      color: item.isVisited
                          ? AppColors.mint
                          : AppColors.borderHairline,
                    ),
                  ),
              ],
            ),

            const SizedBox(width: 12),

            // Right: Waypoint details
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.waypoint.placeName,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: item.isVisited
                                  ? AppColors.ink
                                  : (isNextTarget
                                      ? AppColors.orange
                                      : AppColors.ink2),
                            ),
                          ),
                        ),
                        Text(
                          '+${item.waypoint.xpAwarded} XP',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.ink3,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${item.waypoint.category} • ${item.waypoint.hint}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: AppColors.ink3,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
