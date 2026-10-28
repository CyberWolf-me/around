import React, { createContext, useContext, useState, useEffect, useCallback, useRef } from 'react';
import {
  Place,
  PlaceDrop,
  UserProfile,
  FriendPlan,
  ActivityNotification,
  PrivacySettings,
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
} from '../data/mockData';
import { storage } from '../services/storage';
import { buzz, hapticPatterns } from '../services/haptics';
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
  activeTab: ScreenTab;
  switchTab: (tab: ScreenTab) => void;
  exploreMode: 'map' | 'list';
  setExploreMode: (mode: 'map' | 'list') => void;
  stack: StackScreen[];
  pushScreen: (screen: StackScreen) => void;
  popScreen: () => void;
  places: Place[];
  drops: PlaceDrop[];
  savedPlaceIds: string[];
  toggleSavePlace: (id: string) => void;
  followedUserIds: Set<string>;
  toggleFollowUser: (id: string) => void;
  plans: FriendPlan[];
  notifications: ActivityNotification[];
  markNotificationsRead: () => void;
  privacySettings: PrivacySettings;
  updatePrivacySettings: (partial: Partial<PrivacySettings>) => void;
  blockUser: (id: string) => void;
  reportContent: (type: 'drop' | 'place', id: string, reason: string) => void;
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

const AppContext = createContext<AppContextType | undefined>(undefined);

