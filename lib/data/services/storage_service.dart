import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/services/app_logger.dart';
import '../models/post_model.dart';
import '../models/place_model.dart';
import '../models/profile_model.dart';
import '../models/saved_place_model.dart';
import '../models/notification_model.dart';

class StorageService {
  static const _savedPlacesKey = 'around_saved_places_v1';
  static const _savedStatusesKey = 'around_saved_statuses_v1';
  static const _customDropsKey = 'around_custom_drops_v1';
  static const _customPlacesKey = 'around_custom_places_v1';
  static const _profileKey = 'around_user_profile_v1';
  static const _followedFriendsKey = 'around_followed_friends_v1';
  static const _friendshipStatusesKey = 'around_friendship_statuses_v1';
  static const _blockedUsersKey = 'around_blocked_users_v1';
  static const _reportsKey = 'around_reports_v1';
  static const _plansKey = 'around_friend_plans_v1';
  static const _onboardedKey = 'around_onboarded_v1';
  static const _authUserEmailKey = 'around_auth_user_email_v1';
  static const _guestModeKey = 'around_guest_mode_v1';
  static const _notificationsKey = 'around_notifications_v1';
  static const _biometricLockKey = 'around_biometric_lock_v1';
  static const _appLanguageKey = 'around_app_language_v1';

  static SharedPreferences? _prefs;
  static final Map<String, Object> _memoryFallback = {};
  static final Map<String, DateTime> _sensitiveVisitVault = {};

  static Future<void> init() async {
    try {
      _prefs = await SharedPreferences.getInstance();
    } catch (e) {
      AppLogger.warn('StorageService', 'SharedPreferences init fallback to in-memory store', e);
    }
  }

  // Onboarding state
  static bool isOnboarded() {
    return _prefs?.getBool(_onboardedKey) ?? (_memoryFallback[_onboardedKey] as bool? ?? false);
  }

  static Future<void> setOnboarded(bool value) async {
    _memoryFallback[_onboardedKey] = value;
    await _prefs?.setBool(_onboardedKey, value);
  }

  // Guest browsing mode
  static bool isGuestMode() {
    return _prefs?.getBool(_guestModeKey) ?? (_memoryFallback[_guestModeKey] as bool? ?? false);
  }

  static Future<void> setGuestMode(bool value) async {
    _memoryFallback[_guestModeKey] = value;
    await _prefs?.setBool(_guestModeKey, value);
  }

  // Authenticated session email
  static String? getAuthUserEmail() {
    return _prefs?.getString(_authUserEmailKey) ?? (_memoryFallback[_authUserEmailKey] as String?);
  }

  static Future<void> setAuthUserEmail(String? email) async {
    if (email == null) {
      _memoryFallback.remove(_authUserEmailKey);
      await _prefs?.remove(_authUserEmailKey);
    } else {
      _memoryFallback[_authUserEmailKey] = email;
      await _prefs?.setString(_authUserEmailKey, email);
    }
  }

  static Future<void> clearAuthSession() async {
    _memoryFallback.remove(_authUserEmailKey);
    await _prefs?.remove(_authUserEmailKey);
    _memoryFallback.remove(_profileKey);
    await _prefs?.remove(_profileKey);
    _memoryFallback.remove(_guestModeKey);
    await _prefs?.remove(_guestModeKey);
  }

  // Generic key-value helpers for services & outbox
  static String? getString(String key) {
    return _prefs?.getString(key) ?? (_memoryFallback[key] as String?);
  }

  static Future<void> setString(String key, String value) async {
    _memoryFallback[key] = value;
    await _prefs?.setString(key, value);
  }

  static Future<void> removeString(String key) async {
    _memoryFallback.remove(key);
    await _prefs?.remove(key);
  }

  // Saved places IDs
  static List<String>? getSavedPlaceIds() {
    return _prefs?.getStringList(_savedPlacesKey) ?? (_memoryFallback[_savedPlacesKey] as List<String>?);
  }

  static Future<void> savePlaceIds(List<String> ids) async {
    _memoryFallback[_savedPlacesKey] = List<String>.from(ids);
    await _prefs?.setStringList(_savedPlacesKey, ids);
  }

