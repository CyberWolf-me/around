import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/constants/app_colors.dart';
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
    HapticService.light();
    final zoom = _mapController.camera.zoom + 1.0;
    _mapController.move(_mapController.camera.center, zoom.clamp(10.0, 18.0));
  }

  void _zoomOut() {
    HapticService.light();
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
        color: const Color(0xFFF3F0E4),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.ink, width: 2),
        boxShadow: const [AppColors.shadow],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Real OpenStreetMap Tile Layer
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
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.around.around_app',
                maxZoom: 19,
              ),
              MarkerLayer(
                markers: widget.places.map((place) {
                  final isSelected = place.id == widget.selectedPlaceId;
                  return Marker(
                    point: LatLng(place.latitude, place.longitude),
                    width: isSelected ? 140 : 100,
                    height: isSelected ? 50 : 36,
                    child: GestureDetector(
                      onTap: () {
                        HapticService.selection();
                        widget.onSelectPlace(place.id);
                        _mapController.move(LatLng(place.latitude, place.longitude), 14.5);
                      },
                      child: AnimatedScale(
                        duration: const Duration(milliseconds: 200),
                        scale: isSelected ? 1.08 : 0.95,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.orange : AppColors.paper,
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: AppColors.ink,
                              width: isSelected ? 2.2 : 1.5,
                            ),
                            boxShadow: const [AppColors.shadowSm],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                isSelected ? Icons.place : Icons.location_on_outlined,
                                size: isSelected ? 16 : 13,
                                color: isSelected ? Colors.white : AppColors.ink,
                              ),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  place.name.split(' ').first,
                                  style: TextStyle(
                                    fontSize: isSelected ? 11.5 : 10.0,
                                    fontWeight: FontWeight.bold,
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

          // Tashkent Live Indicator Pill (Top Left)
          Positioned(
            top: 10,
            left: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.paper,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: AppColors.ink, width: 1.5),
                boxShadow: const [AppColors.shadowSm],
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
                  const Text(
                    'Tashkent, UZ · OpenStreetMap',
                    style: TextStyle(
                      fontFamily: 'SpaceMono',
                      fontSize: 9.5,
                      fontWeight: FontWeight.bold,
                      color: AppColors.ink,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Zoom & Recenter Controls (Bottom Right)
          Positioned(
            bottom: 10,
            right: 10,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _MapControlButton(
                  icon: Icons.add,
                  tooltip: 'Zoom In',
                  onTap: _zoomIn,
                ),
                const SizedBox(height: 6),
                _MapControlButton(
                  icon: Icons.remove,
                  tooltip: 'Zoom Out',
                  onTap: _zoomOut,
                ),
                const SizedBox(height: 6),
                _MapControlButton(
                  icon: Icons.my_location,
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
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: AppColors.paper,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.ink, width: 1.8),
            boxShadow: const [AppColors.shadowSm],
          ),
          child: Icon(icon, size: 18, color: AppColors.ink),
        ),
      ),
    );
  }
}
