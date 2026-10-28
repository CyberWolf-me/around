import React from 'react';
import { useApp } from './context/AppContext';
import { MobileFrame } from './components/layout/MobileFrame';
import { DesktopRail } from './components/layout/DesktopRail';
import { TabBar } from './components/layout/TabBar';
import { FlightPhoto } from './components/ui/FlightPhoto';
import { FeedScreen } from './screens/FeedScreen';
import { ExploreScreen } from './screens/ExploreScreen';
import { SavedScreen } from './screens/SavedScreen';
import { ProfileScreen } from './screens/ProfileScreen';
import { PlaceDetailScreen } from './screens/PlaceDetailScreen';
import { ActivityScreen } from './screens/ActivityScreen';
import { SettingsScreen } from './screens/SettingsScreen';
import { OnboardingScreen } from './screens/OnboardingScreen';
import { CreateDropModal } from './screens/CreateDropModal';

export const AppContent: React.FC = () => {
  const { booted, activeTab, stack, flight } = useApp();

  const topScreen = stack[stack.length - 1];

  const renderActiveScreen = () => {
    if (!booted) {
      return <OnboardingScreen />;
    }

    if (topScreen) {
      if (topScreen.kind === 'place') {
        return <PlaceDetailScreen placeId={topScreen.id} />;
      }
      if (topScreen.kind === 'profile') {
        return <ProfileScreen />;
      }
      if (topScreen.kind === 'notifs') {
        return <ActivityScreen />;
      }
      if (topScreen.kind === 'settings') {
        return <SettingsScreen />;
      }
    }

    switch (activeTab) {
      case 'feed':
        return <FeedScreen />;
      case 'explore':
        return <ExploreScreen />;
      case 'saved':
        return <SavedScreen />;
      case 'profile':
        return <ProfileScreen />;
      default:
        return <FeedScreen />;
    }
  };

  const isPlaceActive = topScreen?.kind === 'place';

  return (
    <div className="stage">
      {/* Desktop presentation side navigation rail */}
      <DesktopRail />

      {/* Mobile Device Container */}
      <MobileFrame>
        {renderActiveScreen()}

        {/* Tab Bar - Shown when booted and not inside place detail */}
        {booted && !isPlaceActive && <TabBar />}

        {/* Create Drop 4-step wizard modal sheet */}
        <CreateDropModal />
      </MobileFrame>

      {/* Shared element photo flight animation */}
      <FlightPhoto flight={flight} />
    </div>
  );
};
