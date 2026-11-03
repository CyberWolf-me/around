import 'package:flutter/material.dart';
import 'package:around_app/core/constants/app_colors.dart';
import 'package:around_app/core/services/silk_paper_calligraphy_engine.dart';

/// Interactive Silk Paper Atelier & Calligraphy Masterclass Card Widget.
class SilkPaperCardWidget extends StatefulWidget {
  final SilkPaperAtelier atelier;
  final bool isReserved;
  final String languageCode;
  final ValueChanged<CalligraphyScript>? onReserveMasterclass;
  final VoidCallback? onTapDetails;

  const SilkPaperCardWidget({
    super.key,
    required this.atelier,
    this.isReserved = false,
    this.languageCode = 'en',
    this.onReserveMasterclass,
    this.onTapDetails,
  });

  @override
  State<SilkPaperCardWidget> createState() => _SilkPaperCardWidgetState();
}

class _SilkPaperCardWidgetState extends State<SilkPaperCardWidget> {
  late CalligraphyScript _selectedScript;
  PaperCraftStage _selectedStage = PaperCraftStage.burnishing;

  @override
  void initState() {
    super.initState();
    _selectedScript = widget.atelier.supportedScripts.isNotEmpty
        ? widget.atelier.supportedScripts.first
        : CalligraphyScript.nastaliq;
  }

  String _formatPriceUzs(int price) {
    final str = price.toString();
    final buffer = StringBuffer();
    int count = 0;
    for (int i = str.length - 1; i >= 0; i--) {
      buffer.write(str[i]);
      count++;
      if (count % 3 == 0 && i != 0) {
        buffer.write(' ');
      }
    }
    return '${buffer.toString().split('').reversed.join('')} UZS';
  }

  String _getSeatsLabel() {
    switch (widget.languageCode.toLowerCase()) {
      case 'uz':
        return '${widget.atelier.availableMasterclasses} / ${widget.atelier.maxCapacity} ta joy ochiq';
      case 'ru':
        return '${widget.atelier.availableMasterclasses} из ${widget.atelier.maxCapacity} мест свободно';
      case 'en':
      default:
        return '${widget.atelier.availableMasterclasses} of ${widget.atelier.maxCapacity} seats open';
    }
  }

