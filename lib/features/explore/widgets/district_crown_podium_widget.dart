import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/district_crown_leaderboard_engine.dart';
import '../../../data/services/haptic_service.dart';

class DistrictCrownPodiumWidget extends StatelessWidget {
  final DistrictCrownPodium podium;
  final String locale;
  final void Function(DistrictCuratorStanding curator)? onCuratorTap;

  const DistrictCrownPodiumWidget({
    super.key,
    required this.podium,
    this.locale = 'en',
    this.onCuratorTap,
  });

  Widget _buildPodiumPillar({
    required BuildContext context,
    required DistrictCuratorStanding? curator,
    required int rank,
    required double pillarHeight,
    required Color accentColor,
    required String medalIcon,
  }) {
    final isFirst = rank == 1;

    return Expanded(
      child: GestureDetector(
        key: Key('podium_pillar_rank_$rank'),
        behavior: HitTestBehavior.opaque,
        onTap: () {
          if (curator != null) {
            HapticService.selection();
            if (onCuratorTap != null) onCuratorTap!(curator);
          }
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Avatar & Medal
            Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                Container(
                  width: isFirst ? 56 : 46,
                  height: isFirst ? 56 : 46,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.paper,
                    border: Border.all(color: accentColor, width: isFirst ? 2.5 : 1.8),
                    boxShadow: const [AppColors.shadowCard],
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    curator?.initials ?? '?',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: isFirst ? 16 : 13,
                      fontWeight: FontWeight.w800,
                      color: AppColors.ink,
                    ),
                  ),
                ),
                Positioned(
                  top: -10,
                  child: Text(medalIcon, style: TextStyle(fontSize: isFirst ? 18 : 14)),
                ),
              ],
            ),
            const SizedBox(height: 6),

            // Username
            Text(
              curator?.username ?? (locale.startsWith('uz') ? 'Bo\'sh' : (locale.startsWith('ru') ? 'Свободно' : 'Open')),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
              ),
            ),

            // XP Badge
            if (curator != null)
              Text(
                '${curator.seasonXp} XP',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: isFirst ? AppColors.orange : AppColors.ink3,
                ),
              ),

            const SizedBox(height: 8),

            // Podium Block
            Container(
              height: pillarHeight,
              width: double.infinity,
              decoration: BoxDecoration(
                color: isFirst ? AppColors.butterSubtle : AppColors.paper2,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                border: Border.all(color: accentColor.withValues(alpha: 0.4), width: 1.5),
              ),
              alignment: Alignment.center,
              child: Text(
                '#$rank',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: isFirst ? 20 : 16,
                  fontWeight: FontWeight.w900,
                  color: accentColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final engine = DistrictCrownLeaderboardEngine();
    final districtTitle = engine.formatDistrictTitle(podium.district, locale: locale);

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
          // Header: District & Season info
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text('👑', style: TextStyle(fontSize: 18)),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            districtTitle,
                            key: const Key('district_title_text'),
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
                      '${podium.seasonId} Season • ${podium.totalCuratorsCount} Curators',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
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
                  color: AppColors.paper2,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.borderSubtle),
                ),
                child: Text(
                  locale.startsWith('uz')
                      ? 'Tuman Toji'
                      : (locale.startsWith('ru') ? 'Корона' : 'Crown Board'),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink2,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          // The Top 3 Podium
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // 2nd Place (Silver)
              _buildPodiumPillar(
                context: context,
                curator: podium.silver,
                rank: 2,
                pillarHeight: 70,
                accentColor: const Color(0xFFC0C0C0),
                medalIcon: '🥈',
              ),
              const SizedBox(width: 8),

              // 1st Place (Gold Champion)
              _buildPodiumPillar(
                context: context,
                curator: podium.champion,
                rank: 1,
                pillarHeight: 96,
                accentColor: AppColors.butter,
                medalIcon: '👑',
              ),
              const SizedBox(width: 8),

              // 3rd Place (Bronze)
              _buildPodiumPillar(
                context: context,
                curator: podium.bronze,
                rank: 3,
                pillarHeight: 52,
                accentColor: const Color(0xFFCD7F32),
                medalIcon: '🥉',
              ),
            ],
          ),

          // Runners-up list if any
          if (podium.runnersUp.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Divider(height: 1, color: AppColors.borderHairline),
            const SizedBox(height: 12),
            Text(
              locale.startsWith('uz')
                  ? 'Keyingi O\'rinlar'
                  : (locale.startsWith('ru') ? 'Претенденты' : 'Contenders & Runners-up'),
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.ink2,
              ),
            ),
            const SizedBox(height: 8),
            Column(
              children: podium.runnersUp.take(3).map((runner) {
                return GestureDetector(
                  key: Key('runner_up_item_${runner.userId}'),
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    HapticService.selection();
                    if (onCuratorTap != null) onCuratorTap!(runner);
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.paper,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.borderSubtle),
                    ),
                    child: Row(
                      children: [
                        Text(
                          '#${runner.rank}',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: AppColors.ink3,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            runner.fullName,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.ink,
                            ),
                          ),
                        ),
                        Text(
                          '${runner.seasonXp} XP',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: AppColors.ink2,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }
}
