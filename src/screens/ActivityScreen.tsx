import React from 'react';
import { useApp } from '../context/AppContext';
import { Icon } from '../components/ui/Icon';
import { Avatar } from '../components/ui/Avatar';
import { ActivityNotification } from '../types';

export const ActivityScreen: React.FC = () => {
  const {
    notifications,
    markNotificationsRead,
    popScreen,
    openPlace,
    getPlaceById,
    getUserById,
  } = useApp();

  const unreadCount = notifications.filter((n: ActivityNotification) => n.unread).length;

  return (
    <div className="screen activity-screen" style={{ padding: '8px 14px 28px' }}>
      {/* Top Header */}
      <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginBottom: 16 }}>
        <button className="iconbtn tap" onClick={popScreen} aria-label="Go Back">
          <Icon name="chevL" size={15} sw={2.5} />
        </button>

        <div className="display d-lg" style={{ flex: 1, fontSize: 22, fontWeight: 800 }}>
          Activity
        </div>

        {unreadCount > 0 ? (
          <button
            className="pill fill-or lg"
            onClick={markNotificationsRead}
            style={{ cursor: 'pointer', border: 0 }}
            title="Tap to mark all as read"
          >
            {unreadCount} new
          </button>
        ) : (
          <span className="mono-sm" style={{ color: 'var(--ink-3)', fontSize: 10 }}>
            All caught up
          </span>
        )}
      </div>

      {/* Notifications List */}
      <div style={{ display: 'flex', flexDirection: 'column' }}>
        {notifications.map((n: ActivityNotification) => {
          const user = getUserById(n.who);
          const place = n.placeId ? getPlaceById(n.placeId) : null;

          return (
            <button
              key={n.id}
              onClick={(e) => n.placeId && openPlace(n.placeId, e.currentTarget)}
              style={{
                display: 'flex',
                alignItems: 'center',
                gap: 10,
                padding: '12px 6px',
                background: n.unread ? 'rgba(255, 224, 122, 0.28)' : 'none',
                border: 0,
                borderBottom: '1.5px solid rgba(21, 19, 15, 0.09)',
                textAlign: 'left',
                cursor: n.placeId ? 'pointer' : 'default',
                width: '100%',
                borderRadius: 8,
              }}
            >
              <div style={{ position: 'relative', flexShrink: 0 }}>
                <Avatar id={n.who} size={34} />
                <span
                  style={{
                    position: 'absolute',
                    right: -3,
                    bottom: -3,
                    width: 17,
                    height: 17,
                    borderRadius: '50%',
                    background: 'var(--paper)',
                    border: '1.5px solid var(--ink)',
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: 'center',
                  }}
                >
                  <Icon
                    name={
                      n.kind === 'drop'
                        ? 'map'
                        : n.kind === 'save'
                        ? 'bookmark'
                        : n.kind === 'follow'
                        ? 'users'
                        : 'clock'
                    }
                    size={9}
                    sw={2.5}
                  />
                </span>
              </div>

              <div style={{ flex: 1, minWidth: 0 }}>
                <div style={{ fontSize: 12.5, lineHeight: 1.35 }}>
                  <b>{user?.name}</b> <span style={{ color: 'var(--ink-2)' }}>{n.txt}</span>
                </div>
                <div className="mono-sm" style={{ color: 'var(--ink-3)', marginTop: 2, fontSize: 9.5 }}>
                  {n.when}
                </div>
              </div>

              {place && (
                <div
                  style={{
                    width: 38,
                    height: 38,
                    borderRadius: 8,
                    overflow: 'hidden',
                    border: '1.5px solid var(--ink)',
                    flexShrink: 0,
                  }}
                >
                  <img src={place.img} alt="" style={{ width: '100%', height: '100%', objectFit: 'cover' }} />
                </div>
              )}
            </button>
          );
        })}
      </div>

      <div className="mono-sm" style={{ color: 'var(--ink-3)', textAlign: 'center', marginTop: 20, fontSize: 10 }}>
        That’s everything from the last 2 days
      </div>
    </div>
  );
};
