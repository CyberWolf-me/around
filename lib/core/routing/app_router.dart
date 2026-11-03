import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';
import '../widgets/bouncing_widget.dart';
import '../../data/repositories/posts_repository.dart';
import '../../data/services/haptic_service.dart';
import '../../features/feed/screens/feed_screen.dart';
import '../../features/feed/screens/notifications_screen.dart';
import '../../features/explore/screens/explore_screen.dart';
import '../../features/saved_places/screens/saved_screen.dart';
import '../../features/profile/screens/profile_screen.dart';
import '../../features/profile/screens/user_profile_screen.dart';
import '../../features/profile/screens/taste_passport_screen.dart';
import '../../features/profile/screens/friend_invite_screen.dart';
import '../../features/places/screens/place_detail_screen.dart';
import '../../features/create_post/screens/create_drop_sheet.dart';
import '../../features/settings/screens/settings_screen.dart';
import '../../features/auth/screens/onboarding_screen.dart';
import '../../features/auth/screens/auth_screen.dart';
import '../../data/services/storage_service.dart';
import '../../data/services/supabase_service.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');
final GlobalKey<NavigatorState> _feedNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'feed');
final GlobalKey<NavigatorState> _exploreNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'explore');
final GlobalKey<NavigatorState> _savedNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'saved');
final GlobalKey<NavigatorState> _profileNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'profile');

final GoRouter appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/feed',
  debugLogDiagnostics: false,
  redirect: (context, state) {
    final isOnboarded = StorageService.isOnboarded();
    final isAuthenticated = SupabaseService.isAuthenticated || StorageService.getAuthUserEmail() != null;
    final isGuest = StorageService.isGuestMode();

    final isGoingToOnboarding = state.matchedLocation == '/onboarding';
    final isGoingToAuth = state.matchedLocation == '/auth';

    if (!isOnboarded) {
      return isGoingToOnboarding ? null : '/onboarding';
    }

    if (!isAuthenticated && !isGuest) {
      return (isGoingToAuth || isGoingToOnboarding) ? null : '/auth';
    }

    if (isAuthenticated && (isGoingToAuth || isGoingToOnboarding)) {
      return '/feed';
    }

    return null;
  },
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return ScaffoldWithNavBar(navigationShell: navigationShell);
      },
      branches: [
        StatefulShellBranch(
          navigatorKey: _feedNavigatorKey,
          routes: [
            GoRoute(
              path: '/feed',
              pageBuilder: (context, state) => const NoTransitionPage(
                child: FeedScreen(),
              ),
            ),
          ],
        ),
        StatefulShellBranch(
          navigatorKey: _exploreNavigatorKey,
          routes: [
            GoRoute(
              path: '/explore',
              pageBuilder: (context, state) => const NoTransitionPage(
                child: ExploreScreen(),
              ),
            ),
          ],
        ),
        StatefulShellBranch(
          navigatorKey: _savedNavigatorKey,
          routes: [
            GoRoute(
              path: '/saved',
              pageBuilder: (context, state) => const NoTransitionPage(
                child: SavedScreen(),
              ),
            ),
          ],
        ),
        StatefulShellBranch(
          navigatorKey: _profileNavigatorKey,
          routes: [
            GoRoute(
              path: '/profile',
              pageBuilder: (context, state) => const NoTransitionPage(
                child: ProfileScreen(),
              ),
            ),
          ],
        ),
      ],
    ),
    GoRoute(
      path: '/places/:id',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final placeId = state.pathParameters['id'] ?? '';
        return PlaceDetailScreen(placeId: placeId);
      },
    ),
    GoRoute(
      path: '/drops/:id',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final dropId = state.pathParameters['id'] ?? '';
        return Consumer(
          builder: (context, ref, _) {
            final posts = ref.watch(postsRepositoryProvider);
            final drop = posts.where((p) => p.id == dropId).firstOrNull;
            if (drop != null) {
              return PlaceDetailScreen(placeId: drop.placeId);
            }
            return Scaffold(
              backgroundColor: AppColors.paper,
              appBar: AppBar(leading: const BackButton()),
              body: Center(
                child: Text('Drop not found or expired', style: GoogleFonts.bricolageGrotesque(fontSize: 16)),
              ),
            );
          },
        );
      },
    ),
    GoRoute(
      path: '/users/:id',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final userId = state.pathParameters['id'] ?? '';
        if (userId == 'you') return const ProfileScreen();
        return UserProfileScreen(userId: userId);
      },
    ),
    GoRoute(
      path: '/passport/:username',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final username = state.pathParameters['username'] ?? '';
        return TastePassportScreen(username: username);
      },
    ),
    GoRoute(
      path: '/invite/:code',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final code = state.pathParameters['code'] ?? '';
        return FriendInviteScreen(inviteCode: code);
      },
    ),
    GoRoute(
      path: '/notifications',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const NotificationsScreen(),
    ),
    GoRoute(
      path: '/settings',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const SettingsScreen(),
    ),
    GoRoute(
      path: '/onboarding',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const OnboardingScreen(),
    ),
    GoRoute(
      path: '/auth',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const AuthScreen(),
    ),
    GoRoute(
      path: '/create',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final presetPlaceId = state.uri.queryParameters['placeId'];
        return Scaffold(
          backgroundColor: AppColors.paper,
          appBar: AppBar(
            title: const Text('Drop a Place', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          body: CreateDropSheet(presetPlaceId: presetPlaceId),
        );
      },
    ),
  ],
);

