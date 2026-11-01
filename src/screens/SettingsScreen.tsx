import React, { useState } from 'react';
import { useApp } from '../context/AppContext';
import { Icon } from '../components/ui/Icon';
import { Audience, PlaceDrop } from '../types';
import { buzz } from '../services/haptics';

export const SettingsScreen: React.FC = () => {
  const {
    userProfile,
    privacySettings,
    updatePrivacySettings,
    unblockUser,
    reportContent,
    popScreen,
    showToast,
    resetToDemoData,
    drops,
    savedPlaceIds,
    savedPlaceStatuses,
    authEmail,
    signInWithEmail,
    signOutAccount,
    setBooted,
  } = useApp();

  const [blockedModalOpen, setBlockedModalOpen] = useState<boolean>(false);
  const [reportModalOpen, setReportModalOpen] = useState<boolean>(false);
  const [authModalOpen, setAuthModalOpen] = useState<boolean>(false);
  const [emailInput, setEmailInput] = useState<string>(authEmail || '');
  const [passwordInput, setPasswordInput] = useState<string>('');
  const [reportReason, setReportReason] = useState<string>('');

  const handleAudienceChange = (aud: Audience) => {
    updatePrivacySettings({ defaultAudience: aud });
    buzz(6);
  };

  const exportUserData = () => {
    const data = {
      profile: userProfile,
      privacySettings,
      myDrops: drops.filter((d: PlaceDrop) => d.who === 'you'),
      savedPlaces: savedPlaceIds.map(id => ({ id, status: savedPlaceStatuses[id] || 'want_to_go' })),
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

  const handleSubmitReport = (e: React.FormEvent) => {
    e.preventDefault();
    if (!reportReason.trim()) return;
    reportContent('place', 'general', reportReason.trim());
    setReportReason('');
    setReportModalOpen(false);
  };

  const handleAuthSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (!emailInput.trim() || !emailInput.includes('@')) {
      showToast('Please enter a valid email address');
      return;
    }
    if (passwordInput.length < 6) {
      showToast('Password must be at least 6 characters');
      return;
    }
    signInWithEmail(emailInput.trim());
    setPasswordInput('');
    setAuthModalOpen(false);
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

        <div style={{ display: 'flex', alignItems: 'center', padding: '12px 14px' }}>
          <div style={{ width: 28, height: 28, borderRadius: 8, background: 'var(--paper-2)', border: '1.5px solid var(--ink)', display: 'flex', alignItems: 'center', justifyContent: 'center', marginRight: 10, flexShrink: 0 }}>
            <Icon name="user" size={13} sw={2.4} />
          </div>
          <div style={{ flex: 1, marginRight: 10 }}>
            <div style={{ fontSize: 12.5, fontWeight: 700 }}>Friend requests</div>
            <div style={{ fontSize: 10, color: 'var(--ink-2)', lineHeight: 1.35 }}>
              Allow Tashkent community members to request connection.
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
          onClick={() => setBlockedModalOpen(true)}
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
          onClick={() => setReportModalOpen(true)}
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

      {/* Account & Session Management */}
      <span className="setlabel" style={{ fontFamily: 'var(--mono)', fontSize: 9.5, letterSpacing: '0.1em', textTransform: 'uppercase', color: 'var(--ink-3)', display: 'block', marginBottom: 6 }}>
        Account & Session
      </span>

      <div
        className="setgroup"
        style={{
          padding: '12px 14px',
          background: 'var(--paper)',
          border: '1.8px solid var(--ink)',
          borderRadius: 14,
          boxShadow: 'var(--sh)',
          marginBottom: 14,
        }}
      >
        <div style={{ fontSize: 12, fontWeight: 700, marginBottom: 8 }}>
          {authEmail ? `Signed in as ${authEmail}` : `Local Explorer Session (@${userProfile.handle})`}
        </div>
        <div style={{ display: 'flex', gap: 8 }}>
          <button
            className="btn btn-primary btn-sm"
            style={{ flex: 1, height: 34 }}
            onClick={() => setAuthModalOpen(true)}
          >
            {authEmail ? 'Switch Account' : 'Sign In / Create Account'}
          </button>
          {authEmail && (
            <button
              className="btn btn-ghost btn-sm"
              style={{ height: 34 }}
              onClick={signOutAccount}
            >
              Sign Out
            </button>
          )}
        </div>
      </div>

      <div style={{ display: 'flex', flexDirection: 'column', gap: 8 }}>
        <button
          className="btn btn-ghost btn-block btn-sm"
          onClick={() => {
            popScreen();
            setBooted(false);
          }}
          style={{ height: 38 }}
        >
          <Icon name="compass" size={13} sw={2.2} /> Replay Onboarding Walkthrough
        </button>

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
          <Icon name="trash" size={13} sw={2.2} /> Delete Account & Reset Data
        </button>
      </div>

      {authModalOpen && (
        <div
          style={{
            position: 'fixed',
            inset: 0,
            background: 'rgba(21,19,15,.6)',
            zIndex: 9999,
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            padding: 18,
          }}
          onClick={() => setAuthModalOpen(false)}
        >
          <form
            onSubmit={handleAuthSubmit}
            style={{
              background: 'var(--paper)',
              border: '2.5px solid var(--ink)',
              borderRadius: 18,
              padding: 18,
              width: '100%',
              maxWidth: 330,
              boxShadow: 'var(--sh-lg)',
            }}
            onClick={(e) => e.stopPropagation()}
          >
            <div className="display d-sm" style={{ fontSize: 17, marginBottom: 8 }}>
              Sign In / Create Account
            </div>
            <label className="mono-sm" style={{ display: 'block', marginBottom: 4 }}>Email</label>
            <input
              type="email"
              value={emailInput}
              onChange={(e) => setEmailInput(e.target.value)}
              placeholder="you@tashkent.uz"
              style={{ width: '100%', padding: 8, borderRadius: 8, border: '1.5px solid var(--ink)', marginBottom: 10 }}
            />
            <label className="mono-sm" style={{ display: 'block', marginBottom: 4 }}>Password</label>
            <input
              type="password"
              value={passwordInput}
              onChange={(e) => setPasswordInput(e.target.value)}
              placeholder="Minimum 6 characters"
              style={{ width: '100%', padding: 8, borderRadius: 8, border: '1.5px solid var(--ink)', marginBottom: 12 }}
            />
            <div style={{ display: 'flex', gap: 8 }}>
              <button type="button" className="btn btn-ghost btn-sm" style={{ flex: 1 }} onClick={() => setAuthModalOpen(false)}>
                Cancel
              </button>
              <button type="submit" className="btn btn-primary btn-sm" style={{ flex: 1 }}>
                Continue
              </button>
            </div>
          </form>
        </div>
      )}

      {blockedModalOpen && (
        <div
          style={{
            position: 'fixed',
            inset: 0,
            background: 'rgba(21,19,15,.6)',
            zIndex: 9999,
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            padding: 18,
          }}
          onClick={() => setBlockedModalOpen(false)}
        >
          <div
            style={{
              background: 'var(--paper)',
              border: '2.5px solid var(--ink)',
              borderRadius: 18,
              padding: 18,
              width: '100%',
              maxWidth: 320,
              boxShadow: 'var(--sh-lg)',
            }}
            onClick={(e) => e.stopPropagation()}
          >
            <div className="display d-sm" style={{ fontSize: 17, marginBottom: 10 }}>
              Blocked Accounts
            </div>
            {privacySettings.blockedUsers.length === 0 ? (
              <p className="mono-sm" style={{ color: 'var(--ink-3)', marginBottom: 14 }}>
                No accounts are currently blocked.
              </p>
            ) : (
              <div style={{ display: 'flex', flexDirection: 'column', gap: 8, marginBottom: 14 }}>
                {privacySettings.blockedUsers.map(uid => (
                  <div key={uid} style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', padding: '6px 10px', background: 'var(--paper-2)', borderRadius: 10, border: '1.5px solid var(--ink)' }}>
                    <span style={{ fontWeight: 700, fontSize: 12 }}>@{uid}</span>
                    <button className="pill fill-or" style={{ cursor: 'pointer' }} onClick={() => unblockUser(uid)}>
                      Unblock
                    </button>
                  </div>
                ))}
              </div>
            )}
            <button className="btn btn-primary btn-block btn-sm" onClick={() => setBlockedModalOpen(false)}>
              Done
            </button>
          </div>
        </div>
      )}

      {reportModalOpen && (
        <div
          style={{
            position: 'fixed',
            inset: 0,
            background: 'rgba(21,19,15,.6)',
            zIndex: 9999,
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            padding: 18,
          }}
          onClick={() => setReportModalOpen(false)}
        >
          <form
            onSubmit={handleSubmitReport}
            style={{
              background: 'var(--paper)',
              border: '2.5px solid var(--ink)',
              borderRadius: 18,
              padding: 18,
              width: '100%',
              maxWidth: 330,
              boxShadow: 'var(--sh-lg)',
            }}
            onClick={(e) => e.stopPropagation()}
          >
            <div className="display d-sm" style={{ fontSize: 17, marginBottom: 8 }}>
              Report an Issue
            </div>
            <textarea
              rows={3}
              value={reportReason}
              onChange={(e) => setReportReason(e.target.value)}
              placeholder="Describe the inappropriate content, spam, or venue inaccuracy..."
              style={{ width: '100%', padding: 10, borderRadius: 10, border: '1.5px solid var(--ink)', marginBottom: 12, fontFamily: 'var(--body)' }}
            />
            <div style={{ display: 'flex', gap: 8 }}>
              <button type="button" className="btn btn-ghost btn-sm" style={{ flex: 1 }} onClick={() => setReportModalOpen(false)}>
                Cancel
              </button>
              <button type="submit" className="btn btn-danger btn-sm" style={{ flex: 1 }}>
                Submit Report
              </button>
            </div>
          </form>
        </div>
      )}
    </div>
  );
};
