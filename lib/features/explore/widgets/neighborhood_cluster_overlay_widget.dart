import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/neighborhood_cluster_engine.dart';
import '../../../data/services/haptic_service.dart';

/// Animated cluster badge widget overlaying neighborhood activity hotspots.
class NeighborhoodClusterOverlayWidget extends StatefulWidget {
  final NeighborhoodCluster cluster;
  final String locale;
  final void Function(NeighborhoodCluster cluster)? onClusterTap;

  const NeighborhoodClusterOverlayWidget({
    super.key,
    required this.cluster,
    this.locale = 'en',
    this.onClusterTap,
  });

  @override
  State<NeighborhoodClusterOverlayWidget> createState() =>
      _NeighborhoodClusterOverlayWidgetState();
}

class _NeighborhoodClusterOverlayWidgetState
    extends State<NeighborhoodClusterOverlayWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    final isHot = widget.cluster.intensity == ClusterIntensity.buzzing ||
        widget.cluster.intensity == ClusterIntensity.peak;

    _pulseController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: isHot ? 900 : 1500),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.3, end: 0.85).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Color _getIntensityColor() {
    switch (widget.cluster.intensity) {
      case ClusterIntensity.serene:
        return AppColors.mint;
      case ClusterIntensity.lively:
        return AppColors.butter;
      case ClusterIntensity.buzzing:
        return AppColors.orange;
      case ClusterIntensity.peak:
        return AppColors.danger;
    }
  }

  @override
  Widget build(BuildContext context) {
    final intensityColor = _getIntensityColor();
    final label = widget.cluster.localizedIntensityLabel(locale: widget.locale);
    final summary = widget.cluster.localizedSummary(locale: widget.locale);

    return GestureDetector(
      key: Key('neighborhood_cluster_pill_${widget.cluster.id}'),
      behavior: HitTestBehavior.opaque,
      onTap: () {
        HapticService.selection();
        if (widget.onClusterTap != null) {
          widget.onClusterTap!(widget.cluster);
        }
      },
      child: AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.cardSurface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: intensityColor.withValues(alpha: 0.8),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: intensityColor.withValues(
                    alpha: _pulseAnimation.value * 0.45,
                  ),
                  blurRadius: 16,
                  spreadRadius: 2,
                ),
                AppColors.shadowCard,
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Intensity Emoji & Pulse Indicator
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: intensityColor.withValues(alpha: 0.18),
                    border: Border.all(
                      color: intensityColor.withValues(alpha: 0.5),
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    widget.cluster.intensityEmoji,
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
                const SizedBox(width: 10),

                // Cluster details
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              widget.cluster.primaryVenueName,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: AppColors.ink,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: intensityColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              label,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                color: widget.cluster.intensity == ClusterIntensity.lively
                                    ? AppColors.ink
                                    : intensityColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        summary,
                        key: const Key('cluster_summary_text'),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.ink3,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                // Drops count badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.paper2,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.borderSubtle),
                  ),
                  child: Text(
                    '${widget.cluster.dropsCount}',
                    key: const Key('cluster_drops_count_badge'),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      color: AppColors.ink,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
