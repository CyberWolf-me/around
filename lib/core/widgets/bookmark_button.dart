import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../../data/services/haptic_service.dart';

class BookmarkButton extends StatefulWidget {
  final bool isSaved;
  final VoidCallback onToggle;
  final double size;
  final Color? activeColor;
  final Color? inactiveColor;
  final Color? backgroundColor;

  const BookmarkButton({
    super.key,
    required this.isSaved,
    required this.onToggle,
    this.size = 36,
    this.activeColor,
    this.inactiveColor,
    this.backgroundColor,
  });

  @override
  State<BookmarkButton> createState() => _BookmarkButtonState();
}

class _BookmarkButtonState extends State<BookmarkButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.28).chain(CurveTween(curve: Curves.easeOutCubic)), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.28, end: 1.0).chain(CurveTween(curve: Curves.elasticOut)), weight: 50),
    ]).animate(_controller);
  }

  @override
  void didUpdateWidget(covariant BookmarkButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isSaved != widget.isSaved) {
      _controller.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final active = widget.isSaved;
    final activeCol = widget.activeColor ?? AppColors.orange;
    final inactiveCol = widget.inactiveColor ?? AppColors.ink;
    final bgCol = widget.backgroundColor ?? (active ? AppColors.orangeSubtle : Colors.white.withValues(alpha: 0.92));

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        HapticService.medium();
        widget.onToggle();
      },
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          width: widget.size,
          height: widget.size,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: bgCol,
            borderRadius: BorderRadius.circular(widget.size / 3),
            border: Border.all(
              color: active ? activeCol : AppColors.borderSubtle,
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(
            active ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
            size: widget.size * 0.52,
            color: active ? activeCol : inactiveCol,
          ),
        ),
      ),
    );
  }
}
