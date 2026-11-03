import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/friend_invite_service.dart';
import '../../../core/services/telegram_share_service.dart';
import '../../../core/widgets/bouncing_widget.dart';
import '../../../data/repositories/profiles_repository.dart';
import '../../../data/services/haptic_service.dart';

/// Screen handling incoming mutual friend invite links: around://invite/:code
class FriendInviteScreen extends ConsumerStatefulWidget {
  final String inviteCode;

  const FriendInviteScreen({super.key, required this.inviteCode});

  @override
  ConsumerState<FriendInviteScreen> createState() => _FriendInviteScreenState();
}

class _FriendInviteScreenState extends ConsumerState<FriendInviteScreen> {
  bool _accepted = false;

  @override
  Widget build(BuildContext context) {
    final payload = FriendInviteService.parseInviteCode(widget.inviteCode);
    final currentProfile = ref.watch(currentProfileProvider);
    final blockedUsers = ref.watch(blockedUsersProvider);
    final relations = ref.watch(friendshipStatusesProvider);

    return Scaffold(
      backgroundColor: AppColors.paper,
      appBar: AppBar(
        backgroundColor: AppColors.paper,
        elevation: 0,
        leading: const BackButton(color: AppColors.ink),
        title: Text(
          'Friend Connection',
          style: GoogleFonts.bricolageGrotesque(
            fontWeight: FontWeight.w800,
            fontSize: 18,
            color: AppColors.ink,
          ),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: _buildContent(context, payload, currentProfile, blockedUsers, relations),
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    FriendInvitePayload? payload,
    dynamic currentProfile,
    Set<String> blockedUsers,
    Map<String, FriendshipRelation> relations,
  ) {
    // 1. Invalid or expired check
    if (payload == null || payload.isExpired) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.cardSurface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.borderSubtle, width: 1.5),
          boxShadow: const [AppColors.shadowCard],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(color: AppColors.paper2, shape: BoxShape.circle),
              child: const Icon(Icons.link_off, size: 36, color: AppColors.ink3),
            ),
            const SizedBox(height: 16),
            Text(
              'Invalid or Expired Invite',
              style: GoogleFonts.bricolageGrotesque(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'This Tashkent friend invite link is either expired (14-day limit) or invalid. Ask your friend for a new invite link.',
              style: GoogleFonts.instrumentSans(fontSize: 13, color: AppColors.ink2),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            BouncingWidget(
              onTap: () => context.go('/feed'),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.paper2,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.borderHairline, width: 1),
                ),
                child: const Text('Return to Feed', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.ink)),
              ),
            ),
          ],
        ),
      );
    }

    // 2. Self invite check
    if (payload.inviterId == currentProfile.id || payload.username == currentProfile.username) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.cardSurface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.borderSubtle, width: 1.5),
          boxShadow: const [AppColors.shadowCard],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(color: AppColors.butter, shape: BoxShape.circle),
              child: const Icon(Icons.qr_code, size: 36, color: AppColors.ink),
            ),
            const SizedBox(height: 16),
            Text(
              'Your Personal Invite Link',
              style: GoogleFonts.bricolageGrotesque(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'This is your own friend invite code. Share it with friends across Tashkent to connect instantly.',
              style: GoogleFonts.instrumentSans(fontSize: 13, color: AppColors.ink2),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: BouncingWidget(
                    onTap: () {
                      HapticService.selection();
                      FriendInviteService.copyInviteLink(
                        inviterId: currentProfile.id,
                        username: currentProfile.username,
                        fullName: currentProfile.fullName,
                        neighborhood: currentProfile.neighborhood,
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('✓ Invite link copied to clipboard')),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppColors.paper2,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.borderSubtle, width: 1.2),
                      ),
                      alignment: Alignment.center,
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.copy, size: 14, color: AppColors.ink),
                          SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              'Copy Link',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.ink, fontSize: 12),
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
                    onTap: () async {
                      HapticService.medium();
                      await TelegramShareService.shareInviteToTelegram(
                        inviterId: currentProfile.id,
                        username: currentProfile.username,
                        fullName: currentProfile.fullName,
                        neighborhood: currentProfile.neighborhood,
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF229ED9),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: const [AppColors.shadowTactile],
                      ),
                      alignment: Alignment.center,
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.send_rounded, size: 14, color: Colors.white),
                          SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              'Telegram',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    // 3. Block precedence check (Security invariant Rule C)
    if (blockedUsers.contains(payload.inviterId)) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.cardSurface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.borderSubtle, width: 1.5),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.block, size: 36, color: AppColors.ink3),
            const SizedBox(height: 14),
            Text(
              'Connection Unavailable',
              style: GoogleFonts.bricolageGrotesque(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.ink),
            ),
            const SizedBox(height: 6),
            const Text(
              'You cannot connect with this user due to privacy preferences.',
              style: TextStyle(fontSize: 13, color: AppColors.ink2),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    // 4. Current relationship check
    final relation = relations[payload.inviterId] ?? FriendshipRelation.none;
    final isAlreadyFriend = relation == FriendshipRelation.accepted || _accepted;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.ink, width: 2),
        boxShadow: const [AppColors.shadowCard],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header ribbon
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: AppColors.ink,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'TASHKENT FRIEND INVITE',
                  style: GoogleFonts.spaceMono(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppColors.paper,
                    letterSpacing: 0.8,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.butter,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    payload.neighborhood.toUpperCase(),
                    style: GoogleFonts.spaceMono(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.ink),
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundColor: AppColors.orange,
                  child: Text(
                    payload.fullName.isNotEmpty ? payload.fullName[0].toUpperCase() : 'C',
                    style: GoogleFonts.bricolageGrotesque(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  payload.fullName,
                  style: GoogleFonts.bricolageGrotesque(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink,
                  ),
                ),
                Text(
                  '@${payload.username} · ${payload.neighborhood}',
                  style: GoogleFonts.instrumentSans(
                    fontSize: 13,
                    color: AppColors.ink2,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.paper2,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.borderHairline, width: 1),
                  ),
                  child: Text(
                    isAlreadyFriend
                        ? '✓ You and ${payload.fullName} are mutual friends. You can see each other\'s curated drops and district recommendations.'
                        : '${payload.fullName} invited you to connect as mutual friends on Around Tashkent. Connecting gives mutual access to friend-only drops.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.instrumentSans(fontSize: 12.5, color: AppColors.ink),
                  ),
                ),
                const SizedBox(height: 20),

                if (isAlreadyFriend)
                  BouncingWidget(
                    onTap: () => context.go('/users/${payload.inviterId}'),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: AppColors.butter,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.ink, width: 1.5),
                        boxShadow: const [AppColors.shadowTactile],
                      ),
                      alignment: Alignment.center,
                      child: const Text(
                        'View Profile & Drops',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.ink),
                      ),
                    ),
                  )
                else
                  Row(
                    children: [
                      Expanded(
                        child: BouncingWidget(
                          onTap: () => context.pop(),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: AppColors.paper2,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.borderSubtle, width: 1),
                            ),
                            alignment: Alignment.center,
                            child: const Text(
                              'Not Now',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.ink2),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: BouncingWidget(
                          onTap: () async {
                            HapticService.medium();
                            await ref.read(friendshipStatusesProvider.notifier).acceptIncomingRequest(payload.inviterId);
                            setState(() {
                              _accepted = true;
                            });
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('✓ Connected with @${payload.username} as mutual friends!'),
                                  backgroundColor: AppColors.ink,
                                ),
                              );
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: AppColors.orange,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.ink, width: 1.5),
                              boxShadow: const [AppColors.shadowTactile],
                            ),
                            alignment: Alignment.center,
                            child: const Text(
                              'Connect as Friends',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
