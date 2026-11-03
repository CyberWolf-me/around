import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/metro_stamp_engine.dart';
import '../../../data/services/haptic_service.dart';

/// Interactive passport stamp book displaying ceramic metro station seals across Tashkent.
class MetroStampBookWidget extends StatefulWidget {
  final List<MetroStamp> claimedStamps;
  final String locale;
  final ValueChanged<MetroStation>? onStationTap;
  final MetroLine initialLine;

  const MetroStampBookWidget({
    super.key,
    required this.claimedStamps,
    this.locale = 'en',
    this.onStationTap,
    this.initialLine = MetroLine.uzbekistan,
  });

  @override
  State<MetroStampBookWidget> createState() => _MetroStampBookWidgetState();
}

class _MetroStampBookWidgetState extends State<MetroStampBookWidget> {
  late MetroLine _activeLine;
  final MetroStampEngine _engine = MetroStampEngine();

  @override
  void initState() {
    super.initState();
    _activeLine = widget.initialLine;
  }

  Color _getLineColor(MetroLine line) {
    switch (line) {
      case MetroLine.chilanzar:
        return const Color(0xFFE53935);
      case MetroLine.uzbekistan:
        return const Color(0xFF1E88E5);
      case MetroLine.yunusabad:
        return const Color(0xFF43A047);
    }
  }

  @override
  Widget build(BuildContext context) {
    final claimedIds = widget.claimedStamps.map((s) => s.stationId).toSet();
    final progress = _engine.calculateLineProgress(_activeLine, claimedIds);
    final stations = _engine.getStationsByLine(_activeLine);
    final activeColor = _getLineColor(_activeLine);
    final lineTitle = _engine.localizedLineName(_activeLine, locale: widget.locale);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderSubtle, width: 1.5),
        boxShadow: const [AppColors.shadowCard],
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: activeColor.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.subway_rounded, size: 18, color: activeColor),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _localizedHeaderTitle(widget.locale),
                    key: const Key('stamp_book_header_text'),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.ink,
                    ),
                  ),
                ],
              ),
              // Total claimed count badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.paper2,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${widget.claimedStamps.length} / ${MetroStampEngine.canonicalStations.length}',
                  key: const Key('total_stamps_count_text'),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink2,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Metro Line Selector Tabs
          Row(
            children: MetroLine.values.map((line) {
              final isSelected = line == _activeLine;
              final lineColor = _getLineColor(line);
              final tabLabel = _getShortTabLabel(line, widget.locale);

              return Expanded(
                child: GestureDetector(
                  key: Key('metro_tab_${line.name}'),
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    HapticService.selection();
                    setState(() {
                      _activeLine = line;
                    });
                  },
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? lineColor : AppColors.paper2,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      tabLabel,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: isSelected ? Colors.white : AppColors.ink2,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 14),

          // Line Progress Banner
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: activeColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: activeColor.withValues(alpha: 0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      lineTitle,
                      key: const Key('active_line_title_text'),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: activeColor,
                      ),
                    ),
                    Text(
                      '${progress.claimedStations}/${progress.totalStations} (${progress.completionPercentage.toStringAsFixed(0)}%)',
                      key: const Key('line_completion_pct_text'),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: activeColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress.totalStations > 0
                        ? progress.claimedStations / progress.totalStations
                        : 0.0,
                    backgroundColor: activeColor.withValues(alpha: 0.2),
                    valueColor: AlwaysStoppedAnimation<Color>(activeColor),
                    minHeight: 6,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Stamp Seals Grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: stations.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 1.45,
            ),
            itemBuilder: (context, index) {
              final station = stations[index];
              final isClaimed = claimedIds.contains(station.id);

              return GestureDetector(
                key: Key('stamp_card_${station.id}'),
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  HapticService.selection();
                  widget.onStationTap?.call(station);
                },
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isClaimed
                        ? activeColor.withValues(alpha: 0.06)
                        : AppColors.paper2,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isClaimed ? activeColor : AppColors.borderSubtle,
                      width: isClaimed ? 1.5 : 1.0,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            isClaimed ? Icons.verified_rounded : Icons.lock_outline_rounded,
                            size: 16,
                            color: isClaimed ? activeColor : AppColors.ink3,
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              station.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: isClaimed ? AppColors.ink : AppColors.ink3,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isClaimed ? station.stampMotif : '+25 XP Check-In',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: isClaimed ? activeColor : AppColors.ink3,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    ),
  );
  }

  String _localizedHeaderTitle(String locale) {
    final lang = locale.toLowerCase();
    if (lang.startsWith('uz')) return 'Metro Pasport Muhrlari';
    if (lang.startsWith('ru')) return 'Метро-Печати Паспорта';
    return 'Metro Passport Seals';
  }

  String _getShortTabLabel(MetroLine line, String locale) {
    final lang = locale.toLowerCase();
    switch (line) {
      case MetroLine.chilanzar:
        if (lang.startsWith('uz')) return 'Chilonzor';
        if (lang.startsWith('ru')) return 'Чиланзар';
        return 'Chilanzar';
      case MetroLine.uzbekistan:
        if (lang.startsWith('uz')) return 'O\'zbekiston';
        if (lang.startsWith('ru')) return 'Узбекистан';
        return 'Uzbekistan';
      case MetroLine.yunusabad:
        if (lang.startsWith('uz')) return 'Yunusobod';
        if (lang.startsWith('ru')) return 'Юнусабад';
        return 'Yunusabad';
    }
  }
}