  String _getReserveButtonLabel() {
    if (widget.isReserved) {
      switch (widget.languageCode.toLowerCase()) {
        case 'uz':
          return "Band qilingan (+35 XP)";
        case 'ru':
          return 'Забронировано (+35 XP)';
        case 'en':
        default:
          return 'Reserved (+35 XP)';
      }
    } else if (widget.atelier.availableMasterclasses <= 0) {
      switch (widget.languageCode.toLowerCase()) {
        case 'uz':
          return 'Barcha joylar band';
        case 'ru':
          return 'Все места заняты';
        case 'en':
        default:
          return 'Fully Booked';
      }
    } else {
      switch (widget.languageCode.toLowerCase()) {
        case 'uz':
          return "Joyni band qilish (+35 XP)";
        case 'ru':
          return 'Забронировать место (+35 XP)';
        case 'en':
        default:
          return 'Reserve Workshop (+35 XP)';
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const goldAccent = Color(0xFFD97706);
    const goldBg = Color(0xFFFEF3C7);
    final isFull = widget.atelier.availableMasterclasses <= 0;

    return Container(
      key: Key('silk_paper_card_${widget.atelier.id}'),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: widget.isReserved ? goldAccent.withAlpha(120) : AppColors.borderSubtle,
          width: widget.isReserved ? 1.5 : 1.0,
        ),
        boxShadow: const [AppColors.shadowCard],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: widget.onTapDetails,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header: District Tag and Reservation Badge
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      key: const Key('district_badge'),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: goldBg,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.history_edu, size: 14, color: goldAccent),
                          const SizedBox(width: 4),
                          Text(
                            widget.atelier.district,
                            style: const TextStyle(
                              color: goldAccent,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (widget.isReserved)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.mintSubtle,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.check_circle, size: 14, color: Color(0xFF1B8755)),
                            SizedBox(width: 4),
                            Text(
                              'ENROLLED',
                              style: TextStyle(
                                color: Color(0xFF1B8755),
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),

                // Atelier Title
                Text(
                  widget.atelier.name,
                  style: const TextStyle(
                    color: AppColors.ink,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 2),

                // Master Craftsman Attribution
                Text(
                  widget.atelier.masterName,
                  style: const TextStyle(
                    color: AppColors.ink2,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),

                // Century Legacy Banner
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.paper2,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    widget.atelier.centuryTradition,
                    style: const TextStyle(
                      color: AppColors.ink2,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Mulberry Variety & Burnishing Stone Pills
                Row(
                  children: [
                    const Icon(Icons.eco_outlined, size: 13, color: AppColors.ink3),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        widget.atelier.mulberryVariety,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: AppColors.ink3, fontSize: 11),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.diamond_outlined, size: 13, color: AppColors.ink3),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        widget.atelier.burnishStoneType,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: AppColors.ink3, fontSize: 11),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Supported Calligraphy Scripts Selector
                const Text(
                  'Select Script for Masterclass:',
                  style: TextStyle(
                    color: AppColors.ink,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: widget.atelier.supportedScripts.map((script) {
                    final isSelected = _selectedScript == script;
                    return InkWell(
                      key: Key('script_pill_${script.id}'),
                      borderRadius: BorderRadius.circular(8),
                      onTap: () {
                        setState(() {
                          _selectedScript = script;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.ink : AppColors.paper2,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isSelected ? AppColors.ink : AppColors.borderSubtle,
                          ),
                        ),
                        child: Text(
                          script.localizedName(widget.languageCode),
                          style: TextStyle(
                            color: isSelected ? Colors.white : AppColors.ink2,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),

                // 4-Stage Craft Timeline Navigator
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceWarm,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.borderHairline),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Stage ${_selectedStage.stepNumber} of 4: ${_selectedStage.localizedName(widget.languageCode)}',
                            style: const TextStyle(
                              color: AppColors.ink,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            '${_selectedStage.durationHours}h',
                            style: const TextStyle(
                              color: goldAccent,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: PaperCraftStage.values.map((stage) {
                          final isCurrent = _selectedStage == stage;
                          return Expanded(
                            child: InkWell(
                              onTap: () {
                                setState(() {
                                  _selectedStage = stage;
                                });
                              },
                              child: Container(
                                height: 5,
                                margin: const EdgeInsets.symmetric(horizontal: 2),
                                decoration: BoxDecoration(
                                  color: isCurrent ? goldAccent : AppColors.borderSubtle,
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _selectedStage.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.ink2,
                          fontSize: 11,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Pricing, Capacity & Reservation CTA
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _formatPriceUzs(widget.atelier.workshopPriceUzs),
                          style: const TextStyle(
                            color: AppColors.ink,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          _getSeatsLabel(),
                          style: TextStyle(
                            color: isFull ? AppColors.danger : AppColors.ink3,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    ElevatedButton.icon(
                      key: const Key('reserve_masterclass_button'),
                      onPressed: (widget.isReserved || isFull)
                          ? null
                          : () {
                              if (widget.onReserveMasterclass != null) {
                                widget.onReserveMasterclass!(_selectedScript);
                              }
                            },
                      icon: Icon(
                        widget.isReserved ? Icons.check_circle : Icons.draw_outlined,
                        size: 16,
                        color: widget.isReserved ? AppColors.ink3 : Colors.white,
                      ),
                      label: Text(
                        _getReserveButtonLabel(),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: widget.isReserved ? AppColors.ink3 : Colors.white,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: widget.isReserved ? AppColors.paper3 : goldAccent,
                        disabledBackgroundColor: AppColors.paper3,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        elevation: 0,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
