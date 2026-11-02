import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/bouncing_widget.dart';
import '../../../data/models/profile_model.dart';
import '../../../data/repositories/posts_repository.dart';
import '../../../data/repositories/profiles_repository.dart';
import '../../../data/repositories/saved_places_repository.dart';
import '../../../data/services/haptic_service.dart';
import '../../../data/services/supabase_service.dart';
import '../../../core/services/deep_link_service.dart';
import '../../../core/services/friend_invite_service.dart';
import '../../../core/services/telegram_share_service.dart';
import '../../../data/models/place_model.dart';
import '../../../data/repositories/places_repository.dart';
import '../widgets/taste_passport_card.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  void _showEditProfileDialog(BuildContext context, WidgetRef ref, ProfileModel profile) {
    final nameCtrl = TextEditingController(text: profile.fullName);
    final usernameCtrl = TextEditingController(text: profile.username);
    final neighborhoodCtrl = TextEditingController(text: profile.neighborhood);
    final bioCtrl = TextEditingController(text: profile.bio);

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
          'Edit Profile',
          style: GoogleFonts.bricolageGrotesque(
            fontWeight: FontWeight.w800,
            fontSize: 20,
            color: AppColors.ink,
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: InputDecoration(
                  labelText: 'Full Name',
                  filled: true,
                  fillColor: AppColors.paper2,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.borderHairline),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: usernameCtrl,
                decoration: InputDecoration(
                  labelText: 'Username (@handle)',
                  filled: true,
                  fillColor: AppColors.paper2,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.borderHairline),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: neighborhoodCtrl,
                decoration: InputDecoration(
                  labelText: 'Neighborhood / District',
                  filled: true,
                  fillColor: AppColors.paper2,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.borderHairline),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: bioCtrl,
                maxLines: 3,
                maxLength: 300,
                decoration: InputDecoration(
                  labelText: 'Bio & Tastes',
                  hintText: 'Favorite espresso bars, bakeries, or art spots...',
                  filled: true,
                  fillColor: AppColors.paper2,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.borderHairline),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppColors.ink3, fontWeight: FontWeight.w600)),
          ),
          BouncingWidget(
            onTap: () async {
              await ref.read(currentProfileProvider.notifier).updateProfileDetails(
                    fullName: nameCtrl.text,
                    username: usernameCtrl.text,
                    bio: bioCtrl.text,
                    neighborhood: neighborhoodCtrl.text,
                  );
              if (ctx.mounted) Navigator.pop(ctx);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Profile details updated')),
                );
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.orange,
                borderRadius: BorderRadius.circular(12),
                boxShadow: const [AppColors.shadowTactile],
              ),
              child: const Text(
                'Save Changes',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(currentProfileProvider);
    final posts = ref.watch(postsRepositoryProvider);
    final followedFriends = ref.watch(followedFriendsProvider);
    final savedPlaces = ref.watch(savedPlacesProvider);
    final placesRepo = ref.watch(placesRepositoryProvider);
    final allPlaces = placesRepo.getAllPlaces();
    final topPlaces = savedPlaces
        .map((id) => allPlaces.where((p) => p.id == PlacesRepository.resolveCanonicalId(id)).firstOrNull)
        .whereType<PlaceModel>()
        .take(3)
        .toList();

    final currentUserId = SupabaseService.currentUser?.id ?? profile.id;
    final myDrops = posts.where((p) => p.authorId == currentUserId || p.authorId == profile.id || p.authorId == 'you').toList();

    return Scaffold(
      backgroundColor: AppColors.paper,
      appBar: AppBar(
        title: Text(
          'Your Profile',
          style: GoogleFonts.bricolageGrotesque(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppColors.ink,
          ),
        ),
        actions: [
          BouncingWidget(
            onTap: () => context.push('/settings'),
            child: Container(
              margin: const EdgeInsets.only(right: 14),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.paper2,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.borderSubtle, width: 1),
              ),
              child: const Icon(Icons.settings_outlined, color: AppColors.ink, size: 20),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          if (profile.id == 'guest')
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.butterSubtle,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.butter, width: 1),
                boxShadow: const [AppColors.shadowSubtle],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.butter,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.person_outline, color: AppColors.ink, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Browsing as Guest',
                          style: GoogleFonts.bricolageGrotesque(fontWeight: FontWeight.w800, fontSize: 13, color: AppColors.ink),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Sign in to publish drops, build collections, and connect with friends.',
                          style: TextStyle(fontSize: 11, color: AppColors.ink2, height: 1.3),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  BouncingWidget(
                    onTap: () => context.push('/auth'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.orange,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: const [AppColors.shadowTactile],
                      ),
                      child: const Text('Sign In', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ),

          // Hero Profile Card
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.cardSurface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.borderSubtle, width: 1),
              boxShadow: const [AppColors.shadowCard],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 68,
                      height: 68,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [AppColors.orange, Color(0xFFEA580C)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        border: Border.all(color: Colors.white, width: 2.5),
                        boxShadow: const [AppColors.shadowSubtle],
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        profile.initials,
                        style: GoogleFonts.bricolageGrotesque(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            profile.fullName,
                            style: GoogleFonts.bricolageGrotesque(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: AppColors.ink,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Text(
                                '@${profile.username}',
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.ink2),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                width: 3,
                                height: 3,
                                decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.ink3),
                              ),
                              const SizedBox(width: 6),
                              const Icon(Icons.location_on, size: 12, color: AppColors.orange),
                              const SizedBox(width: 2),
                              Text(
                                profile.neighborhood,
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.ink),
                              ),
                            ],
                          ),
                          if (profile.bio.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text(
                              profile.bio,
                              style: const TextStyle(fontSize: 12.5, color: AppColors.ink2, height: 1.35),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Stats row in clean 3-part micro-bar
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  decoration: BoxDecoration(
                    color: AppColors.paper2,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.borderHairline, width: 1),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _StatItem(count: '${myDrops.length}', label: 'Drops'),
                      Container(width: 1, height: 26, color: AppColors.borderHairline),
                      _StatItem(count: '${followedFriends.length}', label: 'Friends'),
                      Container(width: 1, height: 26, color: AppColors.borderHairline),
                      _StatItem(count: '${savedPlaces.length}', label: 'Saved'),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: BouncingWidget(
                        onTap: () {
                          HapticService.light();
                          _showEditProfileDialog(context, ref, profile);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: AppColors.paper,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.borderSubtle, width: 1.2),
                            boxShadow: const [AppColors.shadowTactile],
                          ),
                          alignment: Alignment.center,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.edit_outlined, size: 14, color: AppColors.ink),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  'Edit Profile',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.instrumentSans(
                                    color: AppColors.ink,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12.5,
                                  ),
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
                          HapticService.light();
                          _showFindFriendsDialog(context, ref);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: AppColors.butter,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.borderSubtle, width: 1.2),
                            boxShadow: const [AppColors.shadowTactile],
                          ),
                          alignment: Alignment.center,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.person_add_outlined, size: 14, color: AppColors.ink),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  'Find Friends',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.instrumentSans(
                                    color: AppColors.ink,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12.5,
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
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Tashkent Taste Passport & Official Curator Badge
          TastePassportCard(
            profile: profile,
            topPlaces: topPlaces,
            totalDrops: myDrops.length,
            totalSaved: savedPlaces.length,
            onShare: () {
              DeepLinkService.copyPassportShareLink(profile.username);
            },
          ),

          const SizedBox(height: 24),

          // Header for drops
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Your Drops',
                style: GoogleFonts.bricolageGrotesque(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.paper2,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.borderHairline, width: 1),
                ),
                child: Text(
                  '${myDrops.length} published',
                  style: GoogleFonts.spaceMono(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: AppColors.ink2,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (myDrops.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
              decoration: BoxDecoration(
                color: AppColors.cardSurface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.borderSubtle, width: 1),
              ),
              alignment: Alignment.center,
              child: Column(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: const BoxDecoration(
                      color: AppColors.paper2,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.place_outlined, color: AppColors.ink3, size: 24),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No drops published yet',
                    style: GoogleFonts.bricolageGrotesque(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.ink),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Share your favorite spots with notes, ratings, and photos.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: AppColors.ink2),
                  ),
                ],
              ),
            )
          else
            ...myDrops.map((drop) => Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.cardSurface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.borderSubtle, width: 1),
                    boxShadow: const [AppColors.shadowCard],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              drop.placeName,
                              style: GoogleFonts.bricolageGrotesque(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: AppColors.ink,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: drop.isFriendsOnly ? AppColors.butter : AppColors.paper2,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: drop.isFriendsOnly ? AppColors.ink.withValues(alpha: 0.15) : AppColors.borderHairline,
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  drop.isFriendsOnly ? Icons.lock : Icons.public,
                                  size: 10,
                                  color: AppColors.ink,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  drop.isFriendsOnly ? 'Friends Only' : 'Public',
                                  style: GoogleFonts.spaceMono(
                                    color: AppColors.ink,
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        drop.note,
                        style: const TextStyle(fontSize: 13, color: AppColors.ink2, height: 1.35),
                      ),
                    ],
                  ),
                )),
          const SizedBox(height: 70),
        ],
      ),
    );
  }

  void _showFindFriendsDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (_) => Consumer(
        builder: (ctx, dialogRef, __) {
          final relations = dialogRef.watch(friendshipStatusesProvider);
          final relationNotifier = dialogRef.read(friendshipStatusesProvider.notifier);
          final currentProfile = dialogRef.watch(currentProfileProvider);

          return AlertDialog(
            backgroundColor: AppColors.paper,
            surfaceTintColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: const BorderSide(color: AppColors.borderSubtle, width: 1),
            ),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.orangeSubtle,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.people_outline, color: AppColors.orange, size: 18),
                ),
                const SizedBox(width: 10),
                Text(
                  'Tashkent Community',
                  style: GoogleFonts.bricolageGrotesque(
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                    color: AppColors.ink,
                  ),
                ),
              ],
            ),
            content: SizedBox(
              width: double.maxFinite,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Quick Invite Link Card
                    Container(
                      margin: const EdgeInsets.only(bottom: 14),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.butter,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.ink, width: 1.2),
                        boxShadow: const [AppColors.shadowTactile],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.qr_code_2, size: 20, color: AppColors.ink),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Invite Friends via Link',
                                  style: GoogleFonts.bricolageGrotesque(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: AppColors.ink,
                                  ),
                                ),
                                const Text(
                                  'Connect instantly with 1 tap',
                                  style: TextStyle(fontSize: 11, color: AppColors.ink2),
                                ),
                              ],
                            ),
                          ),
                          BouncingWidget(
                            onTap: () async {
                              HapticService.selection();
                              final link = await FriendInviteService.copyInviteLink(
                                inviterId: currentProfile.id,
                                username: currentProfile.username,
                                fullName: currentProfile.fullName,
                                neighborhood: currentProfile.neighborhood,
                              );
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('✓ Invite link copied: $link'),
                                    backgroundColor: AppColors.ink,
                                  ),
                                );
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppColors.ink,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'Copy',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          BouncingWidget(
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
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: const Color(0xFF229ED9),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.send_rounded, size: 12, color: Colors.white),
                                  SizedBox(width: 4),
                                  Text(
                                    'Telegram',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    ...kTashkentCommunityMembers.map((member) {
                    final rel = relations[member.id] ?? FriendshipRelation.none;
                    String label;
                    Color btnBg;
                    Color btnFg;
                    switch (rel) {
                      case FriendshipRelation.accepted:
                        label = 'Friends';
                        btnBg = AppColors.paper2;
                        btnFg = AppColors.ink2;
                        break;
                      case FriendshipRelation.pendingOutgoing:
                        label = 'Requested';
                        btnBg = AppColors.paper2;
                        btnFg = AppColors.ink3;
                        break;
                      case FriendshipRelation.pendingIncoming:
                        label = 'Accept';
                        btnBg = AppColors.cobalt;
                        btnFg = Colors.white;
                        break;
                      case FriendshipRelation.none:
                        label = member.allowFriendRequests ? '+ Request' : 'Private';
                        btnBg = member.allowFriendRequests ? AppColors.orange : AppColors.paper2;
                        btnFg = member.allowFriendRequests ? Colors.white : AppColors.ink3;
                        break;
                    }

                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.cardSurface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.borderHairline, width: 1),
                      ),
                      child: Row(
                        children: [
                          GestureDetector(
                            onTap: () {
                              Navigator.pop(ctx);
                              context.push('/users/${member.id}');
                            },
                            child: CircleAvatar(
                              radius: 18,
                              backgroundColor: AppColors.butter,
                              child: Text(
                                member.initials,
                                style: const TextStyle(color: AppColors.ink, fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                Navigator.pop(ctx);
                                context.push('/users/${member.id}');
                              },
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    member.name,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.ink),
                                  ),
                                  Text(
                                    '@${member.handle} · ${member.neighborhood}',
                                    style: const TextStyle(fontSize: 10.5, color: AppColors.ink3),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          BouncingWidget(
                            onTap: () async {
                              HapticService.selection();
                              final msg = await relationNotifier.requestOrToggleFriendship(member.id);
                              if (msg != null && context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: btnBg,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: AppColors.borderSubtle, width: 1),
                              ),
                              child: Text(
                                label,
                                style: TextStyle(
                                  color: btnFg,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
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
}

class _StatItem extends StatelessWidget {
  final String count;
  final String label;

  const _StatItem({required this.count, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          count,
          style: GoogleFonts.bricolageGrotesque(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: AppColors.ink,
          ),
        ),
        const SizedBox(height: 1),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: AppColors.ink2, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}
