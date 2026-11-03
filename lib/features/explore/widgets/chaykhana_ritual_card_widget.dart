import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/chaykhana_ritual_engine.dart';
import '../../../data/services/haptic_service.dart';

/// Card widget showcasing traditional Tashkent chaykhanas, tapchan seating, and the 3-step Kaytarish ritual.
class ChaykhanaRitualCardWidget extends StatefulWidget {
  final ChaykhanaVenue venue;
  final bool isReserved;
  final String locale;
  final void Function(ChaykhanaVenue venue, TeaBlend blend)? onTapchanReserved;
  final void Function(int stepNumber)? onKaytarishStepChanged;

  const ChaykhanaRitualCardWidget({
    super.key,
    required this.venue,
    this.isReserved = false,
    this.locale = 'en',
    this.onTapchanReserved,
    this.onKaytarishStepChanged,
  });

  @override
  State<ChaykhanaRitualCardWidget> createState() =>
      _ChaykhanaRitualCardWidgetState();
}

class _ChaykhanaRitualCardWidgetState extends State<ChaykhanaRitualCardWidget> {
  final ChaykhanaRitualEngine _engine = ChaykhanaRitualEngine();
  int _activeKaytarishStep = 1;
  late TeaBlend _selectedBlend;

  @override
  void initState() {
    super.initState();
    _selectedBlend = widget.venue.signatureBlends.isNotEmpty
        ? widget.venue.signatureBlends.first
        : const TeaBlend(
            id: 'default',
            name: 'Kok Choy',
            teaType: 'Green',
            description: 'Traditional green tea',
            botanicalIngredients: ['Green Leaf'],
            waterTempCelsius: 85,
            steepTimeSeconds: 180,
            flavorProfile: 'Crisp & Floral',
          );
  }

  Color _parseAccentColor(String? hex) {
    if (hex == null || !hex.startsWith('#') || hex.length != 7) {
      return AppColors.orange;
    }
    final val = int.tryParse(hex.substring(1), radix: 16);
    return val != null ? Color(0xFF000000 | val) : AppColors.orange;
  }

  void _onStepTapped(int step) {
    HapticService.selection();
    setState(() {
      _activeKaytarishStep = step;
    });
    widget.onKaytarishStepChanged?.call(step);
  }

  void _onBlendTapped(TeaBlend blend) {
    HapticService.selection();
    setState(() {
      _selectedBlend = blend;
    });
  }

