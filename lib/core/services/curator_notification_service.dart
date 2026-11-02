import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/notification_model.dart';
import '../../data/repositories/notifications_repository.dart';
import '../../data/services/haptic_service.dart';
import '../../data/services/storage_service.dart';
import 'analytics_service.dart';
import 'app_logger.dart';

/// Milestone notification event descriptor.
enum CuratorMilestoneType {
  streakMilestone,
  districtCrown,
  trophyUnlocked,
}

/// Reactive Curator Milestone & Trophy In-App Notification Dispatcher (`P21-04`).
/// Evaluates explorer milestones, deduplicates delivered notifications,
/// formats localized celebratory copy, and triggers tactile feedback.
class CuratorNotificationService {
  static const String _kDeliveredMilestonesKey = 'around_delivered_milestones_v1';

  final NotificationsNotifier? _notificationsNotifier;
  final AnalyticsService? _analytics;

  const CuratorNotificationService({
    NotificationsNotifier? notificationsNotifier,
    AnalyticsService? analytics,
  })  : _notificationsNotifier = notificationsNotifier,
        _analytics = analytics;

  /// Retrieves the set of already delivered milestone identifier keys.
  static Set<String> getDeliveredMilestones() {
    final raw = StorageService.getString(_kDeliveredMilestonesKey);
    if (raw == null || raw.isEmpty) return <String>{};
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list.map((e) => e.toString()).toSet();
    } catch (e) {
      AppLogger.warn('CuratorNotificationService', 'Failed to decode delivered milestones', e);
      return <String>{};
    }
  }

  /// Marks a milestone key as delivered to prevent spam.
  static Future<void> markMilestoneDelivered(String key) async {
    final current = getDeliveredMilestones();
    if (!current.contains(key)) {
      final updated = {...current, key};
      await StorageService.setString(_kDeliveredMilestonesKey, jsonEncode(updated.toList()));
    }
  }

  /// Evaluates and notifies on streak milestone unlocks (2, 4, 8, 12 weeks).
  Future<bool> checkAndNotifyStreakMilestone({
    required String userId,
    required int streakWeeks,
    String lang = 'en',
  }) async {
    if (streakWeeks < 2) return false;

    // Supported milestones
    final qualifyingMilestones = [2, 4, 8, 12];
    final matched = qualifyingMilestones.where((m) => streakWeeks >= m).toList();
    if (matched.isEmpty) return false;

    final targetMilestone = matched.last;
    final milestoneKey = 'streak_milestone_${userId}_$targetMilestone';

    if (getDeliveredMilestones().contains(milestoneKey)) {
      return false; // Already delivered
    }

    String message;
    switch (lang.toLowerCase()) {
      case 'uz':
        message = '🔥 Tabriklaymiz! Siz $targetMilestone haftalik kashfiyot seriyasini muvaffaqiyatli yakunladingiz!';
        break;
      case 'ru':
        message = '🔥 Поздравляем! Вы достигли $targetMilestone-недельной серии открытий в Ташкенте!';
        break;
      case 'en':
      default:
        message = '🔥 Congratulations! You unlocked the $targetMilestone-week Tashkent explorer streak!';
        break;
    }

    final notif = NotificationModel(
      id: 'notif_milestone_${DateTime.now().millisecondsSinceEpoch}',
      recipientId: userId,
      actorId: 'around_system',
      actorName: 'Around Tashkent',
      actorUsername: 'around',
      actorInitials: 'AR',
      kind: 'trophy',
      message: message,
      unread: true,
      createdAt: DateTime.now(),
    );

    await markMilestoneDelivered(milestoneKey);
    await _notificationsNotifier?.addNotification(notif);
    HapticService.medium();

    _analytics?.trackCustom('curator_milestone_notified', {
      'user_id': userId,
      'type': 'streak',
      'milestone_weeks': targetMilestone,
    });

    AppLogger.info('CuratorNotificationService', 'Delivered streak milestone notification for $userId: $targetMilestone wks');
    return true;
  }

  /// Evaluates and notifies when curator secures a district crown.
  Future<bool> checkAndNotifyDistrictCrown({
    required String userId,
    required String districtName,
    String lang = 'en',
  }) async {
    final milestoneKey = 'district_crown_${userId}_${districtName.toLowerCase().replaceAll(' ', '_')}';

    if (getDeliveredMilestones().contains(milestoneKey)) {
      return false;
    }

    String message;
    switch (lang.toLowerCase()) {
      case 'uz':
        message = '👑 Shahar Choʻqqisi! Siz $districtName tumanining yetakchi kuratoriga aylandingiz!';
        break;
      case 'ru':
        message = '👑 Корона района! Вы стали главным куратором района $districtName!';
        break;
      case 'en':
      default:
        message = '👑 District Legend! You earned the Crown for $districtName district!';
        break;
    }

    final notif = NotificationModel(
      id: 'notif_crown_${DateTime.now().millisecondsSinceEpoch}',
      recipientId: userId,
      actorId: 'around_system',
      actorName: 'Around Tashkent',
      actorUsername: 'around',
      actorInitials: 'AR',
      kind: 'trophy',
      message: message,
      unread: true,
      createdAt: DateTime.now(),
    );

    await markMilestoneDelivered(milestoneKey);
    await _notificationsNotifier?.addNotification(notif);
    HapticService.selection();

    _analytics?.trackCustom('curator_milestone_notified', {
      'user_id': userId,
      'type': 'district_crown',
      'district': districtName,
    });

    AppLogger.info('CuratorNotificationService', 'Delivered district crown notification for $userId in $districtName');
    return true;
  }

  /// Evaluates and notifies when a new trophy is unlocked.
  Future<bool> checkAndNotifyTrophyUnlocked({
    required String userId,
    required String trophyId,
    required String trophyTitle,
    String lang = 'en',
  }) async {
    final milestoneKey = 'trophy_${userId}_$trophyId';

    if (getDeliveredMilestones().contains(milestoneKey)) {
      return false;
    }

    String message;
    switch (lang.toLowerCase()) {
      case 'uz':
        message = '🏆 Yangi yutuq ochildi: "$trophyTitle"! Pasportingizda koʻring.';
        break;
      case 'ru':
        message = '🏆 Открыто новое достижение: "$trophyTitle"! Посмотрите в паспорте.';
        break;
      case 'en':
      default:
        message = '🏆 New Achievement Unlocked: "$trophyTitle"! View in your passport.';
        break;
    }

    final notif = NotificationModel(
      id: 'notif_trophy_${DateTime.now().millisecondsSinceEpoch}',
      recipientId: userId,
      actorId: 'around_system',
      actorName: 'Around Tashkent',
      actorUsername: 'around',
      actorInitials: 'AR',
      kind: 'trophy',
      message: message,
      unread: true,
      createdAt: DateTime.now(),
    );

    await markMilestoneDelivered(milestoneKey);
    await _notificationsNotifier?.addNotification(notif);
    HapticService.selection();

    _analytics?.trackCustom('curator_milestone_notified', {
      'user_id': userId,
      'type': 'trophy',
      'trophy_id': trophyId,
    });

    return true;
  }
}

/// Provider binding CuratorNotificationService to NotificationsNotifier and Analytics.
final curatorNotificationServiceProvider = Provider<CuratorNotificationService>((ref) {
  final notifNotifier = ref.watch(notificationsProvider.notifier);
  final analytics = ref.watch(analyticsServiceProvider);

  return CuratorNotificationService(
    notificationsNotifier: notifNotifier,
    analytics: analytics,
  );
});
