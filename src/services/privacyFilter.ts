import { PlaceDrop, PrivacySettings } from '../types';

/**
 * Enforces the dual-layer privacy invariant for social feed:
 * - Only includes drops from followed users (or current user)
 * - Excludes blocked users
 * - Ensures friends-only drops from non-followed accounts are never leaked
 */
export function filterFeedDrops(
  drops: PlaceDrop[],
  currentUserId: string,
  followedUserIds: Set<string>,
  blockedUserIds: Set<string>
): PlaceDrop[] {
  return drops.filter(drop => {
    if (blockedUserIds.has(drop.who)) return false;
    // Current user can always see their own drops
    if (drop.who === currentUserId) return true;
    // Must be following author to see their drops in the friends feed
    if (!followedUserIds.has(drop.who)) return false;
    return true;
  });
}

/**
 * Enforces privacy boundary for public global explore feed:
 * - Strictly ONLY drops with audience === 'public'
 * - Excludes blocked users
 */
export function filterExploreDrops(
  drops: PlaceDrop[],
  blockedUserIds: Set<string>
): PlaceDrop[] {
  return drops.filter(drop => {
    if (blockedUserIds.has(drop.who)) return false;
    return drop.aud === 'public';
  });
}

/**
 * Filters drops specifically for a canonical place page:
 * Separates recommendations into:
 * - Friends' layer (friends-only drops from people you follow)
 * - Public layer (public drops from everyone)
 */
export function filterPlaceDrops(
  drops: PlaceDrop[],
  placeId: string,
  audienceFilter: 'all_friends' | 'public',
  currentUserId: string,
  followedUserIds: Set<string>,
  blockedUserIds: Set<string>
): PlaceDrop[] {
  return drops.filter(drop => {
    if (drop.place !== placeId) return false;
    if (blockedUserIds.has(drop.who)) return false;

    if (audienceFilter === 'all_friends') {
      const isMine = drop.who === currentUserId;
      const isFriend = followedUserIds.has(drop.who);
      return isMine || isFriend;
    } else {
      return drop.aud === 'public';
    }
  });
}

/**
 * Determines whether a user's visit history may be displayed
 */
export function canViewVisitHistory(
  targetUserId: string,
  viewerUserId: string,
  targetSettings: PrivacySettings,
  isMutualFollower: boolean
): boolean {
  if (targetUserId === viewerUserId) return true;
  if (targetSettings.hideVisitsHistory) return false;
  return isMutualFollower;
}
