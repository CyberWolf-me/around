import 'dart:io';
import '../../core/services/app_logger.dart';
import 'storage_service.dart';
import 'supabase_service.dart';

class PushNotificationService {
  static const String _kDeviceTokenKey = 'around_fcm_device_token';

  /// Registers a device push token (FCM/APNs) with Supabase (Sprint 2).
  static Future<void> registerDeviceToken(String token) async {
    if (token.isEmpty) return;

    await StorageService.setString(_kDeviceTokenKey, token);

    if (SupabaseService.isInitialized && SupabaseService.isAuthenticated) {
      try {
        final platform = Platform.isIOS ? 'ios' : (Platform.isAndroid ? 'android' : 'web');
        await SupabaseService.client.from('user_device_tokens').upsert({
          'user_id': SupabaseService.currentUser!.id,
          'fcm_token': token,
          'platform': platform,
          'updated_at': DateTime.now().toIso8601String(),
        });
        AppLogger.info('PushNotificationService', 'Device token registered successfully for platform: $platform');
      } catch (e) {
        AppLogger.warn('PushNotificationService', 'Supabase device token registration skipped', e);
      }
    }
  }

  /// Removes the device push token on user logout.
  static Future<void> unregisterDeviceToken() async {
    final token = StorageService.getString(_kDeviceTokenKey);
    if (token == null || token.isEmpty) return;

    if (SupabaseService.isInitialized && SupabaseService.isAuthenticated) {
      try {
        await SupabaseService.client
            .from('user_device_tokens')
            .delete()
            .eq('user_id', SupabaseService.currentUser!.id)
            .eq('fcm_token', token);
      } catch (e) {
        AppLogger.warn('PushNotificationService', 'Supabase device token removal skipped', e);
      }
    }
    await StorageService.removeString(_kDeviceTokenKey);
  }

  static String? getSavedDeviceToken() {
    return StorageService.getString(_kDeviceTokenKey);
  }
}
