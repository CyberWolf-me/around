import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/bouncing_widget.dart';
import '../../../data/repositories/places_repository.dart';
import '../../../data/services/haptic_service.dart';

/// Privacy-preserving district activity density overlay widget (`P13-02`).
/// Visualizes aggregate social momentum across Tashkent neighborhoods without
/// exposing individual user IDs, timestamps, or raw GPS coordinates.
class DistrictDensityOverlay extends StatelessWidget {
  final List<DistrictDensityModel> districts;
  final String? selectedDistrict;
  final ValueChanged<DistrictDensityModel>? onDistrictTap;

  const DistrictDensityOverlay({
    super.key,
    required this.districts,
    this.selectedDistrict,
    this.onDistrictTap,
  });

  Color _getHeatColor(double density) {
    if (density >= 0.75) {
      return AppColors.orange;
    } else if (density >= 0.45) {
      return AppColors.butter;
    } else {
      return AppColors.mint;
    }
  }

  Color _getHeatBg(double density) {
    if (density >= 0.75) {
      return AppColors.orangeSubtle;
    } else if (density >= 0.45) {
      return AppColors.butterSubtle;
    } else {
      return AppColors.mintSubtle;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (districts.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      key: const Key('district_density_overlay'),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.paper,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSubtle, width: 1.0),
        boxShadow: const [AppColors.shadowCard],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.mintSubtle,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.shield_outlined,
                      size: 13,
                      color: AppColors.ink2,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Tashkent Live Density',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Text(
                '🔒 Zero GPS Tracking',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: AppColors.ink3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: districts.map((district) {
                final isSelected = selectedDistrict != null &&
                    selectedDistrict!.toLowerCase() == district.district.toLowerCase();
                final heatColor = _getHeatColor(district.relativeDensity);
                final heatBg = _getHeatBg(district.relativeDensity);

                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: BouncingWidget(
                    scaleFactor: 0.95,
                    onTap: () {
                      HapticService.selection();
                      onDistrictTap?.call(district);
                    },
                    child: Container(
                      key: Key('district_chip_${district.district}'),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.ink : heatBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? AppColors.ink : heatColor.withValues(alpha: 0.4),
                          width: isSelected ? 1.5 : 1.0,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: isSelected ? AppColors.paper : heatColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                district.district,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: isSelected ? AppColors.paper : AppColors.ink,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${district.dropCount} drops · ${district.activeVenuesCount} spots',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                  color: isSelected ? AppColors.paper3 : AppColors.ink2,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                            decoration: BoxDecoration(
                              color: isSelected ? AppColors.paper2.withValues(alpha: 0.2) : AppColors.paper,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '${(district.relativeDensity * 100).round()}%',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: isSelected ? AppColors.paper : heatColor,
                              ),
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
