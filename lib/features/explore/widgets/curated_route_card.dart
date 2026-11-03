import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/curated_route_engine.dart';

class CuratedRouteCard extends StatefulWidget {
  final CuratedRoute route;
  final RouteProgressReport? customProgress;
  final Set<String>? visitedPlaceIds;
  final String languageCode;
  final bool initiallyExpanded;
  final ValueChanged<CuratedRoute>? onTapRoute;
  final ValueChanged<RouteStop>? onSelectStop;
  final ValueChanged<CuratedRoute>? onStartRoute;

  const CuratedRouteCard({
    super.key,
    required this.route,
    this.customProgress,
    this.visitedPlaceIds,
    this.languageCode = 'en',
    this.initiallyExpanded = false,
    this.onTapRoute,
    this.onSelectStop,
    this.onStartRoute,
  });

  @override
  State<CuratedRouteCard> createState() => _CuratedRouteCardState();
}

class _CuratedRouteCardState extends State<CuratedRouteCard> {
  late bool _isExpanded;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initiallyExpanded;
  }

  RouteProgressReport get _progress {
    if (widget.customProgress != null) {
      return widget.customProgress!;
    }
    return CuratedRouteEngine.computeProgress(
      widget.route,
      widget.visitedPlaceIds ?? {},
    );
  }

  String _t(String key) {
    final lang = widget.languageCode;
    switch (key) {
      case 'stops':
        return lang == 'uz' ? 'bekat' : lang == 'ru' ? 'остановок' : 'stops';
      case 'min':
        return lang == 'uz' ? 'daq' : lang == 'ru' ? 'мин' : 'min';
      case 'start_crawl':
        return lang == 'uz' ? 'Sayrni Boshlash' : lang == 'ru' ? 'Начать маршрут' : 'Start Crawl';
      case 'completed':
        return lang == 'uz' ? 'Marshrut Tamomlandi 🏆' : lang == 'ru' ? 'Маршрут пройден 🏆' : 'Route Completed 🏆';
      case 'visited':
        return lang == 'uz' ? 'tashrif buyurildi' : lang == 'ru' ? 'посещено' : 'visited';
      case 'next_stop':
        return lang == 'uz' ? 'Keyingi bekat' : lang == 'ru' ? 'Следующая остановка' : 'Next Stop';
      default:
        return key;
    }
  }

  @override
  Widget build(BuildContext context) {
    final report = _progress;
    final localizedTitle = CuratedRouteEngine.getLocalizedTitle(widget.route, widget.languageCode);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: report.isCompleted ? AppColors.mint : AppColors.borderSubtle,
          width: report.isCompleted ? 1.5 : 1.0,
        ),
        boxShadow: const [AppColors.shadowCard],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Tappable Area
          InkWell(
            onTap: () {
              setState(() => _isExpanded = !_isExpanded);
              widget.onTapRoute?.call(widget.route);
            },
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Tags Row
                  Row(
                    children: [
                      Text(
                        widget.route.emoji,
                        style: const TextStyle(fontSize: 22),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.orangeSubtle,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          widget.route.district.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: AppColors.orange,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                      const Spacer(),
                      // XP Reward
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.butterSubtle,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '+${widget.route.xpReward} XP',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.orange,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Route Title & Subtitle
                  Text(
                    localizedTitle,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.route.subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.ink3,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Transit & Timing Pill Row
                  Row(
                    children: [
                      const Icon(Icons.directions_walk, size: 14, color: AppColors.ink3),
                      const SizedBox(width: 4),
                      Text(
                        '${widget.route.totalEstimatedMinutes} ${_t('min')} (${widget.route.totalDistanceMeters}m)',
                        style: const TextStyle(fontSize: 12, color: AppColors.ink2),
                      ),
                      const SizedBox(width: 12),
                      const Icon(Icons.place_outlined, size: 14, color: AppColors.ink3),
                      const SizedBox(width: 4),
                      Text(
                        '${widget.route.stops.length} ${_t('stops')}',
                        style: const TextStyle(fontSize: 12, color: AppColors.ink2),
                      ),
                      const Spacer(),
                      Icon(
                        _isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                        color: AppColors.ink3,
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Metro Connectors
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceWarm,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Text('🚇 ', style: TextStyle(fontSize: 12)),
                        Text(
                          widget.route.startSubway,
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.ink2),
                        ),
                        const SizedBox(width: 6),
                        const Icon(Icons.arrow_forward, size: 12, color: AppColors.ink3),
                        const SizedBox(width: 6),
                        Text(
                          widget.route.endSubway,
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.ink2),
                        ),
                      ],
                    ),
                  ),

                  // Progress Bar
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${report.completedStops}/${report.totalStops} ${_t('visited')}',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.ink2),
                      ),
                      Text(
                        '${report.completionPercentage}%',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: report.isCompleted ? AppColors.mint : AppColors.orange,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value: report.totalStops > 0 ? report.completedStops / report.totalStops : 0.0,
                      minHeight: 5,
                      backgroundColor: AppColors.borderHairline,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        report.isCompleted ? AppColors.mint : AppColors.orange,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Expanded Stop Timeline
          if (_isExpanded) ...[
            const Divider(height: 1, color: AppColors.borderHairline),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  for (int i = 0; i < widget.route.stops.length; i++) ...[
                    _buildStopRow(widget.route.stops[i], i + 1, report),
                    if (i < widget.route.stops.length - 1)
                      _buildConnectingStep(widget.route.stops[i + 1]),
                  ],
                ],
              ),
            ),
          ],

          // Footer Action
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: SizedBox(
              width: double.infinity,
              height: 40,
              child: ElevatedButton(
                key: Key('start_route_btn_${widget.route.id}'),
                onPressed: () => widget.onStartRoute?.call(widget.route),
                style: ElevatedButton.styleFrom(
                  backgroundColor: report.isCompleted ? AppColors.surfaceWarm : AppColors.orange,
                  foregroundColor: report.isCompleted ? AppColors.mint : Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: report.isCompleted ? const BorderSide(color: AppColors.mint) : BorderSide.none,
                  ),
                ),
                child: Text(
                  report.isCompleted ? _t('completed') : _t('start_crawl'),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStopRow(RouteStop stop, int stepNumber, RouteProgressReport report) {
    final isDone = widget.visitedPlaceIds?.contains(stop.placeId) ?? false;
    final isNext = report.nextPendingStop?.placeId == stop.placeId;

    return InkWell(
      key: Key('stop_row_${stop.placeId}'),
      onTap: () => widget.onSelectStop?.call(stop),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        child: Row(
          children: [
            // Stop Circle Indicator
            Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDone
                    ? AppColors.mint
                    : isNext
                        ? AppColors.orange
                        : AppColors.surfaceWarm,
                border: Border.all(
                  color: isDone
                      ? AppColors.mint
                      : isNext
                          ? AppColors.orange
                          : AppColors.borderSubtle,
                  width: 1.5,
                ),
              ),
              child: Center(
                child: isDone
                    ? const Icon(Icons.check, size: 14, color: Colors.white)
                    : Text(
                        '$stepNumber',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: isNext ? Colors.white : AppColors.ink2,
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 12),

            // Stop Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    stop.name,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isDone ? AppColors.ink3 : AppColors.ink,
                      decoration: isDone ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceWarm,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          stop.atmosphereTag,
                          style: const TextStyle(fontSize: 10, color: AppColors.ink3),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '🚇 ${stop.nearestSubway}',
                        style: const TextStyle(fontSize: 10, color: AppColors.ink3),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            if (isNext)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.orangeSubtle,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  _t('next_stop'),
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.orange),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildConnectingStep(RouteStop nextStop) {
    return Padding(
      padding: const EdgeInsets.only(left: 12),
      child: Row(
        children: [
          Container(
            width: 2,
            height: 22,
            color: AppColors.borderHairline,
          ),
          const SizedBox(width: 20),
          if (nextStop.walkingMinutesFromPrevious > 0)
            Row(
              children: [
                const Icon(Icons.directions_walk, size: 12, color: AppColors.ink3),
                const SizedBox(width: 4),
                Text(
                  '${nextStop.walkingMinutesFromPrevious} ${_t('min')} walk',
                  style: const TextStyle(fontSize: 10, color: AppColors.ink3),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
