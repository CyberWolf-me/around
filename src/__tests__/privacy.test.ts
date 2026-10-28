import { describe, it, expect } from 'vitest';
import {
  filterFeedDrops,
  filterExploreDrops,
  filterPlaceDrops,
  canViewVisitHistory,
} from '../services/privacyFilter';
import { PlaceDrop, PrivacySettings } from '../types';

describe('Dual-Layer Privacy Enforcement', () => {
  const mockDrops: PlaceDrop[] = [
    {
      id: 'd1',
      who: 'friend_a',
      place: 'kettle',
      img: '/assets/kettle-hero.jpg',
      size: 'hero',
      note: 'Best morning espresso',
      rating: 5,
      when: '1h',
      saves: 5,
      aud: 'friends',
    },
    {
      id: 'd2',
      who: 'friend_b',
      place: 'kettle',
      img: null,
      size: 'note',
      note: 'Great pastries',
      rating: 4,
      when: '2h',
      saves: 2,
      aud: 'public',
    },
    {
      id: 'd3',
      who: 'stranger',
      place: 'fern',
      img: '/assets/study-desk.jpg',
      size: 'half',
      note: 'Loud music today',
      rating: 3,
      when: '3h',
      saves: 0,
      aud: 'friends',
    },
    {
      id: 'd4',
      who: 'stranger',
      place: 'kettle',
      img: null,
      size: 'note',
      note: 'Very crowded',
      rating: 4,
      when: '4h',
      saves: 1,
      aud: 'public',
    },
    {
      id: 'd5',
      who: 'blocked_user',
      place: 'kettle',
      img: null,
      size: 'note',
      note: 'Spam note',
      rating: 1,
      when: '5h',
      saves: 0,
      aud: 'public',
    },
  ];

  const currentUserId = 'you';
  const followedUserIds = new Set(['friend_a', 'friend_b']);
  const blockedUserIds = new Set(['blocked_user']);

  it('Feed screen: only shows drops from followed friends and excludes strangers and blocked users', () => {
    const feed = filterFeedDrops(mockDrops, currentUserId, followedUserIds, blockedUserIds);

    expect(feed.length).toBe(2);
    expect(feed.map(d => d.id)).toEqual(['d1', 'd2']);
    expect(feed.some(d => d.who === 'stranger')).toBe(false);
    expect(feed.some(d => d.who === 'blocked_user')).toBe(false);
  });

  it('Explore screen: strictly only shows drops marked as public and excludes blocked users', () => {
    const explore = filterExploreDrops(mockDrops, blockedUserIds);

    expect(explore.length).toBe(2);
    expect(explore.map(d => d.id)).toEqual(['d2', 'd4']);
    // Friends-only drops must NEVER leak into Explore
    expect(explore.some(d => d.aud === 'friends')).toBe(false);
    expect(explore.some(d => d.who === 'blocked_user')).toBe(false);
  });

  it('Place page: correctly partitions drops between friends layer and public community', () => {
    const friendLayer = filterPlaceDrops(
      mockDrops,
      'kettle',
      'all_friends',
      currentUserId,
      followedUserIds,
      blockedUserIds
    );
    expect(friendLayer.map(d => d.id)).toEqual(['d1', 'd2']);

    const publicLayer = filterPlaceDrops(
      mockDrops,
      'kettle',
      'public',
      currentUserId,
      followedUserIds,
      blockedUserIds
    );
    expect(publicLayer.map(d => d.id)).toEqual(['d2', 'd4']);
  });

  it('Visit history privacy: honors user settings to suppress chronological tracking', () => {
    const strictPrivacySettings: PrivacySettings = {
      defaultAudience: 'friends',
      hideVisitsHistory: true,
      discoverableByFriends: true,
      quietHours: false,
      allowFriendRequests: true,
      blockedUsers: [],
    };

    // Another user cannot view visit history when hideVisitsHistory is true
    expect(canViewVisitHistory('target_user', 'stranger', strictPrivacySettings, false)).toBe(false);
    expect(canViewVisitHistory('target_user', 'friend_a', strictPrivacySettings, true)).toBe(false);

    // Current user can always inspect their own history
    expect(canViewVisitHistory('target_user', 'target_user', strictPrivacySettings, false)).toBe(true);
  });
});
