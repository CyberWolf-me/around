import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/routing/app_router.dart';
import 'core/theme/app_theme.dart';
import 'data/services/storage_service.dart';
import 'data/services/supabase_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await StorageService.init();

  // If user stored custom Supabase credentials, initialize with them
  final customUrl = StorageService.getSupabaseUrl();
  final customKey = StorageService.getSupabaseAnonKey();
  if (customUrl != null && customKey != null && customUrl.isNotEmpty && customKey.isNotEmpty) {
    await SupabaseService.initialize(url: customUrl, anonKey: customKey);
  }

  runApp(
    const ProviderScope(
      child: AroundApp(),
    ),
  );
}

class AroundApp extends StatelessWidget {
  const AroundApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Around · Tashkent Discovery',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: appRouter,
    );
  }
}
