import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/bouncing_widget.dart';

class CaughtUpWidget extends StatelessWidget {
  final VoidCallback onExploreTapped;

  const CaughtUpWidget({super.key, required this.onExploreTapped});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      padding: const EdgeInsets.symmetric(vertical: 26, horizontal: 20),
      decoration: BoxDecoration(
        color: AppColors.paper2,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderSubtle, width: 1.0),
        boxShadow: const [AppColors.shadowSubtle],
      ),
      child: Column(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.paper,
              border: Border.all(color: AppColors.borderSubtle),
            ),
            child: const Icon(Icons.done_all_rounded, color: AppColors.orange, size: 22),
          ),
          const SizedBox(height: 12),
          Text(
            "You're all caught up.",
            style: GoogleFonts.bricolageGrotesque(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: AppColors.ink,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            "That’s every recommendation from your friends in Tashkent today.",
            style: GoogleFonts.instrumentSans(
              fontSize: 12.5,
              color: AppColors.ink2,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          BouncingWidget(
            onTap: onExploreTapped,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.ink,
                borderRadius: BorderRadius.circular(12),
                boxShadow: const [AppColors.shadowSm],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.explore_outlined, size: 16, color: Colors.white),
                  const SizedBox(width: 8),
                  Text(
                    'Explore Tashkent Spots',
                    style: GoogleFonts.instrumentSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
