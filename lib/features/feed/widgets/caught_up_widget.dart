import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class CaughtUpWidget extends StatelessWidget {
  final VoidCallback onExploreTapped;

  const CaughtUpWidget({super.key, required this.onExploreTapped});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 20),
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.paper2,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.ink.withOpacity(0.3), width: 1.5),
      ),
      child: Column(
        children: [
          const Text(
            "You're all caught up.",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              fontFamily: 'BricolageGrotesque',
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            "That’s every recommendation from your friends in Tashkent today.",
            style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 11.5),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 14),
          ElevatedButton.icon(
            onPressed: onExploreTapped,
            icon: const Icon(Icons.explore, size: 15, color: Colors.white),
            label: const Text(
              'Explore Public Community',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.orange,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: const BorderSide(color: AppColors.ink, width: 1.5),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
