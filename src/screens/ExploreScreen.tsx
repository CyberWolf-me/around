import React, { useState, useMemo } from 'react';
import { useApp } from '../context/AppContext';
import { CityMap } from '../components/map/CityMap';
import { Icon } from '../components/ui/Icon';
import { StarRating } from '../components/ui/StarRating';
import { CATEGORIES } from '../data/mockData';
import { Place } from '../types';

export const ExploreScreen: React.FC = () => {
  const {
    places,
    exploreMode,
    setExploreMode,
    savedPlaceIds,
    toggleSavePlace,
    openPlace,
  } = useApp();

  const [activeCategory, setActiveCategory] = useState<string>('All');
  const [searchQuery, setSearchQuery] = useState<string>('');
  const [selectedPlaceId, setSelectedPlaceId] = useState<string>('breadly');

  const filteredPlaces = useMemo(() => {
    return places.filter((p: Place) => {
      const matchesCategory =
        activeCategory === 'All' ||
        p.cat.toLowerCase().includes(activeCategory.toLowerCase()) ||
        p.tags.some((t: string) => t.toLowerCase().includes(activeCategory.toLowerCase()));

      const matchesSearch =
        !searchQuery.trim() ||
        p.name.toLowerCase().includes(searchQuery.toLowerCase()) ||
        p.street.toLowerCase().includes(searchQuery.toLowerCase()) ||
        p.cat.toLowerCase().includes(searchQuery.toLowerCase()) ||
        p.tags.some((t: string) => t.toLowerCase().includes(searchQuery.toLowerCase()));

      return matchesCategory && matchesSearch;
    });
  }, [places, activeCategory, searchQuery]);

  const selectedPlace = places.find((p: Place) => p.id === selectedPlaceId) || filteredPlaces[0] || places[0];

  return (
    <div className="screen explore-screen" style={{ padding: '8px 14px 20px' }}>
      {/* Top Header & Map/List Toggle */}
      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 12 }}>
        <div>
          <div className="mono" style={{ color: 'var(--ink-3)', fontSize: 9.5, marginBottom: 2 }}>
            Public Discovery · 41.31° N, 69.28° E
          </div>
          <div className="display d-lg" style={{ fontSize: 22, fontWeight: 800 }}>
            Tashkent
          </div>
        </div>

        {/* Segmented control for Map vs List */}
        <div className="seg" style={{ display: 'flex', background: 'var(--paper-2)', padding: 2, borderRadius: 10, border: '1.5px solid var(--ink)' }}>
          <button
            className={exploreMode === 'map' ? 'on' : ''}
            onClick={() => setExploreMode('map')}
            style={{ display: 'flex', alignItems: 'center', gap: 5, padding: '5px 12px', border: 0, borderRadius: 8, cursor: 'pointer', fontFamily: 'var(--body)', fontWeight: 700, fontSize: 11 }}
          >
            <Icon name="map" size={12} sw={2.4} /> Map
          </button>
          <button
            className={exploreMode === 'list' ? 'on' : ''}
            onClick={() => setExploreMode('list')}
            style={{ display: 'flex', alignItems: 'center', gap: 5, padding: '5px 12px', border: 0, borderRadius: 8, cursor: 'pointer', fontFamily: 'var(--body)', fontWeight: 700, fontSize: 11 }}
          >
            <Icon name="list" size={12} sw={2.4} /> List
          </button>
        </div>
      </div>

      {/* Search Input */}
      <div
        style={{
          display: 'flex',
          alignItems: 'center',
          gap: 8,
          background: 'var(--paper)',
          border: '1.8px solid var(--ink)',
          borderRadius: 12,
          padding: '8px 12px',
          boxShadow: '2px 2px 0 var(--ink)',
          marginBottom: 10,
        }}
      >
        <Icon name="search" size={15} sw={2.4} style={{ color: 'var(--ink-3)' }} />
        <input
          type="text"
          placeholder="Search Tashkent venues, districts, or tags..."
          value={searchQuery}
          onChange={(e) => setSearchQuery(e.target.value)}
          style={{
            border: 0,
            background: 'none',
            outline: 'none',
            width: '100%',
            fontFamily: 'var(--body)',
            fontSize: 12.5,
            color: 'var(--ink)',
          }}
        />
        {searchQuery && (
          <button
            onClick={() => setSearchQuery('')}
            style={{ background: 'none', border: 0, padding: 0, cursor: 'pointer', color: 'var(--ink-3)' }}
          >
            <Icon name="x" size={14} sw={2.4} />
          </button>
        )}
      </div>

      {/* Category Filter Chips */}
      <div className="scroll-x" style={{ paddingBottom: 10, marginBottom: 10, gap: 6 }}>
        {CATEGORIES.map((cat: string) => (
          <button
            key={cat}
            onClick={() => setActiveCategory(cat)}
            className={`pill ${activeCategory === cat ? 'fill-ink' : 'ghost'}`}
            style={{ cursor: 'pointer', whiteSpace: 'nowrap', height: 27, padding: '0 12px', fontSize: 11 }}
          >
            {cat}
          </button>
        ))}
      </div>

      {/* Content based on Mode */}
      {exploreMode === 'map' ? (
        <div style={{ display: 'flex', flexDirection: 'column', gap: 12 }}>
          {/* Interactive City Map */}
          <CityMap
            places={filteredPlaces}
            activePlaceId={selectedPlaceId}
            onSelectPlace={(id) => setSelectedPlaceId(id)}
          />

          {/* Active Place Preview Drawer Card */}
          {selectedPlace && (
            <div
              className="card-flat"
              style={{
                display: 'flex',
                gap: 10,
                padding: 10,
                background: 'var(--paper)',
                border: '2px solid var(--ink)',
                borderRadius: 16,
                boxShadow: '3px 3px 0 var(--ink)',
                cursor: 'pointer',
              }}
              onClick={(e) => openPlace(selectedPlace.id, e.currentTarget)}
            >
              <div
                style={{
                  width: 76,
                  height: 76,
                  borderRadius: 12,
                  overflow: 'hidden',
                  flexShrink: 0,
                  border: '1.5px solid var(--ink)',
                }}
              >
                <img
                  src={selectedPlace.img}
                  alt={selectedPlace.name}
                  style={{ width: '100%', height: '100%', objectFit: 'cover' }}
                />
              </div>

              <div style={{ flex: 1, minWidth: 0, display: 'flex', flexDirection: 'column', gap: 3 }}>
                <div style={{ display: 'flex', alignItems: 'baseline', justifyContent: 'space-between' }}>
                  <div className="display d-sm" style={{ fontSize: 15, fontWeight: 700 }}>
                    {selectedPlace.name}
                  </div>
                  <span className="mono-sm" style={{ color: 'var(--ink-3)', fontSize: 10 }}>
                    {selectedPlace.price}
                  </span>
                </div>

                <div className="mono-sm" style={{ color: 'var(--ink-2)', fontSize: 10.5 }}>
                  {selectedPlace.cat} · {selectedPlace.dist}
                </div>

                <div style={{ display: 'flex', alignItems: 'center', gap: 5, marginTop: 2 }}>
                  <StarRating rating={selectedPlace.rating} size={9} />
                  <span style={{ fontSize: 10.5, fontWeight: 700 }}>{selectedPlace.rating}</span>
                  <span className="mono-sm" style={{ color: 'var(--ink-3)', fontSize: 9.5 }}>
                    ({selectedPlace.reviews})
                  </span>

                  <span style={{ flex: 1 }} />

                  <button
                    onClick={(e) => {
                      e.stopPropagation();
                      toggleSavePlace(selectedPlace.id);
                    }}
                    style={{
                      background: 'none',
                      border: 0,
                      padding: 4,
                      cursor: 'pointer',
                      color: savedPlaceIds.includes(selectedPlace.id) ? 'var(--orange)' : 'var(--ink-3)',
                    }}
                    title="Bookmark place"
                  >
                    <Icon
                      name="bookmark"
                      size={16}
                      sw={2.2}
                      fill={savedPlaceIds.includes(selectedPlace.id) ? 'currentColor' : 'none'}
                    />
                  </button>
                </div>
              </div>
            </div>
          )}
        </div>
      ) : (
        /* List Mode */
        <div style={{ display: 'flex', flexDirection: 'column', gap: 10 }}>
          {filteredPlaces.length === 0 ? (
            <div style={{ textAlign: 'center', padding: '30px 10px', color: 'var(--ink-3)' }}>
              <div className="display d-sm" style={{ marginBottom: 4 }}>No venues found</div>
              <p className="mono-sm" style={{ fontSize: 11 }}>Try resetting your search query or filters.</p>
            </div>
          ) : (
            filteredPlaces.map((p: Place) => {
              const isSaved = savedPlaceIds.includes(p.id);

              return (
                <button
                  key={p.id}
                  className="venrow"
                  onClick={(e) => openPlace(p.id, e.currentTarget)}
                  style={{
                    display: 'flex',
                    alignItems: 'center',
                    gap: 10,
                    width: '100%',
                    padding: 9,
                    background: 'var(--paper)',
                    border: '1.8px solid var(--ink)',
                    borderRadius: 14,
                    boxShadow: '2.5px 2.5px 0 var(--ink)',
                    textAlign: 'left',
                    cursor: 'pointer',
                  }}
                >
                  <div
                    style={{
                      width: 58,
                      height: 58,
                      borderRadius: 10,
                      overflow: 'hidden',
                      flexShrink: 0,
                      border: '1.5px solid var(--ink)',
                    }}
                  >
                    <img
                      src={p.img}
                      alt={p.name}
                      style={{ width: '100%', height: '100%', objectFit: 'cover' }}
                    />
                  </div>

                  <div style={{ flex: 1, minWidth: 0, display: 'flex', flexDirection: 'column', gap: 3 }}>
                    <div style={{ display: 'flex', alignItems: 'baseline', justifyContent: 'space-between' }}>
                      <span
                        className="display d-sm"
                        style={{ fontSize: 14.5, fontWeight: 700, overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}
                      >
                        {p.name}
                      </span>
                      <span className="mono-sm" style={{ color: 'var(--ink-3)', fontSize: 10 }}>
                        {p.price}
                      </span>
                    </div>

                    <div className="mono-sm" style={{ color: 'var(--ink-2)', fontSize: 10 }}>
                      {p.cat} · {p.dist}
                    </div>

                    <div style={{ display: 'flex', alignItems: 'center', gap: 4 }}>
                      <StarRating rating={p.rating} size={8.5} />
                      <span style={{ fontSize: 10, fontWeight: 700 }}>{p.rating}</span>
                      <span className="mono-sm" style={{ color: 'var(--ink-3)', fontSize: 9 }}>
                        ({p.reviews})
                      </span>
                    </div>
                  </div>

                  <span
                    onClick={(e) => {
                      e.stopPropagation();
                      toggleSavePlace(p.id);
                    }}
                    style={{
                      padding: 6,
                      color: isSaved ? 'var(--orange)' : 'rgba(21,19,15,.35)',
                      display: 'flex',
                      alignItems: 'center',
                    }}
                  >
                    <Icon
                      name="bookmark"
                      size={15}
                      sw={2.2}
                      fill={isSaved ? 'currentColor' : 'none'}
                    />
                  </span>
                </button>
              );
            })
          )}
        </div>
      )}
    </div>
  );
};
