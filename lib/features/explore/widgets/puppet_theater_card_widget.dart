import 'package:flutter/material.dart';
import 'package:around_app/core/constants/app_colors.dart';
import 'package:around_app/core/services/puppet_theater_engine.dart';

/// Interactive Puppet Theater Stage & Marionette Showcase Card Widget.
class PuppetTheaterCardWidget extends StatefulWidget {
  final PuppetTheaterStage stage;
  final bool isReserved;
  final String languageCode;
  final void Function(PuppetPerformance performance, int seatsCount)? onReserveTickets;
  final VoidCallback? onTapDetails;

  const PuppetTheaterCardWidget({
    super.key,
    required this.stage,
    this.isReserved = false,
    this.languageCode = 'en',
    this.onReserveTickets,
    this.onTapDetails,
  });

  @override
  State<PuppetTheaterCardWidget> createState() => _PuppetTheaterCardWidgetState();
}

class _PuppetTheaterCardWidgetState extends State<PuppetTheaterCardWidget> {
  late PuppetPerformance _selectedPerformance;
  int _seatsCount = 1;

  @override
  void initState() {
    super.initState();
    _selectedPerformance = widget.stage.repertoire.isNotEmpty
        ? widget.stage.repertoire.first
        : const PuppetPerformance(
            id: 'fallback-show',
            titleEn: 'Folk Puppetry Showcase',
            titleUz: 'Xalq qo\'g\'irchoq tomoshasi',
            titleRu: 'Народный кукольный спектакль',
            puppetType: PuppetType.chodirJamol,
            durationMinutes: 45,
            ticketPriceUzs: 35000,
            minimumAge: 4,
            scheduleTime: '12:00 PM',
            synopsis: 'Lively showcase of traditional glove puppetry.',
          );
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

  String _getReserveButtonLabel() {
    if (widget.isReserved) {
      switch (widget.languageCode.toLowerCase()) {
        case 'uz':
          return 'Band qilingan (+35 XP)';
        case 'ru':
          return 'Забронировано (+35 XP)';
        case 'en':
        default:
          return 'Reserved (+35 XP)';
      }
    } else if (widget.stage.availableSeats <= 0) {
      switch (widget.languageCode.toLowerCase()) {
        case 'uz':
          return 'Joylar to\'lgan';
        case 'ru':
          return 'Мест нет';
        case 'en':
        default:
          return 'Sold Out';
      }
    } else {
      switch (widget.languageCode.toLowerCase()) {
        case 'uz':
          return 'Chipta band qilish (+35 XP)';
        case 'ru':
          return 'Забронировать (+35 XP)';
        case 'en':
        default:
          return 'Reserve Tickets (+35 XP)';
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const velvetCrimson = Color(0xFF881337);
    const crimsonBg = Color(0xFFFFF1F2);
    const goldAccent = Color(0xFFD97706);
    final hasSeats = widget.stage.availableSeats > 0;
    final totalPrice = _selectedPerformance.ticketPriceUzs * _seatsCount;

    return Container(
      key: Key('puppet_theater_card_${widget.stage.id}'),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: velvetCrimson.withValues(alpha: 0.25),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: velvetCrimson.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: widget.onTapDetails,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header: Stage Title, District & Curtain Badge
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: crimsonBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: velvetCrimson.withValues(alpha: 0.4),
                          width: 1,
                        ),
                      ),
                      child: const Icon(
                        Icons.theater_comedy,
                        color: velvetCrimson,
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.stage.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              letterSpacing: -0.2,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '${widget.stage.district} • Est. ${widget.stage.foundedYear}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.ink2,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: goldAccent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${widget.stage.availableSeats} seats',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: goldAccent,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Chief Master Attribution
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: crimsonBg.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.handyman_outlined,
                        size: 14,
                        color: velvetCrimson,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Chief Puppeteer: ${widget.stage.chiefMaster}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: velvetCrimson,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                // Repertoire Show Selector Chips
                const Text(
                  'Current Repertoire',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.ink2,
                  ),
                ),
                const SizedBox(height: 8),

                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: widget.stage.repertoire.map((perf) {
                    final isSelected = perf.id == _selectedPerformance.id;
                    return ChoiceChip(
                      key: Key('repertoire_chip_${perf.id}'),
                      label: Text(perf.localizedTitle(widget.languageCode)),
                      selected: isSelected,
                      selectedColor: crimsonBg,
                      backgroundColor: Theme.of(context).cardColor,
                      labelStyle: TextStyle(
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected ? velvetCrimson : AppColors.ink,
                      ),
                      side: BorderSide(
                        color: isSelected
                            ? velvetCrimson
                            : AppColors.borderSubtle,
                      ),
                      onSelected: (selected) {
                        if (selected) {
                          setState(() {
                            _selectedPerformance = perf;
                          });
                        }
                      },
                    );
                  }).toList(),
                ),

                const SizedBox(height: 12),

                // Selected Show Details Card
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: AppColors.borderHairline,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.schedule, size: 14, color: velvetCrimson),
                              const SizedBox(width: 4),
                              Text(
                                _selectedPerformance.scheduleTime,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '(${_selectedPerformance.durationMinutes} min)',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.ink3,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: velvetCrimson.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'Age ${_selectedPerformance.minimumAge}+',
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: velvetCrimson,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _selectedPerformance.synopsis,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.ink2,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                // Featured Marionette Highlight
                if (widget.stage.signatureFigures.isNotEmpty) ...[
                  Row(
                    children: [
                      const Icon(Icons.person_pin_outlined, size: 14, color: goldAccent),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Featured Puppet: ${widget.stage.signatureFigures.first.localizedName(widget.languageCode)}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        widget.stage.signatureFigures.first.carvingWood.localizedName(widget.languageCode),
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.ink3,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                ],

                // Seats Counter & Price Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Total Price',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.ink3,
                          ),
                        ),
                        Text(
                          _formatPriceUzs(totalPrice),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: velvetCrimson,
                          ),
                        ),
                      ],
                    ),

                    // Counter (- / +)
                    Row(
                      children: [
                        IconButton(
                          key: const Key('decrement_seats_button'),
                          icon: const Icon(Icons.remove_circle_outline),
                          iconSize: 22,
                          color: _seatsCount > 1
                              ? velvetCrimson
                              : AppColors.inkLight,
                          onPressed: _seatsCount > 1
                              ? () => setState(() => _seatsCount--)
                              : null,
                        ),
                        Text(
                          '$_seatsCount',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          key: const Key('increment_seats_button'),
                          icon: const Icon(Icons.add_circle_outline),
                          iconSize: 22,
                          color: _seatsCount < 6
                              ? velvetCrimson
                              : AppColors.inkLight,
                          onPressed: _seatsCount < 6
                              ? () => setState(() => _seatsCount++)
                              : null,
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                // Reservation CTA Button
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton(
                    key: const Key('reserve_puppet_tickets_button'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: velvetCrimson,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 0,
                    ),
                    onPressed: (hasSeats && !widget.isReserved)
                        ? () {
                            widget.onReserveTickets?.call(
                              _selectedPerformance,
                              _seatsCount,
                            );
                          }
                        : null,
                    child: Text(
                      _getReserveButtonLabel(),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
