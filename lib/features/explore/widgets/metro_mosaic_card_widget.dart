import 'package:flutter/material.dart';
import 'package:around_app/core/constants/app_colors.dart';
import 'package:around_app/core/services/metro_mosaic_engine.dart';

/// Interactive Station Art & Ceramic Mosaic Card Widget.
class MetroMosaicCardWidget extends StatefulWidget {
  final MetroStationModel station;
  final bool isStamped;
  final bool isAudioPlaying;
  final String languageCode;
  final VoidCallback? onCollectStamp;
  final VoidCallback? onToggleAudio;
  final VoidCallback? onTapDetails;

  const MetroMosaicCardWidget({
    super.key,
    required this.station,
    this.isStamped = false,
    this.isAudioPlaying = false,
    this.languageCode = 'en',
    this.onCollectStamp,
    this.onToggleAudio,
    this.onTapDetails,
  });

  @override
  State<MetroMosaicCardWidget> createState() => _MetroMosaicCardWidgetState();
}

class _MetroMosaicCardWidgetState extends State<MetroMosaicCardWidget> {
  Color _getLineColor(String hex) {
    try {
      final clean = hex.replaceFirst('#', '');
      return Color(int.parse('0xFF$clean'));
    } catch (_) {
      return AppColors.cobalt;
    }
  }

  String _getLineLabel(MetroLine line) {
    switch (widget.languageCode.toLowerCase()) {
      case 'uz':
        return line.nameUz;
      case 'ru':
        return line.nameRu;
      case 'en':
      default:
        return line.nameEn;
    }
  }

  String _getYearLabel() {
    switch (widget.languageCode.toLowerCase()) {
      case 'uz':
        return '${widget.station.openingYear}-yilda ochilgan';
      case 'ru':
        return 'Открыта в ${widget.station.openingYear} г.';
      case 'en':
      default:
        return 'Opened ${widget.station.openingYear}';
    }
  }

  String _getStampButtonLabel() {
    if (widget.isStamped) {
      switch (widget.languageCode.toLowerCase()) {
        case 'uz':
          return "Shtamp yig'ilgan (+30 XP)";
        case 'ru':
          return 'Штамп получен (+30 XP)';
        case 'en':
        default:
          return 'Stamp Collected (+30 XP)';
      }
    } else {
      switch (widget.languageCode.toLowerCase()) {
        case 'uz':
          return "Shtampni olish (+30 XP)";
        case 'ru':
          return 'Собрать штамп (+30 XP)';
        case 'en':
        default:
          return 'Collect Stamp (+30 XP)';
      }
    }
  }

  String _getAudioButtonLabel() {
    if (widget.isAudioPlaying) {
      switch (widget.languageCode.toLowerCase()) {
        case 'uz':
          return "To'xtatish";
        case 'ru':
          return 'Пауза';
        case 'en':
        default:
          return 'Pause Guide';
      }
    } else {
      switch (widget.languageCode.toLowerCase()) {
        case 'uz':
          return "Audio qo'llanma";
        case 'ru':
          return 'Аудиогид';
        case 'en':
        default:
          return 'Audio Guide';
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final lineColor = _getLineColor(widget.station.line.colorHex);

    return Container(
      key: Key('metro_station_card_${widget.station.id}'),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: widget.isStamped ? lineColor.withAlpha(80) : AppColors.borderSubtle,
          width: widget.isStamped ? 1.5 : 1.0,
        ),
        boxShadow: const [AppColors.shadowCard],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: widget.onTapDetails,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Line Indicator and Opening Year
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          key: const Key('line_indicator_badge'),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: lineColor,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            _getLineLabel(widget.station.line),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _getYearLabel(),
                          style: const TextStyle(
                            color: AppColors.ink3,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    if (widget.isStamped)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.mintSubtle,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.check_circle, size: 14, color: Color(0xFF1B8755)),
                            SizedBox(width: 4),
                            Text(
                              'STAMPED',
                              style: TextStyle(
                                color: Color(0xFF1B8755),
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),

                // Station Title
                Text(
                  widget.station.localizedName(widget.languageCode),
                  style: const TextStyle(
                    color: AppColors.ink,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 4),

                // Architectural Style Pill
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    Container(
                      key: const Key('architectural_style_pill'),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.paper2,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        widget.station.architecturalStyle,
                        style: const TextStyle(
                          color: AppColors.ink2,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Container(
                      key: const Key('mosaic_artist_pill'),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: lineColor.withAlpha(20),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.palette_outlined, size: 12, color: lineColor),
                          const SizedBox(width: 4),
                          Text(
                            widget.station.mosaicArtist,
                            style: TextStyle(
                              color: lineColor,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Mosaic Narrative
                Text(
                  widget.station.mosaicDescription,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.ink2,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 10),

                // Marble & Lighting details row
                Row(
                  children: [
                    const Icon(Icons.account_balance_outlined, size: 13, color: AppColors.ink3),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        widget.station.marblePillars,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.ink3,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Actions: Audio Guide and Collect Stamp
                Row(
                  children: [
                    // Audio Guide Trigger Button
                    Expanded(
                      flex: 4,
                      child: OutlinedButton.icon(
                        key: const Key('audio_guide_button'),
                        onPressed: widget.onToggleAudio,
                        icon: Icon(
                          widget.isAudioPlaying
                              ? Icons.pause_circle_filled
                              : Icons.headphones_outlined,
                          size: 16,
                          color: widget.isAudioPlaying ? AppColors.orange : lineColor,
                        ),
                        label: Text(
                          _getAudioButtonLabel(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: widget.isAudioPlaying ? AppColors.orange : lineColor,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                            color: widget.isAudioPlaying
                                ? AppColors.orange
                                : lineColor.withAlpha(120),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Collect Stamp CTA Button
                    Expanded(
                      flex: 5,
                      child: ElevatedButton.icon(
                        key: const Key('stamp_button'),
                        onPressed: widget.isStamped ? null : widget.onCollectStamp,
                        icon: Icon(
                          widget.isStamped ? Icons.verified : Icons.stars_rounded,
                          size: 16,
                          color: widget.isStamped ? AppColors.ink3 : Colors.white,
                        ),
                        label: Text(
                          _getStampButtonLabel(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: widget.isStamped ? AppColors.ink3 : Colors.white,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: widget.isStamped ? AppColors.paper3 : AppColors.ink,
                          disabledBackgroundColor: AppColors.paper3,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                          elevation: 0,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
