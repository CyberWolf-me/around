import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static const String defaultUrl = 'https://xyzcompany.supabase.co';
  static const String defaultAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...';

  static bool _isInitialized = false;

  static bool get isInitialized => _isInitialized;

  static SupabaseClient get client => Supabase.instance.client;

  static Future<void> initialize({String? url, String? anonKey}) async {
    try {
      await Supabase.initialize(
        url: url ?? defaultUrl,
        anonKey: anonKey ?? defaultAnonKey,
      );
      _isInitialized = true;
      debugPrint('[SupabaseService] Initialized successfully');
    } catch (e) {
      debugPrint('[SupabaseService] Running in local offline/mock mode: $e');
      _isInitialized = false;
    }
  }
}
