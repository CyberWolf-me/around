import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/repositories/posts_repository.dart';
import '../../../data/repositories/profiles_repository.dart';
import '../../../data/repositories/saved_places_repository.dart';
import '../../../data/services/haptic_service.dart';
import '../../../data/services/storage_service.dart';
import '../../../data/services/supabase_service.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  void _showExportDataDialog() {
    HapticService.light();
    final profile = ref.read(currentProfileProvider);
    final drops = ref.read(postsRepositoryProvider).where((p) => p.authorId == 'you').toList();
    final savedIds = ref.read(savedPlacesProvider);
    final statuses = ref.read(savedPlaceStatusesProvider);
    final plans = ref.read(friendPlansProvider);

    final exportPayload = const JsonEncoder.withIndent('  ').convert({
      'exported_at': DateTime.now().toIso8601String(),
      'profile': profile.toJson(),
      'my_drops': drops.map((d) => d.toJson()).toList(),
      'saved_places': savedIds.map((id) => {'place_id': id, 'status': statuses[id] ?? 'want_to_go'}).toList(),
      'friend_plans': plans.map((p) => p.toJson()).toList(),
    });

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.paper,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.ink, width: 2),
        ),
        title: Text('GDPR Data Export (JSON)', style: GoogleFonts.bricolageGrotesque(fontWeight: FontWeight.w800, fontSize: 18)),
        content: SizedBox(
          width: double.maxFinite,
          height: 220,
          child: SingleChildScrollView(
            child: SelectableText(
              exportPayload,
              style: GoogleFonts.spaceMono(fontSize: 10, color: AppColors.ink2),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close', style: TextStyle(color: AppColors.ink3)),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: exportPayload));
              if (ctx.mounted) Navigator.pop(ctx);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('GDPR JSON export copied to clipboard')),
                );
              }
            },
            icon: const Icon(Icons.copy, size: 14, color: Colors.white),
            label: const Text('Copy JSON', style: TextStyle(color: Colors.white)),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.orange),
          ),
        ],
      ),
    );
  }

  void _showBlockedUsersDialog() {
    showDialog(
      context: context,
      builder: (ctx) => Consumer(
        builder: (ctx, dialogRef, _) {
          final blockedIds = dialogRef.watch(blockedUsersProvider);
          return AlertDialog(
            backgroundColor: AppColors.paper,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: AppColors.ink, width: 2),
            ),
            title: Text('Blocked Accounts', style: GoogleFonts.bricolageGrotesque(fontWeight: FontWeight.w800, fontSize: 18)),
            content: blockedIds.isEmpty
                ? const Text('You have not blocked any accounts.', style: TextStyle(fontSize: 13))
                : SizedBox(
                    width: double.maxFinite,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: blockedIds.map((id) {
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text('@$id', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          trailing: TextButton(
                            onPressed: () => dialogRef.read(blockedUsersProvider.notifier).unblockUser(id),
                            child: const Text('Unblock', style: TextStyle(color: AppColors.orange, fontWeight: FontWeight.bold)),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
            actions: [
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.ink),
                child: const Text('Done', style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showReportIssueDialog() {
    final detailsCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.paper,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.ink, width: 2),
        ),
        title: Text('Report a Safety or Venue Issue', style: GoogleFonts.bricolageGrotesque(fontWeight: FontWeight.w800, fontSize: 17)),
        content: TextField(
          controller: detailsCtrl,
          maxLines: 3,
          maxLength: 500,
          decoration: const InputDecoration(
            hintText: 'Describe the inappropriate content, bug, or venue inaccuracy...',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppColors.ink3)),
          ),
          ElevatedButton(
            onPressed: () async {
              if (detailsCtrl.text.trim().length < 3) return;
              await StorageService.addReport({
                'target_type': 'place',
                'target_id': 'general',
                'reason': detailsCtrl.text.trim(),
                'created_at': DateTime.now().toIso8601String(),
              });
              if (ctx.mounted) Navigator.pop(ctx);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Report logged for Trust & Safety review (24h SLA).')),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger, foregroundColor: Colors.white),
            child: const Text('Submit Report'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDeleteOrResetAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.paper,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.ink, width: 2),
        ),
        title: const Text('Delete Account & Reset Data?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        content: const Text(
          'This invokes the server-side account deletion procedure (cascading all drops, friendships, saved places, and media) and resets local device storage.',
          style: TextStyle(fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: AppColors.ink3)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger, foregroundColor: Colors.white),
            child: const Text('Delete Account'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      if (SupabaseService.isAuthenticated) {
        await SupabaseService.deleteOwnAccount();
      } else {
        await SupabaseService.signOut();
      }
      await StorageService.clearAll();
      ref.invalidate(currentProfileProvider);
      ref.invalidate(postsRepositoryProvider);
      ref.invalidate(savedPlacesProvider);
      ref.invalidate(savedPlaceStatusesProvider);
      ref.invalidate(followedFriendsProvider);
      ref.invalidate(friendshipStatusesProvider);
      ref.invalidate(blockedUsersProvider);
      ref.invalidate(friendPlansProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Account deleted and local session reset.')),
        );
        context.go('/onboarding');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(currentProfileProvider);
    final profileNotifier = ref.read(currentProfileProvider.notifier);
    final blockedUsers = ref.watch(blockedUsersProvider);
    final authEmail = StorageService.getAuthUserEmail();

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
          Text(
            'WHO SEES YOUR DROPS BY DEFAULT',
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
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
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
                  'Every new drop starts with this visibility. You can customize per drop anytime.',
                  style: TextStyle(fontSize: 11, color: AppColors.ink2),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
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
                  subtitle: const Text('Places you visit are never shown as a chronological timeline.', style: TextStyle(fontSize: 10.5)),
                  value: profile.hideVisitsHistory,
                  activeThumbColor: AppColors.orange,
                  onChanged: (val) {
                    HapticService.light();
                    profileNotifier.updatePrivacySettings(hideVisits: val);
                  },
                ),
                const Divider(height: 1, indent: 14, endIndent: 14),
                SwitchListTile(
                  title: const Text('Let friends find me', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  subtitle: const Text('Allow mutual connections to discover your profile.', style: TextStyle(fontSize: 10.5)),
                  value: profile.discoverableByFriends,
                  activeThumbColor: AppColors.orange,
                  onChanged: (val) {
                    HapticService.light();
                    profileNotifier.updatePrivacySettings(discoverableByFriends: val);
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
                const Divider(height: 1, indent: 14, endIndent: 14),
                SwitchListTile(
                  title: const Text('Allow friend requests', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  subtitle: const Text('Let Tashkent community members request connection.', style: TextStyle(fontSize: 10.5)),
                  value: profile.allowFriendRequests,
                  activeThumbColor: AppColors.orange,
                  onChanged: (val) {
                    HapticService.light();
                    profileNotifier.updatePrivacySettings(allowFriendRequests: val);
                  },
                ),
                const Divider(height: 1, indent: 14, endIndent: 14),
                ListTile(
                  leading: const Icon(Icons.shield_outlined, color: AppColors.ink),
                  title: const Text('Blocked accounts', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  subtitle: Text('${blockedUsers.length} users blocked', style: const TextStyle(fontSize: 10.5)),
                  trailing: const Icon(Icons.chevron_right, size: 18),
                  onTap: _showBlockedUsersDialog,
                ),
                const Divider(height: 1, indent: 14, endIndent: 14),
                ListTile(
                  leading: const Icon(Icons.flag_outlined, color: AppColors.danger),
                  title: const Text('Report an issue', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.danger)),
                  subtitle: const Text('Report inappropriate content or venue inaccuracies', style: TextStyle(fontSize: 10.5)),
                  trailing: const Icon(Icons.chevron_right, size: 18),
                  onTap: _showReportIssueDialog,
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'ACCOUNT & SESSION',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(fontSize: 9.5),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.all(14),
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
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: authEmail != null ? const Color(0xFF10B981) : AppColors.orange,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        authEmail != null ? 'Signed in as $authEmail' : 'Local Explorer Session (@${profile.username})',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => context.push('/auth'),
                    icon: const Icon(Icons.login, size: 16),
                    label: Text(authEmail != null ? 'Switch Account' : 'Sign In / Create Account'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.ink,
                      foregroundColor: AppColors.paper,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () => context.push('/onboarding'),
            icon: const Icon(Icons.explore_outlined, size: 16),
            label: const Text('Replay Onboarding Walkthrough'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.paper2,
              foregroundColor: AppColors.ink,
              elevation: 0,
              side: const BorderSide(color: AppColors.ink, width: 1.5),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 8),
          ElevatedButton.icon(
            onPressed: _showExportDataDialog,
            icon: const Icon(Icons.download, size: 16),
            label: const Text('Export My Data (GDPR JSON format)'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.paper2,
              foregroundColor: AppColors.ink,
              elevation: 0,
              side: const BorderSide(color: AppColors.ink, width: 1.5),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 8),
          ElevatedButton.icon(
            onPressed: _confirmDeleteOrResetAccount,
            icon: const Icon(Icons.delete_outline, size: 16, color: Colors.white),
            label: const Text('Delete Account & Reset Data', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              elevation: 0,
              side: const BorderSide(color: AppColors.ink, width: 1.5),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
