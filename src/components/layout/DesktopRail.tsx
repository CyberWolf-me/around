import React from 'react';
import { useApp } from '../../context/AppContext';

export const DesktopRail: React.FC = () => {
  const {
    activeTab,
    switchTab,
    exploreMode,
    setExploreMode,
    stack,
    pushScreen,
    booted,
    setBooted,
    openCreateDrop,
    deviceFrame,
    setDeviceFrame,
    resetToDemoData,
  } = useApp();

  const topScreen = stack[stack.length - 1];

  const screens: Array<{ id: string; label: string; action: () => void; isActive: boolean }> = [
    {
      id: 'feed',
      label: 'Friends feed',
      action: () => {
        setBooted(true);
        switchTab('feed');
      },
      isActive: booted && activeTab === 'feed' && stack.length === 0,
    },
    {
      id: 'explore-map',
      label: 'Explore · map',
      action: () => {
        setBooted(true);
        switchTab('explore');
        setExploreMode('map');
      },
      isActive: booted && activeTab === 'explore' && exploreMode === 'map' && stack.length === 0,
    },
    {
      id: 'explore-list',
      label: 'Explore · list',
      action: () => {
        setBooted(true);
        switchTab('explore');
        setExploreMode('list');
      },
      isActive: booted && activeTab === 'explore' && exploreMode === 'list' && stack.length === 0,
    },
    {
      id: 'place',
      label: 'Place page (Kettle & Loaf)',
      action: () => {
        setBooted(true);
        pushScreen({ kind: 'place', id: 'kettle' });
      },
      isActive: booted && topScreen?.kind === 'place',
    },
    {
      id: 'create',
      label: 'Create a drop',
      action: () => {
        setBooted(true);
        openCreateDrop();
      },
      isActive: false,
    },
    {
      id: 'saved',
      label: 'Saved places & plans',
      action: () => {
        setBooted(true);
        switchTab('saved');
      },
      isActive: booted && activeTab === 'saved' && stack.length === 0,
    },
    {
      id: 'profile',
      label: 'Your profile',
      action: () => {
        setBooted(true);
        pushScreen({ kind: 'profile' });
      },
      isActive: booted && topScreen?.kind === 'profile',
    },
    {
      id: 'settings',
      label: 'Privacy & settings',
      action: () => {
        setBooted(true);
        pushScreen({ kind: 'settings' });
      },
      isActive: booted && topScreen?.kind === 'settings',
    },
    {
      id: 'notifs',
      label: 'Activity & notifications',
      action: () => {
        setBooted(true);
        pushScreen({ kind: 'notifs' });
      },
      isActive: booted && topScreen?.kind === 'notifs',
    },
    {
      id: 'onboard',
      label: 'Onboarding walkthrough',
      action: () => {
        setBooted(false);
      },
      isActive: !booted,
    },
  ];

  return (
    <aside className="rail" style={{ width: 250, flexShrink: 0 }}>
      <div className="mark" style={{ fontFamily: 'var(--display)', fontWeight: 800, fontSize: 32, letterSpacing: '-0.04em', lineHeight: 0.95, marginBottom: 8 }}>
        Around<span style={{ color: 'var(--orange)' }}>.</span>
      </div>
      <div className="sub" style={{ fontFamily: 'var(--mono)', fontSize: 9.5, lineHeight: 1.6, letterSpacing: '0.08em', textTransform: 'uppercase', color: 'var(--ink-2)', marginBottom: 20 }}>
        Places from people<br />you actually trust.
      </div>

      <div className="rail-h" style={{ fontFamily: 'var(--mono)', fontSize: 9, letterSpacing: '0.14em', textTransform: 'uppercase', color: 'var(--ink-3)', paddingBottom: 8, borderBottom: '1.5px solid var(--ink)', marginBottom: 10 }}>
        Direct Navigation
      </div>

      <nav className="rail-nav" style={{ display: 'flex', flexDirection: 'column', gap: 2, marginBottom: 24 }}>
        {screens.map((item, idx) => (
          <button
            key={item.id}
            onClick={item.action}
            className={item.isActive ? 'on' : ''}
            style={{
              display: 'flex',
              alignItems: 'baseline',
              gap: 8,
              background: 'none',
              border: 0,
              padding: '6px 0',
              cursor: 'pointer',
              textAlign: 'left',
              fontFamily: 'var(--body)',
              fontSize: 13,
              fontWeight: item.isActive ? 700 : 500,
              color: item.isActive ? 'var(--orange)' : 'var(--ink-2)',
              transition: 'all 0.15s ease',
            }}
          >
            <i style={{ fontFamily: 'var(--mono)', fontSize: 9, fontStyle: 'normal', color: 'var(--ink-3)' }}>
              {String(idx + 1).padStart(2, '0')}
            </i>
            <span>{item.label}</span>
          </button>
        ))}
      </nav>

      <div className="rail-h" style={{ fontFamily: 'var(--mono)', fontSize: 9, letterSpacing: '0.14em', textTransform: 'uppercase', color: 'var(--ink-3)', paddingBottom: 8, borderBottom: '1.5px solid var(--ink)', marginBottom: 10 }}>
        Device Simulation
      </div>

      <div style={{ display: 'flex', gap: 6, marginBottom: 18 }}>
        {(['iphone', 'pixel', 'fullscreen'] as const).map(frame => (
          <button
            key={frame}
            onClick={() => setDeviceFrame(frame)}
            style={{
              flex: 1,
              padding: '6px 0',
              borderRadius: 8,
              border: `1.5px solid ${deviceFrame === frame ? 'var(--ink)' : 'rgba(21,19,15,.2)'}`,
              background: deviceFrame === frame ? 'var(--butter)' : 'transparent',
              fontFamily: 'var(--mono)',
              fontSize: 10,
              fontWeight: 700,
              textTransform: 'capitalize',
              cursor: 'pointer',
            }}
          >
            {frame}
          </button>
        ))}
      </div>

      <button
        onClick={resetToDemoData}
        className="btn btn-ghost btn-sm btn-block"
        style={{ fontSize: 11, height: 32 }}
      >
        ↺ Reset Demo State
      </button>

      <div className="rail-note" style={{ marginTop: 20, fontFamily: 'var(--mono)', fontSize: 9, color: 'var(--ink-3)', lineHeight: 1.5 }}>
        All data is persisted to localStorage. Tap any card, map pin, or bookmark to explore.
      </div>
    </aside>
  );
};
