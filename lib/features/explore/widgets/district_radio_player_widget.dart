import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/district_radio_engine.dart';
import '../../../data/services/haptic_service.dart';

/// Interactive retro-futuristic radio dial tuner for Tashkent district field recordings.
class DistrictRadioPlayerWidget extends StatefulWidget {
  final double initialFrequency;
  final bool initialPlaying;
  final String locale;
  final void Function(
    double frequency,
    RadioStation? station,
    bool isPlaying,
    double receptionQuality,
  )? onTuningChanged;

  const DistrictRadioPlayerWidget({
    super.key,
    this.initialFrequency = 88.4,
    this.initialPlaying = false,
    this.locale = 'en',
    this.onTuningChanged,
  });

  @override
  State<DistrictRadioPlayerWidget> createState() =>
      _DistrictRadioPlayerWidgetState();
}

class _DistrictRadioPlayerWidgetState extends State<DistrictRadioPlayerWidget>
    with SingleTickerProviderStateMixin {
  final DistrictRadioEngine _engine = DistrictRadioEngine();
  late double _currentFrequency;
  late bool _isPlaying;
  late AnimationController _equalizerController;
  late List<RadioStation> _stations;
  late TuningResult _tuningResult;
  String? _lastLockedStationId;

  @override
  void initState() {
    super.initState();
    _stations = _engine.getAllStations();
    _currentFrequency = widget.initialFrequency;
    _isPlaying = widget.initialPlaying;
    _tuningResult = _engine.tuneToFrequency(_currentFrequency);
    _lastLockedStationId = _tuningResult.lockedStation?.id;

    _equalizerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    if (_isPlaying) {
      _equalizerController.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _equalizerController.dispose();
    super.dispose();
  }

  void _onFrequencyChanged(double newFrequency) {
    final rounded = (newFrequency * 10).roundToDouble() / 10.0;
    final result = _engine.tuneToFrequency(rounded);

    // Haptic tick when locking onto or leaving a station
    if (result.lockedStation?.id != _lastLockedStationId) {
      _lastLockedStationId = result.lockedStation?.id;
      if (result.isLocked) {
        HapticService.selection();
      } else {
        HapticService.light();
      }
    }

    setState(() {
      _currentFrequency = rounded;
      _tuningResult = result;
    });

    widget.onTuningChanged?.call(
      _currentFrequency,
      _tuningResult.lockedStation,
      _isPlaying,
      _tuningResult.receptionQuality,
    );
  }

  void _selectStation(RadioStation station) {
    HapticService.selection();
    final result = _engine.tuneToFrequency(station.frequencyMhz);

    setState(() {
      _currentFrequency = station.frequencyMhz;
      _tuningResult = result;
      _lastLockedStationId = station.id;
    });

    widget.onTuningChanged?.call(
      _currentFrequency,
      station,
      _isPlaying,
      _tuningResult.receptionQuality,
    );
  }

  void _togglePlayPause() {
    HapticService.selection();
    setState(() {
      _isPlaying = !_isPlaying;
      if (_isPlaying) {
        _equalizerController.repeat(reverse: true);
      } else {
        _equalizerController.stop();
      }
    });

    widget.onTuningChanged?.call(
      _currentFrequency,
      _tuningResult.lockedStation,
      _isPlaying,
      _tuningResult.receptionQuality,
    );
  }

  Color _parseAccentColor(String? hex) {
    if (hex == null || !hex.startsWith('#') || hex.length != 7) {
      return AppColors.orange;
    }
    final val = int.tryParse(hex.substring(1), radix: 16);
    return val != null ? Color(0xFF000000 | val) : AppColors.orange;
  }

  @override
  Widget build(BuildContext context) {
    final lockedStation = _tuningResult.lockedStation;
    final accentColor = lockedStation != null
        ? _parseAccentColor(lockedStation.accentColorHex)
        : AppColors.ink3;

    final stationName = lockedStation != null
        ? lockedStation.localizedTitle(locale: widget.locale)
        : (widget.locale == 'uz'
            ? 'Statik signal'
            : widget.locale == 'ru'
                ? 'Статический шум'
                : 'Static Noise');

    final stationGenre = lockedStation != null
        ? lockedStation.localizedGenre(locale: widget.locale)
        : (widget.locale == 'uz'
            ? 'Bo\'sh to\'lqin'
            : widget.locale == 'ru'
                ? 'Свободная частота'
                : 'Open Frequency');

    final receptionLabel = _engine.formatReceptionLabel(
      _tuningResult.receptionQuality,
      locale: widget.locale,
    );

    return Container(
      key: const Key('district_radio_player_widget'),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: _tuningResult.isLocked
              ? accentColor.withValues(alpha: 0.4)
              : AppColors.borderSubtle,
          width: 1.5,
        ),
        boxShadow: const [AppColors.shadowFloating],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header Bar: Callsign, Live Listener Badge, and Signal Status
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Retro Vintage Radio Antenna Icon
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: _tuningResult.isLocked
                      ? accentColor.withValues(alpha: 0.12)
                      : AppColors.paper2,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: _tuningResult.isLocked
                        ? accentColor.withValues(alpha: 0.25)
                        : AppColors.borderHairline,
                  ),
                ),
                alignment: Alignment.center,
                child: Icon(
                  Icons.radio_rounded,
                  color: _tuningResult.isLocked ? accentColor : AppColors.ink3,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),

              // Station Name & Genre
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            lockedStation?.callsign ??
                                _engine.formatFrequency(_currentFrequency),
                            key: const Key('radio_station_callsign'),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: AppColors.ink,
                            ),
                          ),
                        ),
                        if (_tuningResult.isLocked) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: accentColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'LOCK',
                              style: GoogleFonts.jetBrainsMono(
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                color: accentColor,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$stationName • $stationGenre',
                      key: const Key('radio_station_details'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: AppColors.ink3,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              // Play / Pause Button
              GestureDetector(
                key: const Key('radio_play_pause_button'),
                behavior: HitTestBehavior.opaque,
                onTap: _togglePlayPause,
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: _isPlaying ? AppColors.orange : AppColors.paper2,
                    shape: BoxShape.circle,
                    boxShadow: const [AppColors.shadowTactile],
                  ),
                  child: Icon(
                    _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                    color: _isPlaying ? Colors.white : AppColors.ink,
                    size: 26,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Digital Display Screen Pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.paper,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.borderSubtle),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Frequency readout
                Row(
                  children: [
                    Text(
                      _currentFrequency.toStringAsFixed(1),
                      key: const Key('radio_frequency_display'),
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                        color: _tuningResult.isLocked
                            ? accentColor
                            : AppColors.ink,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'MHz',
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.ink3,
                      ),
                    ),
                  ],
                ),

                // Signal Quality Badge
                Container(
                  key: const Key('radio_signal_quality_badge'),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _tuningResult.isLocked
                        ? AppColors.mintSubtle
                        : AppColors.orangeSubtle,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _tuningResult.isLocked
                            ? Icons.wifi_rounded
                            : Icons.wifi_find_rounded,
                        size: 13,
                        color: _tuningResult.isLocked
                            ? AppColors.mint
                            : AppColors.orange,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        receptionLabel,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: _tuningResult.isLocked
                              ? AppColors.mint
                              : AppColors.orange,
                        ),
                      ),
                    ],
                  ),
                ),

                // Live Listeners Badge
                Container(
                  key: const Key('radio_listener_count_badge'),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.paper2,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.borderHairline),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: _isPlaying
                              ? AppColors.mint
                              : AppColors.ink3,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        '${_tuningResult.liveListeners} live',
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: AppColors.ink2,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // Equalizer Visualizer Waves
          SizedBox(
            height: 24,
            key: const Key('radio_equalizer_visualizer'),
            child: AnimatedBuilder(
              animation: _equalizerController,
              builder: (context, child) {
                return Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: List.generate(11, (i) {
                    final progress =
                        _isPlaying ? _equalizerController.value : 0.0;
                    final waveHeights = [
                      5.0 + 9.0 * progress,
                      8.0 + 12.0 * (1.0 - progress),
                      4.0 + 16.0 * progress,
                      12.0 + 8.0 * (1.0 - progress),
                      6.0 + 17.0 * progress,
                      10.0 + 10.0 * (1.0 - progress),
                      7.0 + 14.0 * progress,
                      14.0 + 6.0 * (1.0 - progress),
                      5.0 + 18.0 * progress,
                      10.0 + 11.0 * (1.0 - progress),
                      6.0 + 10.0 * progress,
                    ];
                    final barHeight = _tuningResult.isLocked
                        ? waveHeights[i] * _tuningResult.receptionQuality
                        : 4.0 + 3.0 * (i % 2 == 0 ? progress : 1.0 - progress);

                    return Container(
                      width: 4,
                      height: barHeight.clamp(3.0, 24.0),
                      margin: const EdgeInsets.symmetric(horizontal: 2.5),
                      decoration: BoxDecoration(
                        color: _isPlaying
                            ? (_tuningResult.isLocked
                                ? accentColor
                                : AppColors.ink3)
                            : AppColors.inkLight,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    );
                  }),
                );
              },
            ),
          ),

          const SizedBox(height: 12),

          // Analog Frequency Tuning Scrubber Slider
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 4,
              activeTrackColor: accentColor,
              inactiveTrackColor: AppColors.paper2,
              thumbColor: accentColor,
              overlayColor: accentColor.withValues(alpha: 0.15),
              thumbShape: const RoundSliderThumbShape(
                enabledThumbRadius: 9,
                elevation: 3,
              ),
              tickMarkShape: const RoundSliderTickMarkShape(tickMarkRadius: 2),
              activeTickMarkColor: Colors.white,
              inactiveTickMarkColor: AppColors.inkLight,
            ),
            child: Slider(
              key: const Key('radio_frequency_slider'),
              min: _engine.minFrequency,
              max: _engine.maxFrequency,
              divisions: 200, // 0.1 MHz increments across 20 MHz
              value: _currentFrequency.clamp(
                _engine.minFrequency,
                _engine.maxFrequency,
              ),
              onChanged: _onFrequencyChanged,
            ),
          ),

          // Station Quick-Jump Pills
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _stations.map((st) {
                final isSelected = _tuningResult.lockedStation?.id == st.id;
                final pillColor = _parseAccentColor(st.accentColorHex);

                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    key: Key('radio_station_tab_${st.id}'),
                    behavior: HitTestBehavior.opaque,
                    onTap: () => _selectStation(st),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? pillColor.withValues(alpha: 0.15)
                            : AppColors.paper,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSelected
                              ? pillColor
                              : AppColors.borderHairline,
                          width: isSelected ? 1.5 : 1.0,
                        ),
                      ),
                      child: Row(
                        children: [
                          Text(
                            st.frequencyMhz.toStringAsFixed(1),
                            style: GoogleFonts.jetBrainsMono(
                              fontSize: 11,
                              fontWeight: isSelected
                                  ? FontWeight.w800
                                  : FontWeight.w600,
                              color: isSelected ? pillColor : AppColors.ink2,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            st.districtSlug.toUpperCase(),
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: isSelected ? pillColor : AppColors.ink3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
