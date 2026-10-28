import React, { useState } from 'react';
import { useApp } from '../context/AppContext';
import { Icon } from '../components/ui/Icon';
import { Avatar } from '../components/ui/Avatar';
import { StarRating } from '../components/ui/StarRating';
import { FriendPlan, Place } from '../types';

export const SavedScreen: React.FC = () => {
  const {
    savedPlaceIds,
    toggleSavePlace,
    openPlace,
    getPlaceById,
    plans,
    switchTab,
  } = useApp();

  const [activeFilter, setActiveFilter] = useState<'All' | 'Want to go' | 'Been'>('All');

  const filters = ['All', 'Want to go', 'Been'] as const;

  const validSavedPlaces = savedPlaceIds
    .map((id: string) => getPlaceById(id))
    .filter((p): p is Place => Boolean(p));

  return (
    <div className="screen saved-screen" style={{ padding: '8px 14px 24px' }}>
      {/* Header */}
      <div style={{ paddingBottom: 10 }}>
        <div className="mono-sm" style={{ color: 'var(--ink-3)', marginBottom: 2 }}>
          Your shortlist
        </div>
        <div style={{ display: 'flex', alignItems: 'flex-end', justifyContent: 'space-between' }}>
          <div className="display d-xl" style={{ fontSize: 26, fontWeight: 800 }}>
            Saved
          </div>
          <div style={{ display: 'flex', alignItems: 'baseline', gap: 4 }}>
            <span className="display d-md" style={{ color: 'var(--orange)', fontSize: 18, fontWeight: 800 }}>
              {validSavedPlaces.length}
            </span>
            <span className="mono-sm" style={{ color: 'var(--ink-3)' }}>
              places
            </span>
          </div>
        </div>
      </div>

      {/* Filter Segmented Control */}
      <div className="seg" style={{ marginBottom: 14, display: 'flex', background: 'var(--paper-2)', padding: 3, borderRadius: 10, border: '1.5px solid var(--ink)' }}>
        {filters.map((f) => (
          <button
            key={f}
            className={activeFilter === f ? 'on' : ''}
            onClick={() => setActiveFilter(f)}
            style={{
              flex: 1,
              padding: '6px 0',
              border: 0,
              borderRadius: 8,
              fontFamily: 'var(--body)',
              fontWeight: 700,
              fontSize: 11,
              cursor: 'pointer',
            }}
          >
            {f}
          </button>
        ))}
      </div>

      {/* Shared Plans with Friends Box */}
      {plans.length > 0 && (
        <div
          style={{
            border: '2px solid var(--ink)',
            borderRadius: 16,
            background: 'var(--mint)',
            padding: '11px 12px',
            boxShadow: 'var(--sh)',
            marginBottom: 16,
          }}
        >
          <div style={{ display: 'flex', alignItems: 'center', gap: 6, marginBottom: 8 }}>
            <Icon name="users" size={13} sw={2.4} />
            <span className="mono-sm" style={{ color: 'var(--ink)', fontWeight: 700 }}>
              {plans.length} upcoming plans with friends
            </span>
          </div>

          <div style={{ display: 'flex', flexDirection: 'column', gap: 4 }}>
            {plans.map((pl: FriendPlan) => {
              const p = getPlaceById(pl.placeId);
              if (!p) return null;

              return (
                <button
                  key={pl.id}
                  onClick={(e) => openPlace(pl.placeId, e.currentTarget)}
                  style={{
                    display: 'flex',
                    alignItems: 'center',
                    gap: 8,
                    width: '100%',
                    padding: '6px 0',
                    background: 'none',
                    border: 0,
                    borderTop: '1px solid rgba(21,19,15,.16)',
                    cursor: 'pointer',
                    textAlign: 'left',
                  }}
                >
                  <div style={{ display: 'flex', marginRight: 4 }}>
                    {pl.who.map((w: string, idx: number) => (
                      <div key={w} style={{ marginLeft: idx > 0 ? -6 : 0 }}>
                        <Avatar id={w} size={20} />
                      </div>
                    ))}
                  </div>

                  <span
                    style={{
                      fontSize: 12.5,
                      fontWeight: 700,
                      flex: 1,
                      overflow: 'hidden',
                      textOverflow: 'ellipsis',
                      whiteSpace: 'nowrap',
                    }}
                  >
                    {p.name}
                  </span>

                  <span className="pill fill-ink" style={{ height: 20, fontSize: 10 }}>
                    {pl.when}
                  </span>
                </button>
              );
            })}
          </div>
        </div>
      )}

      {/* Saved Place List */}
      <div style={{ display: 'flex', flexDirection: 'column', gap: 10 }}>
        {validSavedPlaces.length === 0 ? (
          <div
            style={{
              textAlign: 'center',
              padding: '40px 16px',
              background: 'var(--paper-2)',
              borderRadius: 16,
              border: '1.5px dashed var(--ink)',
            }}
          >
            <div className="display d-sm" style={{ fontSize: 16, marginBottom: 4 }}>
              Your shortlist is empty
            </div>
            <p className="mono-sm" style={{ fontSize: 11, color: 'var(--ink-3)', marginBottom: 14 }}>
              Bookmark places you want to visit so you never forget friend recommendations.
            </p>
            <button className="btn btn-primary btn-sm" onClick={() => switchTab('explore')}>
              Explore Barlow Hill
            </button>
          </div>
        ) : (
          validSavedPlaces.map((p: Place) => (
            <div key={p.id} style={{ display: 'flex', gap: 8, alignItems: 'stretch' }}>
              <button
                className="venrow"
                style={{
                  flex: 1,
                  display: 'flex',
                  alignItems: 'center',
                  gap: 10,
                  padding: 9,
                  background: 'var(--paper)',
                  border: '1.8px solid var(--ink)',
                  borderRadius: 14,
                  boxShadow: '2.5px 2.5px 0 var(--ink)',
                  textAlign: 'left',
                  cursor: 'pointer',
                }}
                onClick={(e) => openPlace(p.id, e.currentTarget)}
              >
                <div
                  style={{
                    width: 54,
                    height: 54,
                    borderRadius: 10,
                    overflow: 'hidden',
                    flexShrink: 0,
                    border: '1.5px solid var(--ink)',
                  }}
                >
                  <img src={p.img} alt="" style={{ width: '100%', height: '100%', objectFit: 'cover' }} />
                </div>

                <div style={{ flex: 1, minWidth: 0, display: 'flex', flexDirection: 'column', gap: 2 }}>
                  <div className="display d-sm" style={{ fontSize: 14.5, fontWeight: 700 }}>
                    {p.name}
                  </div>
                  <div className="mono-sm" style={{ color: 'var(--ink-3)', fontSize: 10 }}>
                    {p.cat} · {p.dist}
                  </div>
                  <div style={{ display: 'flex', alignItems: 'center', gap: 4 }}>
                    <StarRating rating={p.rating} size={8.5} />
                    <span style={{ fontSize: 10, fontWeight: 700 }}>{p.rating}</span>
                  </div>
                </div>
              </button>

              <button
                className="iconbtn"
                onClick={() => toggleSavePlace(p.id)}
                style={{
                  alignSelf: 'center',
                  background: 'var(--orange)',
                  color: '#FFFFFF',
                  borderColor: 'var(--ink)',
                  boxShadow: '2px 2px 0 var(--ink)',
                }}
                aria-label="Remove from saved"
                title="Remove from saved"
              >
                <Icon name="bookmark" size={14} sw={2.2} fill="currentColor" />
              </button>
            </div>
          ))
        )}
      </div>

      <button
        className="btn btn-ghost btn-block btn-sm"
        style={{ marginTop: 16, height: 38 }}
        onClick={() => switchTab('explore')}
      >
        <Icon name="compass" size={14} sw={2.2} /> Find More Places in Barlow Hill
      </button>
    </div>
  );
};
