import React from 'react';
import { useApp } from '../../context/AppContext';
import { Avatar } from '../ui/Avatar';
import { Icon } from '../ui/Icon';

export const AppHeader: React.FC = () => {
  const { notifications, pushScreen, currentUserId } = useApp();
  const unreadCount = notifications.filter(n => n.unread).length;

  return (
    <header className="apphead" style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', padding: '12px 18px 8px' }}>
      <div style={{ display: 'flex', alignItems: 'baseline', gap: 7 }}>
        <div className="wordmark" style={{ fontFamily: 'var(--display)', fontSize: 24, fontWeight: 800, letterSpacing: '-0.04em' }}>
          Around<em style={{ color: 'var(--orange)', fontStyle: 'normal' }}>.</em>
        </div>
        <span className="mono-sm" style={{ color: 'var(--ink-3)', fontSize: 9.5, letterSpacing: '0.04em' }}>
          Tashkent
        </span>
      </div>

      <div style={{ display: 'flex', gap: 8, alignItems: 'center' }}>
        <button
          className="iconbtn sm plain bell tap"
          onClick={() => pushScreen({ kind: 'notifs' })}
          aria-label="Activity & Notifications"
          style={{ position: 'relative' }}
        >
          <Icon name="bell" size={19} sw={2} />
          {unreadCount > 0 && (
            <span
              className="bell-dot"
              style={{
                position: 'absolute',
                top: 4,
                right: 4,
                width: 8,
                height: 8,
                borderRadius: '50%',
                background: 'var(--orange)',
                border: '1.5px solid var(--paper)',
              }}
            />
          )}
        </button>

        <button
          className="iconbtn plain tap"
          onClick={() => pushScreen({ kind: 'profile' })}
          aria-label="Profile"
          style={{ width: 33, height: 33, padding: 0, border: 0, background: 'none' }}
        >
          <Avatar id={currentUserId} size={30} ring={true} />
        </button>
      </div>
    </header>
  );
};
