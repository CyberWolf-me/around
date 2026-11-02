import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/bouncing_widget.dart';
import '../../../data/models/place_model.dart';
import '../../../data/services/haptic_service.dart';

class CityMapWidget extends StatefulWidget {
  final List<PlaceModel> places;
  final String? selectedPlaceId;
  final Function(String placeId) onSelectPlace;

  const CityMapWidget({
    super.key,
    required this.places,
    this.selectedPlaceId,
    required this.onSelectPlace,
  });

  @override
  State<CityMapWidget> createState() => _CityMapWidgetState();
}

class _CityMapWidgetState extends State<CityMapWidget> {
  final MapController _mapController = MapController();
  static const LatLng _tashkentCenter = LatLng(41.3111, 69.2797);

  static const String _tileUrlTemplate = String.fromEnvironment(
    'MAP_TILE_URL',
    defaultValue: 'https://basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}.png',
  );

  @override
  void didUpdateWidget(covariant CityMapWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedPlaceId != oldWidget.selectedPlaceId && widget.selectedPlaceId != null) {
      final match = widget.places.where((p) => p.id == widget.selectedPlaceId).firstOrNull;
      if (match != null) {
        _mapController.move(LatLng(match.latitude, match.longitude), 14.5);
      }
    }
  }

  void _zoomIn() {
    final zoom = _mapController.camera.zoom + 1.0;
    _mapController.move(_mapController.camera.center, zoom.clamp(10.0, 18.0));
  }

  void _zoomOut() {
    final zoom = _mapController.camera.zoom - 1.0;
    _mapController.move(_mapController.camera.center, zoom.clamp(10.0, 18.0));
  }

  void _recenterTashkent() {
    HapticService.medium();
    _mapController.move(_tashkentCenter, 13.5);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.paper2,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderSubtle, width: 1.0),
        boxShadow: const [AppColors.shadowCard],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: const MapOptions(
              initialCenter: _tashkentCenter,
              initialZoom: 13.5,
              minZoom: 10.0,
              maxZoom: 18.0,
              interactionOptions: InteractionOptions(
                flags: InteractiveFlag.all,
              ),
            ),
            children: [
              TileLayer(
                urlTemplate: _tileUrlTemplate,
                userAgentPackageName: 'com.around.around_app',
                maxZoom: 19,
              ),
              MarkerLayer(
                markers: widget.places.map((place) {
                  final isSelected = place.id == widget.selectedPlaceId;
                  return Marker(
                    point: LatLng(place.latitude, place.longitude),
                    width: isSelected ? 140 : 100,
                    height: isSelected ? 48 : 36,
                    child: BouncingWidget(
                      scaleFactor: 0.94,
                      onTap: () {
                        widget.onSelectPlace(place.id);
                        _mapController.move(LatLng(place.latitude, place.longitude), 14.5);
                      },
                      child: AnimatedScale(
                        duration: const Duration(milliseconds: 200),
                        scale: isSelected ? 1.08 : 0.96,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.orange : Colors.white,
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: isSelected ? AppColors.orange : AppColors.borderSubtle,
                              width: 1.2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: isSelected
                                    ? AppColors.orange.withValues(alpha: 0.35)
                                    : Colors.black.withValues(alpha: 0.12),
                                blurRadius: isSelected ? 8 : 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                isSelected ? Icons.place_rounded : Icons.location_on_rounded,
                                size: isSelected ? 15 : 12,
                                color: isSelected ? Colors.white : AppColors.ink,
                              ),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  place.name.split(' ').first,
                                  style: GoogleFonts.instrumentSans(
                                    fontSize: isSelected ? 11.5 : 10.5,
                                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                                    color: isSelected ? Colors.white : AppColors.ink,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
          Positioned(
            top: 12,
            left: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.92),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: AppColors.borderHairline),
                boxShadow: const [AppColors.shadowSubtle],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.orange,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Tashkent, UZ · Live Map',
                    style: GoogleFonts.spaceMono(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 12,
            right: 12,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _MapControlButton(
                  icon: Icons.add_rounded,
                  tooltip: 'Zoom In',
                  onTap: _zoomIn,
                ),
                const SizedBox(height: 6),
                _MapControlButton(
                  icon: Icons.remove_rounded,
                  tooltip: 'Zoom Out',
                  onTap: _zoomOut,
                ),
                const SizedBox(height: 6),
                _MapControlButton(
                  icon: Icons.my_location_rounded,
                  tooltip: 'Recenter Tashkent',
                  onTap: _recenterTashkent,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MapControlButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const _MapControlButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: BouncingWidget(
        scaleFactor: 0.9,
        onTap: onTap,
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.94),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.borderHairline),
            boxShadow: const [AppColors.shadowSubtle],
          ),
          child: Icon(icon, size: 18, color: AppColors.ink),
        ),
      ),
    );
  }
}
