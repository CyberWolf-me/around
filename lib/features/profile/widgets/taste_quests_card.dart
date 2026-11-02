import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/quest_model.dart';

class TasteQuestsCard extends StatelessWidget {
  final List<QuestModel> quests;
  final Set<String> visitedPlaceIds;
  final VoidCallback? onExploreMore;

  const TasteQuestsCard({
    super.key,
    required this.quests,
    required this.visitedPlaceIds,
    this.onExploreMore,
  });

  @override
  Widget build(BuildContext context) {
    final completedCount = quests.where((q) => q.isCompleted(visitedPlaceIds)).length;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderSubtle, width: 1),
        boxShadow: const [AppColors.shadowCard],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'TASHKENT TASTE QUESTS',
                style: GoogleFonts.spaceMono(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                  color: AppColors.orange,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.orangeSubtle,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$completedCount / ${quests.length} Completed',
                  style: GoogleFonts.spaceMono(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: AppColors.orange,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Explore trails & earn Local Legend status',
            style: GoogleFonts.bricolageGrotesque(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 14),
          ...quests.map((quest) {
            final isDone = quest.isCompleted(visitedPlaceIds);
            final progress = quest.progressFraction(visitedPlaceIds);
            final count = quest.completedCount(visitedPlaceIds);

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDone ? AppColors.orangeSubtle.withValues(alpha: 0.5) : AppColors.paper,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isDone ? AppColors.orange.withValues(alpha: 0.3) : AppColors.borderHairline,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(quest.icon, style: const TextStyle(fontSize: 20)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              quest.title,
                              style: GoogleFonts.instrumentSans(
                                fontWeight: FontWeight.bold,
                                fontSize: 13.5,
                                color: AppColors.ink,
                              ),
                            ),
                            Text(
                              quest.district,
                              style: GoogleFonts.spaceMono(
                                fontSize: 9.5,
                                color: AppColors.ink3,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isDone)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.orange,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'UNLOCKED',
                            style: GoogleFonts.spaceMono(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    quest.description,
                    style: GoogleFonts.instrumentSans(
                      fontSize: 11.5,
                      color: AppColors.ink2,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: progress,
                            backgroundColor: AppColors.borderHairline,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              isDone ? AppColors.orange : AppColors.mint,
                            ),
                            minHeight: 6,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        '$count / ${quest.requiredCount}',
                        style: GoogleFonts.spaceMono(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: isDone ? AppColors.orange : AppColors.ink2,
                        ),
                      ),
                    ],
                  ),
                  if (isDone) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.military_tech, size: 14, color: AppColors.orange),
                        const SizedBox(width: 4),
                        Text(
                          'Badge: ${quest.badgeName}',
                          style: GoogleFonts.instrumentSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.orange,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
