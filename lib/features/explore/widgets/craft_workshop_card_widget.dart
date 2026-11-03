import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/craft_workshop_engine.dart';
import '../../../data/services/haptic_service.dart';

/// Card widget showcasing authentic Tashkent craft studios and masterclasses.
class CraftWorkshopCardWidget extends StatelessWidget {
  final CraftStudio studio;
  final String? reservedMasterclassId;
  final String locale;
  final void Function(CraftStudio studio, WorkshopMasterclass masterclass)?
      onMasterclassSelected;
  final void Function(CraftStudio studio)? onStudioTapped;

  const CraftWorkshopCardWidget({
    super.key,
    required this.studio,
    this.reservedMasterclassId,
    this.locale = 'en',
    this.onMasterclassSelected,
    this.onStudioTapped,
  });

  Color _parseAccentColor(String? hex) {
    if (hex == null || !hex.startsWith('#') || hex.length != 7) {
      return AppColors.orange;
    }
    final val = int.tryParse(hex.substring(1), radix: 16);
    return val != null ? Color(0xFF000000 | val) : AppColors.orange;
  }

  IconData _disciplineIcon(String discipline) {
    switch (discipline.toLowerCase()) {
      case 'ceramics':
        return Icons.coffee_rounded;
      case 'woodcarving':
        return Icons.carpenter_rounded;
      case 'silk weaving':
        return Icons.gesture_rounded;
      case 'copper embossing':
        return Icons.hardware_rounded;
      default:
        return Icons.brush_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final accentColor = _parseAccentColor(studio.accentColorHex);
    final engine = CraftWorkshopEngine();

    return Container(
      key: Key('craft_workshop_card_${studio.id}'),
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.borderSubtle, width: 1.5),
        boxShadow: const [AppColors.shadowCard],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Top Row: Discipline badge, District Pill, and Icon
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: accentColor.withValues(alpha: 0.25),
                  ),
                ),
                alignment: Alignment.center,
                child: Icon(
                  _disciplineIcon(studio.craftDiscipline),
                  color: accentColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: accentColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            studio.craftDiscipline.toUpperCase(),
                            style: GoogleFonts.jetBrainsMono(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              color: accentColor,
                              letterSpacing: 0.4,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.paper2,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            studio.district,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: AppColors.ink2,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    GestureDetector(
                      onTap: () {
                        HapticService.light();
                        onStudioTapped?.call(studio);
                      },
                      child: Text(
                        studio.localizedTitle(locale: locale),
                        key: Key('studio_title_${studio.id}'),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppColors.ink,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Master Artisan Credentials
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.paper,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.borderHairline),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.verified_user_rounded,
                  size: 15,
                  color: AppColors.orange,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: '${studio.masterArtisanName}  •  ',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.ink,
                          ),
                        ),
                        TextSpan(
                          text: studio.masterHonorific,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: AppColors.ink3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // Description
          Text(
            studio.description,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.ink2,
              height: 1.4,
            ),
          ),

          const SizedBox(height: 12),

          // Materials Tag Chips
          Wrap(
            key: const Key('studio_materials_wrap'),
            spacing: 6,
            runSpacing: 6,
            children: studio.materials.map((mat) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.paper,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.borderHairline),
                ),
                child: Text(
                  mat,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: AppColors.ink3,
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 14),

          // Masterclasses List
          ...studio.masterclasses.map((masterclass) {
            final isReserved = reservedMasterclassId == masterclass.id;
            final isFull = masterclass.isFull && !isReserved;
            final priceFormatted = engine.formatPriceUzs(masterclass.priceUzs);
            final statusLabel = engine.formatReservationStatus(
              isReserved: isReserved,
              isFull: isFull,
              locale: locale,
            );

            return Container(
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isReserved
                    ? accentColor.withValues(alpha: 0.08)
                    : AppColors.paper,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isReserved ? accentColor : AppColors.borderHairline,
                  width: isReserved ? 1.5 : 1.0,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          masterclass.title,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.ink,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.orangeSubtle,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '+${masterclass.xpReward} XP',
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: AppColors.orange,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.schedule_rounded,
                            size: 13,
                            color: AppColors.ink3,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${masterclass.timeSlot} (${masterclass.durationMinutes} min)',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: AppColors.ink3,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        priceFormatted,
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.ink,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  GestureDetector(
                    key: Key('workshop_reserve_btn_${masterclass.id}'),
                    behavior: HitTestBehavior.opaque,
                    onTap: isFull
                        ? null
                        : () {
                            HapticService.selection();
                            onMasterclassSelected?.call(studio, masterclass);
                          },
                    child: Container(
                      height: 38,
                      decoration: BoxDecoration(
                        color: isReserved
                            ? accentColor
                            : (isFull ? AppColors.paper2 : AppColors.ink),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        statusLabel,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: isFull ? AppColors.ink3 : Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
