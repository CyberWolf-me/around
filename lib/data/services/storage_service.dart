import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/post_model.dart';
import '../models/place_model.dart';

class StorageService {
  static const _savedPlacesKey = 'around_saved_places_v1';
  static const _customDropsKey = 'around_custom_drops_v1';
  static const _customPlacesKey = 'around_custom_places_v1';
  static const _supabaseUrlKey = 'around_supabase_url_v1';
  static const _supabaseAnonKey = 'around_supabase_anon_key_v1';

  static SharedPreferences? _prefs;

  static Future<void> init() async {
    try {
      _prefs = await SharedPreferences.getInstance();
    } catch (e) {
      debugPrint('[StorageService] Init error (using memory fallback): $e');
    }
  }

  // Saved places
  static List<String>? getSavedPlaceIds() {
    return _prefs?.getStringList(_savedPlacesKey);
  }

  static Future<void> savePlaceIds(List<String> ids) async {
    await _prefs?.setStringList(_savedPlacesKey, ids);
  }

  // Custom drops
  static List<PostModel> getStoredDrops() {
    final raw = _prefs?.getString(_customDropsKey);
    if (raw == null || raw.isEmpty) return [];
    try {
      final List list = jsonDecode(raw);
      return list.map((item) => PostModel.fromJson(Map<String, dynamic>.from(item))).toList();
    } catch (e) {
      debugPrint('[StorageService] Error loading stored drops: $e');
      return [];
    }
  }

  static Future<void> persistDrops(List<PostModel> drops) async {
    try {
      final encoded = jsonEncode(drops.map((p) => {
        'id': p.id,
        'author_id': p.authorId,
        'author_name': p.authorName,
        'author_username': p.authorUsername,
        'author_avatar': p.authorAvatar,
        'place_id': p.placeId,
        'place_name': p.placeName,
        'place_category': p.placeCategory,
        'place_address': p.placeAddress,
        'note': p.note,
        'rating': p.rating,
        'audience': p.audience.name,
        'size': p.size.name,
        'tags': p.tags,
        'media_url': p.mediaUrl,
        'saves_count': p.savesCount,
        'created_at': p.createdAt.toIso8601String(),
        'is_saved': p.isSaved,
      }).toList());
      await _prefs?.setString(_customDropsKey, encoded);
    } catch (e) {
      debugPrint('[StorageService] Error persisting drops: $e');
    }
  }

  // Custom places created by user
  static List<PlaceModel> getCustomPlaces() {
    final raw = _prefs?.getString(_customPlacesKey);
    if (raw == null || raw.isEmpty) return [];
    try {
      final List list = jsonDecode(raw);
      return list.map((item) => PlaceModel.fromJson(Map<String, dynamic>.from(item))).toList();
    } catch (e) {
      debugPrint('[StorageService] Error loading custom places: $e');
      return [];
    }
  }

  static Future<void> persistCustomPlaces(List<PlaceModel> places) async {
    try {
      final encoded = jsonEncode(places.map((p) => {
        'id': p.id,
        'slug': p.slug,
        'name': p.name,
        'category': p.category,
        'street_address': p.streetAddress,
        'district': p.district,
        'city': p.city,
        'latitude': p.latitude,
        'longitude': p.longitude,
        'distance_meters': p.distanceMeters,
        'walk_time_minutes': p.walkTimeMinutes,
        'price_tier': p.priceTier,
        'hours': p.hours,
        'status_line': p.statusLine,
        'description': p.description,
        'hero_image_url': p.heroImageUrl,
        'rating_avg': p.ratingAvg,
        'rating_count': p.ratingCount,
        'tags': p.tags,
        'photos': p.photos,
      }).toList());
      await _prefs?.setString(_customPlacesKey, encoded);
    } catch (e) {
      debugPrint('[StorageService] Error persisting custom places: $e');
    }
  }

  // Supabase settings
  static String? getSupabaseUrl() => _prefs?.getString(_supabaseUrlKey);
  static String? getSupabaseAnonKey() => _prefs?.getString(_supabaseAnonKey);

  static Future<void> saveSupabaseCredentials(String url, String anonKey) async {
    await _prefs?.setString(_supabaseUrlKey, url);
    await _prefs?.setString(_supabaseAnonKey, anonKey);
  }

  static Future<void> clearAll() async {
    await _prefs?.clear();
  }
}
