import 'package:flutter/foundation.dart';

/// Available application deployment environments.
enum AppEnvironment {
  dev,
  staging,
  production;

  bool get isDev => this == AppEnvironment.dev;
  bool get isStaging => this == AppEnvironment.staging;
  bool get isProduction => this == AppEnvironment.production;

  String get label => switch (this) {
        AppEnvironment.dev => 'development',
        AppEnvironment.staging => 'staging',
        AppEnvironment.production => 'production',
      };
}

/// Centralized configuration provider resolving compile-time variables
/// injected via `--dart-define` or `--dart-define-from-file`.
class AppConfig {
  final AppEnvironment environment;
  final String supabaseUrl;
  final String supabaseAnonKey;
  final String deepLinkDomain;
  final Duration apiTimeout;
  final bool enableDetailedLogs;
  final bool enableAnalytics;

  const AppConfig({
    required this.environment,
    required this.supabaseUrl,
    required this.supabaseAnonKey,
    required this.deepLinkDomain,
    required this.apiTimeout,
    required this.enableDetailedLogs,
    required this.enableAnalytics,
  });

  /// Parse environment from compile-time definition with fallback to development.
  static AppEnvironment parseEnvironment(String raw) {
    final normalized = raw.trim().toLowerCase();
    if (normalized == 'production' || normalized == 'prod') {
      return AppEnvironment.production;
    }
    if (normalized == 'staging' || normalized == 'stage') {
      return AppEnvironment.staging;
    }
    return AppEnvironment.dev;
  }

  /// Active application configuration resolved from build definitions.
  static final AppConfig current = _resolveFromEnvironment();

  static AppConfig _resolveFromEnvironment() {
    const rawEnv = String.fromEnvironment(
      'ENV',
      defaultValue: String.fromEnvironment('APP_ENV', defaultValue: 'dev'),
    );
    final env = parseEnvironment(rawEnv);

    const rawUrl = String.fromEnvironment('SUPABASE_URL', defaultValue: '');
    const rawAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: '');
    const rawDomain = String.fromEnvironment('DEEP_LINK_DOMAIN', defaultValue: '');

    final deepLinkDomain = rawDomain.isNotEmpty
        ? rawDomain
        : switch (env) {
            AppEnvironment.production => 'around.tashkent.app',
            AppEnvironment.staging => 'staging.around.tashkent.app',
            AppEnvironment.dev => 'dev.around.tashkent.app',
          };

    final timeoutSeconds = int.tryParse(
      const String.fromEnvironment('API_TIMEOUT_SECONDS', defaultValue: ''),
    );

    final apiTimeout = Duration(
      seconds: timeoutSeconds ?? (env.isProduction ? 15 : 30),
    );

    return AppConfig(
      environment: env,
      supabaseUrl: rawUrl,
      supabaseAnonKey: rawAnonKey,
      deepLinkDomain: deepLinkDomain,
      apiTimeout: apiTimeout,
      enableDetailedLogs: !env.isProduction || kDebugMode,
      enableAnalytics: env.isProduction || env.isStaging,
    );
  }

  /// Validates that Supabase credentials satisfy production security invariants.
  /// Throws [SecurityException] or returns error message if credentials violate invariants.
  static String? validateCredentials({
    required String url,
    required String anonKey,
    required AppEnvironment environment,
  }) {
    if (url.isEmpty && anonKey.isEmpty) {
      return 'No credentials provided (local persistence mode active).';
    }

    if (anonKey.toLowerCase().contains('service_role')) {
      return 'CRITICAL SECURITY VIOLATION: service_role key must NEVER be embedded in client code or builds.';
    }

    if (url.isNotEmpty && !url.startsWith('https://') && !url.startsWith('http://localhost') && !url.startsWith('http://127.0.0.1')) {
      return 'Invalid Supabase URL: Must use HTTPS (or localhost in dev).';
    }

    if (environment.isProduction && (url.contains('localhost') || url.contains('127.0.0.1'))) {
      return 'Invalid configuration: Production environment cannot point to localhost.';
    }

    return null;
  }
}
