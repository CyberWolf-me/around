import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/config/app_config.dart';
import '../../core/services/app_logger.dart';
import '../../core/services/exif_sanitizer.dart';

class UploadedMediaResult {
  final String storagePath;
  final String mediaUrl;

  const UploadedMediaResult({
    required this.storagePath,
    required this.mediaUrl,
  });
}

class SupabaseService {
  // Credentials resolved through centralized AppConfig (P12-01 / SEC-06)
  static String get appEnv => AppConfig.current.environment.label;
  static String get envUrl => AppConfig.current.supabaseUrl;
  static String get envAnonKey => AppConfig.current.supabaseAnonKey;

  static bool _isInitialized = false;

  static bool get isInitialized => _isInitialized;

  static SupabaseClient get client => Supabase.instance.client;

  static User? get currentUser => _isInitialized ? Supabase.instance.client.auth.currentUser : null;

  static bool get isAuthenticated => currentUser != null;

  static Future<void> initialize() async {
    final validationError = AppConfig.validateCredentials(
      url: envUrl,
      anonKey: envAnonKey,
      environment: AppConfig.current.environment,
    );

    if (envUrl.isEmpty || envAnonKey.isEmpty) {
      AppLogger.info(
        'SupabaseService',
        'Missing compile-time SUPABASE_URL or SUPABASE_ANON_KEY (ENV=$appEnv). '
        'Pass --dart-define-from-file=.env for cloud mode; running in local persistence mode.',
      );
      _isInitialized = false;
      return;
    }

    if (validationError != null && validationError.contains('CRITICAL SECURITY VIOLATION')) {
      AppLogger.error(
        'SupabaseService',
        validationError,
      );
      _isInitialized = false;
      return;
    }

    try {
      await Supabase.initialize(
        url: envUrl,
        publishableKey: envAnonKey,
      );
      _isInitialized = true;
      AppLogger.info('SupabaseService', 'Initialized Supabase cloud client ($appEnv)');
    } catch (e) {
      AppLogger.warn('SupabaseService', 'Cloud init failed; falling back to local persistence mode', e);
      _isInitialized = false;
    }
  }

  static Future<AuthResponse?> signInWithEmail(String email, String password) async {
    if (!_isInitialized) return null;
    return await client.auth.signInWithPassword(email: email.trim(), password: password);
  }

  static Future<AuthResponse?> signUpWithEmail({
    required String email,
    required String password,
    required String username,
    required String fullName,
    String neighborhood = 'Mirabad',
  }) async {
    if (!_isInitialized) return null;
    return await client.auth.signUp(
      email: email.trim(),
      password: password,
      data: {
        'username': username.trim(),
        'full_name': fullName.trim(),
        'neighborhood': neighborhood.trim(),
      },
    );
  }

  static Future<void> signOut() async {
    if (!_isInitialized) return;
    await client.auth.signOut();
  }

  /// Invokes the trusted server-side `delete_own_account()` RPC (`00005_security_and_rls_remediation.sql`)
  /// so account deletion never requires a service-role credential on the client (TASK-09).
  static Future<bool> deleteOwnAccount() async {
    if (!_isInitialized || currentUser == null) return false;
    try {
      await client.rpc('delete_own_account');
      await client.auth.signOut();
      return true;
    } catch (e) {
      AppLogger.error('SupabaseService', 'Server-side delete_own_account RPC failed', e);
      return false;
    }
  }

  /// Validates file type & size (<= 5 MB), uploads to the private 'post-media' bucket,
  /// and returns both the internal `storagePath` (for RLS & orphan cleanup) and signed/public URL (SEC-14).
  static Future<UploadedMediaResult?> uploadDropMediaResult(String localFilePath) async {
    if (!_isInitialized || currentUser == null) return null;
    if (localFilePath.startsWith('assets/') || localFilePath.startsWith('http')) {
      return UploadedMediaResult(storagePath: localFilePath, mediaUrl: localFilePath);
    }
    try {
      if (localFilePath.startsWith('data:image/')) {
        final commaIdx = localFilePath.indexOf(',');
        if (commaIdx == -1) return null;
        final rawBytes = base64Decode(localFilePath.substring(commaIdx + 1));
        final sanitizedBytes = ExifSanitizer.stripExif(rawBytes);
        final validationError = AppLogger.validateImagePath(localFilePath, byteLength: sanitizedBytes.length);
        if (validationError != null) throw validationError;

        final storagePath = '${currentUser!.id}/drop_${DateTime.now().millisecondsSinceEpoch}.jpg';
        await client.storage.from('post-media').uploadBinary(
              storagePath,
              sanitizedBytes,
              fileOptions: const FileOptions(contentType: 'image/jpeg', upsert: false),
            );
        final signedUrl = await client.storage.from('post-media').createSignedUrl(storagePath, 60 * 60 * 24 * 365);
        return UploadedMediaResult(storagePath: storagePath, mediaUrl: signedUrl);
      }

      if (kIsWeb) {
        return UploadedMediaResult(storagePath: localFilePath, mediaUrl: localFilePath);
      }

      final file = File(localFilePath);
      if (!await file.exists()) return null;
      final rawBytes = await file.readAsBytes();
      final sanitizedBytes = ExifSanitizer.stripExif(rawBytes);
      final validationError = AppLogger.validateImagePath(localFilePath, byteLength: sanitizedBytes.length);
      if (validationError != null) {
        AppLogger.warn('SupabaseService', validationError.message);
        throw validationError;
      }

      final ext = localFilePath.split('.').last.toLowerCase();
      final contentType = ext == 'png'
          ? 'image/png'
          : (ext == 'webp' ? 'image/webp' : 'image/jpeg');
      final storagePath = '${currentUser!.id}/drop_${DateTime.now().millisecondsSinceEpoch}.$ext';

      await client.storage.from('post-media').uploadBinary(
            storagePath,
            sanitizedBytes,
            fileOptions: FileOptions(contentType: contentType, upsert: false),
          );
      final signedUrl = await client.storage.from('post-media').createSignedUrl(storagePath, 60 * 60 * 24 * 365);
      return UploadedMediaResult(storagePath: storagePath, mediaUrl: signedUrl);
    } catch (e) {
      AppLogger.error('SupabaseService', 'Media upload error', e);
      return null;
    }
  }

  /// Alias for uploadDropMedia (P8-02 / Experience Domain).
  static Future<String?> uploadPostMedia(String localFilePath) => uploadDropMedia(localFilePath);

  /// Backward-compatible wrapper returning the uploaded media URL.
  static Future<String?> uploadDropMedia(String localFilePath) async {
    final res = await uploadDropMediaResult(localFilePath);
    return res?.mediaUrl;
  }

  /// Cleans up an orphaned object in `post-media` using its internal `storagePath` if DB insertion fails (FEATURE-03 / SEC-14).
  static Future<void> removeOrphanedMedia(String storagePath) async {
    if (!_isInitialized || currentUser == null) return;
    if (storagePath.startsWith('assets/') || storagePath.startsWith('http')) return;
    try {
      await client.storage.from('post-media').remove([storagePath]);
    } catch (e) {
      AppLogger.warn('SupabaseService', 'Failed cleaning up orphaned media $storagePath', e);
    }
  }
}
