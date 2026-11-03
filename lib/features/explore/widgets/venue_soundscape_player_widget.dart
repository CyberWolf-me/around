import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/venue_soundscape_engine.dart';
import '../../../data/services/haptic_service.dart';

/// Floating audio capsule widget for experiencing ambient venue soundscapes.
class VenueSoundscapePlayerWidget extends StatefulWidget {
  final VenueSoundscapePreset initialPreset;
  final String locale;
  final void Function(
    VenueSoundscapePreset preset,
    bool isPlaying,
    double volume,
  )? onStateChanged;

  const VenueSoundscapePlayerWidget({
    super.key,
    this.initialPreset = VenueSoundscapePreset.espressoMurmur,
    this.locale = 'en',
    this.onStateChanged,
  });

  @override
  State<VenueSoundscapePlayerWidget> createState() =>
      _VenueSoundscapePlayerWidgetState();
}

class _VenueSoundscapePlayerWidgetState
    extends State<VenueSoundscapePlayerWidget>
    with SingleTickerProviderStateMixin {
  late VenueSoundscapePreset _currentPreset;
  bool _isPlaying = false;
  late double _volume;
  late AnimationController _waveController;
  final VenueSoundscapeEngine _engine = VenueSoundscapeEngine();

  @override
  void initState() {
    super.initState();
    _currentPreset = widget.initialPreset;
    _volume = _engine.getConfig(_currentPreset).defaultVolume;

    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
  }

  @override
  void dispose() {
    _waveController.dispose();
    super.dispose();
  }

  void _togglePlayPause() {
    HapticService.selection();
    setState(() {
      _isPlaying = !_isPlaying;
      if (_isPlaying) {
        _waveController.repeat(reverse: true);
      } else {
        _waveController.stop();
      }
    });

    if (widget.onStateChanged != null) {
      widget.onStateChanged!(_currentPreset, _isPlaying, _volume);
    }
  }

  void _selectPreset(VenueSoundscapePreset preset) {
    if (_currentPreset == preset) return;
    HapticService.selection();
    setState(() {
      _currentPreset = preset;
      _volume = _engine.getConfig(preset).defaultVolume;
    });

    if (widget.onStateChanged != null) {
      widget.onStateChanged!(_currentPreset, _isPlaying, _volume);
    }
  }

  void _onVolumeChanged(double newVolume) {
    setState(() {
      _volume = _engine.clampVolume(newVolume);
    });

    if (widget.onStateChanged != null) {
      widget.onStateChanged!(_currentPreset, _isPlaying, _volume);
    }
  }

  @override
  Widget build(BuildContext context) {
    final config = _engine.getConfig(_currentPreset);
    final title = config.localizedTitle(locale: widget.locale);
    final description = config.localizedDescription(locale: widget.locale);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.borderSubtle, width: 1.5),
        boxShadow: const [AppColors.shadowFloating],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header: Emoji, Title, and Play/Pause Toggle
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.orangeSubtle,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.borderHairline),
                ),
                alignment: Alignment.center,
                child: Text(
                  config.emoji,
                  style: const TextStyle(fontSize: 22),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      key: const Key('soundscape_title_text'),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      description,
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

              // Play/Pause Action Button
              GestureDetector(
                key: const Key('soundscape_play_pause_button'),
                behavior: HitTestBehavior.opaque,
                onTap: _togglePlayPause,
                child: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: _isPlaying ? AppColors.orange : AppColors.paper2,
                    shape: BoxShape.circle,
                    boxShadow: const [AppColors.shadowTactile],
                  ),
                  child: Icon(
                    _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                    color: _isPlaying ? Colors.white : AppColors.ink,
                    size: 24,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Animated Equalizer Waveform Bars
          SizedBox(
            height: 28,
            child: AnimatedBuilder(
              animation: _waveController,
              builder: (context, child) {
                return Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: List.generate(7, (i) {
                    final progress = _isPlaying ? _waveController.value : 0.0;
                    final heights = [
                      8.0 + 12.0 * progress,
                      12.0 + 14.0 * (1.0 - progress),
                      6.0 + 20.0 * progress,
                      14.0 + 10.0 * (1.0 - progress),
                      8.0 + 18.0 * progress,
                      10.0 + 12.0 * (1.0 - progress),
                      6.0 + 14.0 * progress,
                    ];
                    final height = _isPlaying ? heights[i] : 6.0;

                    return Container(
                      width: 4,
                      height: height,
                      margin: const EdgeInsets.symmetric(horizontal: 2.5),
                      decoration: BoxDecoration(
                        color: _isPlaying
                            ? AppColors.orange
                            : AppColors.borderSubtle,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    );
                  }),
                );
              },
            ),
          ),

          const SizedBox(height: 14),

          // Preset Chips Selector
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: VenueSoundscapePreset.values.map((preset) {
                final pConfig = _engine.getConfig(preset);
                final isSelected = preset == _currentPreset;

                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    key: Key('preset_chip_${pConfig.id}'),
                    behavior: HitTestBehavior.opaque,
                    onTap: () => _selectPreset(preset),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.orangeSubtle
                            : AppColors.paper,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.orange
                              : AppColors.borderSubtle,
                          width: isSelected ? 1.5 : 1.0,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(pConfig.emoji, style: const TextStyle(fontSize: 13)),
                          const SizedBox(width: 4),
                          Text(
                            pConfig.localizedTitle(locale: widget.locale),
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              fontWeight: isSelected
                                  ? FontWeight.w800
                                  : FontWeight.w600,
                              color: isSelected
                                  ? AppColors.orange
                                  : AppColors.ink,
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

          const SizedBox(height: 14),

          // Volume Slider
          Row(
            children: [
              const Icon(
                Icons.volume_mute_rounded,
                size: 16,
                color: AppColors.ink3,
              ),
              Expanded(
                child: SliderTheme(
                  data: const SliderThemeData(
                    trackHeight: 3,
                    thumbShape: RoundSliderThumbShape(
                      enabledThumbRadius: 6,
                    ),
                    overlayShape: RoundSliderOverlayShape(
                      overlayRadius: 12,
                    ),
                    activeTrackColor: AppColors.orange,
                    inactiveTrackColor: AppColors.borderSubtle,
                    thumbColor: AppColors.orange,
                  ),
                  child: Slider(
                    key: const Key('soundscape_volume_slider'),
                    value: _volume,
                    min: 0.0,
                    max: 1.0,
                    onChanged: _onVolumeChanged,
                  ),
                ),
              ),
              const Icon(
                Icons.volume_up_rounded,
                size: 16,
                color: AppColors.ink3,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