  @override
  Widget build(BuildContext context) {
    final accentColor = _parseAccentColor(widget.venue.accentColorHex);
    final steps = _engine.getKaytarishSteps();
    final currentStep = steps.firstWhere(
      (s) => s.stepNumber == _activeKaytarishStep,
      orElse: () => steps.first,
    );
    final proverb = _engine.formatKaytarishProverb(locale: widget.locale);
    final tapchanStatus = _engine.formatTapchanStatus(
      widget.venue.availableTapchans,
      widget.venue.totalTapchans,
      locale: widget.locale,
    );

    return Container(
      key: Key('chaykhana_ritual_card_${widget.venue.id}'),
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
          // Header: Venue Name, District, and Samovar Type
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
                  Icons.emoji_food_beverage_rounded,
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
                            'CHAYKHANA',
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
                            widget.venue.district,
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
                    Text(
                      widget.venue.localizedName(locale: widget.locale),
                      key: Key('venue_title_${widget.venue.id}'),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Tapchan Availability & Samovar Credentials Pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.paper,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.borderHairline),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.table_restaurant_rounded,
                      size: 15,
                      color: widget.venue.availableTapchans > 0
                          ? AppColors.mint
                          : AppColors.ink3,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      tapchanStatus,
                      key: const Key('tapchan_status_text'),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink,
                      ),
                    ),
                  ],
                ),
                Text(
                  widget.venue.chaykhanaUstoName,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.ink3,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // 3-Step Kaytarish Aeration Ritual Interactive Stepper
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.paper,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.borderHairline),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '3-Step Kaytarish Aeration',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink,
                      ),
                    ),
                    Text(
                      '${currentStep.oxygenationPercent}% Oxygenated',
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: accentColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // 3 Step Buttons
                Row(
                  children: steps.map((s) {
                    final isSelected = s.stepNumber == _activeKaytarishStep;
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 3),
                        child: GestureDetector(
                          key: Key('kaytarish_step_btn_${s.stepNumber}'),
                          behavior: HitTestBehavior.opaque,
                          onTap: () => _onStepTapped(s.stepNumber),
                          child: Container(
                            height: 32,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? accentColor
                                  : AppColors.cardSurface,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isSelected
                                    ? accentColor
                                    : AppColors.borderHairline,
                              ),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              '${s.stepNumber}. ${s.nameUz}',
                              style: GoogleFonts.jetBrainsMono(
                                fontSize: 11,
                                fontWeight: isSelected
                                    ? FontWeight.w800
                                    : FontWeight.w600,
                                color: isSelected
                                    ? Colors.white
                                    : AppColors.ink2,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 8),

                // Active Step Description
                Text(
                  currentStep.localizedTitle(locale: widget.locale),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  currentStep.descriptionEn,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: AppColors.ink3,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Folk Proverb Banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.format_quote_rounded,
                  size: 14,
                  color: accentColor,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    proverb,
                    key: const Key('chaykhana_proverb_text'),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      fontStyle: FontStyle.italic,
                      color: accentColor,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // Signature Tea Blends
          if (widget.venue.signatureBlends.isNotEmpty) ...[
            Text(
              'Signature Tea Blends',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 6),
            ...widget.venue.signatureBlends.map((blend) {
              final isSelected = _selectedBlend.id == blend.id;

              return GestureDetector(
                key: Key('tea_blend_${blend.id}'),
                behavior: HitTestBehavior.opaque,
                onTap: () => _onBlendTapped(blend),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? accentColor.withValues(alpha: 0.08)
                        : AppColors.paper,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? accentColor : AppColors.borderHairline,
                      width: isSelected ? 1.5 : 1.0,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              blend.name,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppColors.ink,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              blend.flavorProfile,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                                color: AppColors.ink3,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.paper2,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${blend.waterTempCelsius}°C • ${blend.steepTimeSeconds ~/ 60}m',
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: AppColors.ink2,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],

          const SizedBox(height: 10),

          // Reserve Tapchan Button
          GestureDetector(
            key: Key('reserve_tapchan_btn_${widget.venue.id}'),
            behavior: HitTestBehavior.opaque,
            onTap: widget.venue.availableTapchans <= 0 && !widget.isReserved
                ? null
                : () {
                    HapticService.selection();
                    widget.onTapchanReserved
                        ?.call(widget.venue, _selectedBlend);
                  },
            child: Container(
              height: 42,
              decoration: BoxDecoration(
                color: widget.isReserved
                    ? accentColor
                    : (widget.venue.availableTapchans <= 0
                        ? AppColors.paper2
                        : AppColors.ink),
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    widget.isReserved
                        ? (widget.locale == 'uz'
                            ? 'Tapchan band qilindi (+35 XP)'
                            : widget.locale == 'ru'
                                ? 'Тапчан забронирован (+35 XP)'
                                : 'Tapchan Reserved (+35 XP)')
                        : (widget.venue.availableTapchans <= 0
                            ? (widget.locale == 'uz'
                                ? 'Barcha tapchanlar band'
                                : widget.locale == 'ru'
                                    ? 'Все места заняты'
                                    : 'Fully Booked')
                            : (widget.locale == 'uz'
                                ? 'Tapchan yig\'ilishini o\'tkazish'
                                : widget.locale == 'ru'
                                    ? 'Собрать гостей на тапчан'
                                    : 'Host Tapchan Gathering (+35 XP)')),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: widget.venue.availableTapchans <= 0 &&
                              !widget.isReserved
                          ? AppColors.ink3
                          : Colors.white,
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
