import 'package:flutter/material.dart';
import 'package:around_app/core/constants/app_colors.dart';
import 'package:around_app/core/services/tandoor_bakery_engine.dart';

/// Interactive Tandoor Bakery & Fresh Bread Batch Card Widget.
class TandoorBreadCardWidget extends StatefulWidget {
  final TandoorBakeryVenue bakery;
  final bool isReserved;
  final String languageCode;
  final void Function(BreadVariety variety, int count)? onReserveBatch;
  final VoidCallback? onTapDetails;

  const TandoorBreadCardWidget({
    super.key,
    required this.bakery,
    this.isReserved = false,
    this.languageCode = 'en',
    this.onReserveBatch,
    this.onTapDetails,
  });

  @override
  State<TandoorBreadCardWidget> createState() => _TandoorBreadCardWidgetState();
}

class _TandoorBreadCardWidgetState extends State<TandoorBreadCardWidget> {
  late BreadVariety _selectedVariety;
  int _loavesCount = 2;

  @override
  void initState() {
    super.initState();
    _selectedVariety = widget.bakery.signatureBreads.isNotEmpty
        ? widget.bakery.signatureBreads.first
        : BreadVariety.obiNon;
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

  String _getFreshnessLabel() {
    if (widget.bakery.currentBatchHotLoaves > 0) {
      switch (widget.languageCode.toLowerCase()) {
        case 'uz':
          return 'Tandirdan uzilgan (${widget.bakery.currentBatchHotLoaves} ta issiq)';
        case 'ru':
          return 'С пылу с жару (${widget.bakery.currentBatchHotLoaves} гор. лепешек)';
        case 'en':
        default:
          return 'Piping Hot (${widget.bakery.currentBatchHotLoaves} hot loaves)';
      }
    } else {
      switch (widget.languageCode.toLowerCase()) {
        case 'uz':
          return 'Navbatdagi tandir ${widget.bakery.nextBatchMinutes} daqiqada';
        case 'ru':
          return 'Следующая выпечка через ${widget.bakery.nextBatchMinutes} мин.';
        case 'en':
        default:
          return 'Next hot batch in ${widget.bakery.nextBatchMinutes} min';
      }
    }
  }

  String _getReserveButtonLabel() {
    if (widget.isReserved) {
      switch (widget.languageCode.toLowerCase()) {
        case 'uz':
          return 'Band qilingan (+30 XP)';
        case 'ru':
          return 'Забронировано (+30 XP)';
        case 'en':
        default:
          return 'Reserved (+30 XP)';
      }
    } else if (widget.bakery.currentBatchHotLoaves <= 0) {
      switch (widget.languageCode.toLowerCase()) {
        case 'uz':
          return 'Kutilmoqda';
        case 'ru':
          return 'В ожидании';
        case 'en':
        default:
          return 'Baking Batch';
      }
    } else {
      switch (widget.languageCode.toLowerCase()) {
        case 'uz':
          return 'Nonni band qilish (+30 XP)';
        case 'ru':
          return 'Забронировать (+30 XP)';
        case 'en':
        default:
          return 'Reserve Hot Bread (+30 XP)';
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const terracotta = Color(0xFFEA580C);
    const terracottaBg = Color(0xFFFFEDD5);
    final hasHotLoaves = widget.bakery.currentBatchHotLoaves > 0;
    final totalPrice = _selectedVariety.defaultPriceUzs * _loavesCount;

    return Container(
      key: Key('tandoor_bakery_card_${widget.bakery.id}'),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: widget.isReserved ? terracotta.withAlpha(120) : AppColors.borderSubtle,
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
                // Header: District Badge & Hot Loaves Status
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      key: const Key('bakery_district_badge'),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: terracottaBg,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.bakery_dining_outlined, size: 14, color: terracotta),
                          const SizedBox(width: 4),
                          Text(
                            widget.bakery.district,
                            style: const TextStyle(
                              color: terracotta,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      key: const Key('freshness_status_badge'),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: hasHotLoaves ? AppColors.mintSubtle : AppColors.paper2,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            hasHotLoaves ? Icons.local_fire_department : Icons.schedule,
                            size: 13,
                            color: hasHotLoaves ? const Color(0xFF1B8755) : AppColors.ink3,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _getFreshnessLabel(),
                            style: TextStyle(
                              color: hasHotLoaves ? const Color(0xFF1B8755) : AppColors.ink2,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Bakery Name & Head Baker
                Text(
                  widget.bakery.name,
                  style: const TextStyle(
                    color: AppColors.ink,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  widget.bakery.headBaker,
                  style: const TextStyle(
                    color: AppColors.ink2,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),

                // Tandoor Clay Origin & Chekich Stamp Summary
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.paper2,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.terrain_outlined, size: 12, color: AppColors.ink3),
                          const SizedBox(width: 4),
                          Text(
                            widget.bakery.tandoorClayOrigin,
                            style: const TextStyle(color: AppColors.ink2, fontSize: 11, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: terracotta.withAlpha(20),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.stars, size: 12, color: terracotta),
                          const SizedBox(width: 4),
                          Text(
                            widget.bakery.favoriteChekich.localizedName(widget.languageCode),
                            style: const TextStyle(color: terracotta, fontSize: 11, fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Signature Bread Variety Selector
                const Text(
                  'Signature Breads from Tandoor:',
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
                  children: widget.bakery.signatureBreads.map((variety) {
                    final isSelected = _selectedVariety == variety;
                    return InkWell(
                      key: Key('variety_pill_${variety.id}'),
                      borderRadius: BorderRadius.circular(8),
                      onTap: () {
                        setState(() {
                          _selectedVariety = variety;
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
                          variety.localizedName(widget.languageCode),
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
                const SizedBox(height: 8),

                // Selected Variety Description & Oven Temp
                Text(
                  _selectedVariety.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.ink2,
                    fontSize: 12,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 14),

                // Loaves Quantity Selector & Reservation Action
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Quantity Counter (- / +)
                    Row(
                      children: [
                        IconButton(
                          key: const Key('decrement_loaves_button'),
                          icon: const Icon(Icons.remove_circle_outline, size: 20),
                          color: _loavesCount > 1 ? AppColors.ink : AppColors.ink3,
                          onPressed: _loavesCount > 1
                              ? () {
                                  setState(() {
                                    _loavesCount--;
                                  });
                                }
                              : null,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Text(
                            '$_loavesCount',
                            key: const Key('loaves_count_display'),
                            style: const TextStyle(
                              color: AppColors.ink,
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        IconButton(
                          key: const Key('increment_loaves_button'),
                          icon: const Icon(Icons.add_circle_outline, size: 20),
                          color: _loavesCount < 10 ? AppColors.ink : AppColors.ink3,
                          onPressed: _loavesCount < 10
                              ? () {
                                  setState(() {
                                    _loavesCount++;
                                  });
                                }
                              : null,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _formatPriceUzs(totalPrice),
                          style: const TextStyle(
                            color: AppColors.ink,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),

                    // Reserve Button
                    ElevatedButton.icon(
                      key: const Key('reserve_bread_button'),
                      onPressed: (widget.isReserved || !hasHotLoaves)
                          ? null
                          : () {
                              if (widget.onReserveBatch != null) {
                                widget.onReserveBatch!(_selectedVariety, _loavesCount);
                              }
                            },
                      icon: Icon(
                        widget.isReserved ? Icons.check_circle : Icons.bakery_dining,
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
                        backgroundColor: widget.isReserved ? AppColors.paper3 : terracotta,
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
