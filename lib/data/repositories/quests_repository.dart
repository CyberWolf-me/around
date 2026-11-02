import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/quest_model.dart';
import 'places_repository.dart';

final questsRepositoryProvider = Provider<QuestsRepository>((ref) {
  return QuestsRepository();
});

class QuestsRepository {
  static final List<QuestModel> _canonicalQuests = [
    const QuestModel(
      id: 'mirabad_coffee_trail',
      title: 'Mirabad Specialty Coffee Trail',
      description: 'Taste artisan single-origins and flat whites across Shevchenko Street’s top third-wave roasteries.',
      district: 'Mirabad',
      category: 'Coffee',
      icon: '☕',
      badgeName: 'Mirabad Roastmaster',
      targetPlaceIds: ['breadly', 'tims', 'pie-republic', 'coffee-milk', 'blend-coffee'],
      requiredCount: 3,
    ),
    const QuestModel(
      id: 'old_city_plov_connoisseur',
      title: 'Old City Plov Connoisseur',
      description: 'Savor legendary saffron wedding plov from massive bronze kazans in the culinary heart of Old Tashkent.',
      district: 'Shaykhontohur',
      category: 'Heritage',
      icon: '🥘',
      badgeName: 'Master Oshpaz',
      targetPlaceIds: ['chorsu', 'besh-qozon-plov', 'chorsu-bazaar-domes'],
      requiredCount: 2,
    ),
    const QuestModel(
      id: 'tashkent_night_circuit',
      title: 'Sunset & Vinyl Night Circuit',
      description: 'Experience craft pomegranate cocktails and analog vinyl sets high above illuminated Tashkent.',
      district: 'Central Tashkent',
      category: 'Nightlife',
      icon: '🍸',
      badgeName: 'Tashkent Nocturne',
      targetPlaceIds: ['steam', 'sette', 'hotel-uzbekistan-bar', 'city-21-hilton'],
      requiredCount: 2,
    ),
    const QuestModel(
      id: 'emerald_promenade_explorer',
      title: 'Emerald Promenade Explorer',
      description: 'Stroll along sycamore-shaded lake circuits and serene forested gardens across Tashkent’s green oases.',
      district: 'Metropolitan',
      category: 'Outdoors',
      icon: '🌿',
      badgeName: 'Green City Walker',
      targetPlaceIds: ['centralpark', 'bobur-park', 'ecopark-tashkent', 'botanical-garden'],
      requiredCount: 2,
    ),
  ];

  /// Returns all available Tashkent city quests.
  List<QuestModel> getQuests() {
    return List.unmodifiable(_canonicalQuests);
  }

  /// Normalizes place IDs through canonical resolution before checking progress.
  Set<String> _normalizeVisited(Set<String> visitedPlaceIds) {
    return visitedPlaceIds.map(PlacesRepository.resolveCanonicalId).toSet();
  }

  /// Returns all quests completed by the given visited place IDs.
  List<QuestModel> getCompletedQuests(Set<String> visitedPlaceIds) {
    final normalized = _normalizeVisited(visitedPlaceIds);
    return _canonicalQuests.where((q) => q.isCompleted(normalized)).toList();
  }

  /// Returns all badge names earned by completing quests.
  List<String> getUnlockedBadges(Set<String> visitedPlaceIds) {
    return getCompletedQuests(visitedPlaceIds).map((q) => q.badgeName).toList();
  }

  /// Computes summary statistics for user's quest progress.
  Map<String, dynamic> getQuestStats(Set<String> visitedPlaceIds) {
    final normalized = _normalizeVisited(visitedPlaceIds);
    final total = _canonicalQuests.length;
    final completed = _canonicalQuests.where((q) => q.isCompleted(normalized)).length;
    final badges = getUnlockedBadges(normalized);

    return {
      'totalQuests': total,
      'completedQuests': completed,
      'progressPercent': total > 0 ? ((completed / total) * 100).round() : 0,
      'unlockedBadges': badges,
      'hasBadges': badges.isNotEmpty,
    };
  }
}
