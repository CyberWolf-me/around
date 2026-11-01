import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/profile_model.dart';
import '../../../data/repositories/posts_repository.dart';
import '../../../data/repositories/profiles_repository.dart';
import '../../../data/repositories/saved_places_repository.dart';
import '../../../data/services/haptic_service.dart';

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
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: AppColors.ink, width: 2),
        ),
        title: Text('Edit Profile', style: GoogleFonts.bricolageGrotesque(fontWeight: FontWeight.w800)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Full Name'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: usernameCtrl,
                decoration: const InputDecoration(labelText: 'Username (@handle)'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: neighborhoodCtrl,
                decoration: const InputDecoration(labelText: 'Neighborhood / District'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: bioCtrl,
                maxLines: 2,
                maxLength: 300,
                decoration: const InputDecoration(labelText: 'Bio'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppColors.ink3)),
          ),
          ElevatedButton(
            onPressed: () async {
              await ref.read(currentProfileProvider.notifier).updateProfileDetails(
                    fullName: nameCtrl.text,
                    username: usernameCtrl.text,
                    bio: bioCtrl.text,
                    neighborhood: neighborhoodCtrl.text,
                  );
              if (ctx.mounted) Navigator.pop(ctx);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Profile details saved')),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.orange, foregroundColor: Colors.white),
            child: const Text('Save'),
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

    final myDrops = posts.where((p) => p.authorId == 'you').toList();

    return Scaffold(
      backgroundColor: AppColors.paper,
      appBar: AppBar(
        title: const Text('Your Profile', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: AppColors.ink),
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        children: [
          Row(
            children: [
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.orange,
                  border: Border.all(color: AppColors.ink, width: 2.5),
                  boxShadow: const [AppColors.shadowSm],
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
                      style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '@${profile.username} · ${profile.neighborhood}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    if (profile.bio.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        profile.bio,
                        style: const TextStyle(fontSize: 11.5, color: AppColors.ink2),
                      ),
                    ],
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Text('${myDrops.length} drops', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                        const SizedBox(width: 12),
                        Text('${followedFriends.length} friends', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                        const SizedBox(width: 12),
                        Text('${savedPlaces.length} saved', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    HapticService.light();
                    _showEditProfileDialog(context, ref, profile);
                  },
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.ink, width: 1.5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Edit Profile', style: TextStyle(color: AppColors.ink, fontSize: 12)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    HapticService.light();
                    _showFindFriendsDialog(context, ref);
                  },
                  icon: const Icon(Icons.person_add, size: 14, color: AppColors.ink),
                  label: const Text('Find Friends', style: TextStyle(color: AppColors.ink, fontSize: 12)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.butter,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: const BorderSide(color: AppColors.ink, width: 1.5),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Your Drops',
                style: GoogleFonts.bricolageGrotesque(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                'Friends & Public',
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (myDrops.isEmpty)
            Container(
              padding: const EdgeInsets.all(20),
              alignment: Alignment.center,
              child: const Text('No drops published yet.'),
            )
          else
            ...myDrops.map((drop) => Container(
                  margin: const EdgeInsets.only(bottom: 10),
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
                            child: Text(
                              drop.placeName,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: drop.isFriendsOnly ? AppColors.butter : AppColors.ink,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              drop.isFriendsOnly ? 'Friends Only' : 'Public',
                              style: TextStyle(
                                color: drop.isFriendsOnly ? AppColors.ink : AppColors.paper,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(drop.note, style: const TextStyle(fontSize: 12, color: AppColors.ink2)),
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

          return AlertDialog(
            backgroundColor: AppColors.paper,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
              side: const BorderSide(color: AppColors.ink, width: 2),
            ),
            title: Text('Tashkent Community', style: GoogleFonts.bricolageGrotesque(fontWeight: FontWeight.w800)),
            content: SizedBox(
              width: double.maxFinite,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: kTashkentCommunityMembers.map((member) {
                    final rel = relations[member.id] ?? FriendshipRelation.none;
                    String label;
                    Color labelColor;
                    switch (rel) {
                      case FriendshipRelation.accepted:
                        label = 'Friends';
                        labelColor = AppColors.ink3;
                        break;
                      case FriendshipRelation.pendingOutgoing:
                        label = 'Requested';
                        labelColor = AppColors.ink2;
                        break;
                      case FriendshipRelation.pendingIncoming:
                        label = 'Accept';
                        labelColor = AppColors.cobalt;
                        break;
                      case FriendshipRelation.none:
                        label = member.allowFriendRequests ? '+ Request' : 'Private';
                        labelColor = member.allowFriendRequests ? AppColors.orange : AppColors.ink3;
                        break;
                    }

                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      onTap: () {
                        Navigator.pop(ctx);
                        context.push('/users/${member.id}');
                      },
                      leading: CircleAvatar(
                        backgroundColor: AppColors.ink,
                        child: Text(member.initials, style: const TextStyle(color: Colors.white, fontSize: 11)),
                      ),
                      title: Text(member.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      subtitle: Text(
                        '@${member.handle} · ${member.neighborhood} · ${member.dropsCount} drops',
                        style: const TextStyle(fontSize: 10),
                      ),
                      trailing: TextButton(
                        onPressed: () async {
                          HapticService.selection();
                          final msg = await relationNotifier.requestOrToggleFriendship(member.id);
                          if (msg != null && context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
                          }
                        },
                        child: Text(
                          label,
                          style: TextStyle(
                            color: labelColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 11.5,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
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
}
