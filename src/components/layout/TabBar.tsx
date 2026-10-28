import React from 'react';
import { useApp } from '../../context/AppContext';
import { Icon } from '../ui/Icon';
import { ScreenTab } from '../../types';

export const TabBar: React.FC = () => {
  const { activeTab, switchTab, stack, openCreateDrop, pushScreen } = useApp();

  const isProfileActive = stack.length > 0 && stack[stack.length - 1].kind === 'profile';
  const isPlaceActive = stack.length > 0 && stack[stack.length - 1].kind === 'place';

  // Do not show tab bar when inside full place view modal
  if (isPlaceActive) return null;

  const tabs: Array<{ id: ScreenTab | 'drop'; icon: string; label: string }> = [
    { id: 'feed', icon: 'home', label: 'Feed' },
    { id: 'explore', icon: 'compass', label: 'Explore' },
    { id: 'drop', icon: 'plus', label: 'Drop' },
    { id: 'saved', icon: 'bookmark', label: 'Saved' },
    { id: 'profile', icon: 'user', label: 'You' },
  ];

  return (
    <nav className="tabbar" role="navigation" aria-label="Bottom navigation">
      {tabs.map((tab) => {
        if (tab.id === 'drop') {
          return (
            <button
              key="drop-button"
              className="tab-drop"
              onClick={() => openCreateDrop()}
              aria-label="Create Place Drop"
            >
              <span className="orb">
                <Icon name="plus" size={24} sw={2.8} />
              </span>
              <span>Drop</span>
            </button>
          );
        }

        if (tab.id === 'profile') {
          return (
            <button
              key="profile"
              className={`tab ${isProfileActive ? 'on' : ''}`}
              onClick={() => pushScreen({ kind: 'profile' })}
              aria-label="Your Profile"
            >
              <Icon name="user" size={19} sw={2} />
              <span>You</span>
              <span className="tab-dot" />
            </button>
          );
        }

        const isCurrent = activeTab === tab.id && stack.length === 0;

        return (
          <button
            key={tab.id}
            className={`tab ${isCurrent ? 'on' : ''}`}
            onClick={() => switchTab(tab.id as ScreenTab)}
            aria-label={tab.label}
          >
            <Icon name={tab.icon} size={19} sw={2} />
            <span>{tab.label}</span>
            <span className="tab-dot" />
          </button>
        );
      })}
    </nav>
  );
};
