import React, { useState } from 'react';
import { useApp } from '../context/AppContext';
import { Icon } from '../components/ui/Icon';
import { Avatar } from '../components/ui/Avatar';
import { AudienceBadge } from '../components/ui/AudienceBadge';
import { INITIAL_PEOPLE } from '../data/mockData';
import { PlaceDrop, UserProfile } from '../types';

export const ProfileScreen: React.FC = () => {
  const {
    currentUserId,
    getUserById,
    getPlaceById,
    drops,
    savedPlaceIds,
    followedUserIds,
    toggleFollowUser,
    pushScreen,
    openPlace,
    showToast,
  } = useApp();

  const [findFriendsOpen, setFindFriendsOpen] = useState<boolean>(false);
  const user = getUserById(currentUserId) || INITIAL_PEOPLE.you;

  const myDrops = drops.filter((d: PlaceDrop) => d.who === currentUserId);

  return (
    <div className="screen profile-screen" style={{ padding: '8px 14px 28px' }}>
      {/* Top Header */}
      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 14 }}>
        <span className="mono-sm" style={{ color: 'var(--ink-3)', fontSize: 11 }}>
          Your Profile
        </span>
        <button
          className="iconbtn sm plain tap"
          onClick={() => pushScreen({ kind: 'settings' })}
          aria-label="Settings"
          title="Settings"
        >
          <Icon name="dots" size={18} sw={3.2} />
        </button>
      </div>

      {/* User Info Header */}
      <div style={{ display: 'flex', alignItems: 'center', gap: 14, marginBottom: 16 }}>
        <div
          style={{
            width: 74,
            height: 74,
            borderRadius: '50%',
            border: '2.5px solid var(--ink)',
            background: user.bg || 'var(--orange)',
            color: '#FFFFFF',
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            fontFamily: 'var(--display)',
            fontWeight: 800,
            fontSize: 27,
            letterSpacing: '-.03em',
            boxShadow: 'var(--sh)',
            flexShrink: 0,
          }}
        >
          {user.init}
        </div>

        <div style={{ flex: 1, minWidth: 0 }}>
          <div className="display d-md" style={{ fontSize: 20, fontWeight: 800, marginBottom: 2 }}>
            {user.name}
          </div>
          <div className="mono-sm" style={{ color: 'var(--ink-3)', fontSize: 10.5, marginBottom: 6 }}>
            @{user.handle} · {user.neighborhood}
          </div>

          <div style={{ display: 'flex', gap: 12 }}>
            <span style={{ display: 'flex', alignItems: 'baseline', gap: 3 }}>
              <span style={{ fontSize: 13, fontWeight: 700 }}>{myDrops.length}</span>
              <span className="mono-sm" style={{ color: 'var(--ink-3)', fontSize: 9.5 }}>drops</span>
            </span>
            <span style={{ display: 'flex', alignItems: 'baseline', gap: 3 }}>
              <span style={{ fontSize: 13, fontWeight: 700 }}>{followedUserIds.size}</span>
              <span className="mono-sm" style={{ color: 'var(--ink-3)', fontSize: 9.5 }}>friends</span>
            </span>
            <span style={{ display: 'flex', alignItems: 'baseline', gap: 3 }}>
              <span style={{ fontSize: 13, fontWeight: 700 }}>{savedPlaceIds.length}</span>
              <span className="mono-sm" style={{ color: 'var(--ink-3)', fontSize: 9.5 }}>saved</span>
            </span>
          </div>
        </div>
      </div>

      {/* Profile CTA Buttons */}
      <div style={{ display: 'flex', gap: 8, marginBottom: 18 }}>
        <button
          className="btn btn-sm"
          style={{ flex: 1 }}
          onClick={() => showToast('Profile details updated')}
        >
          Edit Profile
        </button>
        <button
          className="btn btn-sm btn-ghost"
          style={{ flex: 1 }}
          onClick={() => setFindFriendsOpen(true)}
        >
          <Icon name="users" size={13} sw={2.2} /> Find Friends
        </button>
      </div>

      {/* Your Drops Section */}
      <div className="sectionhead" style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'baseline', marginBottom: 10 }}>
        <span className="display d-sm" style={{ fontSize: 16, fontWeight: 700 }}>
          Your Drops
        </span>
        <span className="mono-sm" style={{ color: 'var(--ink-3)', fontSize: 10 }}>
          Friends & public
        </span>
      </div>

      <div style={{ display: 'flex', flexDirection: 'column', gap: 10 }}>
        {myDrops.length === 0 ? (
          <div style={{ padding: 16, textAlign: 'center', background: 'var(--paper-2)', borderRadius: 14 }}>
            <div className="mono-sm" style={{ fontSize: 11, color: 'var(--ink-3)' }}>
              You haven’t posted any drops yet.
            </div>
          </div>
        ) : (
          myDrops.map((d: PlaceDrop) => {
            const p = getPlaceById(d.place);
            if (!p) return null;

            return (
              <div
                key={d.id}
                className="card-flat"
                style={{
                  display: 'flex',
                  gap: 10,
                  padding: 10,
                  background: 'var(--paper)',
                  border: '1.8px solid var(--ink)',
                  borderRadius: 14,
                  boxShadow: '2px 2px 0 var(--ink)',
                  cursor: 'pointer',
                }}
                onClick={(e) => openPlace(d.place, e.currentTarget)}
              >
                <div
                  style={{
                    width: 52,
                    height: 52,
                    borderRadius: 10,
                    overflow: 'hidden',
                    flexShrink: 0,
                    border: '1.5px solid var(--ink)',
                  }}
                >
                  <img
                    src={d.img || p.img}
                    alt=""
                    style={{ width: '100%', height: '100%', objectFit: 'cover' }}
                  />
                </div>

                <div style={{ flex: 1, minWidth: 0 }}>
                  <div style={{ display: 'flex', alignItems: 'center', gap: 6, marginBottom: 3 }}>
                    <span style={{ fontSize: 12, fontWeight: 700, flex: 1, overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>
                      {p.name}
                    </span>
                    <AudienceBadge aud={d.aud} />
                  </div>
                  <div style={{ fontSize: 11.5, lineHeight: 1.35, color: 'var(--ink-2)' }}>
                    {d.note}
                  </div>
                  <div style={{ display: 'flex', alignItems: 'center', gap: 10, marginTop: 4 }}>
                    <span className="mono-sm" style={{ color: 'var(--ink-3)', fontSize: 9.5 }}>
                      {d.when}
                    </span>
                    <span style={{ display: 'flex', alignItems: 'center', gap: 3 }}>
                      <Icon name="heart" size={11} sw={2.2} style={{ color: 'var(--orange)' }} />
                      <span style={{ fontSize: 9.5, fontWeight: 700 }}>{d.saves}</span>
                    </span>
                  </div>
                </div>
              </div>
            );
          })
        )}
      </div>

      {/* You Also Saved Section */}
      <div style={{ marginTop: 20, paddingTop: 14, borderTop: '1.5px solid rgba(21,19,15,.12)' }}>
        <div className="mono-sm" style={{ color: 'var(--ink-3)', fontSize: 10, marginBottom: 10 }}>
          You also saved
        </div>
        <div className="scroll-x" style={{ gap: 8 }}>
          {savedPlaceIds.slice(0, 5).map((id: string) => {
            const p = getPlaceById(id);
            if (!p) return null;
            return (
              <button
                key={id}
                onClick={(e) => openPlace(id, e.currentTarget)}
                style={{
                  border: 0,
                  background: 'none',
                  padding: 0,
                  width: 76,
                  flexShrink: 0,
                  cursor: 'pointer',
                  textAlign: 'left',
                }}
              >
                <div style={{ height: 76, borderRadius: 12, overflow: 'hidden', border: '1.5px solid var(--ink)' }}>
                  <img src={p.img} alt="" style={{ width: '100%', height: '100%', objectFit: 'cover' }} />
                </div>
                <div style={{ fontSize: 10, fontWeight: 700, marginTop: 4, lineHeight: 1.2, overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>
                  {p.name}
                </div>
              </button>
            );
          })}
        </div>
      </div>

      {/* Find Friends Modal */}
      {findFriendsOpen && (
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
          onClick={() => setFindFriendsOpen(false)}
        >
          <div
            style={{
              background: 'var(--paper)',
              border: '2.5px solid var(--ink)',
              borderRadius: 20,
              padding: 18,
              width: '100%',
              maxWidth: 340,
              boxShadow: 'var(--sh-lg)',
            }}
            onClick={(e) => e.stopPropagation()}
          >
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 12 }}>
              <div className="display d-sm" style={{ fontSize: 17, fontWeight: 700 }}>
                Barlow Hill Community
              </div>
              <button
                onClick={() => setFindFriendsOpen(false)}
                style={{ background: 'none', border: 0, padding: 4, cursor: 'pointer' }}
              >
                <Icon name="x" size={16} sw={2.4} />
              </button>
            </div>

            <div style={{ display: 'flex', flexDirection: 'column', gap: 8, maxHeight: 280, overflowY: 'auto', marginBottom: 14 }}>
              {(Object.values(INITIAL_PEOPLE) as UserProfile[])
                .filter((p: UserProfile) => p.id !== currentUserId)
                .map((person: UserProfile) => {
                  const isFollowing = followedUserIds.has(person.id);
                  return (
                    <div
                      key={person.id}
                      style={{
                        display: 'flex',
                        alignItems: 'center',
                        gap: 10,
                        padding: '8px 10px',
                        borderRadius: 12,
                        background: 'var(--paper-2)',
                        border: '1.5px solid var(--ink)',
                      }}
                    >
                      <Avatar id={person.id} size={30} />
                      <div style={{ flex: 1, minWidth: 0 }}>
                        <div style={{ fontSize: 12, fontWeight: 700 }}>{person.name}</div>
                        <div className="mono-sm" style={{ color: 'var(--ink-3)', fontSize: 9.5 }}>
                          @{person.handle} · {person.dropsCount} drops
                        </div>
                      </div>
                      <button
                        className={`pill ${isFollowing ? 'fill-ink' : 'fill-or'}`}
                        style={{ height: 26, padding: '0 10px', cursor: 'pointer', fontSize: 10.5 }}
                        onClick={() => toggleFollowUser(person.id)}
                      >
                        {isFollowing ? 'Following' : '+ Follow'}
                      </button>
                    </div>
                  );
                })}
            </div>

            <button
              className="btn btn-primary btn-block btn-sm"
              onClick={() => setFindFriendsOpen(false)}
            >
              Done
            </button>
          </div>
        </div>
      )}
    </div>
  );
};
