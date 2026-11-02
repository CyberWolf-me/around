import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/sunday_retrospective_service.dart';
import '../../../data/services/haptic_service.dart';

/// Modal dialog displaying Sunday Retrospective recap or Streak Rescue alert (`P20-02`).
/// Triggers during Sunday evening reflection window (18:00 - 22:00) or when explorer streak is at risk.
class WeeklyRetrospectiveModal extends StatelessWidget {
  final SundayRetrospectiveCard card;
  final VoidCallback onAction;
  final VoidCallback onDismiss;

  const WeeklyRetrospectiveModal({
    super.key,
    required this.card,
    required this.onAction,
    required this.onDismiss,
  });

  /// Shows the retrospective modal sheet with tactile feedback.
  static Future<void> show({
    required BuildContext context,
    required SundayRetrospectiveCard card,
    required VoidCallback onAction,
  }) {
    HapticService.selection();
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => WeeklyRetrospectiveModal(
        card: card,
        onAction: () {
          Navigator.pop(ctx);
          onAction();
        },
        onDismiss: () => Navigator.pop(ctx),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isAtRisk = card.isAtRisk;
    final isSecured = !isAtRisk && card.dropsThisWeek > 0;
    final statusLabel = isAtRisk
        ? 'STREAK AT RISK'
        : (isSecured ? 'STREAK SECURED' : 'SUNDAY RETROSPECTIVE');

    return SafeArea(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.paper,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isAtRisk ? AppColors.orange.withValues(alpha: 0.5) : AppColors.borderSubtle,
            width: 1.5,
          ),
          boxShadow: const [AppColors.shadowFloating],
        ),
        padding: const EdgeInsets.all(22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(
                  color: AppColors.inkLight.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: isAtRisk
                              ? AppColors.orangeSubtle
                              : (isSecured ? AppColors.mintSubtle : AppColors.paper2),
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          isAtRisk ? '⚠️' : (isSecured ? '🔥' : '✨'),
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          statusLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.spaceMono(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                            color: isAtRisk
                                ? AppColors.orange
                                : (isSecured ? AppColors.mint : AppColors.ink2),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  key: const Key('btn_retro_dismiss'),
                  icon: const Icon(Icons.close, size: 20, color: AppColors.ink3),
                  onPressed: () {
                    HapticService.selection();
                    onDismiss();
                  },
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              card.title,
              style: GoogleFonts.bricolageGrotesque(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppColors.ink,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              card.message,
              style: GoogleFonts.instrumentSans(
                fontSize: 13.5,
                color: AppColors.ink2,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            // Weekly stats breakdown grid
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.paper2,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.borderSubtle, width: 1),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'YOUR DROPS',
                          style: GoogleFonts.spaceMono(fontSize: 9, color: AppColors.ink3),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${card.dropsThisWeek} this wk',
                          style: GoogleFonts.bricolageGrotesque(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.ink,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Container(width: 1, height: 28, color: AppColors.borderHairline),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'STREAK',
                          style: GoogleFonts.spaceMono(fontSize: 9, color: AppColors.ink3),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Flexible(
                              child: Text(
                                '${card.streakWeeks} wks',
                                style: GoogleFonts.bricolageGrotesque(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: isAtRisk ? AppColors.orange : AppColors.mint,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (isSecured) ...[
                              const SizedBox(width: 4),
                              Text(
                                'Secured',
                                style: GoogleFonts.spaceMono(
                                  fontSize: 8.5,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.mint,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(width: 1, height: 28, color: AppColors.borderHairline),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'CIRCLE DROPS',
                          style: GoogleFonts.spaceMono(fontSize: 9, color: AppColors.ink3),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${card.circleDropsThisWeek} spots',
                          style: GoogleFonts.bricolageGrotesque(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.ink,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Primary Action Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                key: const Key('btn_retro_action'),
                onPressed: () {
                  HapticService.selection();
                  onAction();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: isAtRisk ? AppColors.orange : AppColors.ink,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  card.ctaText,
                  style: GoogleFonts.bricolageGrotesque(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
