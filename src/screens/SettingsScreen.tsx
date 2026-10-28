import React from 'react';
import { useApp } from '../context/AppContext';
import { Icon } from '../components/ui/Icon';
import { Audience, PlaceDrop } from '../types';
import { buzz } from '../services/haptics';

export const SettingsScreen: React.FC = () => {
  const {
    privacySettings,
    updatePrivacySettings,
    popScreen,
    showToast,
    resetToDemoData,
    drops,
    savedPlaceIds,
  } = useApp();

  const handleAudienceChange = (aud: Audience) => {
    updatePrivacySettings({ defaultAudience: aud });
    buzz(6);
  };

  const exportUserData = () => {
    const data = {
      profile: { id: 'you', name: 'Yusuf Okonjo' },
      privacySettings,
      myDrops: drops.filter((d: PlaceDrop) => d.who === 'you'),
      savedPlaceIds,
      exportedAt: new Date().toISOString(),
    };
    const blob = new Blob([JSON.stringify(data, null, 2)], { type: 'application/json' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = `around-user-data-${Date.now()}.json`;
    a.click();
    URL.revokeObjectURL(url);
    showToast('User data exported (GDPR format)');
  };

  return (
    <div className="screen settings-screen" style={{ padding: '8px 14px 40px' }}>
      {/* Top Header */}
      <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginBottom: 16 }}>
        <button className="iconbtn tap" onClick={popScreen} aria-label="Go Back">
          <Icon name="chevL" size={15} sw={2.5} />
        </button>
        <div className="display d-lg" style={{ flex: 1, fontSize: 22, fontWeight: 800 }}>
          Settings
        </div>
      </div>

      {/* Default Audience Selector */}
      <span className="setlabel" style={{ fontFamily: 'var(--mono)', fontSize: 9.5, letterSpacing: '0.1em', textTransform: 'uppercase', color: 'var(--ink-3)', display: 'block', marginBottom: 6 }}>
        Default Audience for New Drops
      </span>

      <div
        className="setgroup"
        style={{
          padding: '12px 14px',
          background: 'var(--paper)',
          border: '1.8px solid var(--ink)',
          borderRadius: 14,
          boxShadow: 'var(--sh)',
          marginBottom: 18,
        }}
      >
        <div style={{ display: 'flex', gap: 6, marginBottom: 8 }}>
          {(['friends', 'public'] as const).map((aud) => {
            const isSelected = privacySettings.defaultAudience === aud;
            return (
              <button
                key={aud}
                onClick={() => handleAudienceChange(aud)}
                style={{
                  flex: 1,
                  height: 38,
                  borderRadius: 10,
                  cursor: 'pointer',
                  border: `2px solid ${isSelected ? 'var(--ink)' : 'rgba(21,19,15,.18)'}`,
                  background: isSelected ? (aud === 'friends' ? 'var(--butter)' : 'var(--ink)') : 'transparent',
                  color: isSelected && aud === 'public' ? 'var(--paper)' : 'var(--ink)',
                  fontFamily: 'var(--body)',
                  fontWeight: 700,
                  fontSize: 12,
                  display: 'flex',
                  alignItems: 'center',
                  justifyContent: 'center',
                  gap: 5,
                }}
              >
                <Icon name={aud === 'friends' ? 'lock' : 'globe'} size={12} sw={2.4} />
                {aud === 'friends' ? 'Friends Only' : 'Public Discovery'}
              </button>
            );
          })}
        </div>

        <div style={{ fontSize: 11, lineHeight: 1.4, color: 'var(--ink-2)' }}>
          This is what every new Place Drop starts as. You can still customize visibility per post before publishing.
        </div>
      </div>

      {/* Privacy Toggles */}
      <span className="setlabel" style={{ fontFamily: 'var(--mono)', fontSize: 9.5, letterSpacing: '0.1em', textTransform: 'uppercase', color: 'var(--ink-3)', display: 'block', marginBottom: 6 }}>
        Privacy & Data Separation
      </span>

      <div
        className="setgroup"
        style={{
          background: 'var(--paper)',
          border: '1.8px solid var(--ink)',
          borderRadius: 14,
          boxShadow: 'var(--sh)',
          overflow: 'hidden',
          marginBottom: 18,
        }}
      >
        {/* Row 1: Keep visits private */}
        <div style={{ display: 'flex', alignItems: 'center', padding: '12px 14px', borderBottom: '1px solid rgba(21,19,15,.12)' }}>
          <div style={{ width: 28, height: 28, borderRadius: 8, background: 'var(--butter)', border: '1.5px solid var(--ink)', display: 'flex', alignItems: 'center', justifyContent: 'center', marginRight: 10, flexShrink: 0 }}>
            <Icon name="lock" size={13} sw={2.4} />
          </div>
          <div style={{ flex: 1, marginRight: 10 }}>
            <div style={{ fontSize: 12.5, fontWeight: 700 }}>Keep my visits private</div>
            <div style={{ fontSize: 10, color: 'var(--ink-2)', lineHeight: 1.35 }}>
              Places you visit are never listed on public profiles or maps.
            </div>
          </div>
          <input
            type="checkbox"
            checked={privacySettings.hideVisitsHistory}
            onChange={(e) => updatePrivacySettings({ hideVisitsHistory: e.target.checked })}
            style={{ width: 20, height: 20, accentColor: 'var(--orange)', cursor: 'pointer' }}
          />
        </div>

        {/* Row 2: Let friends find me */}
        <div style={{ display: 'flex', alignItems: 'center', padding: '12px 14px', borderBottom: '1px solid rgba(21,19,15,.12)' }}>
          <div style={{ width: 28, height: 28, borderRadius: 8, background: 'var(--paper-2)', border: '1.5px solid var(--ink)', display: 'flex', alignItems: 'center', justifyContent: 'center', marginRight: 10, flexShrink: 0 }}>
            <Icon name="users" size={13} sw={2.4} />
          </div>
          <div style={{ flex: 1, marginRight: 10 }}>
            <div style={{ fontSize: 12.5, fontWeight: 700 }}>Let friends find me</div>
            <div style={{ fontSize: 10, color: 'var(--ink-2)', lineHeight: 1.35 }}>
              Allows mutual connections to discover your profile in search.
            </div>
          </div>
          <input
            type="checkbox"
            checked={privacySettings.discoverableByFriends}
            onChange={(e) => updatePrivacySettings({ discoverableByFriends: e.target.checked })}
            style={{ width: 20, height: 20, accentColor: 'var(--orange)', cursor: 'pointer' }}
          />
        </div>

        {/* Row 3: Quiet hours */}
        <div style={{ display: 'flex', alignItems: 'center', padding: '12px 14px', borderBottom: '1px solid rgba(21,19,15,.12)' }}>
          <div style={{ width: 28, height: 28, borderRadius: 8, background: 'var(--paper-2)', border: '1.5px solid var(--ink)', display: 'flex', alignItems: 'center', justifyContent: 'center', marginRight: 10, flexShrink: 0 }}>
            <Icon name="bell" size={13} sw={2.4} />
          </div>
          <div style={{ flex: 1, marginRight: 10 }}>
            <div style={{ fontSize: 12.5, fontWeight: 700 }}>Quiet hours</div>
            <div style={{ fontSize: 10, color: 'var(--ink-2)', lineHeight: 1.35 }}>
              Mutes push alerts between 11pm and 8am.
            </div>
          </div>
          <input
            type="checkbox"
            checked={privacySettings.quietHours}
            onChange={(e) => updatePrivacySettings({ quietHours: e.target.checked })}
            style={{ width: 20, height: 20, accentColor: 'var(--orange)', cursor: 'pointer' }}
          />
        </div>

        {/* Row 4: Friend requests */}
        <div style={{ display: 'flex', alignItems: 'center', padding: '12px 14px' }}>
          <div style={{ width: 28, height: 28, borderRadius: 8, background: 'var(--paper-2)', border: '1.5px solid var(--ink)', display: 'flex', alignItems: 'center', justifyContent: 'center', marginRight: 10, flexShrink: 0 }}>
            <Icon name="user" size={13} sw={2.4} />
          </div>
          <div style={{ flex: 1, marginRight: 10 }}>
            <div style={{ fontSize: 12.5, fontWeight: 700 }}>Friend requests</div>
            <div style={{ fontSize: 10, color: 'var(--ink-2)', lineHeight: 1.35 }}>
              Allow university classmates to request connection.
            </div>
          </div>
          <input
            type="checkbox"
            checked={privacySettings.allowFriendRequests}
            onChange={(e) => updatePrivacySettings({ allowFriendRequests: e.target.checked })}
            style={{ width: 20, height: 20, accentColor: 'var(--orange)', cursor: 'pointer' }}
          />
        </div>
      </div>

      {/* Safety & Moderation Controls */}
      <span className="setlabel" style={{ fontFamily: 'var(--mono)', fontSize: 9.5, letterSpacing: '0.1em', textTransform: 'uppercase', color: 'var(--ink-3)', display: 'block', marginBottom: 6 }}>
        Safety & Content Moderation
      </span>

      <div
        className="setgroup"
        style={{
          background: 'var(--paper)',
          border: '1.8px solid var(--ink)',
          borderRadius: 14,
          boxShadow: 'var(--sh)',
          overflow: 'hidden',
          marginBottom: 18,
        }}
      >
        <button
          onClick={() => showToast('Zero accounts currently blocked')}
          style={{
            display: 'flex',
            alignItems: 'center',
            width: '100%',
            padding: '12px 14px',
            background: 'none',
            border: 0,
            borderBottom: '1px solid rgba(21,19,15,.12)',
            cursor: 'pointer',
            textAlign: 'left',
          }}
        >
          <div style={{ width: 28, height: 28, borderRadius: 8, background: 'var(--paper-2)', border: '1.5px solid var(--ink)', display: 'flex', alignItems: 'center', justifyContent: 'center', marginRight: 10 }}>
            <Icon name="shield" size={13} sw={2.4} />
          </div>
          <div style={{ flex: 1 }}>
            <div style={{ fontSize: 12.5, fontWeight: 700 }}>Blocked accounts</div>
            <div style={{ fontSize: 10, color: 'var(--ink-2)' }}>
              {privacySettings.blockedUsers.length} users blocked
            </div>
          </div>
          <Icon name="chevR" size={14} sw={2.4} style={{ color: 'var(--ink-3)' }} />
        </button>

        <button
          onClick={() => showToast('Report filed with trust & safety team')}
          style={{
            display: 'flex',
            alignItems: 'center',
            width: '100%',
            padding: '12px 14px',
            background: 'none',
            border: 0,
            cursor: 'pointer',
            textAlign: 'left',
          }}
        >
          <div style={{ width: 28, height: 28, borderRadius: 8, background: '#FFEBEE', border: '1.5px solid #D32F2F', color: '#D32F2F', display: 'flex', alignItems: 'center', justifyContent: 'center', marginRight: 10 }}>
            <Icon name="flag" size={13} sw={2.4} />
          </div>
          <div style={{ flex: 1 }}>
            <div style={{ fontSize: 12.5, fontWeight: 700, color: '#D32F2F' }}>Report an issue</div>
            <div style={{ fontSize: 10, color: 'var(--ink-2)' }}>
              Report inappropriate content or venue inaccuracies
            </div>
          </div>
          <Icon name="chevR" size={14} sw={2.4} style={{ color: 'var(--ink-3)' }} />
        </button>
      </div>

      {/* Account & Data Management */}
      <span className="setlabel" style={{ fontFamily: 'var(--mono)', fontSize: 9.5, letterSpacing: '0.1em', textTransform: 'uppercase', color: 'var(--ink-3)', display: 'block', marginBottom: 6 }}>
        Data & Account
      </span>

      <div style={{ display: 'flex', flexDirection: 'column', gap: 8 }}>
        <button
          className="btn btn-ghost btn-block btn-sm"
          onClick={exportUserData}
          style={{ height: 38 }}
        >
          <Icon name="share" size={13} sw={2.2} /> Export My Data (GDPR Portability)
        </button>

        <button
          className="btn btn-danger btn-block btn-sm"
          onClick={resetToDemoData}
          style={{ height: 38 }}
        >
          <Icon name="trash" size={13} sw={2.2} /> Reset App & Demo Data
        </button>
      </div>
    </div>
  );
};
