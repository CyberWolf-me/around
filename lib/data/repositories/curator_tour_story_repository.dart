import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/app_logger.dart';
import '../../core/services/curator_tour_story_engine.dart';
import '../services/supabase_service.dart';

/// Repository for retrieving and managing curator audio walking tours.
class CuratorTourStoryRepository {
  final CuratorTourStoryEngine _engine;

  CuratorTourStoryRepository({CuratorTourStoryEngine? engine})
      : _engine = engine ?? CuratorTourStoryEngine();

  /// Access underlying engine.
  CuratorTourStoryEngine get engine => _engine;

  /// Fetches complete tour details including ordered chapters and curator info.
  Future<CuratorTour?> getCuratorTourDetails(String tourId) async {
    if (!SupabaseService.isInitialized) {
      return _buildOfflineTour(tourId);
    }

    try {
      final res = await SupabaseService.client.rpc(
        'get_curator_tour_details',
        params: {'p_tour_id': tourId},
      );

      if (res is Map<String, dynamic> && res['success'] == true) {
        final tourData = res['tour'] as Map<String, dynamic>?;
        if (tourData != null) {
          return CuratorTour.fromJson(tourData);
        }
      }

      return _buildOfflineTour(tourId);
    } catch (e) {
      AppLogger.warn(
        'CuratorTourStoryRepository',
        'Failed to fetch tour details via RPC, using offline fallback',
        e,
      );
      return _buildOfflineTour(tourId);
    }
  }

  /// Fetches tours for a district, falling back to local seeds when offline.
  Future<List<CuratorTour>> getDistrictTours({String? district}) async {
    final allTours = [
      _buildModernismTour(),
      _buildChorsuSpiceTour(),
    ];

    if (district == null || district.trim().isEmpty || district.toLowerCase() == 'all') {
      return allTours;
    }

    final query = district.trim().toLowerCase();
    final matching = allTours.where((t) => t.district.toLowerCase() == query).toList();
    return matching.isNotEmpty ? matching : allTours;
  }

  CuratorTour _buildOfflineTour(String tourId) {
    if (tourId.toLowerCase().contains('chorsu') || tourId.toLowerCase().contains('spice')) {
      return _buildChorsuSpiceTour();
    }
    return _buildModernismTour();
  }

  CuratorTour _buildModernismTour() {
    return const CuratorTour(
      id: 'tour-tashkent-modernism',
      title: 'Tashkent Modernism & Cosmic Mosaics',
      subtitle: 'Walking through post-earthquake Soviet modernist landmarks and cobalt metro halls',
      curatorId: 'u-aziza',
      curatorName: 'Aziza Tursunova',
      district: 'Central',
      estimatedWalkingMinutes: 50,
      xpReward: 120,
      stops: [
        TourStopStory(
          id: 'stop-modernism-1',
          tourId: 'tour-tashkent-modernism',
          chapterIndex: 1,
          title: 'Cosmic Mosaic Portal',
          venueId: 'pl-kosmonavtlar',
          venueName: 'Kosmonavtlar Metro Hall',
          latitude: 41.3094,
          longitude: 69.2678,
          triggerRadiusMeters: 50.0,
          audioUrl: 'https://cdn.around.uz/audio/tour-ch1.m4a',
          durationSeconds: 180,
          transcript: 'Look up at the deep cobalt glass panels honoring early space pioneers.',
          curatorNotes: 'Stand directly under the blue medallion near the western stairs.',
        ),
        TourStopStory(
          id: 'stop-modernism-2',
          tourId: 'tour-tashkent-modernism',
          chapterIndex: 2,
          title: 'Paxtakor Concrete Geometry',
          venueId: 'pl-paxtakor',
          venueName: 'Paxtakor Metro Pavilion',
          latitude: 41.3135,
          longitude: 69.2562,
          triggerRadiusMeters: 60.0,
          audioUrl: 'https://cdn.around.uz/audio/tour-ch2.m4a',
          durationSeconds: 210,
          transcript: 'Stylized cotton blossom motifs carved into local limestone columns.',
        ),
      ],
    );
  }

  CuratorTour _buildChorsuSpiceTour() {
    return const CuratorTour(
      id: 'tour-chorsu-spice',
      title: 'Old City Spice & Silk Trail',
      subtitle: 'Atmospheric courtyards, saffron sellers, and copper artisans of Chorsu',
      curatorId: 'u-nodir',
      curatorName: 'Nodir Usmanov',
      district: 'Shaykhontohur',
      estimatedWalkingMinutes: 40,
      xpReward: 100,
      stops: [
        TourStopStory(
          id: 'stop-chorsu-1',
          tourId: 'tour-chorsu-spice',
          chapterIndex: 1,
          title: 'The Turquoise Dome Acoustics',
          venueId: 'pl-chorsu',
          venueName: 'Chorsu Bazaar Center',
          latitude: 41.3271,
          longitude: 69.2365,
          triggerRadiusMeters: 60.0,
          audioUrl: 'https://cdn.around.uz/audio/spice-ch1.m4a',
          durationSeconds: 195,
          transcript: 'Notice the whispering gallery resonance under the giant central cupola.',
        ),
        TourStopStory(
          id: 'stop-chorsu-2',
          tourId: 'tour-chorsu-spice',
          chapterIndex: 2,
          title: 'Kukeldash Courtyard Shadows',
          venueId: 'pl-kukeldash',
          venueName: 'Kukeldash Courtyard',
          latitude: 41.3255,
          longitude: 69.2382,
          triggerRadiusMeters: 50.0,
          audioUrl: 'https://cdn.around.uz/audio/spice-ch2.m4a',
          durationSeconds: 240,
          transcript: 'A five-century-old madrasah courtyard cooled by plane trees and stone waterways.',
        ),
      ],
    );
  }
}

final curatorTourStoryRepositoryProvider = Provider<CuratorTourStoryRepository>((ref) {
  final engine = ref.watch(curatorTourStoryEngineProvider);
  return CuratorTourStoryRepository(engine: engine);
});

final curatorTourDetailsProvider =
    FutureProvider.family<CuratorTour?, String>((ref, tourId) async {
  final repo = ref.watch(curatorTourStoryRepositoryProvider);
  return repo.getCuratorTourDetails(tourId);
});

final districtCuratorToursProvider =
    FutureProvider.family<List<CuratorTour>, String?>((ref, district) async {
  final repo = ref.watch(curatorTourStoryRepositoryProvider);
  return repo.getDistrictTours(district: district);
});
