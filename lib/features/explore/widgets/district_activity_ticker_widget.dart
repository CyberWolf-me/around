import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/district_activity_ticker_engine.dart';
import '../../../data/services/haptic_service.dart';

/// Animated marquee / ticker widget displaying real-time community pulses across Tashkent.
class DistrictActivityTickerWidget extends StatefulWidget {
  final List<DistrictActivityEvent> events;
  final String locale;
  final void Function(DistrictActivityEvent event)? onEventTap;
  final Duration rotationInterval;

  const DistrictActivityTickerWidget({
    super.key,
    required this.events,
    this.locale = 'en',
    this.onEventTap,
    this.rotationInterval = const Duration(seconds: 4),
  });

  @override
  State<DistrictActivityTickerWidget> createState() =>
      _DistrictActivityTickerWidgetState();
}

class _DistrictActivityTickerWidgetState
    extends State<DistrictActivityTickerWidget>
    with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  Timer? _timer;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _startTimer();
  }

  @override
  void didUpdateWidget(covariant DistrictActivityTickerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.events.length != widget.events.length) {
      _currentIndex = 0;
      _startTimer();
    }
  }

  void _startTimer() {
    _timer?.cancel();
    if (widget.events.length > 1) {
      _timer = Timer.periodic(widget.rotationInterval, (_) {
        if (mounted) {
          setState(() {
            _currentIndex = (_currentIndex + 1) % widget.events.length;
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  String _getLiveBadgeText() {
    final lang = widget.locale.toLowerCase();
    if (lang.startsWith('uz')) return 'JONLI';
    if (lang.startsWith('ru')) return 'ПУЛЬС';
    return 'LIVE';
  }

  String _getEmptyStateText() {
    final lang = widget.locale.toLowerCase();
    if (lang.startsWith('uz')) return 'Toshkentda hozircha sokin';
    if (lang.startsWith('ru')) return 'В Ташкенте пока спокойно';
    return 'Quiet across Tashkent';
  }

  @override
  Widget build(BuildContext context) {
    final hasEvents = widget.events.isNotEmpty;
    final currentEvent = hasEvents && _currentIndex < widget.events.length
        ? widget.events[_currentIndex]
        : null;

    return GestureDetector(
      key: const Key('district_activity_ticker_gesture'),
      behavior: HitTestBehavior.opaque,
      onTap: () {
        if (currentEvent != null) {
          HapticService.selection();
          if (widget.onEventTap != null) {
            widget.onEventTap!(currentEvent);
          }
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.cardSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.borderSubtle, width: 1.2),
          boxShadow: const [AppColors.shadowCard],
        ),
        child: Row(
          children: [
            // Live pulsing dot + badge
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (context, child) {
                    return Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.orange.withValues(
                          alpha: _pulseAnimation.value,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.orange.withValues(
                              alpha: _pulseAnimation.value * 0.6,
                            ),
                            blurRadius: 6,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(width: 6),
                Text(
                  _getLiveBadgeText(),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    color: AppColors.orange,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),

            const SizedBox(width: 10),
            Container(width: 1, height: 16, color: AppColors.borderHairline),
            const SizedBox(width: 10),

            // Animated Event Marquee
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 350),
                transitionBuilder: (child, animation) {
                  return SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 0.4),
                      end: Offset.zero,
                    ).animate(animation),
                    child: FadeTransition(opacity: animation, child: child),
                  );
                },
                child: hasEvents && currentEvent != null
                    ? Row(
                        key: ValueKey<String>(currentEvent.id),
                        children: [
                          Text(
                            currentEvent.iconEmoji,
                            style: const TextStyle(fontSize: 14),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: RichText(
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              text: TextSpan(
                                children: [
                                  TextSpan(
                                    text: currentEvent.formatEventTitle(
                                      locale: widget.locale,
                                    ),
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.ink,
                                    ),
                                  ),
                                  const TextSpan(text: ' • '),
                                  TextSpan(
                                    text: currentEvent.formatRelativeTime(
                                      locale: widget.locale,
                                    ),
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.ink3,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      )
                    : Text(
                        _getEmptyStateText(),
                        key: const Key('ticker_empty_state_text'),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.ink3,
                        ),
                      ),
              ),
            ),

            const SizedBox(width: 6),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 11,
              color: AppColors.ink3,
            ),
          ],
        ),
      ),
    );
  }
}
