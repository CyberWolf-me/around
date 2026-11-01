import React, { createContext, useContext, useState, useEffect, useCallback, useRef } from 'react';
import {
  Place,
  PlaceDrop,
  UserProfile,
  FriendPlan,
  ActivityNotification,
  PrivacySettings,
  ContentReport,
  SaveStatus,
  ScreenTab,
  StackScreen,
  Audience
} from '../types';
import {
  INITIAL_PLACES,
  INITIAL_DROPS,
  INITIAL_PEOPLE,
  INITIAL_PLANS,
  INITIAL_NOTIFICATIONS,
  LEGACY_PLACE_ALIASES,
  LEGACY_USER_ALIASES,
} from '../data/mockData';
import { storage } from '../services/storage';
import { buzz, hapticPatterns } from '../services/haptics';
import { applyReportToDrop } from '../services/privacyFilter';
import { FlightState } from '../components/ui/FlightPhoto';

interface CreateDropPayload {
  placeId: string;
  note: string;
  rating: number | null;
  tags: string[];
  aud: Audience;
  photoUrl: string | null;
}

interface AppContextType {
  booted: boolean;
  setBooted: (b: boolean) => void;
  currentUserId: string;
  setCurrentUserId: (id: string) => void;
  authEmail: string | null;
  signInWithEmail: (email: string) => void;
  signOutAccount: () => void;
  userProfile: UserProfile;
  updateUserProfile: (partial: Partial<UserProfile>) => void;
  activeTab: ScreenTab;
  switchTab: (tab: ScreenTab) => void;
  exploreMode: 'map' | 'list';
  setExploreMode: (mode: 'map' | 'list') => void;
  stack: StackScreen[];
  pushScreen: (screen: StackScreen) => void;
  popScreen: () => void;
  places: Place[];
  addCustomPlace: (place: Place) => void;
  drops: PlaceDrop[];
  savedPlaceIds: string[];
  savedPlaceStatuses: Record<string, SaveStatus>;
  toggleSavePlace: (id: string) => void;
  setSavedPlaceStatus: (id: string, status: SaveStatus) => void;
  followedUserIds: Set<string>;
  toggleFollowUser: (id: string) => void;
  plans: FriendPlan[];
  addPlan: (plan: Omit<FriendPlan, 'id'>) => void;
  notifications: ActivityNotification[];
  markNotificationsRead: () => void;
  privacySettings: PrivacySettings;
  updatePrivacySettings: (partial: Partial<PrivacySettings>) => void;
  blockUser: (id: string) => void;
  unblockUser: (id: string) => void;
  reports: ContentReport[];
  reportContent: (type: 'drop' | 'place' | 'profile', id: string, reason: string) => void;
  createModal: { open: boolean; presetPlaceId: string | null; initialStep: number };
  openCreateDrop: (presetPlaceId?: string, initialStep?: number) => void;
  closeCreateDrop: () => void;
  publishDrop: (payload: CreateDropPayload) => void;
  toast: string | null;
  showToast: (msg: string) => void;
  deviceFrame: 'iphone' | 'pixel' | 'fullscreen';
  setDeviceFrame: (frame: 'iphone' | 'pixel' | 'fullscreen') => void;
  flight: FlightState | null;
  openPlace: (id: string, sourceElement?: HTMLElement | null) => void;
  resetToDemoData: () => void;
  getPlaceById: (id: string) => Place | undefined;
  getUserById: (id: string) => UserProfile | undefined;
}

const DEFAULT_SAVED_STATUSES: Record<string, SaveStatus> = {
  breadly: 'want_to_go',
  bnb: 'been',
  ecorn: 'want_to_go',
  steam: 'want_to_go',
  kitobxon: 'been',
};

const AppContext = createContext<AppContextType | undefined>(undefined);

