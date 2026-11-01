import React from 'react';
import { useApp } from '../context/AppContext';
import { AppHeader } from '../components/layout/AppHeader';
import { Avatar } from '../components/ui/Avatar';
import { AudienceBadge } from '../components/ui/AudienceBadge';
import { Icon } from '../components/ui/Icon';
import { PlaceDrop } from '../types';
import { filterFeedDrops } from '../services/privacyFilter';

export const FeedScreen: React.FC = () => {
  const {
    drops,
    currentUserId,
    followedUserIds,
    privacySettings,
    savedPlaceIds,
    toggleSavePlace,
    openPlace,
    pushScreen,
    getPlaceById,
    getUserById,
    switchTab,
  } = useApp();

  // Enforce privacy boundaries: only followed friends + current user
  const visibleDrops = filterFeedDrops(
    drops,
    currentUserId,
    followedUserIds,
    new Set(privacySettings.blockedUsers)
  );

  const storiesPlaceIds = ['breadly', 'bnb', 'ecorn', 'tims', 'chorsu', 'centralpark', 'steam', 'kitobxon'];

  const renderDropCard = (d: PlaceDrop) => {
    const place = getPlaceById(d.place);
    const author = getUserById(d.who);
    if (!place) return null;

    const isSaved = savedPlaceIds.includes(place.id) || savedPlaceIds.includes(d.place);

    // Note card (text-first)
    if (d.size === 'note') {
      return (
        <button
          key={d.id}
          className="note-card span2"
          onClick={(e) => openPlace(place.id, e.currentTarget)}
          style={{ background: d.tint || 'var(--butter)', gridColumn: 'span 2' }}
        >
          <div style={{ display: 'flex', alignItems: 'center', gap: 6, width: '100%' }}>
            <span
              onClick={(e) => {
                e.stopPropagation();
                pushScreen({ kind: 'profile', userId: d.who });
              }}
              style={{ display: 'inline-flex', alignItems: 'center', gap: 6, cursor: 'pointer' }}
              title={`View @${author?.handle}'s profile`}
            >
              <Avatar id={d.who} size={22} ring={true} />
              <span style={{ fontSize: 11, fontWeight: 700 }}>
                {author?.name.split(' ')[0]}
              </span>
            </span>
            <AudienceBadge aud={d.aud} />
            <span className="mono-sm" style={{ color: 'var(--ink-2)', marginLeft: 'auto', fontSize: 10 }}>
              {place.cat.split(' · ')[0]}
            </span>
          </div>

          <div className="q" style={{ fontSize: 14.5, fontWeight: 600, lineHeight: 1.35, margin: '8px 0' }}>
            “{d.note}”
          </div>

          <div style={{ display: 'flex', alignItems: 'center', gap: 6, flexWrap: 'wrap', width: '100%' }}>
            <span className="pill fill-ink" style={{ borderColor: 'var(--ink)' }}>
              {place.name} <Icon name="arrowUR" size={9} sw={3} />
            </span>
            {d.tags && d.tags.map((t: string) => (
              <span key={t} className="pill ghost">
                {t}
              </span>
            ))}
            <span style={{ marginLeft: 'auto', fontFamily: 'var(--mono)', fontSize: 9.5, color: 'var(--ink-3)' }}>
              {d.when}
            </span>
          </div>
        </button>
      );
    }

    const isHero = d.size === 'hero';
    const isWide = d.size === 'wide';
    const imgHeight = isHero ? 196 : isWide ? 132 : 116;

    return (
      <button
        key={d.id}
        className={`drop-card ${isHero || isWide ? 'span2' : ''}`}
        onClick={(e) => openPlace(place.id, e.currentTarget)}
      >
        <div className="dc-img" style={{ height: imgHeight, position: 'relative' }}>
          {d.img ? (
            <img src={d.img} alt={place.name} loading="lazy" />
          ) : (
            <div style={{ width: '100%', height: '100%', background: 'var(--paper-2)' }} />
          )}

          <span className="dc-aud">
            <AudienceBadge aud={d.aud} />
          </span>

          <span
            className={`dc-save ${isSaved ? 'on' : ''}`}
            onClick={(e) => {
              e.stopPropagation();
              toggleSavePlace(place.id);
            }}
            title={isSaved ? 'Remove from saved' : 'Save to shortlist'}
          >
            <Icon
              name="bookmark"
              size={14}
              sw={2}
              fill={isSaved ? 'currentColor' : 'none'}
            />
          </span>
        </div>

        <div className="dc-body" style={{ padding: '8px 9px 10px' }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: 6, marginBottom: 5 }}>
            <span
              onClick={(e) => {
                e.stopPropagation();
                pushScreen({ kind: 'profile', userId: d.who });
              }}
              style={{ display: 'inline-flex', alignItems: 'center', gap: 6, cursor: 'pointer' }}
              title={`View @${author?.handle}'s profile`}
            >
              <Avatar id={d.who} size={18} ring={false} />
              <span style={{ fontSize: 10.5, fontWeight: 700, overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>
                {author?.name.split(' ')[0]}
              </span>
            </span>
            <span className="mono-sm" style={{ color: 'var(--ink-3)', marginLeft: 'auto', fontSize: 9 }}>
              {d.when}
            </span>
          </div>

          <div style={{ display: 'flex', alignItems: 'baseline', gap: 4, marginBottom: 4 }}>
            <span className="display d-sm" style={{ fontSize: 13.5, fontWeight: 700, overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>
              {place.name}
            </span>
          </div>

          <p style={{ margin: 0, fontSize: 11.5, lineHeight: 1.35, color: 'var(--ink-2)' }}>
            {d.note}
          </p>
        </div>
      </button>
    );
  };

  return (
    <div className="screen feed-screen" style={{ paddingBottom: 24 }}>
      <AppHeader />

      {/* Story avatars rail */}
      <div className="scroll-x" style={{ paddingTop: 6, paddingBottom: 10, marginBottom: 8 }}>
        {storiesPlaceIds.map(placeId => {
          const place = getPlaceById(placeId);
          if (!place) return null;
          return (
            <button
              key={placeId}
              onClick={(e) => openPlace(place.id, e.currentTarget)}
              style={{
                border: 0,
                background: 'none',
                padding: 0,
                cursor: 'pointer',
                display: 'flex',
                flexDirection: 'column',
                alignItems: 'center',
                gap: 5,
                flexShrink: 0,
                width: 64,
              }}
            >
              <div
                style={{
                  width: 58,
                  height: 58,
                  borderRadius: '50%',
                  padding: 2.5,
                  border: '2px solid var(--ink)',
                  background: 'var(--paper)',
                  boxShadow: '2px 2px 0 var(--ink)',
                  overflow: 'hidden',
                }}
              >
                <img
                  src={place.img}
                  alt={place.name}
                  style={{ width: '100%', height: '100%', borderRadius: '50%', objectFit: 'cover' }}
                />
              </div>
              <span
                style={{
                  fontFamily: 'var(--mono)',
                  fontSize: 7.5,
                  letterSpacing: '0.04em',
                  textTransform: 'uppercase',
                  color: 'var(--ink-2)',
                  textAlign: 'center',
                  lineHeight: 1.2,
                  width: 64,
                  overflow: 'hidden',
                  textOverflow: 'ellipsis',
                  whiteSpace: 'nowrap',
                }}
              >
                {place.name.split(' ')[0]}
              </span>
            </button>
          );
        })}
      </div>

      {/* Finite Bento Grid Feed */}
      <div className="bento" style={{ display: 'grid', gridTemplateColumns: 'repeat(2, 1fr)', gap: 11, padding: '0 14px' }}>
        {visibleDrops.map(renderDropCard)}
      </div>

      {/* Caught-Up Finite State (Anti-Doomscrolling principle) */}
      <div
        style={{
          marginTop: 24,
          padding: '16px 14px',
          textAlign: 'center',
          borderTop: '1.5px dashed rgba(21, 19, 15, 0.18)',
          margin: '24px 14px 0',
        }}
      >
        <div className="display d-sm" style={{ fontSize: 16, marginBottom: 4 }}>
          You're all caught up.
        </div>
        <div className="mono-sm" style={{ color: 'var(--ink-3)', fontSize: 10.5, marginBottom: 12 }}>
          That’s every drop from your friends in Tashkent today.
        </div>
        <button
          className="btn btn-primary btn-sm"
          onClick={() => switchTab('explore')}
          style={{ height: 36, margin: '0 auto' }}
        >
          <Icon name="compass" size={13} sw={2.2} /> Explore Public Tashkent
        </button>
      </div>
    </div>
  );
};
