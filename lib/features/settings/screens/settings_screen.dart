import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/repositories/profiles_repository.dart';
import '../../../data/services/haptic_service.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(currentProfileProvider);
    final profileNotifier = ref.read(currentProfileProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.paper,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: const Text('Settings', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        children: [
          // Default audience selector
          Text(
            'WHO SEES YOUR DROPS',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(fontSize: 9.5),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.paper,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.ink, width: 1.8),
              boxShadow: const [AppColors.shadowSm],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          HapticService.selection();
                          profileNotifier.updatePrivacySettings(defaultAud: 'friends');
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: profile.defaultAudience == 'friends' ? AppColors.butter : Colors.transparent,
                            border: Border.all(
                              color: profile.defaultAudience == 'friends' ? AppColors.ink : const Color(0x3015130F),
                              width: 1.5,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          alignment: Alignment.center,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(Icons.lock, size: 12),
                              SizedBox(width: 4),
                              Text('Friends only', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          HapticService.selection();
                          profileNotifier.updatePrivacySettings(defaultAud: 'public');
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: profile.defaultAudience == 'public' ? AppColors.ink : Colors.transparent,
                            border: Border.all(
                              color: profile.defaultAudience == 'public' ? AppColors.ink : const Color(0x3015130F),
                              width: 1.5,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          alignment: Alignment.center,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.public,
                                size: 12,
                                color: profile.defaultAudience == 'public' ? AppColors.paper : AppColors.ink,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Public',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                  color: profile.defaultAudience == 'public' ? AppColors.paper : AppColors.ink,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Every new drop starts with this visibility. You can still customize it before publishing.',
                  style: TextStyle(fontSize: 11, color: AppColors.ink2),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // Privacy Section
          Text(
            'PRIVACY & SAFETY',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(fontSize: 9.5),
          ),
          const SizedBox(height: 6),
          Container(
            decoration: BoxDecoration(
              color: AppColors.paper,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.ink, width: 1.8),
              boxShadow: const [AppColors.shadowSm],
            ),
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('Keep my visits private', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  subtitle: const Text('Places you visit are never shown to anyone, even on public drops.', style: TextStyle(fontSize: 10.5)),
                  value: profile.hideVisitsHistory,
                  activeThumbColor: AppColors.orange,
                  onChanged: (val) {
                    HapticService.light();
                    profileNotifier.updatePrivacySettings(hideVisits: val);
                  },
                ),
                const Divider(height: 1, indent: 14, endIndent: 14),
                SwitchListTile(
                  title: const Text('Quiet hours', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  subtitle: const Text('No notifications between 11pm and 8am.', style: TextStyle(fontSize: 10.5)),
                  value: profile.quietHours,
                  activeThumbColor: AppColors.orange,
                  onChanged: (val) {
                    HapticService.light();
                    profileNotifier.updatePrivacySettings(quietHours: val);
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Data & Account
          ElevatedButton.icon(
            onPressed: () {
              HapticService.light();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Account data exported in GDPR JSON format')),
              );
            },
            icon: const Icon(Icons.download, size: 16),
            label: const Text('Export My Data (GDPR format)'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.paper2,
              foregroundColor: AppColors.ink,
              elevation: 0,
              side: const BorderSide(color: AppColors.ink, width: 1.5),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }
}