export const AppProvider: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  // Booted state (onboarding completed)
  const [booted, setBootedState] = useState<boolean>(() => storage.get('booted', true));
  const setBooted = (val: boolean) => {
    setBootedState(val);
    storage.set('booted', val);
  };

  const [currentUserId, setCurrentUserId] = useState<string>('you');
  const [activeTab, setActiveTab] = useState<ScreenTab>('feed');
  const [exploreMode, setExploreMode] = useState<'map' | 'list'>('map');
  const [stack, setStack] = useState<StackScreen[]>([]);
  const [toast, setToast] = useState<string | null>(null);
  const toastTimeoutRef = useRef<number | null>(null);

  const [deviceFrame, setDeviceFrame] = useState<'iphone' | 'pixel' | 'fullscreen'>('iphone');

  // Stored state with local storage fallback
  const [places, setPlaces] = useState<Place[]>(() => storage.get('places', INITIAL_PLACES));
  const [drops, setDrops] = useState<PlaceDrop[]>(() => storage.get('drops', INITIAL_DROPS));
  const [savedPlaceIds, setSavedPlaceIds] = useState<string[]>(() =>
    storage.get('saved_places', ['kettle', 'sable', 'castellan'])
  );
  const [followedUserIds, setFollowedUserIds] = useState<Set<string>>(() => {
    const list = storage.get('followed_users', ['noor', 'teo', 'mina', 'ari', 'priya']);
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

  // Flight photo state
  const [flight, setFlight] = useState<FlightState | null>(null);

  // Create drop modal state
  const [createModal, setCreateModal] = useState<{
    open: boolean;
    presetPlaceId: string | null;
    initialStep: number;
  }>({
    open: false,
    presetPlaceId: null,
    initialStep: 0,
  });

  // Sync to local storage
  useEffect(() => {
    storage.set('drops', drops);
  }, [drops]);

  useEffect(() => {
    storage.set('saved_places', savedPlaceIds);
  }, [savedPlaceIds]);

  useEffect(() => {
    storage.set('followed_users', Array.from(followedUserIds));
  }, [followedUserIds]);

  useEffect(() => {
    storage.set('privacy_settings', privacySettings);
  }, [privacySettings]);

  useEffect(() => {
    storage.set('notifications', notifications);
  }, [notifications]);

  const showToast = useCallback((msg: string) => {
    if (toastTimeoutRef.current) clearTimeout(toastTimeoutRef.current);
    setToast(msg);
    toastTimeoutRef.current = window.setTimeout(() => {
      setToast(null);
    }, 2400);
  }, []);

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

  const openPlace = useCallback((id: string, sourceElement?: HTMLElement | null) => {
    const place = places.find(p => p.id === id);
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
    pushScreen({ kind: 'place', id });
  }, [places, pushScreen]);

  const toggleSavePlace = useCallback((id: string) => {
    setSavedPlaceIds(prev => {
      const exists = prev.includes(id);
      hapticPatterns.medium();
      if (exists) {
        showToast('Removed from shortlist');
        return prev.filter(x => x !== id);
      } else {
        showToast('Saved to your shortlist');
        return [...prev, id];
      }
    });
  }, [showToast]);

  const toggleFollowUser = useCallback((id: string) => {
    setFollowedUserIds(prev => {
      const next = new Set(prev);
      if (next.has(id)) {
        next.delete(id);
        showToast(`Unfollowed @${INITIAL_PEOPLE[id]?.handle || id}`);
      } else {
        next.add(id);
        showToast(`Now following @${INITIAL_PEOPLE[id]?.handle || id}`);
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
    setPrivacySettings(prev => ({
      ...prev,
      blockedUsers: [...prev.blockedUsers, id],
    }));
    showToast(`Blocked @${INITIAL_PEOPLE[id]?.handle || id}`);
  }, [showToast]);

  const reportContent = useCallback((_type: 'drop' | 'place', _id: string, reason: string) => {
    showToast(`Report received: "${reason}". Under review.`);
  }, [showToast]);

  const openCreateDrop = useCallback((presetPlaceId?: string, initialStep = 0) => {
    setCreateModal({
      open: true,
      presetPlaceId: presetPlaceId || null,
      initialStep,
    });
    hapticPatterns.medium();
  }, []);

  const closeCreateDrop = useCallback(() => {
    setCreateModal(prev => ({ ...prev, open: false }));
  }, []);

  const publishDrop = useCallback((payload: CreateDropPayload) => {
    const newDrop: PlaceDrop = {
      id: `drop_${Date.now()}`,
      who: currentUserId,
      place: payload.placeId,
      img: payload.photoUrl,
      size: payload.photoUrl ? 'hero' : 'note',
      note: payload.note || 'Dropped this venue.',
      rating: payload.rating,
      when: 'Just now',
      timestamp: Date.now(),
      saves: 0,
      aud: payload.aud,
      tags: payload.tags,
      fresh: true,
    };

    setDrops(prev => [newDrop, ...prev]);
    closeCreateDrop();
    hapticPatterns.success();
    showToast(payload.aud === 'friends' ? 'Dropped for your friends' : 'Dropped publicly for Barlow Hill');
  }, [currentUserId, closeCreateDrop, showToast]);

  const resetToDemoData = useCallback(() => {
    storage.clearAll();
    setPlaces(INITIAL_PLACES);
    setDrops(INITIAL_DROPS);
    setSavedPlaceIds(['kettle', 'sable', 'castellan']);
    setFollowedUserIds(new Set(['noor', 'teo', 'mina', 'ari', 'priya']));
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
    setBootedState(true);
    setStack([]);
    setActiveTab('feed');
    showToast('Reset to initial Barlow Hill demo data');
  }, [showToast]);

  const getPlaceById = useCallback((id: string) => places.find(p => p.id === id), [places]);
  const getUserById = useCallback((id: string) => INITIAL_PEOPLE[id] || INITIAL_PEOPLE.you, []);

  return (
    <AppContext.Provider
      value={{
        booted,
        setBooted,
        currentUserId,
        setCurrentUserId,
        activeTab,
        switchTab,
        exploreMode,
        setExploreMode,
        stack,
        pushScreen,
        popScreen,
        places,
        drops,
        savedPlaceIds,
        toggleSavePlace,
        followedUserIds,
        toggleFollowUser,
        plans,
        notifications,
        markNotificationsRead,
        privacySettings,
        updatePrivacySettings,
        blockUser,
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
