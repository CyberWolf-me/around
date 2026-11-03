import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'district_legend_engine.dart';

/// Type of district crown ownership transition (`P18-04`).
enum CrownTransitionType {
  claimed,  // Unclaimed district crowned for the first time
  usurped,  // Previous Local Legend was overtaken by a rival
  extended, // Current Local Legend increased their drop lead
}

/// Event model representing a crown leadership shift in a Tashkent neighborhood.
class CrownTransitionEvent {
  final String district;
  final CrownTransitionType type;
  final String newLeaderId;
  final String newLeaderName;
  final int newLeaderDrops;
  final String? previousLeaderId;
  final String? previousLeaderName;
  final int? previousLeaderDrops;
  final DateTime timestamp;

  const CrownTransitionEvent({
    required this.district,
    required this.type,
    required this.newLeaderId,
    required this.newLeaderName,
    required this.newLeaderDrops,
    this.previousLeaderId,
    this.previousLeaderName,
    this.previousLeaderDrops,
    required this.timestamp,
  });

  /// Localized rivalry notification copy across Uzbek, Russian, and English.
  String getLocalizedNotification(String lang) {
    final uzDistrict = _toUzbekDistrict(district);
    switch (lang.toLowerCase().trim()) {
      case 'uz':
        if (type == CrownTransitionType.usurped) {
          return '👑 $newLeaderName $uzDistrict afsonasi tojini qoʻlga kiritdi ($newLeaderDrops ta joy). $previousLeaderName, toj sizdan ketdi!';
        }
        if (type == CrownTransitionType.claimed) {
          return '👑 $newLeaderName $uzDistrict tumanining ilk afsonasiga aylandi ($newLeaderDrops ta joy)!';
        }
        return '👑 $newLeaderName $uzDistrict tumanidagi yetakchiligini mustahkamladi ($newLeaderDrops ta joy).';

      case 'ru':
        if (type == CrownTransitionType.usurped) {
          return '👑 $newLeaderName перехватил корону района $district ($newLeaderDrops дропов). $previousLeaderName, вернете первенство?';
        }
        if (type == CrownTransitionType.claimed) {
          return '👑 $newLeaderName стал первой Легендой района $district ($newLeaderDrops дропов)!';
        }
        return '👑 $newLeaderName укрепил лидерство в районе $district ($newLeaderDrops дропов).';

      case 'en':
      default:
        if (type == CrownTransitionType.usurped) {
          return '👑 $newLeaderName just claimed the $district Local Legend crown ($newLeaderDrops drops) from $previousLeaderName!';
        }
        if (type == CrownTransitionType.claimed) {
          return '👑 $newLeaderName became the first Local Legend in $district ($newLeaderDrops drops)!';
        }
        return '👑 $newLeaderName extended their lead in $district ($newLeaderDrops drops).';
    }
  }

  static String _toUzbekDistrict(String district) {
    switch (district.toLowerCase().trim()) {
      case 'mirabad':
        return 'Mirobod';
      case 'yunusabad':
        return 'Yunusobod';
      case 'yakkasaray':
        return 'Yakkasaroy';
      case 'shaykhontohur':
        return 'Shayxontohur';
      case 'chilanzar':
        return 'Chilonzor';
      case 'central tashkent':
        return 'Markaziy Toshkent';
      default:
        return district;
    }
  }
}

/// District Crown Rivalry & Usurpation Notification Engine (`P18-04`).
/// Detects changes in neighborhood Local Legend status between consecutive board evaluations,
/// triggering friendly rivalry notifications and gamified re-engagement prompts.
class CrownRivalryEngine {
  /// Compares previous and current district leaderboards and identifies leadership shifts.
  static List<CrownTransitionEvent> detectTransitions({
    required DistrictLegendLeaderboard previousLeaderboard,
    required DistrictLegendLeaderboard currentLeaderboard,
    DateTime? eventTime,
  }) {
    final now = eventTime ?? DateTime.now();
    final events = <CrownTransitionEvent>[];

    for (final entry in currentLeaderboard.districtLegends.entries) {
      final district = entry.key;
      final currentLegend = entry.value;
      final previousLegend = previousLeaderboard.districtLegends[district];

      if (previousLegend == null) {
        // District claimed for the first time
        events.add(
          CrownTransitionEvent(
            district: currentLegend.district,
            type: CrownTransitionType.claimed,
            newLeaderId: currentLegend.userId,
            newLeaderName: currentLegend.userName,
            newLeaderDrops: currentLegend.dropCount,
            timestamp: now,
          ),
        );
      } else if (previousLegend.userId != currentLegend.userId) {
        // Crown usurped by a different curator
        events.add(
          CrownTransitionEvent(
            district: currentLegend.district,
            type: CrownTransitionType.usurped,
            newLeaderId: currentLegend.userId,
            newLeaderName: currentLegend.userName,
            newLeaderDrops: currentLegend.dropCount,
            previousLeaderId: previousLegend.userId,
            previousLeaderName: previousLegend.userName,
            previousLeaderDrops: previousLegend.dropCount,
            timestamp: now,
          ),
        );
      } else if (currentLegend.dropCount > previousLegend.dropCount) {
        // Same leader extended drop lead
        events.add(
          CrownTransitionEvent(
            district: currentLegend.district,
            type: CrownTransitionType.extended,
            newLeaderId: currentLegend.userId,
            newLeaderName: currentLegend.userName,
            newLeaderDrops: currentLegend.dropCount,
            previousLeaderId: previousLegend.userId,
            previousLeaderName: previousLegend.userName,
            previousLeaderDrops: previousLegend.dropCount,
            timestamp: now,
          ),
        );
      }
    }

    return events;
  }
}

/// Global Riverpod provider for crown rivalry engine.
final crownRivalryEngineProvider =
    Provider<CrownRivalryEngine>((ref) => CrownRivalryEngine());
