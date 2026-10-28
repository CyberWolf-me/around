import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/place_model.dart';
import '../../../data/services/haptic_service.dart';

class CityMapWidget extends StatelessWidget {
  final List<PlaceModel> places;
  final String? selectedPlaceId;
  final Function(String placeId) onSelectPlace;

  const CityMapWidget({
    super.key,
    required this.places,
    this.selectedPlaceId,
    required this.onSelectPlace,
  });

  // Relative pin coordinates normalized 0.0 to 1.0 for the Tashkent / Barlow Hill map
  static const Map<String, Offset> pinPositions = {
    'kettle': Offset(0.35, 0.58),
    'fern': Offset(0.52, 0.33),
    'sable': Offset(0.73, 0.62),
    'castellan': Offset(0.12, 0.26),
    'volta': Offset(0.44, 0.76),
    'noodle': Offset(0.63, 0.43),
    'marigold': Offset(0.86, 0.35),
    'longtable': Offset(0.22, 0.77),
    'quiet': Offset(0.31, 0.19),
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFF3F0E4),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.ink, width: 2),
        boxShadow: const [AppColors.shadow],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final w = constraints.maxWidth;
            final h = constraints.maxHeight;

            return Stack(
              children: [
                // Vector background canvas (City blocks, parks, diagonals)
                CustomPaint(
                  size: Size(w, h),
                  painter: _MapCanvasPainter(),
                ),

                // Street labels
                const Positioned(
                  top: 24,
                  left: 36,
                  child: Text(
                    'SHOTA RUSTAVELI AVE',
                    style: TextStyle(
                      fontFamily: 'SpaceMono',
                      fontSize: 7.5,
                      letterSpacing: 1.0,
                      color: Color(0x7015130F),
                    ),
                  ),
                ),
                const Positioned(
                  bottom: 30,
                  right: 40,
                  child: Text(
                    'AMIR TIMUR STREET',
                    style: TextStyle(
                      fontFamily: 'SpaceMono',
                      fontSize: 7,
                      letterSpacing: 0.8,
                      color: Color(0x6015130F),
                    ),
                  ),
                ),

                // User Location Dot
                Positioned(
                  left: w * 0.47 - 7,
                  top: h * 0.52 - 7,
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.orange,
                      border: Border.all(color: Colors.white, width: 2.5),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.orange.withOpacity(0.5),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),
                ),

                // Venue Pins
                ...places.map((place) {
                  final pos = pinPositions[place.id] ?? const Offset(0.5, 0.5);
                  final isSelected = selectedPlaceId == place.id;
                  final double pinSize = isSelected ? 34.0 : 26.0;

                  return Positioned(
                    left: w * pos.dx - (pinSize / 2),
                    top: h * pos.dy - (pinSize / 2),
                    child: GestureDetector(
                      onTap: () {
                        HapticService.selection();
                        onSelectPlace(place.id);
                      },
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: pinSize,
                            height: pinSize,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                              border: Border.all(
                                color: isSelected ? AppColors.orange : AppColors.ink,
                                width: isSelected ? 2.5 : 2.0,
                              ),
                              boxShadow: const [AppColors.shadowSm],
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: Image.asset(
                              place.heroImageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const Icon(Icons.place, size: 14),
                            ),
                          ),
                          if (isSelected)
                            Container(
                              margin: const EdgeInsets.only(top: 3),
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.ink,
                                borderRadius: BorderRadius.circular(5),
                                boxShadow: const [AppColors.shadowSm],
                              ),
                              child: Text(
                                place.name,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 8.5,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'SpaceMono',
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _MapCanvasPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final blockPaint = Paint()
      ..color = const Color(0xFFE9E4D5)
      ..style = PaintingStyle.fill;

    final parkPaint = Paint()
      ..color = const Color(0xFFCFE2C4)
      ..style = PaintingStyle.fill;

    final waterPaint = Paint()
      ..color = const Color(0xFFCBDCE7)
      ..style = PaintingStyle.fill;

    final roadBorderPaint = Paint()
      ..color = const Color(0x3015130F)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    // Draw blocks grid
    const cols = 5;
    const rows = 4;
    final blockW = (size.width - 24) / cols;
    final blockH = (size.height - 20) / rows;

    for (int i = 0; i < cols; i++) {
      for (int j = 0; j < rows; j++) {
        final rect = Rect.fromLTWH(
          4 + (i * (blockW + 4)),
          4 + (j * (blockH + 4)),
          blockW,
          blockH,
        );

        Paint currentPaint = blockPaint;
        if (i == 2 && j == 1) currentPaint = parkPaint; // Tashkent Central Park
        if (i == 3 && j == 2) currentPaint = waterPaint; // Anhor Canal

        canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(3)), currentPaint);
        canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(3)), roadBorderPaint);
      }
    }

    // Diagonal arterial roads
    final roadPaint = Paint()
      ..color = const Color(0xFFFBFAF6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10.0
      ..strokeCap = StrokeCap.round;

    final roadBorder = Paint()
      ..color = const Color(0x3515130F)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;

    final path = Path()
      ..moveTo(-4, size.height * 0.9)
      ..lineTo(size.width * 0.42, size.height * 0.48)
      ..lineTo(size.width * 0.8, size.height * 0.48);

    canvas.drawPath(path, roadPaint);
    canvas.drawPath(path, roadBorder);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
