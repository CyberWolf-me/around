import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/bouncing_widget.dart';

class CategoryChips extends StatelessWidget {
  final String selectedCategory;
  final Function(String category) onSelected;
  final List<String>? customCategories;
  final String? atmosphereLabel;
  final bool isAtmosphereActive;
  final VoidCallback? onToggleAtmosphere;

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
    this.customCategories,
    this.atmosphereLabel,
    this.isAtmosphereActive = false,
    this.onToggleAtmosphere,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveCategories = customCategories ?? categories;
    final hasAtmosphere = atmosphereLabel != null && onToggleAtmosphere != null;
    final totalCount = effectiveCategories.length + (hasAtmosphere ? 1 : 0);

    return SizedBox(
      height: 36,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: totalCount,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          if (hasAtmosphere && index == 0) {
            return BouncingWidget(
              scaleFactor: 0.94,
              onTap: onToggleAtmosphere,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                curve: Curves.easeOutCubic,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: isAtmosphereActive ? AppColors.orange : AppColors.butter,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: AppColors.ink,
                    width: 1.2,
                  ),
                  boxShadow: const [AppColors.shadowTactile],
                ),
                alignment: Alignment.center,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.wb_twilight_rounded,
                      size: 14,
                      color: isAtmosphereActive ? Colors.white : AppColors.ink,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      atmosphereLabel!,
                      style: GoogleFonts.instrumentSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: isAtmosphereActive ? Colors.white : AppColors.ink,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          final catIndex = hasAtmosphere ? index - 1 : index;
          final cat = effectiveCategories[catIndex];
          final isSelected = selectedCategory == cat && !isAtmosphereActive;

          return BouncingWidget(
            scaleFactor: 0.94,
            onTap: () => onSelected(cat),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.ink : AppColors.cardSurface,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: isSelected ? AppColors.ink : AppColors.borderSubtle,
                  width: 1.0,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: AppColors.ink.withValues(alpha: 0.15),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : const [AppColors.shadowSubtle],
              ),
              alignment: Alignment.center,
              child: Text(
                cat,
                style: GoogleFonts.instrumentSans(
                  fontSize: 12.5,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? Colors.white : AppColors.ink2,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
