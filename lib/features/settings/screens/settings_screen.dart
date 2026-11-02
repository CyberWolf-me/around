import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/biometric_service.dart';
import '../../../core/widgets/bouncing_widget.dart';
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
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.borderSubtle, width: 1),
        ),
        title: Text(
          'GDPR Data Export',
          style: GoogleFonts.bricolageGrotesque(fontWeight: FontWeight.w800, fontSize: 18, color: AppColors.ink),
        ),
        content: SizedBox(
          width: double.maxFinite,
          height: 240,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.paper2,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.borderHairline),
            ),
            child: SingleChildScrollView(
              child: SelectableText(
                exportPayload,
                style: GoogleFonts.spaceMono(fontSize: 10, color: AppColors.ink2),
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close', style: TextStyle(color: AppColors.ink3, fontWeight: FontWeight.bold)),
          ),
          BouncingWidget(
            onTap: () async {
              await Clipboard.setData(ClipboardData(text: exportPayload));
              if (ctx.mounted) Navigator.pop(ctx);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('GDPR JSON export copied to clipboard')),
                );
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.orange,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.copy, size: 14, color: Colors.white),
                  SizedBox(width: 6),
                  Text('Copy JSON', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12.5)),
                ],
              ),
            ),
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
            surfaceTintColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: const BorderSide(color: AppColors.borderSubtle, width: 1),
            ),
            title: Text(
              'Blocked Accounts',
              style: GoogleFonts.bricolageGrotesque(fontWeight: FontWeight.w800, fontSize: 18, color: AppColors.ink),
            ),
            content: blockedIds.isEmpty
                ? const Text('You have not blocked any accounts.', style: TextStyle(fontSize: 13, color: AppColors.ink2))
                : SizedBox(
                    width: double.maxFinite,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: blockedIds.map((id) {
                        return Container(
                          margin: const EdgeInsets.only(bottom: 6),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.paper2,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text('@$id', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.ink)),
                              ),
                              BouncingWidget(
                                onTap: () => dialogRef.read(blockedUsersProvider.notifier).unblockUser(id),
                                child: const Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  child: Text('Unblock', style: TextStyle(color: AppColors.orange, fontWeight: FontWeight.bold, fontSize: 12)),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Done', style: TextStyle(color: AppColors.ink, fontWeight: FontWeight.bold)),
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
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.borderSubtle, width: 1),
        ),
        title: Text(
          'Report an Issue',
          style: GoogleFonts.bricolageGrotesque(fontWeight: FontWeight.w800, fontSize: 18, color: AppColors.ink),
        ),
        content: TextField(
          controller: detailsCtrl,
          maxLines: 4,
          maxLength: 500,
          decoration: InputDecoration(
            hintText: 'Describe inappropriate content, bugs, or venue inaccuracies...',
            filled: true,
            fillColor: AppColors.paper2,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.borderHairline),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppColors.ink3)),
          ),
          BouncingWidget(
            onTap: () async {
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
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.danger,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text('Submit Report', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12.5)),
            ),
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
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.borderSubtle, width: 1),
        ),
        title: Text(
          'Delete Account & Reset Data?',
          style: GoogleFonts.bricolageGrotesque(fontWeight: FontWeight.w800, fontSize: 18, color: AppColors.danger),
        ),
        content: const Text(
          'This invokes the server-side account deletion procedure (cascading all drops, friendships, saved places, and media) and resets local device storage.',
          style: TextStyle(fontSize: 13, color: AppColors.ink2, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: AppColors.ink3)),
          ),
          BouncingWidget(
            onTap: () => Navigator.pop(ctx, true),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.danger,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text('Delete Account', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12.5)),
            ),
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

  Future<void> _handleSignOut() async {
    HapticService.light();
    await SupabaseService.signOut();
    await StorageService.clearAuthSession();
    await ref.read(currentProfileProvider.notifier).resetToGuest();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Signed out successfully.')),
    );
    context.go('/auth');
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
        title: Text(
          'Settings',
          style: GoogleFonts.bricolageGrotesque(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppColors.ink,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          // Section: Default Visibility
          const _SectionTitle(title: 'DEFAULT VISIBILITY'),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.cardSurface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.borderSubtle, width: 1),
              boxShadow: const [AppColors.shadowCard],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: BouncingWidget(
                        onTap: () {
                          HapticService.selection();
                          profileNotifier.updatePrivacySettings(defaultAud: 'friends');
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: profile.defaultAudience == 'friends' ? AppColors.butter : AppColors.paper2,
                            border: Border.all(
                              color: profile.defaultAudience == 'friends' ? AppColors.ink : AppColors.borderHairline,
                              width: profile.defaultAudience == 'friends' ? 1.5 : 1,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: profile.defaultAudience == 'friends' ? const [AppColors.shadowTactile] : null,
                          ),
                          alignment: Alignment.center,
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.lock_outline, size: 14, color: AppColors.ink),
                              SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  'Friends only',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.ink),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: BouncingWidget(
                        onTap: () {
                          HapticService.selection();
                          profileNotifier.updatePrivacySettings(defaultAud: 'public');
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: profile.defaultAudience == 'public' ? AppColors.ink : AppColors.paper2,
                            border: Border.all(
                              color: profile.defaultAudience == 'public' ? AppColors.ink : AppColors.borderHairline,
                              width: 1,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: profile.defaultAudience == 'public' ? const [AppColors.shadowTactile] : null,
                          ),
                          alignment: Alignment.center,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.public,
                                size: 14,
                                color: profile.defaultAudience == 'public' ? Colors.white : AppColors.ink,
                              ),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  'Public',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                    color: profile.defaultAudience == 'public' ? Colors.white : AppColors.ink,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                const Text(
                  'Every new drop starts with this visibility. You can customize per drop anytime.',
                  style: TextStyle(fontSize: 11.5, color: AppColors.ink2, height: 1.3),
                ),
              ],
            ),
          ),

          const SizedBox(height: 22),

          // Section: Privacy & Safety
          const _SectionTitle(title: 'PRIVACY & SECURITY'),
          Material(
            color: AppColors.cardSurface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
              side: const BorderSide(color: AppColors.borderSubtle, width: 1),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('Require Biometrics on Resume', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.ink)),
                  subtitle: const Text('Prompt for Face ID / Fingerprint after 60s backgrounded.', style: TextStyle(fontSize: 11, color: AppColors.ink2)),
                  value: ref.watch(biometricLockEnabledProvider),
                  activeThumbColor: AppColors.orange,
                  onChanged: (val) {
                    HapticService.light();
                    ref.read(biometricLockEnabledProvider.notifier).setEnabled(val);
                  },
                ),
                const Divider(height: 1, color: AppColors.borderHairline, indent: 16, endIndent: 16),
                SwitchListTile(
                  title: const Text('Keep my visits private', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.ink)),
                  subtitle: const Text('Places you visit are never shown as a chronological timeline.', style: TextStyle(fontSize: 11, color: AppColors.ink2)),
                  value: profile.hideVisitsHistory,
                  activeThumbColor: AppColors.orange,
                  onChanged: (val) {
                    HapticService.light();
                    profileNotifier.updatePrivacySettings(hideVisits: val);
                  },
                ),
                const Divider(height: 1, color: AppColors.borderHairline, indent: 16, endIndent: 16),
                SwitchListTile(
                  title: const Text('Let friends find me', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.ink)),
                  subtitle: const Text('Allow mutual connections to discover your profile.', style: TextStyle(fontSize: 11, color: AppColors.ink2)),
                  value: profile.discoverableByFriends,
                  activeThumbColor: AppColors.orange,
                  onChanged: (val) {
                    HapticService.light();
                    profileNotifier.updatePrivacySettings(discoverableByFriends: val);
                  },
                ),
                const Divider(height: 1, color: AppColors.borderHairline, indent: 16, endIndent: 16),
                SwitchListTile(
                  title: const Text('Quiet hours', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.ink)),
                  subtitle: const Text('Silence notifications between 11pm and 8am.', style: TextStyle(fontSize: 11, color: AppColors.ink2)),
                  value: profile.quietHours,
                  activeThumbColor: AppColors.orange,
                  onChanged: (val) {
                    HapticService.light();
                    profileNotifier.updatePrivacySettings(quietHours: val);
                  },
                ),
                const Divider(height: 1, color: AppColors.borderHairline, indent: 16, endIndent: 16),
                SwitchListTile(
                  title: const Text('Allow friend requests', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.ink)),
                  subtitle: const Text('Let Tashkent community members request connection.', style: TextStyle(fontSize: 11, color: AppColors.ink2)),
                  value: profile.allowFriendRequests,
                  activeThumbColor: AppColors.orange,
                  onChanged: (val) {
                    HapticService.light();
                    profileNotifier.updatePrivacySettings(allowFriendRequests: val);
                  },
                ),
                const Divider(height: 1, color: AppColors.borderHairline, indent: 16, endIndent: 16),
                ListTile(
                  leading: const Icon(Icons.shield_outlined, color: AppColors.ink, size: 20),
                  title: const Text('Blocked accounts', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.ink)),
                  subtitle: Text('${blockedUsers.length} users blocked', style: const TextStyle(fontSize: 11, color: AppColors.ink2)),
                  trailing: const Icon(Icons.chevron_right, size: 18, color: AppColors.ink3),
                  onTap: _showBlockedUsersDialog,
                ),
                const Divider(height: 1, color: AppColors.borderHairline, indent: 16, endIndent: 16),
                ListTile(
                  leading: const Icon(Icons.flag_outlined, color: AppColors.danger, size: 20),
                  title: const Text('Report an issue', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.danger)),
                  subtitle: const Text('Report inappropriate content or venue inaccuracies', style: TextStyle(fontSize: 11, color: AppColors.ink2)),
                  trailing: const Icon(Icons.chevron_right, size: 18, color: AppColors.ink3),
                  onTap: _showReportIssueDialog,
                ),
              ],
            ),
          ),

          const SizedBox(height: 22),

          // Section: Account & Session
          const _SectionTitle(title: 'ACCOUNT & SESSION'),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.cardSurface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.borderSubtle, width: 1),
              boxShadow: const [AppColors.shadowCard],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 9,
                      height: 9,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: authEmail != null ? const Color(0xFF10B981) : AppColors.orange,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        authEmail != null ? 'Signed in as $authEmail' : 'Local Explorer Session (@${profile.username})',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5, color: AppColors.ink),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                BouncingWidget(
                  onTap: () => context.push('/auth'),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.ink,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.center,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.login, size: 16, color: Colors.white),
                        const SizedBox(width: 8),
                        Text(
                          authEmail != null ? 'Switch Account' : 'Sign In / Create Account',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ),
                if (authEmail != null || SupabaseService.isAuthenticated) ...[
                  const SizedBox(height: 10),
                  BouncingWidget(
                    onTap: _handleSignOut,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: AppColors.paper,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.danger.withValues(alpha: 0.5), width: 1),
                      ),
                      alignment: Alignment.center,
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.logout, size: 16, color: AppColors.danger),
                          SizedBox(width: 8),
                          Text('Sign Out', style: TextStyle(color: AppColors.danger, fontWeight: FontWeight.bold, fontSize: 13)),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 22),

          // Secondary Utilities
          const _SectionTitle(title: 'PREFERENCES & DATA'),
          Material(
            color: AppColors.cardSurface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
              side: const BorderSide(color: AppColors.borderSubtle, width: 1),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.explore_outlined, color: AppColors.ink, size: 20),
                  title: const Text('Replay Onboarding Walkthrough', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.ink)),
                  trailing: const Icon(Icons.chevron_right, size: 18, color: AppColors.ink3),
                  onTap: () => context.push('/onboarding'),
                ),
                const Divider(height: 1, color: AppColors.borderHairline, indent: 16, endIndent: 16),
                ListTile(
                  leading: const Icon(Icons.download_outlined, color: AppColors.ink, size: 20),
                  title: const Text('Export My Data (GDPR JSON)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.ink)),
                  trailing: const Icon(Icons.chevron_right, size: 18, color: AppColors.ink3),
                  onTap: _showExportDataDialog,
                ),
                const Divider(height: 1, color: AppColors.borderHairline, indent: 16, endIndent: 16),
                ListTile(
                  leading: const Icon(Icons.delete_outline, color: AppColors.danger, size: 20),
                  title: const Text('Delete Account & Reset Data', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.danger)),
                  trailing: const Icon(Icons.chevron_right, size: 18, color: AppColors.ink3),
                  onTap: _confirmDeleteOrResetAccount,
                ),
              ],
            ),
          ),
          const SizedBox(height: 36),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: GoogleFonts.spaceMono(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.1,
          color: AppColors.ink3,
        ),
      ),
    );
  }
}
