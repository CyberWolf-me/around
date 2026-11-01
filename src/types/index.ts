export type Audience = 'friends' | 'public';

export type DropSize = 'hero' | 'half' | 'wide' | 'note';

export type SaveStatus = 'want_to_go' | 'been';

export type FriendshipStatus = 'accepted' | 'pending_outgoing' | 'pending_incoming' | 'none';

export interface UserProfile {
  id: string;
  name: string;
  handle: string;
  init: string;
  bg: string;
  neighborhood: string;
  dropsCount: number;
  friendsCount: number;
  savedCount: number;
  bio?: string;
  isFollowing?: boolean;
  hideVisitsHistory?: boolean;
  allowFriendRequests?: boolean;
}

export interface Place {
  id: string;
  name: string;
  cat: string;
  street: string;
  dist: string;
  price: string;
  img: string;
  hours: string;
  closed: string;
  rating: number;
  reviews: number;
  tags: string[];
  line: string;
  imgs: string[];
  coords?: { x: number; y: number };
}

export interface PlaceDrop {
  id: string;
  who: string;
  place: string;
  img: string | null;
  size: DropSize;
  note: string;
  rating: number | null;
  when: string;
  timestamp?: number;
  saves: number;
  aud: Audience;
  tags?: string[];
  tint?: string;
  fresh?: boolean;
  reportsCount?: number;
  quarantined?: boolean;
}

export interface PublicReview {
  id: string;
  who: string;
  rating: number;
  when: string;
  txt: string;
}

export interface FriendPlan {
  id: string;
  placeId: string;
  who: string[];
  when: string;
  note?: string;
}

export interface ActivityNotification {
  id: string;
  who: string;
  kind: 'drop' | 'save' | 'follow' | 'plan';
  placeId: string | null;
  txt: string;
  when: string;
  unread: boolean;
}

export interface PrivacySettings {
  defaultAudience: Audience;
  hideVisitsHistory: boolean;
  discoverableByFriends: boolean;
  quietHours: boolean;
  allowFriendRequests: boolean;
  blockedUsers: string[];
}

export interface ContentReport {
  id: string;
  targetType: 'drop' | 'place' | 'profile';
  targetId: string;
  reason: string;
  createdAt: string;
}

export type ScreenTab = 'feed' | 'explore' | 'saved' | 'profile';

export type StackScreen =
  | { kind: 'place'; id: string }
  | { kind: 'profile'; userId?: string }
  | { kind: 'notifs' }
  | { kind: 'settings' };
