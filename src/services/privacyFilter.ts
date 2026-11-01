import { PlaceDrop, PrivacySettings } from '../types';

/**
 * Enforces the dual-layer privacy & moderation invariant for social feed:
 * - Excludes quarantined drops (3+ unique community reports)
 * - Excludes blocked users
 * - Only includes drops from accepted mutual friends (or current user)
 * - Ensures friends-only drops from non-connected accounts are never leaked
 */
export function filterFeedDrops(
  drops: PlaceDrop[],
  currentUserId: string,
  followedUserIds: Set<string>,
  blockedUserIds: Set<string>
): PlaceDrop[] {
  return drops.filter(drop => {
    if (drop.quarantined) return false;
    if (blockedUserIds.has(drop.who)) return false;
    if (drop.who === currentUserId) return true;
    if (!followedUserIds.has(drop.who)) return false;
    return true;
  });
}

/**
 * Enforces privacy & moderation boundary for public global explore feed:
 * - Excludes quarantined drops
 * - Excludes blocked users
 * - Strictly ONLY drops with audience === 'public'
 */
export function filterExploreDrops(
  drops: PlaceDrop[],
  blockedUserIds: Set<string>
): PlaceDrop[] {
  return drops.filter(drop => {
    if (drop.quarantined) return false;
    if (blockedUserIds.has(drop.who)) return false;
    return drop.aud === 'public';
  });
}

/**
 * Filters drops specifically for a canonical place page:
 * Separates recommendations into:
 * - Friends' layer (drops from accepted mutual friends)
 * - Public layer (public drops from everyone, excluding quarantined/blocked)
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
    if (drop.quarantined) return false;
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
 * Determines whether a user's chronological visit history may be displayed
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

/**
 * Applies automated moderation quarantine when a drop reaches 3+ reports
 */
export function applyReportToDrop(drop: PlaceDrop): PlaceDrop {
  const nextCount = (drop.reportsCount || 0) + 1;
  return {
    ...drop,
    reportsCount: nextCount,
    quarantined: nextCount >= 3,
  };
}
