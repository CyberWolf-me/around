import React, { useState } from 'react';

export interface WebCityPassportProps {
  username: string;
  neighborhood?: string;
  dropsCount?: number;
  visitedDistricts?: string[];
  crownsCount?: number;
  initialTab?: 'stamps' | 'crowns';
  locale?: 'en' | 'uz' | 'ru';
}

const TASHKENT_DISTRICTS = [
  'Mirabad',
  'Yakkasaray',
  'Shaykhontohur',
  'Yunusabad',
  'Chilanzar',
  'Mirzo Ulugbek',
  'Almazar',
  'Uchtepa',
  'Yashnabad',
  'Sergeli',
  'Yangihayot',
  'Bektemir',
];

export const WebCityPassport: React.FC<WebCityPassportProps> = ({
  username,
  neighborhood = 'Mirabad',
  dropsCount = 0,
  visitedDistricts = ['Mirabad'],
  crownsCount = 1,
  initialTab = 'stamps',
}) => {
  const [activeTab, setActiveTab] = useState<'stamps' | 'crowns'>(initialTab);

  const visitedSet = new Set(visitedDistricts.map((d) => d.toLowerCase()));
  if (neighborhood) visitedSet.add(neighborhood.toLowerCase());

  return (
    <div
      data-testid="web-city-passport"
      style={{
        background: 'var(--paper)',
        borderRadius: 20,
        border: '2px solid var(--ink)',
        overflow: 'hidden',
        boxShadow: 'var(--shadow-card)',
      }}
    >
      {/* Ribbon Header */}
      <div
        style={{
          background: 'var(--ink)',
          color: 'var(--paper)',
          padding: '12px 16px',
          display: 'flex',
          justifyContent: 'space-between',
          alignItems: 'center',
        }}
      >
        <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
          <div
            style={{
              width: 10,
              height: 10,
              borderRadius: '50%',
              background: 'var(--orange)',
            }}
          />
          <span className="mono-sm" style={{ fontWeight: 800, letterSpacing: '0.06em', fontSize: 11 }}>
            TASHKENT CITY PASSPORT · @{username}
          </span>
        </div>
        <div
          style={{
            background: 'var(--butter)',
            color: 'var(--ink)',
            padding: '2px 8px',
            borderRadius: 6,
            border: '1px solid var(--ink)',
            fontSize: 9,
            fontWeight: 700,
            fontFamily: 'monospace',
          }}
        >
          {visitedSet.size}/12 DISTRICTS
        </div>
      </div>

      {/* Tabs */}
      <div
        style={{
          display: 'flex',
          gap: 8,
          padding: 8,
          background: 'var(--paper-2)',
          borderBottom: '1px solid var(--border-subtle)',
        }}
      >
        <button
          data-testid="tab-stamps"
          style={{
            flex: 1,
            padding: '8px 12px',
            borderRadius: 10,
            border: activeTab === 'stamps' ? '1.5px solid var(--border-subtle)' : 'none',
            background: activeTab === 'stamps' ? 'var(--paper)' : 'transparent',
            fontWeight: activeTab === 'stamps' ? 700 : 500,
            color: activeTab === 'stamps' ? 'var(--ink)' : 'var(--ink-3)',
            cursor: 'pointer',
            fontSize: 12,
          }}
          onClick={() => setActiveTab('stamps')}
        >
          🏷️ District & Metro Stamps
        </button>
        <button
          data-testid="tab-crowns"
          style={{
            flex: 1,
            padding: '8px 12px',
            borderRadius: 10,
            border: activeTab === 'crowns' ? '1.5px solid var(--border-subtle)' : 'none',
            background: activeTab === 'crowns' ? 'var(--paper)' : 'transparent',
            fontWeight: activeTab === 'crowns' ? 700 : 500,
            color: activeTab === 'crowns' ? 'var(--ink)' : 'var(--ink-3)',
            cursor: 'pointer',
            fontSize: 12,
          }}
          onClick={() => setActiveTab('crowns')}
        >
          👑 Territory Crowns
        </button>
      </div>

      {/* Content */}
      <div style={{ padding: 16 }}>
        {activeTab === 'stamps' ? (
          <div>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'baseline', marginBottom: 10 }}>
              <span style={{ fontSize: 13, fontWeight: 700 }}>12 Tashkent Districts</span>
              <span className="mono-sm" style={{ color: 'var(--orange)', fontWeight: 700, fontSize: 11 }}>
                {Math.round((visitedSet.size / 12) * 100)}% Explored
              </span>
            </div>
            <div style={{ display: 'flex', flexWrap: 'wrap', gap: 6, marginBottom: 14 }}>
              {TASHKENT_DISTRICTS.map((dist) => {
                const visited = visitedSet.has(dist.toLowerCase());
                return (
                  <span
                    key={dist}
                    style={{
                      display: 'inline-flex',
                      alignItems: 'center',
                      gap: 4,
                      padding: '4px 8px',
                      borderRadius: 6,
                      fontSize: 11,
                      fontWeight: visited ? 700 : 500,
                      background: visited ? 'var(--mint)' : 'var(--paper-2)',
                      border: `1px solid ${visited ? '#A3D9A5' : 'var(--border-hairline)'}`,
                      color: visited ? 'var(--ink)' : 'var(--ink-3)',
                    }}
                  >
                    <span>{visited ? '✓' : '○'}</span>
                    <span>{dist}</span>
                  </span>
                );
              })}
            </div>
            <div style={{ borderTop: '1px solid var(--border-hairline)', paddingTop: 12 }}>
              <div style={{ fontSize: 12, fontWeight: 700, marginBottom: 8 }}>Ceramic Metro Seals</div>
              <div style={{ display: 'flex', gap: 6 }}>
                <span
                  style={{
                    flex: 1,
                    textAlign: 'center',
                    padding: '6px 4px',
                    borderRadius: 6,
                    fontSize: 10,
                    fontWeight: 700,
                    background: 'rgba(229, 57, 53, 0.1)',
                    border: '1px solid rgba(229, 57, 53, 0.4)',
                    color: '#E53935',
                  }}
                >
                  Chilanzar Red
                </span>
                <span
                  style={{
                    flex: 1,
                    textAlign: 'center',
                    padding: '6px 4px',
                    borderRadius: 6,
                    fontSize: 10,
                    fontWeight: 700,
                    background: 'rgba(30, 136, 229, 0.1)',
                    border: '1px solid rgba(30, 136, 229, 0.4)',
                    color: '#1E88E5',
                  }}
                >
                  Uzbekistan Blue
                </span>
                <span
                  style={{
                    flex: 1,
                    textAlign: 'center',
                    padding: '6px 4px',
                    borderRadius: 6,
                    fontSize: 10,
                    fontWeight: 700,
                    background: 'rgba(67, 160, 71, 0.1)',
                    border: '1px solid rgba(67, 160, 71, 0.4)',
                    color: '#43A047',
                  }}
                >
                  Yunusabad Green
                </span>
              </div>
            </div>
          </div>
        ) : (
          <div>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'baseline', marginBottom: 10 }}>
              <span style={{ fontSize: 13, fontWeight: 700 }}>Territory Crowns ("Strava for Places")</span>
              <span
                style={{
                  background: 'var(--butter)',
                  border: '1px solid var(--ink)',
                  fontSize: 9,
                  fontWeight: 700,
                  padding: '2px 6px',
                  borderRadius: 4,
                }}
              >
                LIVE STANDINGS
              </span>
            </div>
            <div
              style={{
                display: 'flex',
                alignItems: 'center',
                gap: 12,
                padding: 12,
                borderRadius: 12,
                background: 'var(--paper-2)',
                border: '1px solid var(--border-subtle)',
                marginBottom: 10,
              }}
            >
              <div
                style={{
                  width: 40,
                  height: 40,
                  borderRadius: '50%',
                  background: 'var(--butter)',
                  display: 'flex',
                  alignItems: 'center',
                  justifyContent: 'center',
                  fontSize: 20,
                }}
              >
                👑
              </div>
              <div>
                <div style={{ fontSize: 13, fontWeight: 700, color: 'var(--ink)' }}>
                  {neighborhood} Tastemaker
                </div>
                <div style={{ fontSize: 11, color: 'var(--ink-2)' }}>
                  Rank #{crownsCount >= 1 ? 1 : 2} local tastemaker · {dropsCount} verified drops
                </div>
              </div>
            </div>
            <p style={{ fontSize: 11, color: 'var(--ink-3)', margin: 0, lineHeight: 1.4 }}>
              Crowns are earned by check-in density, high-signal recommendations, and friend saves in each neighborhood.
            </p>
          </div>
        )}
      </div>
    </div>
  );
};
