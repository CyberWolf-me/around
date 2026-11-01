import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/services/haptic_service.dart';

class CategoryChips extends StatelessWidget {
  final String selectedCategory;
  final Function(String category) onSelected;

  static const List<String> categories = [
    'All',
    'Café',
    'Bakery',
    'Study',
    'Ramen',
    'Wine Bar',
    'Records',
    'Bookshop',
  ];

  const CategoryChips({
    super.key,
    required this.selectedCategory,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 32,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 6),
        itemBuilder: (context, index) {
          final cat = categories[index];
          final isSelected = selectedCategory == cat;

          return GestureDetector(
            onTap: () {
              HapticService.selection();
              onSelected(cat);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.ink : AppColors.paper2,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: isSelected ? AppColors.ink : AppColors.ink.withValues(alpha: 0.2),
                  width: 1.4,
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                cat,
                style: GoogleFonts.spaceMono(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: isSelected ? AppColors.paper : AppColors.ink2,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
