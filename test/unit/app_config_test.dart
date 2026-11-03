import 'package:flutter_test/flutter_test.dart';
import 'package:around_app/core/config/app_config.dart';
import 'package:around_app/data/services/supabase_service.dart';

void main() {
  group('AppConfig & Environment Resolution Tests (P12-01)', () {
    test('AppEnvironment enum provides correct flags and labels', () {
      expect(AppEnvironment.dev.isDev, isTrue);
      expect(AppEnvironment.dev.isStaging, isFalse);
      expect(AppEnvironment.dev.isProduction, isFalse);
      expect(AppEnvironment.dev.label, equals('development'));

      expect(AppEnvironment.staging.isStaging, isTrue);
      expect(AppEnvironment.staging.isDev, isFalse);
      expect(AppEnvironment.staging.label, equals('staging'));

      expect(AppEnvironment.production.isProduction, isTrue);
      expect(AppEnvironment.production.isDev, isFalse);
      expect(AppEnvironment.production.label, equals('production'));
    });

    test('parseEnvironment correctly parses variations and fallbacks', () {
      expect(AppConfig.parseEnvironment('prod'), equals(AppEnvironment.production));
      expect(AppConfig.parseEnvironment('production'), equals(AppEnvironment.production));
      expect(AppConfig.parseEnvironment('PRODUCTION'), equals(AppEnvironment.production));

      expect(AppConfig.parseEnvironment('staging'), equals(AppEnvironment.staging));
      expect(AppConfig.parseEnvironment('stage'), equals(AppEnvironment.staging));
      expect(AppConfig.parseEnvironment('STAGING'), equals(AppEnvironment.staging));

      expect(AppConfig.parseEnvironment('dev'), equals(AppEnvironment.dev));
      expect(AppConfig.parseEnvironment('development'), equals(AppEnvironment.dev));
      expect(AppConfig.parseEnvironment('unknown_env'), equals(AppEnvironment.dev));
      expect(AppConfig.parseEnvironment(''), equals(AppEnvironment.dev));
    });

    test('validateCredentials rejects dangerous service_role keys', () {
      final error = AppConfig.validateCredentials(
        url: 'https://xyz.supabase.co',
        anonKey: 'eyJh...service_role...secret',
        environment: AppEnvironment.production,
      );

      expect(error, isNotNull);
      expect(error, contains('CRITICAL SECURITY VIOLATION'));
      expect(error, contains('service_role'));
    });

    test('validateCredentials rejects insecure HTTP in cloud environments', () {
      final error = AppConfig.validateCredentials(
        url: 'http://my-supabase.com',
        anonKey: 'valid_anon_key',
        environment: AppEnvironment.staging,
      );

      expect(error, isNotNull);
      expect(error, contains('Must use HTTPS'));
    });

    test('validateCredentials rejects localhost in production environment', () {
      final error = AppConfig.validateCredentials(
        url: 'http://localhost:54321',
        anonKey: 'valid_anon_key',
        environment: AppEnvironment.production,
      );

      expect(error, isNotNull);
      expect(error, contains('Production environment cannot point to localhost'));
    });

    test('validateCredentials passes valid HTTPS configuration cleanly', () {
      final error = AppConfig.validateCredentials(
        url: 'https://prod.around.tashkent.app.supabase.co',
        anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.valid_anon_key',
        environment: AppEnvironment.production,
      );

      expect(error, isNull);
    });

    test('validateCredentials handles empty local development fallback', () {
      final message = AppConfig.validateCredentials(
        url: '',
        anonKey: '',
        environment: AppEnvironment.dev,
      );

      expect(message, isNotNull);
      expect(message, contains('local persistence mode active'));
    });

    test('SupabaseService exposes AppConfig current environment bindings', () {
      expect(SupabaseService.appEnv, equals(AppConfig.current.environment.label));
      expect(SupabaseService.envUrl, equals(AppConfig.current.supabaseUrl));
      expect(SupabaseService.envAnonKey, equals(AppConfig.current.supabaseAnonKey));
    });
  });
}
