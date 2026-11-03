import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/curated_route_engine.dart';
import '../../../core/services/group_crawl_session_engine.dart';

class GroupCrawlRadarHUD extends StatelessWidget {
  final GroupCrawlSession session;
  final List<RouteStop> routeStops;
  final String languageCode;
  final VoidCallback? onTapShare;
  final ValueChanged<String>? onCheckInStop;
  final VoidCallback? onLeaveSession;

  const GroupCrawlRadarHUD({
    super.key,
    required this.session,
    required this.routeStops,
    this.languageCode = 'en',
    this.onTapShare,
    this.onCheckInStop,
    this.onLeaveSession,
  });

  String _t(String key) {
    switch (key) {
      case 'squad_crawl':
        return languageCode == 'uz'
            ? 'GURUH SAYRI'
            : languageCode == 'ru'
                ? 'ГРУППОВОЙ МАРШРУТ'
                : 'SQUAD CRAWL';
      case 'squad_progress':
        return languageCode == 'uz'
            ? 'Guruh Jarayoni'
            : languageCode == 'ru'
                ? 'Прогресс группы'
                : 'Squad Progress';
      case 'check_in':
        return languageCode == 'uz'
            ? 'Belgilanish'
            : languageCode == 'ru'
                ? 'Отметиться'
                : 'Check In';
      case 'at_stop':
        return languageCode == 'uz'
            ? 'Shu yerda'
            : languageCode == 'ru'
                ? 'Здесь'
                : 'Here';
      case 'share_code':
        return languageCode == 'uz'
            ? 'Kodni Ulashish'
            : languageCode == 'ru'
                ? 'Поделиться кодом'
                : 'Share Code';
      case 'squad_complete':
        return languageCode == 'uz'
            ? 'Guruh Barcha Bekatlarni Yakunladi! 🏆'
            : languageCode == 'ru'
                ? 'Группа завершила все остановки! 🏆'
                : 'Squad Completed All Stops! 🏆';
      default:
        return key;
    }
  }

  @override
  Widget build(BuildContext context) {
    final stopIds = routeStops.map((s) => s.placeId).toList();
    final progress = GroupCrawlSessionEngine.calculateProgress(session, stopIds);

    return Container(
      key: const Key('group_crawl_radar_hud'),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: progress.isSquadComplete ? AppColors.mint : AppColors.borderSubtle,
          width: progress.isSquadComplete ? 1.5 : 1.0,
        ),
        boxShadow: const [AppColors.shadowCard],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header: Squad Tag + Session Code + Bonus XP
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.orangeSubtle,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: [
                    const Text('👥 ', style: TextStyle(fontSize: 12)),
                    Text(
                      _t('squad_crawl'),
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: AppColors.orange,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Session Code Pill
              InkWell(
                key: const Key('share_session_code_btn'),
                onTap: onTapShare,
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceWarm,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppColors.borderSubtle),
                  ),
                  child: Row(
                    children: [
                      Text(
                        session.sessionCode,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.ink,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.share, size: 12, color: AppColors.ink3),
                    ],
                  ),
                ),
              ),
              const Spacer(),
              // Squad Bonus XP
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.butterSubtle,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '+${session.squadBonusXp} XP Squad',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.orange,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Route Title & Collective Progress
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  session.routeTitle,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                '${progress.completionPercentage}%',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: progress.isSquadComplete ? AppColors.mint : AppColors.orange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: progress.totalRouteStops > 0
                  ? progress.stopsCoveredByGroup / progress.totalRouteStops
                  : 0.0,
              minHeight: 6,
              backgroundColor: AppColors.borderHairline,
              valueColor: AlwaysStoppedAnimation<Color>(
                progress.isSquadComplete ? AppColors.mint : AppColors.orange,
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Stop Radar List with Participant Avatars
          for (int i = 0; i < routeStops.length; i++) ...[
            _buildStopRadarRow(routeStops[i], i + 1, progress),
            if (i < routeStops.length - 1) const SizedBox(height: 8),
          ],

          const SizedBox(height: 14),

          // Participant Avatars Footer
          Row(
            children: [
              const Text('Squad: ', style: TextStyle(fontSize: 11, color: AppColors.ink3, fontWeight: FontWeight.w600)),
              const SizedBox(width: 4),
              for (final p in session.participants)
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: Tooltip(
                    message: '${p.name} (${p.visitedStopIds.length}/${routeStops.length} visited)',
                    child: CircleAvatar(
                      radius: 12,
                      backgroundColor: p.isHost ? AppColors.orange : AppColors.surfaceWarm,
                      child: Text(
                        p.avatarInitials,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: p.isHost ? Colors.white : AppColors.ink,
                        ),
                      ),
                    ),
                  ),
                ),
              const Spacer(),
              if (onLeaveSession != null)
                TextButton(
                  onPressed: onLeaveSession,
                  child: const Text('Leave', style: TextStyle(fontSize: 11, color: AppColors.ink3)),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStopRadarRow(RouteStop stop, int stepNum, CollectiveProgress progress) {
    final activeParticipants = progress.activeStopParticipants[stop.placeId] ?? [];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceWarm,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: activeParticipants.isNotEmpty ? AppColors.orangeSubtle : AppColors.borderHairline,
        ),
      ),
      child: Row(
        children: [
          // Step Circle
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: activeParticipants.isNotEmpty ? AppColors.orange : AppColors.cardSurface,
              border: Border.all(color: AppColors.borderSubtle),
            ),
            child: Center(
              child: Text(
                '$stepNum',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: activeParticipants.isNotEmpty ? Colors.white : AppColors.ink,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Stop Name & Subway
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  stop.name,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.ink,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '🚇 ${stop.nearestSubway}',
                  style: const TextStyle(fontSize: 10, color: AppColors.ink3),
                ),
              ],
            ),
          ),

          // Active Member Badges
          if (activeParticipants.isNotEmpty)
            Row(
              children: [
                for (final name in activeParticipants)
                  Container(
                    margin: const EdgeInsets.only(left: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.orangeSubtle,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      name,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppColors.orange,
                      ),
                    ),
                  ),
              ],
            )
          else if (onCheckInStop != null)
            InkWell(
              key: Key('check_in_btn_${stop.placeId}'),
              onTap: () => onCheckInStop?.call(stop.placeId),
              borderRadius: BorderRadius.circular(6),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.cardSurface,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppColors.borderSubtle),
                ),
                child: Text(
                  _t('check_in'),
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink2,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