class ScaffoldWithNavBar extends StatelessWidget {
  const ScaffoldWithNavBar({
    required this.navigationShell,
    super.key,
  });

  final StatefulNavigationShell navigationShell;

  void _onTap(BuildContext context, int index) {
    if (index == 2) {
      HapticService.medium();
      if (!SupabaseService.isAuthenticated) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: AppColors.paper,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: const BorderSide(color: AppColors.borderSubtle, width: 1.2),
            ),
            title: Text('Account Required', style: GoogleFonts.bricolageGrotesque(fontWeight: FontWeight.w800)),
            content: const Text(
              'You are browsing as a Guest. Sign in or create an account to drop recommendations and share spots with your circle.',
              style: TextStyle(height: 1.4, color: AppColors.ink2),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel', style: TextStyle(color: AppColors.ink3)),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  context.push('/auth');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.orange,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('Sign In'),
              ),
            ],
          ),
        );
        return;
      }
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => const CreateDropSheet(),
      );
      return;
    }

    final branchIndex = index > 2 ? index - 1 : index;
    navigationShell.goBranch(
      branchIndex,
      initialLocation: branchIndex == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentBranch = navigationShell.currentIndex;
    final selectedNavIndex = currentBranch >= 2 ? currentBranch + 1 : currentBranch;

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.paper,
          border: Border(
            top: BorderSide(color: AppColors.borderHairline, width: 1.0),
          ),
          boxShadow: [AppColors.shadowSubtle],
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 62,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(
                  context,
                  index: 0,
                  isSelected: selectedNavIndex == 0,
                  icon: Icons.dynamic_feed_outlined,
                  selectedIcon: Icons.dynamic_feed,
                  label: 'FEED',
                ),
                _buildNavItem(
                  context,
                  index: 1,
                  isSelected: selectedNavIndex == 1,
                  icon: Icons.explore_outlined,
                  selectedIcon: Icons.explore,
                  label: 'EXPLORE',
                ),
                _buildDropButton(context),
                _buildNavItem(
                  context,
                  index: 3,
                  isSelected: selectedNavIndex == 3,
                  icon: Icons.bookmark_border_rounded,
                  selectedIcon: Icons.bookmark_rounded,
                  label: 'SAVED',
                ),
                _buildNavItem(
                  context,
                  index: 4,
                  isSelected: selectedNavIndex == 4,
                  icon: Icons.person_outline_rounded,
                  selectedIcon: Icons.person_rounded,
                  label: 'YOU',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDropButton(BuildContext context) {
    return BouncingWidget(
      onTap: () => _onTap(context, 2),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.orange,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.borderHairline, width: 1),
          boxShadow: [
            BoxShadow(
              color: AppColors.orange.withValues(alpha: 0.32),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
            AppColors.shadowSm,
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.add_rounded, color: Colors.white, size: 17),
            const SizedBox(width: 4),
            Text(
              'DROP',
              style: GoogleFonts.spaceMono(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                letterSpacing: 0.6,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context, {
    required int index,
    required bool isSelected,
    required IconData icon,
    required IconData selectedIcon,
    required String label,
  }) {
    return Expanded(
      child: BouncingWidget(
        onTap: () => _onTap(context, index),
        scaleFactor: 0.92,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedScale(
                scale: isSelected ? 1.08 : 1.0,
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOutBack,
                child: Icon(
                  isSelected ? selectedIcon : icon,
                  size: 21,
                  color: isSelected ? AppColors.orange : AppColors.ink3,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                label,
                style: GoogleFonts.spaceMono(
                  fontSize: 9.5,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? AppColors.orange : AppColors.ink3,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