  // Saved places status map ('want_to_go' | 'been')
  static Map<String, String> getSavedPlaceStatuses() {
    final raw = _prefs?.getString(_savedStatusesKey) ?? (_memoryFallback[_savedStatusesKey] as String?);
    if (raw == null || raw.isEmpty) return {};
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      return decoded.map((k, v) => MapEntry(k, v.toString()));
    } catch (e) {
      AppLogger.warn('StorageService', 'Failed decoding saved place statuses', e);
      return {};
    }
  }

  static Future<void> savePlaceStatuses(Map<String, String> statuses) async {
    final encoded = jsonEncode(statuses);
    _memoryFallback[_savedStatusesKey] = encoded;
    await _prefs?.setString(_savedStatusesKey, encoded);
  }

  // Custom drops
  static List<PostModel> getStoredDrops() {
    final raw = _prefs?.getString(_customDropsKey) ?? (_memoryFallback[_customDropsKey] as String?);
    if (raw == null || raw.isEmpty) return [];
    try {
      final List list = jsonDecode(raw);
      return list.map((item) => PostModel.fromJson(Map<String, dynamic>.from(item))).toList();
    } catch (e) {
      AppLogger.error('StorageService', 'Error loading stored drops', e);
      return [];
    }
  }

  static Future<void> persistDrops(List<PostModel> drops) async {
    try {
      final encoded = jsonEncode(drops.map((p) => p.toJson()).toList());
      _memoryFallback[_customDropsKey] = encoded;
      await _prefs?.setString(_customDropsKey, encoded);
    } catch (e) {
      AppLogger.error('StorageService', 'Error persisting drops', e);
    }
  }

  // Custom places created by user
  static List<PlaceModel> getCustomPlaces() {
    final raw = _prefs?.getString(_customPlacesKey) ?? (_memoryFallback[_customPlacesKey] as String?);
    if (raw == null || raw.isEmpty) return [];
    try {
      final List list = jsonDecode(raw);
      return list.map((item) => PlaceModel.fromJson(Map<String, dynamic>.from(item))).toList();
    } catch (e) {
      AppLogger.error('StorageService', 'Error loading custom places', e);
      return [];
    }
  }

  static Future<void> persistCustomPlaces(List<PlaceModel> places) async {
    try {
      final encoded = jsonEncode(places.map((p) => p.toJson()).toList());
      _memoryFallback[_customPlacesKey] = encoded;
      await _prefs?.setString(_customPlacesKey, encoded);
    } catch (e) {
      AppLogger.error('StorageService', 'Error persisting custom places', e);
    }
  }

  // Profile & Privacy Settings
  static ProfileModel? getStoredProfile() {
    final raw = _prefs?.getString(_profileKey) ?? (_memoryFallback[_profileKey] as String?);
    if (raw == null || raw.isEmpty) return null;
    try {
      return ProfileModel.fromJson(Map<String, dynamic>.from(jsonDecode(raw)));
    } catch (e) {
      AppLogger.warn('StorageService', 'Failed decoding stored profile', e);
      return null;
    }
  }

  static Future<void> persistProfile(ProfileModel profile) async {
    final encoded = jsonEncode(profile.toJson());
    _memoryFallback[_profileKey] = encoded;
    await _prefs?.setString(_profileKey, encoded);
  }

  // Mutual & Pending Friendship Statuses ('accepted' | 'pending_outgoing' | 'pending_incoming')
  static Map<String, String>? getFriendshipStatuses() {
    final raw = _prefs?.getString(_friendshipStatusesKey) ?? (_memoryFallback[_friendshipStatusesKey] as String?);
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      return decoded.map((k, v) => MapEntry(k, v.toString()));
    } catch (e) {
      AppLogger.warn('StorageService', 'Failed decoding friendship statuses', e);
      return null;
    }
  }

  static Future<void> persistFriendshipStatuses(Map<String, String> statuses) async {
    final encoded = jsonEncode(statuses);
    _memoryFallback[_friendshipStatusesKey] = encoded;
    await _prefs?.setString(_friendshipStatusesKey, encoded);
  }

  // Accepted friends set
  static Set<String>? getFollowedFriends() {
    final list = _prefs?.getStringList(_followedFriendsKey) ?? (_memoryFallback[_followedFriendsKey] as List<String>?);
    return list?.toSet();
  }

  static Future<void> persistFollowedFriends(Set<String> ids) async {
    final list = ids.toList();
    _memoryFallback[_followedFriendsKey] = list;
    await _prefs?.setStringList(_followedFriendsKey, list);
  }

  // Blocked users
  static Set<String> getBlockedUsers() {
    final list = _prefs?.getStringList(_blockedUsersKey) ?? (_memoryFallback[_blockedUsersKey] as List<String>?);
    return list?.toSet() ?? <String>{};
  }

  static Future<void> persistBlockedUsers(Set<String> ids) async {
    final list = ids.toList();
    _memoryFallback[_blockedUsersKey] = list;
    await _prefs?.setStringList(_blockedUsersKey, list);
  }

  // Moderation reports
  static List<Map<String, dynamic>> getReports() {
    final raw = _prefs?.getString(_reportsKey) ?? (_memoryFallback[_reportsKey] as String?);
    if (raw == null || raw.isEmpty) return [];
    try {
      final List list = jsonDecode(raw);
      return list.map((e) => Map<String, dynamic>.from(e)).toList();
    } catch (e) {
      AppLogger.warn('StorageService', 'Failed decoding reports', e);
      return [];
    }
  }

  static Future<int> addReport(Map<String, dynamic> report) async {
    final current = getReports();
    final updated = [report, ...current];
    final encoded = jsonEncode(updated);
    _memoryFallback[_reportsKey] = encoded;
    await _prefs?.setString(_reportsKey, encoded);
    final targetId = report['target_id']?.toString() ?? '';
    return updated.where((r) => r['target_id'] == targetId).length;
  }

  // Friend plans
  static List<FriendPlanModel>? getStoredPlans() {
    final raw = _prefs?.getString(_plansKey) ?? (_memoryFallback[_plansKey] as String?);
    if (raw == null || raw.isEmpty) return null;
    try {
      final List list = jsonDecode(raw);
      return list.map((e) => FriendPlanModel.fromJson(Map<String, dynamic>.from(e))).toList();
    } catch (e) {
      AppLogger.warn('StorageService', 'Failed decoding stored plans', e);
      return null;
    }
  }

  static Future<void> persistPlans(List<FriendPlanModel> plans) async {
    final encoded = jsonEncode(plans.map((p) => p.toJson()).toList());
    _memoryFallback[_plansKey] = encoded;
    await _prefs?.setString(_plansKey, encoded);
  }

  // Activity notifications
  static List<NotificationModel>? getStoredNotifications() {
    final raw = _prefs?.getString(_notificationsKey) ?? (_memoryFallback[_notificationsKey] as String?);
    if (raw == null || raw.isEmpty) return null;
    try {
      final List list = jsonDecode(raw);
      return list.map((e) => NotificationModel.fromJson(Map<String, dynamic>.from(e))).toList();
    } catch (e) {
      AppLogger.warn('StorageService', 'Failed decoding stored notifications', e);
      return null;
    }
  }

  static Future<void> persistNotifications(List<NotificationModel> notifications) async {
    final encoded = jsonEncode(notifications.map((n) => n.toJson()).toList());
    _memoryFallback[_notificationsKey] = encoded;
    await _prefs?.setString(_notificationsKey, encoded);
  }

  // Biometric / App Lock preference
  static bool isBiometricLockEnabled() {
    return _prefs?.getBool(_biometricLockKey) ?? (_memoryFallback[_biometricLockKey] as bool? ?? false);
  }

  static Future<void> setBiometricLockEnabled(bool value) async {
    _memoryFallback[_biometricLockKey] = value;
    await _prefs?.setBool(_biometricLockKey, value);
  }

  // Sensitive Visit History Memory Vault
  static void recordSensitiveVisit(String placeId, DateTime timestamp) {
    _sensitiveVisitVault[placeId] = timestamp;
  }

  static Map<String, DateTime> getSensitiveVisitVault({bool hideVisitsHistory = false, bool isLocked = false}) {
    if (hideVisitsHistory || isLocked) {
      return const {};
    }
    return Map<String, DateTime>.unmodifiable(_sensitiveVisitVault);
  }

  static void purgeSensitiveMemoryVault() {
    _sensitiveVisitVault.clear();
  }

  // Trilingual App Language Preference
  static String getAppLanguage() {
    return _prefs?.getString(_appLanguageKey) ?? (_memoryFallback[_appLanguageKey] as String? ?? 'en');
  }

  static Future<void> setAppLanguage(String langCode) async {
    _memoryFallback[_appLanguageKey] = langCode;
    await _prefs?.setString(_appLanguageKey, langCode);
  }

  static Future<void> clearAll() async {
    _memoryFallback.clear();
    _sensitiveVisitVault.clear();
    await _prefs?.clear();
  }
}
