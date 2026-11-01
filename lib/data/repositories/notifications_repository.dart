import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/app_logger.dart';
import '../models/notification_model.dart';
import '../services/storage_service.dart';
import '../services/supabase_service.dart';

final notificationsProvider =
    NotifierProvider<NotificationsNotifier, List<NotificationModel>>(NotificationsNotifier.new);

class NotificationsNotifier extends Notifier<List<NotificationModel>> {
  static final List<NotificationModel> _initialSeedNotifications = [
    NotificationModel(
      id: 'notif_1',
      recipientId: 'you',
      actorId: 'kamila',
      actorName: 'Kamila Rahimova',
      actorUsername: 'kamilar',
      actorInitials: 'KR',
      kind: 'drop',
      placeId: 'breadly',
      placeName: 'Breadly Bakery & Café',
      message: 'dropped a morning note with fresh sourdough photo.',
      unread: true,
      createdAt: DateTime.now().subtract(const Duration(minutes: 24)),
    ),
    NotificationModel(
      id: 'notif_2',
      recipientId: 'you',
      actorId: 'bekzod',
      actorName: 'Bekzod Alimov',
      actorUsername: 'bekalimov',
      actorInitials: 'BA',
      kind: 'plan',
      placeId: 'bnb',
      placeName: 'B&B Coffee House',
      message: 'invited you to a study session at B&B this Saturday.',
      unread: true,
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
    ),
    NotificationModel(
      id: 'notif_3',
      recipientId: 'you',
      actorId: 'aziza',
      actorName: 'Aziza Tursunova',
      actorUsername: 'azizatur',
      actorInitials: 'AT',
      kind: 'save',
      placeId: 'ecorn',
      placeName: 'Ecorn Patisserie',
      message: 'saved Ecorn Patisserie to her Want to go list.',
      unread: false,
      createdAt: DateTime.now().subtract(const Duration(hours: 5)),
    ),
    NotificationModel(
      id: 'notif_4',
      recipientId: 'you',
      actorId: 'diyor',
      actorName: 'Diyor Usmanov',
      actorUsername: 'diyor_u',
      actorInitials: 'DU',
      kind: 'follow',
      message: 'accepted your friend request. You can now see his private drops.',
      unread: false,
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
  ];

  @override
  List<NotificationModel> build() {
    final cached = StorageService.getStoredNotifications();
    if (SupabaseService.isInitialized && SupabaseService.isAuthenticated) {
      Future.microtask(syncRemoteNotifications);
      if (cached != null && cached.isNotEmpty) return cached;
      return [];
    }
    if (cached != null && cached.isNotEmpty) return cached;
    return _initialSeedNotifications;
  }

  Future<void> syncRemoteNotifications() async {
    if (!SupabaseService.isInitialized || !SupabaseService.isAuthenticated) return;
    try {
      final myUid = SupabaseService.currentUser!.id;
      final rows = await SupabaseService.client
          .from('notifications')
          .select('*, profiles:actor_id(full_name, username, avatar_url), places(name, slug)')
          .eq('recipient_id', myUid)
          .order('created_at', ascending: false)
          .limit(30);

      if (rows.isNotEmpty) {
        final remotes = rows
            .whereType<Map<String, dynamic>>()
            .map((r) => NotificationModel.fromJson(r))
            .toList();
        state = remotes;
        await StorageService.persistNotifications(remotes);
      }
    } catch (e) {
      AppLogger.warn('NotificationsNotifier', 'Remote notifications hydration skipped', e);
    }
  }

  Future<void> markAllRead() async {
    final updated = state.map((n) => n.copyWith(unread: false)).toList();
    state = updated;
    await StorageService.persistNotifications(updated);

    if (SupabaseService.isInitialized && SupabaseService.isAuthenticated) {
      try {
        final myUid = SupabaseService.currentUser!.id;
        await SupabaseService.client
            .from('notifications')
            .update({'unread': false})
            .eq('recipient_id', myUid);
      } catch (e) {
        AppLogger.warn('NotificationsNotifier', 'Failed updating notifications read status', e);
      }
    }
  }

  Future<void> markAsRead(String notifId) async {
    final updated = state.map((n) {
      if (n.id == notifId) return n.copyWith(unread: false);
      return n;
    }).toList();
    state = updated;
    await StorageService.persistNotifications(updated);

    if (SupabaseService.isInitialized && SupabaseService.isAuthenticated) {
      try {
        await SupabaseService.client
            .from('notifications')
            .update({'unread': false})
            .eq('id', notifId);
      } catch (e) {
        AppLogger.warn('NotificationsNotifier', 'Failed marking notification as read', e);
      }
    }
  }
}