export const AppProvider: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  const [booted, setBootedState] = useState<boolean>(() => storage.get('booted', true));
  const setBooted = (val: boolean) => {
    setBootedState(val);
    storage.set('booted', val);
  };

  const [currentUserId, setCurrentUserId] = useState<string>('you');
  const [authEmail, setAuthEmail] = useState<string | null>(() => storage.get<string | null>('auth_email', null));
  const [userProfile, setUserProfile] = useState<UserProfile>(() =>
    storage.get('user_profile', INITIAL_PEOPLE.you)
  );
  const [activeTab, setActiveTab] = useState<ScreenTab>('feed');
  const [exploreMode, setExploreMode] = useState<'map' | 'list'>('map');
  const [stack, setStack] = useState<StackScreen[]>([]);
  const [toast, setToast] = useState<string | null>(null);
  const toastTimeoutRef = useRef<number | null>(null);

  const [deviceFrame, setDeviceFrame] = useState<'iphone' | 'pixel' | 'fullscreen'>('iphone');

  const [places, setPlaces] = useState<Place[]>(() => storage.get('places', INITIAL_PLACES));
  const [drops, setDrops] = useState<PlaceDrop[]>(() => storage.get('drops', INITIAL_DROPS));
  const [savedPlaceIds, setSavedPlaceIds] = useState<string[]>(() =>
    storage.get('saved_places', ['breadly', 'bnb', 'ecorn', 'steam', 'kitobxon'])
  );
  const [savedPlaceStatuses, setSavedPlaceStatuses] = useState<Record<string, SaveStatus>>(() =>
    storage.get('saved_place_statuses', DEFAULT_SAVED_STATUSES)
  );
  const [followedUserIds, setFollowedUserIds] = useState<Set<string>>(() => {
    const list = storage.get('followed_users', ['kamila', 'bekzod', 'aziza', 'diyor', 'madina']);
    return new Set(list);
  });
  const [plans, setPlans] = useState<FriendPlan[]>(() => storage.get('plans', INITIAL_PLANS));
  const [notifications, setNotifications] = useState<ActivityNotification[]>(() =>
    storage.get('notifications', INITIAL_NOTIFICATIONS)
  );
  const [privacySettings, setPrivacySettings] = useState<PrivacySettings>(() =>
    storage.get('privacy_settings', {
      defaultAudience: 'friends',
      hideVisitsHistory: true,
      discoverableByFriends: true,
      quietHours: false,
      allowFriendRequests: true,
      blockedUsers: [],
    })
  );
  const [reports, setReports] = useState<ContentReport[]>(() => storage.get('reports', []));

  const [flight, setFlight] = useState<FlightState | null>(null);

  const [createModal, setCreateModal] = useState<{
    open: boolean;
    presetPlaceId: string | null;
    initialStep: number;
  }>({
    open: false,
    presetPlaceId: null,
    initialStep: 0,
  });

  useEffect(() => {
    storage.set('user_profile', userProfile);
  }, [userProfile]);

  useEffect(() => {
    storage.set('places', places);
  }, [places]);

  useEffect(() => {
    storage.set('drops', drops);
  }, [drops]);

  useEffect(() => {
    storage.set('saved_places', savedPlaceIds);
  }, [savedPlaceIds]);

  useEffect(() => {
    storage.set('saved_place_statuses', savedPlaceStatuses);
  }, [savedPlaceStatuses]);

  useEffect(() => {
    storage.set('followed_users', Array.from(followedUserIds));
  }, [followedUserIds]);

  useEffect(() => {
    storage.set('plans', plans);
  }, [plans]);

  useEffect(() => {
    storage.set('privacy_settings', privacySettings);
  }, [privacySettings]);

  useEffect(() => {
    storage.set('notifications', notifications);
  }, [notifications]);

  useEffect(() => {
    storage.set('reports', reports);
  }, [reports]);

  const showToast = useCallback((msg: string) => {
    if (toastTimeoutRef.current) clearTimeout(toastTimeoutRef.current);
    setToast(msg);
    toastTimeoutRef.current = window.setTimeout(() => {
      setToast(null);
    }, 2400);
  }, []);

  const signInWithEmail = useCallback((email: string) => {
    setAuthEmail(email);
    storage.set('auth_email', email);
    hapticPatterns.success();
    showToast(`Signed in as ${email}`);
  }, [showToast]);

  const signOutAccount = useCallback(() => {
    setAuthEmail(null);
    storage.set('auth_email', null);
    hapticPatterns.light();
    showToast('Signed out of account');
  }, [showToast]);

  const updateUserProfile = useCallback((partial: Partial<UserProfile>) => {
    setUserProfile(prev => {
      const next = { ...prev, ...partial };
      if (partial.name && partial.name.trim()) {
        const parts = partial.name.trim().split(/\s+/);
        next.init = parts.length >= 2
          ? `${parts[0][0]}${parts[1][0]}`.toUpperCase()
          : parts[0].slice(0, 2).toUpperCase();
      }
      return next;
    });
    hapticPatterns.light();
    showToast('Profile details saved');
  }, [showToast]);

  const addCustomPlace = useCallback((place: Place) => {
    setPlaces(prev => [...prev, place]);
    hapticPatterns.medium();
    showToast(`Added "${place.name}"`);
  }, [showToast]);

  const addPlan = useCallback((plan: Omit<FriendPlan, 'id'>) => {
    const newPlan: FriendPlan = {
      ...plan,
      id: `plan_${Date.now()}`,
    };
    setPlans(prev => [newPlan, ...prev]);
    hapticPatterns.medium();
    showToast('Created plan with friends');
  }, [showToast]);

  const switchTab = useCallback((tab: ScreenTab) => {
    setStack([]);
    setActiveTab(tab);
    buzz(6);
  }, []);

  const pushScreen = useCallback((screen: StackScreen) => {
    setStack(prev => [...prev, screen]);
    buzz(8);
  }, []);

  const popScreen = useCallback(() => {
    setStack(prev => prev.slice(0, -1));
    buzz(6);
  }, []);

  const getPlaceById = useCallback(
    (id: string) => {
      const canonical = LEGACY_PLACE_ALIASES[id] || id;
      return places.find(p => p.id === canonical || p.id === id);
    },
    [places]
  );

  const getUserById = useCallback(
    (id: string) => {
      if (id === 'you') return userProfile;
      const canonical = LEGACY_USER_ALIASES[id] || id;
      return INITIAL_PEOPLE[canonical] || INITIAL_PEOPLE[id] || userProfile;
    },
    [userProfile]
  );

  const openPlace = useCallback((id: string, sourceElement?: HTMLElement | null) => {
    const canonical = LEGACY_PLACE_ALIASES[id] || id;
    const place = places.find(p => p.id === canonical || p.id === id);
    if (sourceElement && place) {
      const img = sourceElement.querySelector('img') || sourceElement;
      const rect = img.getBoundingClientRect();
      setFlight({
        src: place.img,
        x: rect.left,
        y: rect.top,
        w: rect.width,
        h: rect.height,
        radius: 18,
        phase: 'in',
      });
      setTimeout(() => {
        setFlight(f => (f ? { ...f, phase: 'out' } : null));
        setTimeout(() => setFlight(null), 240);
      }, 400);
    }
    pushScreen({ kind: 'place', id: place?.id || canonical });
  }, [places, pushScreen]);

  const toggleSavePlace = useCallback((id: string) => {
    const canonical = LEGACY_PLACE_ALIASES[id] || id;
    setSavedPlaceIds(prev => {
      const exists = prev.includes(canonical) || prev.includes(id);
      hapticPatterns.medium();
      if (exists) {
        showToast('Removed from shortlist');
        return prev.filter(x => x !== canonical && x !== id);
      } else {
        setSavedPlaceStatuses(s => ({ ...s, [canonical]: s[canonical] || 'want_to_go' }));
        showToast('Saved to your Tashkent shortlist');
        return [...prev, canonical];
      }
    });
  }, [showToast]);

  const setSavedPlaceStatus = useCallback((id: string, status: SaveStatus) => {
    const canonical = LEGACY_PLACE_ALIASES[id] || id;
    setSavedPlaceStatuses(prev => ({ ...prev, [canonical]: status }));
    hapticPatterns.light();
  }, []);

  const toggleFollowUser = useCallback((id: string) => {
    const canonical = LEGACY_USER_ALIASES[id] || id;
    const targetPerson = INITIAL_PEOPLE[canonical];
    setFollowedUserIds(prev => {
      const next = new Set(prev);
      if (next.has(canonical)) {
        next.delete(canonical);
        showToast(`Unfollowed @${targetPerson?.handle || canonical}`);
      } else {
        if (targetPerson?.allowFriendRequests === false) {
          showToast(`@${targetPerson.handle} has disabled friend requests`);
          return prev;
        }
        next.add(canonical);
        showToast(`Connected with @${targetPerson?.handle || canonical}`);
      }
      hapticPatterns.light();
      return next;
    });
  }, [showToast]);

  const markNotificationsRead = useCallback(() => {
    setNotifications(prev => prev.map(n => ({ ...n, unread: false })));
  }, []);

  const updatePrivacySettings = useCallback((partial: Partial<PrivacySettings>) => {
    setPrivacySettings(prev => ({ ...prev, ...partial }));
    showToast('Privacy preferences updated');
  }, [showToast]);

  const blockUser = useCallback((id: string) => {
    if (id === 'you') return;
    const canonical = LEGACY_USER_ALIASES[id] || id;
    setPrivacySettings(prev => ({
      ...prev,
      blockedUsers: prev.blockedUsers.includes(canonical) ? prev.blockedUsers : [...prev.blockedUsers, canonical],
    }));
    setFollowedUserIds(prev => {
      const next = new Set(prev);
      next.delete(canonical);
      return next;
    });
    showToast(`Blocked @${INITIAL_PEOPLE[canonical]?.handle || canonical}`);
  }, [showToast]);

  const unblockUser = useCallback((id: string) => {
    setPrivacySettings(prev => ({
      ...prev,
      blockedUsers: prev.blockedUsers.filter(u => u !== id),
    }));
    showToast(`Unblocked @${INITIAL_PEOPLE[id]?.handle || id}`);
  }, [showToast]);

  const reportContent = useCallback((type: 'drop' | 'place' | 'profile', id: string, reason: string) => {
    const newReport: ContentReport = {
      id: `rep_${Date.now()}`,
      targetType: type,
      targetId: id,
      reason,
      createdAt: new Date().toISOString(),
    };
    setReports(prev => [newReport, ...prev]);

    if (type === 'drop') {
      let wasQuarantined = false;
      setDrops(prev =>
        prev.map(d => {
          if (d.id !== id) return d;
          const updated = applyReportToDrop(d);
          if (updated.quarantined) wasQuarantined = true;
          return updated;
        })
      );
      if (wasQuarantined) {
        showToast('Drop quarantined after reaching 3 community reports.');
        return;
      }
    }
    showToast(`Report submitted: "${reason}". Under review.`);
  }, [showToast]);

  const openCreateDrop = useCallback((presetPlaceId?: string, initialStep = 0) => {
    setCreateModal({
      open: true,
      presetPlaceId: presetPlaceId ? (LEGACY_PLACE_ALIASES[presetPlaceId] || presetPlaceId) : null,
      initialStep,
    });
    hapticPatterns.medium();
  }, []);

  const closeCreateDrop = useCallback(() => {
    setCreateModal(prev => ({ ...prev, open: false }));
  }, []);

  const publishDrop = useCallback((payload: CreateDropPayload) => {
    const trimmedNote = payload.note.trim();
    if (trimmedNote.length > 500) {
      showToast('Drop note cannot exceed 500 characters.');
      return;
    }
    const canonicalPlace = LEGACY_PLACE_ALIASES[payload.placeId] || payload.placeId;
    const newDrop: PlaceDrop = {
      id: `drop_${Date.now()}`,
      who: currentUserId,
      place: canonicalPlace,
      img: payload.photoUrl,
      size: payload.photoUrl ? 'hero' : 'note',
      note: trimmedNote || 'Recommended spot in Tashkent.',
      rating: payload.rating,
      when: 'Just now',
      timestamp: Date.now(),
      saves: 0,
      aud: payload.aud,
      tags: payload.tags.slice(0, 10),
      fresh: true,
      reportsCount: 0,
      quarantined: false,
    };

    setDrops(prev => [newDrop, ...prev]);
    closeCreateDrop();
    hapticPatterns.success();
    showToast(payload.aud === 'friends' ? 'Dropped for your friends' : 'Dropped publicly in Tashkent');
  }, [currentUserId, closeCreateDrop, showToast]);

  const resetToDemoData = useCallback(() => {
    storage.clearAll();
    setAuthEmail(null);
    setUserProfile(INITIAL_PEOPLE.you);
    setPlaces(INITIAL_PLACES);
    setDrops(INITIAL_DROPS);
    setSavedPlaceIds(['breadly', 'bnb', 'ecorn', 'steam', 'kitobxon']);
    setSavedPlaceStatuses(DEFAULT_SAVED_STATUSES);
    setFollowedUserIds(new Set(['kamila', 'bekzod', 'aziza', 'diyor', 'madina']));
    setPlans(INITIAL_PLANS);
    setNotifications(INITIAL_NOTIFICATIONS);
    setPrivacySettings({
      defaultAudience: 'friends',
      hideVisitsHistory: true,
      discoverableByFriends: true,
      quietHours: false,
      allowFriendRequests: true,
      blockedUsers: [],
    });
    setReports([]);
    setBootedState(true);
    setStack([]);
    setActiveTab('feed');
    showToast('Reset to initial Tashkent demo state');
  }, [showToast]);

  return (
    <AppContext.Provider
      value={{
        booted,
        setBooted,
        currentUserId,
        setCurrentUserId,
        authEmail,
        signInWithEmail,
        signOutAccount,
        userProfile,
        updateUserProfile,
        activeTab,
        switchTab,
        exploreMode,
        setExploreMode,
        stack,
        pushScreen,
        popScreen,
        places,
        addCustomPlace,
        drops,
        savedPlaceIds,
        savedPlaceStatuses,
        toggleSavePlace,
        setSavedPlaceStatus,
        followedUserIds,
        toggleFollowUser,
        plans,
        addPlan,
        notifications,
        markNotificationsRead,
        privacySettings,
        updatePrivacySettings,
        blockUser,
        unblockUser,
        reports,
        reportContent,
        createModal,
        openCreateDrop,
        closeCreateDrop,
        publishDrop,
        toast,
        showToast,
        deviceFrame,
        setDeviceFrame,
        flight,
        openPlace,
        resetToDemoData,
        getPlaceById,
        getUserById,
      }}
    >
      {children}
    </AppContext.Provider>
  );
};

export const useApp = (): AppContextType => {
  const context = useContext(AppContext);
  if (!context) {
    throw new Error('useApp must be used within an AppProvider');
  }
  return context;
};
