import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/repositories/posts_repository.dart';
import '../../../data/repositories/profiles_repository.dart';
import '../../../data/repositories/saved_places_repository.dart';
import '../../../data/services/haptic_service.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

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
          // User Avatar & Bio
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
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    fontFamily: 'BricolageGrotesque',
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

          // Action buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    HapticService.light();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Profile details updated')),
                    );
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

          // Your Drops Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Your Drops',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  fontFamily: 'BricolageGrotesque',
                ),
              ),
              Text(
                'Friends & Public',
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Drops list
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
    final followedNotifier = ref.read(followedFriendsProvider.notifier);
    final followedSet = ref.watch(followedFriendsProvider);

    final suggested = [
      {'id': 'noor', 'name': 'Noor Haddad', 'handle': 'noorh', 'drops': 18},
      {'id': 'teo', 'name': 'Teo Vasquez', 'handle': 'teovas', 'drops': 14},
      {'id': 'mina', 'name': 'Mina Osei', 'handle': 'minaosei', 'drops': 29},
      {'id': 'ari', 'name': 'Ari Lindqvist', 'handle': 'arilind', 'drops': 11},
      {'id': 'priya', 'name': 'Priya Raman', 'handle': 'priyar', 'drops': 33},
    ];

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.paper,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: AppColors.ink, width: 2),
        ),
        title: const Text('Tashkent Community', style: TextStyle(fontFamily: 'BricolageGrotesque')),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: suggested.map((user) {
              final id = user['id'] as String;
              final isFollowing = followedSet.contains(id);
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  backgroundColor: AppColors.ink,
                  child: Text(user['name'].toString()[0], style: const TextStyle(color: Colors.white)),
                ),
                title: Text(user['name'] as String, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                subtitle: Text('@${user['handle']} · ${user['drops']} drops', style: const TextStyle(fontSize: 10)),
                trailing: TextButton(
                  onPressed: () {
                    HapticService.selection();
                    followedNotifier.toggleFollow(id);
                  },
                  child: Text(
                    isFollowing ? 'Following' : '+ Follow',
                    style: TextStyle(
                      color: isFollowing ? AppColors.ink3 : AppColors.orange,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.ink),
            child: const Text('Done', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
