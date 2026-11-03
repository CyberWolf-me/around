import React, { useState } from 'react';
import { useApp } from '../context/AppContext';
import { Icon } from '../components/ui/Icon';
import { Avatar } from '../components/ui/Avatar';
import { AudienceBadge } from '../components/ui/AudienceBadge';
import { WebCityPassport } from '../components/WebCityPassport';
import { INITIAL_PEOPLE } from '../data/mockData';
import { PlaceDrop, UserProfile } from '../types';
import { canViewVisitHistory } from '../services/privacyFilter';

export interface ProfileScreenProps {
  userId?: string;
}

export const ProfileScreen: React.FC<ProfileScreenProps> = ({ userId }) => {
  const {
    currentUserId,
    userProfile,
    updateUserProfile,
    getUserById,
    getPlaceById,
    drops,
    savedPlaceIds,
    followedUserIds,
    toggleFollowUser,
    privacySettings,
    popScreen,
    pushScreen,
    openPlace,
  } = useApp();

  const targetUserId = userId || currentUserId;
  const isOwnProfile = targetUserId === currentUserId;
  const user = getUserById(targetUserId) || userProfile;

  const [findFriendsOpen, setFindFriendsOpen] = useState<boolean>(false);
  const [editModalOpen, setEditModalOpen] = useState<boolean>(false);
  const [editName, setEditName] = useState<string>(userProfile.name);
  const [editHandle, setEditHandle] = useState<string>(userProfile.handle);
  const [editNeighborhood, setEditNeighborhood] = useState<string>(userProfile.neighborhood);
  const [editBio, setEditBio] = useState<string>(userProfile.bio || '');

  const isFollowingTarget = followedUserIds.has(targetUserId);

  const canSeeTargetHistory = isOwnProfile || canViewVisitHistory(
    targetUserId,
    currentUserId,
    {
      ...privacySettings,
      hideVisitsHistory: Boolean(user.hideVisitsHistory),
    },
    isFollowingTarget
  );

  const myDrops = drops.filter((d: PlaceDrop) => {
    if (d.who !== targetUserId || d.quarantined) return false;
    if (!isOwnProfile && d.aud === 'friends' && !isFollowingTarget) return false;
    return true;
  });

  const openEditModal = () => {
    setEditName(userProfile.name);
    setEditHandle(userProfile.handle);
    setEditNeighborhood(userProfile.neighborhood);
    setEditBio(userProfile.bio || '');
    setEditModalOpen(true);
  };

  const handleSaveProfile = (e: React.FormEvent) => {
    e.preventDefault();
    updateUserProfile({
      name: editName.trim() || userProfile.name,
      handle: editHandle.trim() || userProfile.handle,
      neighborhood: editNeighborhood.trim() || userProfile.neighborhood,
      bio: editBio.trim(),
    });
    setEditModalOpen(false);
  };

  return (
    <div className="screen profile-screen" style={{ padding: '8px 14px 28px' }}>
      {/* Top Header */}
      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 14 }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
          {!isOwnProfile && (
            <button className="iconbtn sm tap" onClick={popScreen} aria-label="Go Back">
              <Icon name="chevL" size={14} sw={2.5} />
            </button>
          )}
          <span className="mono-sm" style={{ color: 'var(--ink-3)', fontSize: 11 }}>
            {isOwnProfile ? 'Your Profile' : `@${user.handle}`}
          </span>
        </div>
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
      <div style={{ display: 'flex', alignItems: 'center', gap: 14, marginBottom: 12 }}>
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
              <span style={{ fontSize: 13, fontWeight: 700 }}>{isOwnProfile ? myDrops.length : user.dropsCount}</span>
              <span className="mono-sm" style={{ color: 'var(--ink-3)', fontSize: 9.5 }}>drops</span>
            </span>
            <span style={{ display: 'flex', alignItems: 'baseline', gap: 3 }}>
              <span style={{ fontSize: 13, fontWeight: 700 }}>{isOwnProfile ? followedUserIds.size : user.friendsCount}</span>
              <span className="mono-sm" style={{ color: 'var(--ink-3)', fontSize: 9.5 }}>friends</span>
            </span>
            <span style={{ display: 'flex', alignItems: 'baseline', gap: 3 }}>
              <span style={{ fontSize: 13, fontWeight: 700 }}>{isOwnProfile ? savedPlaceIds.length : user.savedCount}</span>
              <span className="mono-sm" style={{ color: 'var(--ink-3)', fontSize: 9.5 }}>saved</span>
            </span>
          </div>
        </div>
      </div>

      {user.bio && (
        <div style={{ fontSize: 12, color: 'var(--ink-2)', marginBottom: 14, lineHeight: 1.4 }}>
          {user.bio}
        </div>
      )}

      {/* Profile CTA Buttons */}
      {isOwnProfile ? (
        <div style={{ display: 'flex', gap: 8, marginBottom: 18 }}>
          <button
            className="btn btn-sm"
            style={{ flex: 1 }}
            onClick={openEditModal}
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
      ) : (
        <div style={{ display: 'flex', gap: 8, marginBottom: 18 }}>
          <button
            className={`btn btn-sm ${isFollowingTarget ? 'btn-ghost' : 'btn-primary'}`}
            style={{ flex: 1 }}
            onClick={() => toggleFollowUser(targetUserId)}
          >
            {isFollowingTarget ? '✓ Following (Mutual)' : '+ Follow'}
          </button>
        </div>
      )}

      {/* City Passport: District Stamps & Territory Crowns Section */}
      <div style={{ marginBottom: 18 }}>
        <WebCityPassport
          username={user.handle}
          neighborhood={user.neighborhood}
          dropsCount={myDrops.length}
          visitedDistricts={[user.neighborhood || 'Mirabad']}
          crownsCount={isOwnProfile ? 2 : (myDrops.length >= 5 ? 1 : 0)}
          locale="en"
        />
      </div>

      {/* Drops Section */}
      <div className="sectionhead" style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'baseline', marginBottom: 10 }}>
        <span className="display d-sm" style={{ fontSize: 16, fontWeight: 700 }}>
          {isOwnProfile ? 'Your Drops' : `${user.name.split(' ')[0]}'s Drops`}
        </span>
        <span className="mono-sm" style={{ color: 'var(--ink-3)', fontSize: 10 }}>
          Friends & public
        </span>
      </div>

      <div style={{ display: 'flex', flexDirection: 'column', gap: 10 }}>
        {!canSeeTargetHistory ? (
          <div style={{ padding: 20, textAlign: 'center', background: 'var(--paper-2)', borderRadius: 14, border: '1.5px dashed var(--ink)' }}>
            <Icon name="lock" size={18} sw={2.4} />
            <div className="display d-sm" style={{ fontSize: 13.5, marginTop: 6, marginBottom: 4 }}>
              Visit timeline is private
            </div>
            <div className="mono-sm" style={{ fontSize: 10.5, color: 'var(--ink-3)' }}>
              {user.hideVisitsHistory
                ? `@${user.handle} has enabled "Keep my visits private".`
                : `Connect with @${user.handle} to see their friends-only drops.`}
            </div>
          </div>
        ) : myDrops.length === 0 ? (
          <div style={{ padding: 16, textAlign: 'center', background: 'var(--paper-2)', borderRadius: 14 }}>
            <div className="mono-sm" style={{ fontSize: 11, color: 'var(--ink-3)' }}>
              No drops posted yet.
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

      {/* You Also Saved Section (Strictly Own Profile Only) */}
      {isOwnProfile && (
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
      )}

      {/* Edit Profile Modal */}
      {editModalOpen && (
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
          onClick={() => setEditModalOpen(false)}
        >
          <form
            onSubmit={handleSaveProfile}
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
            <div className="display d-sm" style={{ fontSize: 17, fontWeight: 700, marginBottom: 12 }}>
              Edit Profile
            </div>
            <label className="mono-sm" style={{ display: 'block', marginBottom: 4 }}>Full Name</label>
            <input
              type="text"
              value={editName}
              maxLength={80}
              onChange={(e) => setEditName(e.target.value)}
              style={{ width: '100%', padding: 8, borderRadius: 8, border: '1.5px solid var(--ink)', marginBottom: 10 }}
            />
            <label className="mono-sm" style={{ display: 'block', marginBottom: 4 }}>Handle (@username)</label>
            <input
              type="text"
              value={editHandle}
              maxLength={32}
              onChange={(e) => setEditHandle(e.target.value)}
              style={{ width: '100%', padding: 8, borderRadius: 8, border: '1.5px solid var(--ink)', marginBottom: 10 }}
            />
            <label className="mono-sm" style={{ display: 'block', marginBottom: 4 }}>Neighborhood</label>
            <input
              type="text"
              value={editNeighborhood}
              maxLength={80}
              onChange={(e) => setEditNeighborhood(e.target.value)}
              style={{ width: '100%', padding: 8, borderRadius: 8, border: '1.5px solid var(--ink)', marginBottom: 10 }}
            />
            <label className="mono-sm" style={{ display: 'block', marginBottom: 4 }}>Bio</label>
            <textarea
              rows={2}
              value={editBio}
              maxLength={300}
              onChange={(e) => setEditBio(e.target.value)}
              style={{ width: '100%', padding: 8, borderRadius: 8, border: '1.5px solid var(--ink)', marginBottom: 14, fontFamily: 'var(--body)' }}
            />
            <div style={{ display: 'flex', gap: 8 }}>
              <button type="button" className="btn btn-ghost btn-sm" style={{ flex: 1 }} onClick={() => setEditModalOpen(false)}>
                Cancel
              </button>
              <button type="submit" className="btn btn-primary btn-sm" style={{ flex: 1 }}>
                Save
              </button>
            </div>
          </form>
        </div>
      )}

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
                Community Friends
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
                      <Avatar
                        id={person.id}
                        size={30}
                        onClick={() => {
                          setFindFriendsOpen(false);
                          pushScreen({ kind: 'profile', userId: person.id });
                        }}
                      />
                      <div
                        style={{ flex: 1, minWidth: 0, cursor: 'pointer' }}
                        onClick={() => {
                          setFindFriendsOpen(false);
                          pushScreen({ kind: 'profile', userId: person.id });
                        }}
                      >
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
