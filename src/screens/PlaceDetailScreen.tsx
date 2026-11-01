import React, { useState } from 'react';
import { useApp } from '../context/AppContext';
import { Icon } from '../components/ui/Icon';
import { Avatar } from '../components/ui/Avatar';
import { StarRating } from '../components/ui/StarRating';
import { AudienceBadge } from '../components/ui/AudienceBadge';
import { filterPlaceDrops } from '../services/privacyFilter';
import { INITIAL_PUBLIC_NOTES, FRIENDS_BEEN_COUNT } from '../data/mockData';
import { PlaceDrop, PublicReview } from '../types';

export interface PlaceDetailScreenProps {
  placeId: string;
}

export const PlaceDetailScreen: React.FC<PlaceDetailScreenProps> = ({ placeId }) => {
  const {
    getPlaceById,
    getUserById,
    savedPlaceIds,
    toggleSavePlace,
    popScreen,
    pushScreen,
    openCreateDrop,
    showToast,
    drops,
    currentUserId,
    followedUserIds,
    privacySettings,
    blockUser,
    reportContent,
  } = useApp();

  const [activeTab, setActiveTab] = useState<'friends' | 'public'>('friends');
  const [directionsModal, setDirectionsModal] = useState<boolean>(false);
  const [moderationTarget, setModerationTarget] = useState<{
    type: 'drop' | 'place';
    id: string;
    authorId?: string;
    authorHandle?: string;
  } | null>(null);

  const place = getPlaceById(placeId);
  if (!place) {
    return (
      <div className="screen" style={{ padding: 20 }}>
        <button className="iconbtn tap" onClick={popScreen}>
          <Icon name="chevL" size={16} sw={2.5} />
        </button>
        <p>Place not found.</p>
      </div>
    );
  }

  const isSaved = savedPlaceIds.includes(place.id);

  const friendDrops = filterPlaceDrops(
    drops,
    place.id,
    'all_friends',
    currentUserId,
    followedUserIds,
    new Set(privacySettings.blockedUsers)
  );

  const friendsCount = Math.max(friendDrops.length, FRIENDS_BEEN_COUNT[place.id] || 1);

  const publicNotes = (INITIAL_PUBLIC_NOTES[place.id] || [
    {
      id: 'default-pn',
      who: 'rustam',
      rating: 5,
      when: '2 days ago',
      txt: 'Best visited early morning before the Mirabad crowd arrives.',
    },
  ]).filter(pn => !privacySettings.blockedUsers.includes(pn.who));

  const handleShare = () => {
    if (navigator.clipboard) {
      navigator.clipboard.writeText(`https://around.app/places/${place.id}`);
    }
    showToast('Place link copied to clipboard');
  };

  return (
    <div className="screen place-detail-screen" style={{ padding: '6px 14px 90px' }}>
      {/* Navigation Top Bar */}
      <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginBottom: 12 }}>
        <button className="iconbtn tap" onClick={popScreen} aria-label="Go Back">
          <Icon name="chevL" size={15} sw={2.5} />
        </button>

        <span className="mono" style={{ color: 'var(--ink-3)', flex: 1, fontSize: 11, overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>
          Tashkent · {place.cat.split(' · ')[0]}
        </span>

        <button
          className="iconbtn tap"
          onClick={() => toggleSavePlace(place.id)}
          style={isSaved ? { background: 'var(--orange)', color: '#FFFFFF', borderColor: 'var(--ink)' } : undefined}
          aria-label={isSaved ? 'Remove from saved' : 'Save venue'}
        >
          <Icon name="bookmark" size={15} sw={2.2} fill={isSaved ? 'currentColor' : 'none'} />
        </button>

        <button className="iconbtn tap" onClick={handleShare} aria-label="Share venue">
          <Icon name="share" size={15} sw={2.2} />
        </button>

        <button
          className="iconbtn tap"
          onClick={() => setModerationTarget({ type: 'place', id: place.id })}
          aria-label="Report venue"
          title="Report venue"
        >
          <Icon name="flag" size={14} sw={2.2} />
        </button>
      </div>

      {/* Hero Photo Target */}
      <div className="hero-card" style={{ marginBottom: 14 }}>
        <div
          className="photo-wrap"
          id="place-hero-target"
          style={{
            position: 'relative',
            height: 230,
            borderRadius: 20,
            overflow: 'hidden',
            border: '2px solid var(--ink)',
            boxShadow: 'var(--sh)',
          }}
        >
          <img
            src={place.img}
            alt={place.name}
            style={{ width: '100%', height: '100%', objectFit: 'cover' }}
          />

          <div
            style={{
              position: 'absolute',
              inset: 0,
              background: 'linear-gradient(to top, rgba(21,19,15,.7) 0%, rgba(21,19,15,.1) 50%, transparent 80%)',
            }}
          />

          <div style={{ position: 'absolute', left: 14, right: 14, bottom: 12, color: '#FFFFFF' }}>
            <div style={{ display: 'flex', gap: 6, marginBottom: 6 }}>
              <span className="pill fill-or" style={{ borderColor: 'rgba(255,255,255,.5)' }}>
                {place.cat.split(' · ')[0]}
              </span>
              <span className="pill" style={{ background: 'rgba(251,250,246,.95)', color: 'var(--ink)' }}>
                {place.closed}
              </span>
            </div>

            <div className="display" style={{ fontSize: 26, fontWeight: 800, color: '#FFFFFF', textShadow: '0 1px 12px rgba(0,0,0,.4)' }}>
              {place.name}
            </div>

            <div style={{ display: 'flex', alignItems: 'center', gap: 6, marginTop: 4, fontSize: 11.5, color: 'rgba(255,255,255,.95)' }}>
              <Icon name="map" size={12} sw={2.3} />
              {place.street} · {place.dist}
            </div>
          </div>
        </div>
      </div>

      {/* Trust Split Metric Box */}
      <div
        className="statgrid"
        style={{
          display: 'grid',
          gridTemplateColumns: 'repeat(2, 1fr)',
          gap: 8,
          marginBottom: 14,
        }}
      >
        <div
          className="stat"
          style={{
            background: 'var(--paper-2)',
            padding: '10px 12px',
            borderRadius: 14,
            border: '1.5px solid var(--ink)',
            boxShadow: '2px 2px 0 var(--ink)',
          }}
        >
          <div style={{ display: 'flex', alignItems: 'baseline', gap: 4 }}>
            <b style={{ fontSize: 18, fontFamily: 'var(--display)' }}>{place.rating}</b>
            <span style={{ fontSize: 10, color: 'var(--ink-3)' }}>★</span>
          </div>
          <span className="mono-sm" style={{ color: 'var(--ink-2)', fontSize: 9.5 }}>
            {place.reviews} public reviews
          </span>
        </div>

        <div
          className="stat"
          style={{
            background: 'var(--butter)',
            padding: '10px 12px',
            borderRadius: 14,
            border: '1.5px solid var(--ink)',
            boxShadow: '2px 2px 0 var(--ink)',
          }}
        >
          <b style={{ fontSize: 18, fontFamily: 'var(--display)' }}>{friendsCount} friends</b>
          <span className="mono-sm" style={{ color: 'var(--ink)', fontSize: 9.5 }}>
            recommend this venue
          </span>
        </div>
      </div>

      {/* Curated Venue Tag Line */}
      <div
        style={{
          padding: '10px 12px',
          background: 'var(--paper)',
          border: '1.5px solid var(--ink)',
          borderRadius: 12,
          fontSize: 12,
          lineHeight: 1.45,
          color: 'var(--ink-2)',
          marginBottom: 14,
        }}
      >
        “{place.line}”
      </div>

      {/* Tags List */}
      <div style={{ display: 'flex', gap: 6, flexWrap: 'wrap', marginBottom: 16 }}>
        {place.tags.map((t: string) => (
          <span key={t} className="pill ghost" style={{ fontSize: 10.5 }}>
            #{t}
          </span>
        ))}
      </div>

      {/* Tab Switcher: Friends Layer vs Public Community */}
      <div className="seg" style={{ marginBottom: 14, display: 'flex', background: 'var(--paper-2)', padding: 3, borderRadius: 10, border: '1.5px solid var(--ink)' }}>
        <button
          className={activeTab === 'friends' ? 'on' : ''}
          onClick={() => setActiveTab('friends')}
          style={{
            flex: 1,
            padding: '7px 0',
            border: 0,
            borderRadius: 7,
            background: activeTab === 'friends' ? 'var(--ink)' : 'transparent',
            color: activeTab === 'friends' ? 'var(--paper)' : 'var(--ink)',
            fontFamily: 'var(--body)',
            fontWeight: 700,
            fontSize: 11.5,
            cursor: 'pointer',
          }}
        >
          Friends' Drops ({friendDrops.length})
        </button>
        <button
          className={activeTab === 'public' ? 'on' : ''}
          onClick={() => setActiveTab('public')}
          style={{
            flex: 1,
            padding: '7px 0',
            border: 0,
            borderRadius: 7,
            background: activeTab === 'public' ? 'var(--ink)' : 'transparent',
            color: activeTab === 'public' ? 'var(--paper)' : 'var(--ink)',
            fontFamily: 'var(--body)',
            fontWeight: 700,
            fontSize: 11.5,
            cursor: 'pointer',
          }}
        >
          Public Reviews ({publicNotes.length})
        </button>
      </div>

      {/* Tab Content */}
      {activeTab === 'friends' ? (
        <div style={{ display: 'flex', flexDirection: 'column', gap: 10 }}>
          {friendDrops.length === 0 ? (
            <div style={{ padding: '24px 12px', textAlign: 'center', background: 'var(--paper-2)', borderRadius: 14, border: '1.5px dashed var(--ink)' }}>
              <div className="display d-sm" style={{ fontSize: 14, marginBottom: 4 }}>
                No friends have dropped here yet
              </div>
              <p className="mono-sm" style={{ fontSize: 10.5, color: 'var(--ink-3)', marginBottom: 12 }}>
                Be the first person in your circle to share this Tashkent spot!
              </p>
              <button
                className="btn btn-primary btn-sm"
                onClick={() => openCreateDrop(place.id, 2)}
                style={{ height: 34, margin: '0 auto' }}
              >
                <Icon name="camera" size={13} sw={2.2} /> Drop this place
              </button>
            </div>
          ) : (
            friendDrops.map((d: PlaceDrop) => {
              const author = getUserById(d.who);
              return (
                <div
                  key={d.id}
                  className="card-flat"
                  style={{
                    padding: 12,
                    background: 'var(--paper)',
                    border: '1.8px solid var(--ink)',
                    borderRadius: 14,
                    boxShadow: '2.5px 2.5px 0 var(--ink)',
                  }}
                >
                  <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginBottom: 8 }}>
                    <Avatar
                      id={d.who}
                      size={26}
                      onClick={() => pushScreen({ kind: 'profile', userId: d.who })}
                    />
                    <div
                      style={{ flex: 1, cursor: 'pointer' }}
                      onClick={() => pushScreen({ kind: 'profile', userId: d.who })}
                    >
                      <div style={{ fontSize: 12, fontWeight: 700 }}>{author?.name}</div>
                      <div className="mono-sm" style={{ fontSize: 9.5, color: 'var(--ink-3)' }}>
                        @{author?.handle} · {d.when}
                      </div>
                    </div>
                    <AudienceBadge aud={d.aud} />
                    <button
                      style={{ background: 'none', border: 0, cursor: 'pointer', padding: 2, color: 'var(--ink-3)' }}
                      onClick={() => setModerationTarget({ type: 'drop', id: d.id, authorId: d.who, authorHandle: author?.handle })}
                      aria-label="Report or block"
                    >
                      <Icon name="dots" size={14} sw={2.5} />
                    </button>
                  </div>

                  {d.img && (
                    <div style={{ width: '100%', height: 140, borderRadius: 10, overflow: 'hidden', border: '1.5px solid var(--ink)', marginBottom: 8 }}>
                      <img src={d.img} alt="" style={{ width: '100%', height: '100%', objectFit: 'cover' }} />
                    </div>
                  )}

                  <div style={{ fontSize: 12.5, lineHeight: 1.4, color: 'var(--ink)' }}>
                    “{d.note}”
                  </div>

                  {d.rating && (
                    <div style={{ marginTop: 6 }}>
                      <StarRating rating={d.rating} size={10} />
                    </div>
                  )}
                </div>
              );
            })
          )}
        </div>
      ) : (
        <div style={{ display: 'flex', flexDirection: 'column', gap: 10 }}>
          {publicNotes.map((pn: PublicReview) => {
            const author = getUserById(pn.who);
            return (
              <div
                key={pn.id}
                style={{
                  padding: 12,
                  background: 'var(--paper-2)',
                  border: '1.5px solid var(--ink)',
                  borderRadius: 14,
                }}
              >
                <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginBottom: 6 }}>
                  <Avatar
                    id={pn.who}
                    size={22}
                    ring={false}
                    onClick={() => pushScreen({ kind: 'profile', userId: pn.who })}
                  />
                  <span
                    style={{ fontSize: 11.5, fontWeight: 700, cursor: 'pointer' }}
                    onClick={() => pushScreen({ kind: 'profile', userId: pn.who })}
                  >
                    {author?.name}
                  </span>
                  <span className="mono-sm" style={{ color: 'var(--ink-3)', fontSize: 9.5, marginLeft: 'auto' }}>
                    {pn.when}
                  </span>
                </div>
                <div style={{ marginBottom: 4 }}>
                  <StarRating rating={pn.rating} size={9} />
                </div>
                <div style={{ fontSize: 11.5, lineHeight: 1.4, color: 'var(--ink-2)' }}>
                  {pn.txt}
                </div>
              </div>
            );
          })}
        </div>
      )}

      {/* Floating Bottom Fixed CTA */}
      <div
        style={{
          position: 'sticky',
          bottom: 12,
          display: 'flex',
          gap: 8,
          marginTop: 20,
          zIndex: 50,
        }}
      >
        <button
          className="btn btn-ghost"
          onClick={() => setDirectionsModal(true)}
          style={{ flex: 1, height: 44, borderRadius: 12, boxShadow: '2px 2px 0 var(--ink)' }}
        >
          <Icon name="nav" size={14} sw={2.4} fill="currentColor" /> Directions
        </button>

        <button
          className="btn btn-primary"
          onClick={() => openCreateDrop(place.id, 2)}
          style={{ flex: 2, height: 44, borderRadius: 12, boxShadow: '3px 3px 0 var(--ink)' }}
        >
          <Icon name="camera" size={15} sw={2.2} /> Drop This Place
        </button>
      </div>

      {/* Directions Modal */}
      {directionsModal && (
        <div
          style={{
            position: 'fixed',
            inset: 0,
            background: 'rgba(21,19,15,.6)',
            zIndex: 9999,
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            padding: 20,
          }}
          onClick={() => setDirectionsModal(false)}
        >
          <div
            style={{
              background: 'var(--paper)',
              border: '2.5px solid var(--ink)',
              borderRadius: 18,
              padding: 20,
              width: '100%',
              maxWidth: 320,
              boxShadow: 'var(--sh-lg)',
            }}
            onClick={(e) => e.stopPropagation()}
          >
            <div className="display d-sm" style={{ fontSize: 18, marginBottom: 6 }}>
              Walk to {place.name}
            </div>
            <p className="mono-sm" style={{ fontSize: 11, color: 'var(--ink-2)', lineHeight: 1.5, marginBottom: 16 }}>
              Address: {place.street}, Tashkent ({place.dist}). Hours: {place.hours}.
            </p>
            <button
              className="btn btn-primary btn-block"
              onClick={() => {
                if (navigator.clipboard) {
                  navigator.clipboard.writeText(`${place.name}, ${place.street}, Tashkent`);
                }
                setDirectionsModal(false);
                showToast('Copied Tashkent address for map navigation');
              }}
            >
              Copy Address & Open Maps
            </button>
          </div>
        </div>
      )}

      {/* Moderation / Block Modal */}
      {moderationTarget && (
        <div
          style={{
            position: 'fixed',
            inset: 0,
            background: 'rgba(21,19,15,.6)',
            zIndex: 9999,
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            padding: 20,
          }}
          onClick={() => setModerationTarget(null)}
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
              Safety & Moderation
            </div>
            <div style={{ display: 'flex', flexDirection: 'column', gap: 6, marginBottom: 12 }}>
              {[
                'Inappropriate photo or text',
                'Spam or promotional shilling',
                'Wrong venue / inaccurate location',
                'Harassment or privacy violation',
              ].map(reason => (
                <button
                  key={reason}
                  className="btn btn-ghost btn-sm"
                  style={{ justifyContent: 'flex-start', textAlign: 'left' }}
                  onClick={() => {
                    reportContent(moderationTarget.type, moderationTarget.id, reason);
                    setModerationTarget(null);
                  }}
                >
                  <Icon name="flag" size={12} sw={2.2} /> {reason}
                </button>
              ))}
              {moderationTarget.authorId && moderationTarget.authorId !== 'you' && (
                <button
                  className="btn btn-danger btn-sm"
                  style={{ marginTop: 4 }}
                  onClick={() => {
                    blockUser(moderationTarget.authorId!);
                    setModerationTarget(null);
                  }}
                >
                  Block @{moderationTarget.authorHandle || moderationTarget.authorId}
                </button>
              )}
            </div>
            <button className="btn btn-ghost btn-block btn-sm" onClick={() => setModerationTarget(null)}>
              Cancel
            </button>
          </div>
        </div>
      )}
    </div>
  );
};
