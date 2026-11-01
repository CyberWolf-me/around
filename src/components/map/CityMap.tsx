import React, { useState } from 'react';
import { Place } from '../../types';
import { COLORS } from '../../data/mockData';

export interface CityMapProps {
  places: Place[];
  activePlaceId?: string | null;
  onSelectPlace: (placeId: string) => void;
  showUserLocation?: boolean;
  className?: string;
}

export const CityMap: React.FC<CityMapProps> = ({
  places,
  activePlaceId,
  onSelectPlace,
  showUserLocation = true,
  className = '',
}) => {
  const [zoom, setZoom] = useState<number>(1);

  const blocks: Array<{ x: number; y: number; w: number; h: number; isPark: boolean; isWater: boolean; k: string }> = [];
  const cols = [0, 74, 148, 222, 296];
  const rows = [0, 62, 124, 186];

  cols.forEach((x, i) => {
    rows.forEach((y, j) => {
      const w = i === cols.length - 1 ? 366 - x - 6 : 62;
      const h = j === rows.length - 1 ? 250 - y - 6 : 50;
      if (w <= 0 || h <= 0) return;
      const isPark = i === 2 && j === 1;
      const isWater = i === 3 && j === 2;
      blocks.push({ x: x + 4, y: y + 4, w, h, isPark, isWater, k: `${i}-${j}` });
    });
  });

  return (
    <div className={`mapframe ${className}`} style={{ position: 'relative', width: '100%', borderRadius: 18, overflow: 'hidden', border: `2px solid ${COLORS.ink}`, boxShadow: 'var(--sh)' }}>
      <div style={{ transform: `scale(${zoom})`, transformOrigin: 'center center', transition: 'transform 0.25s ease', position: 'relative' }}>
        <svg viewBox="0 0 366 250" className="map-svg" style={{ display: 'block', width: '100%', height: 'auto', background: '#F3F0E4' }}>
          <rect width="366" height="250" fill="#F3F0E4" />

          {blocks.map(b => (
            <rect
              key={b.k}
              x={b.x}
              y={b.y}
              width={b.w}
              height={b.h}
              rx="3"
              fill={b.isPark ? '#CFE2C4' : b.isWater ? '#CBDCE7' : '#E9E4D5'}
              stroke="rgba(21, 19, 15, 0.30)"
              strokeWidth="1"
            />
          ))}

          <path d="M-4 232 L150 118 L250 118" stroke="#FBFAF6" strokeWidth="11" fill="none" />
          <path d="M-4 232 L150 118 L250 118" stroke="rgba(21,19,15,.24)" strokeWidth="1.4" fill="none" />
          <path d="M-4 232 L150 118 L250 118" stroke="#FBFAF6" strokeWidth="9" fill="none" />

          <text x="210" y="106" fontFamily="Space Mono, monospace" fontSize="6.5" fill="rgba(21,19,15,.55)" letterSpacing="1">
            AMIR TIMUR AVE
          </text>
          <text
            x="152"
            y="216"
            fontFamily="Space Mono, monospace"
            fontSize="6.5"
            fill="rgba(21,19,15,.55)"
            letterSpacing="1"
            transform="rotate(-38 152 216)"
          >
            SHOTA RUSTAVELI
          </text>
          <text x="174" y="152" fontFamily="Space Mono, monospace" fontSize="6" fill="rgba(21,19,15,.42)" letterSpacing=".8">
            SHEVCHENKO ST
          </text>
          <text x="34" y="96" fontFamily="Space Mono, monospace" fontSize="6" fill="rgba(21,19,15,.42)" letterSpacing=".8">
            ALISHER NAVOI
          </text>
        </svg>

        {places.map(p => {
          const coords = p.coords || { x: 50, y: 50 };
          const isActive = activePlaceId === p.id;

          return (
            <button
              key={p.id}
              className={`pin ${isActive ? 'on' : ''}`}
              style={{
                left: `${coords.x}%`,
                top: `${coords.y}%`,
                position: 'absolute',
                transform: 'translate(-50%, -50%)',
                background: 'none',
                border: 0,
                padding: 0,
                cursor: 'pointer',
                zIndex: isActive ? 20 : 10,
              }}
              onClick={() => onSelectPlace(p.id)}
              aria-label={p.name}
            >
              <span
                className="bulb"
                style={{
                  display: 'block',
                  width: isActive ? 34 : 26,
                  height: isActive ? 34 : 26,
                  borderRadius: '50%',
                  border: `2px solid ${isActive ? COLORS.orange : COLORS.ink}`,
                  boxShadow: isActive ? '0 0 0 3px rgba(255,90,31,0.3), 2px 2px 0 var(--ink)' : '2px 2px 0 var(--ink)',
                  overflow: 'hidden',
                  transition: 'all 0.2s cubic-bezier(0.2, 0.9, 0.3, 1)',
                  background: '#FFFFFF',
                }}
              >
                <img
                  src={p.img}
                  alt=""
                  style={{ width: '100%', height: '100%', objectFit: 'cover', display: 'block' }}
                />
              </span>

              {isActive && (
                <span
                  className="lbl"
                  style={{
                    position: 'absolute',
                    top: '100%',
                    left: '50%',
                    transform: 'translateX(-50%)',
                    marginTop: 4,
                    background: COLORS.ink,
                    color: COLORS.paper,
                    padding: '2px 7px',
                    borderRadius: 6,
                    fontFamily: 'var(--mono)',
                    fontSize: 8.5,
                    fontWeight: 700,
                    whiteSpace: 'nowrap',
                    boxShadow: '2px 2px 0 rgba(0,0,0,0.2)',
                    zIndex: 30,
                  }}
                >
                  {p.name}
                </span>
              )}
            </button>
          );
        })}

        {showUserLocation && (
          <span
            className="map-me"
            style={{
              position: 'absolute',
              left: '47%',
              top: '52%',
              transform: 'translate(-50%, -50%)',
              width: 14,
              height: 14,
              borderRadius: '50%',
              background: COLORS.orange,
              border: '2.5px solid #FFFFFF',
              boxShadow: '0 0 0 2px var(--ink), 0 0 12px rgba(255,90,31,0.6)',
              zIndex: 15,
              pointerEvents: 'none',
            }}
            title="Your location in Tashkent"
          />
        )}
      </div>

      {/* Zoom Controls */}
      <div style={{ position: 'absolute', right: 8, bottom: 8, display: 'flex', flexDirection: 'column', gap: 4, zIndex: 35 }}>
        <button
          type="button"
          onClick={() => setZoom(z => Math.min(1.6, +(z + 0.2).toFixed(1)))}
          style={{ width: 28, height: 28, borderRadius: 8, border: `1.5px solid ${COLORS.ink}`, background: COLORS.paper, fontWeight: 800, cursor: 'pointer' }}
          aria-label="Zoom In"
        >
          +
        </button>
        <button
          type="button"
          onClick={() => setZoom(z => Math.max(1.0, +(z - 0.2).toFixed(1)))}
          style={{ width: 28, height: 28, borderRadius: 8, border: `1.5px solid ${COLORS.ink}`, background: COLORS.paper, fontWeight: 800, cursor: 'pointer' }}
          aria-label="Zoom Out"
        >
          −
        </button>
      </div>
    </div>
  );
};
