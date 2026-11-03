import React, { useState } from 'react';
import { playSoundWithHaptic } from '../services/soundEffects';

export interface CuratorLeaderboardEntry {
  id: string;
  name: string;
  handle: string;
  district: string;
  dropsCount: number;
  streakWeeks: number;
  archetype?: string;
  avatarBg?: string;
  initials?: string;
}

export const DEFAULT_CURATORS: CuratorLeaderboardEntry[] = [
  {
    id: 'kamila',
    name: 'Kamila Rahimova',
    handle: 'kamilar',
    district: 'Mirabad',
    dropsCount: 32,
    streakWeeks: 6,
    archetype: 'Specialty Connoisseur',
    avatarBg: '#FFE07A',
    initials: 'KR',
  },
  {
    id: 'aziza',
    name: 'Aziza Tursunova',
    handle: 'azizatur',
    district: 'Yunusabad',
    dropsCount: 29,
    streakWeeks: 6,
    archetype: 'Old City Gourmet',
    avatarBg: '#D7E3EC',
    initials: 'AT',
  },
  {
    id: 'madina',
    name: 'Madina Karimova',
    handle: 'madina_k',
    district: 'Central Tashkent',
    dropsCount: 24,
    streakWeeks: 4,
    archetype: 'Specialty Connoisseur',
    avatarBg: '#2B4CFF',
    initials: 'MK',
  },
  {
    id: 'yusuf',
    name: 'Yusuf Okonjo',
    handle: 'yusuf',
    district: 'Mirabad',
    dropsCount: 22,
    streakWeeks: 5,
    archetype: 'All-Around Tashkent Explorer',
    avatarBg: '#FF5A1F',
    initials: 'YO',
  },
  {
    id: 'jasur',
    name: 'Jasur Rahmonov',
    handle: 'jasur_r',
    district: 'Old City',
    dropsCount: 21,
    streakWeeks: 5,
    archetype: 'Old City Gourmet',
    avatarBg: '#F6D2C4',
    initials: 'JR',
  },
  {
    id: 'rustam',
    name: 'Rustam Saidov',
    handle: 'rustam_s',
    district: 'Central Tashkent',
    dropsCount: 19,
    streakWeeks: 3,
    archetype: 'Urban Culturist',
    avatarBg: '#FFE07A',
    initials: 'RS',
  },
  {
    id: 'bekzod',
    name: 'Bekzod Alimov',
    handle: 'bekalimov',
    district: 'Yakkasaray',
    dropsCount: 18,
    streakWeeks: 3,
    archetype: 'Urban Culturist',
    avatarBg: '#D5E8CB',
    initials: 'BA',
  },
  {
    id: 'diyor',
    name: 'Diyor Usmanov',
    handle: 'diyor_u',
    district: 'Mirabad',
    dropsCount: 16,
    streakWeeks: 2,
    archetype: 'Evening Epicurean',
    avatarBg: '#F6D2C4',
    initials: 'DU',
  },
];

export const DISTRICT_TABS = [
  'All',
  'Mirabad',
  'Central Tashkent',
  'Yakkasaray',
  'Old City',
  'Yunusabad',
] as const;

export interface CuratorLeaderboardProps {
  curators?: CuratorLeaderboardEntry[];
  initialDistrict?: string;
  onSelectCurator?: (curator: CuratorLeaderboardEntry) => void;
  className?: string;
}

export const CuratorLeaderboard: React.FC<CuratorLeaderboardProps> = ({
  curators = DEFAULT_CURATORS,
  initialDistrict = 'All',
  onSelectCurator,
  className = '',
}) => {
  const [selectedDistrict, setSelectedDistrict] = useState<string>(initialDistrict);

  const handleTabClick = (district: string) => {
    playSoundWithHaptic('click');
    setSelectedDistrict(district);
  };

  const filteredCurators = curators
    .filter((c) => {
      if (selectedDistrict === 'All') return true;
      return c.district.toLowerCase().includes(selectedDistrict.toLowerCase());
    })
    .sort((a, b) => {
      // Sort primarily by dropsCount, secondary by streakWeeks
      if (b.dropsCount !== a.dropsCount) {
        return b.dropsCount - a.dropsCount;
      }
      return b.streakWeeks - a.streakWeeks;
    });

  const topCurator = filteredCurators.length > 0 ? filteredCurators[0] : null;

  return (
    <div className={`curator-leaderboard ${className}`} data-testid="curator-leaderboard">
      {/* Header */}
      <div style={{ marginBottom: '16px' }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: '8px', marginBottom: '4px' }}>
          <span style={{ fontSize: '20px' }}>👑</span>
          <h2
            style={{
              fontFamily: 'var(--display, "Bricolage Grotesque", sans-serif)',
              fontSize: '18px',
              fontWeight: 800,
              color: 'var(--ink, #15130F)',
              margin: 0,
            }}
          >
            District Crown Leaderboard
          </h2>
        </div>
        <p
          style={{
            fontFamily: 'var(--font, "Instrument Sans", sans-serif)',
            fontSize: '12.5px',
            color: 'var(--ink2, #575247)',
            margin: 0,
          }}
        >
          Top tastemakers and local legends curating Tashkent neighborhoods
        </p>
      </div>

      {/* District Filter Tabs */}
      <div
        role="tablist"
        aria-label="Filter leaderboard by district"
        style={{
          display: 'flex',
          gap: '6px',
          overflowX: 'auto',
          paddingBottom: '8px',
          marginBottom: '16px',
          scrollbarWidth: 'none',
        }}
      >
        {DISTRICT_TABS.map((dist) => {
          const isActive = selectedDistrict === dist;
          return (
            <button
              key={dist}
              role="tab"
              aria-selected={isActive}
              data-testid={`district-tab-${dist.toLowerCase().replace(/\s+/g, '-')}`}
              onClick={() => handleTabClick(dist)}
              style={{
                padding: '6px 12px',
                borderRadius: '100px',
                fontSize: '11.5px',
                fontFamily: 'var(--mono, "Space Mono", monospace)',
                fontWeight: isActive ? 700 : 500,
                border: '1.2px solid',
                borderColor: isActive ? 'var(--orange, #FF5A1F)' : 'var(--paper3, #E6E1D3)',
                background: isActive ? 'var(--orange, #FF5A1F)' : 'var(--paper, #FBFAF6)',
                color: isActive ? '#FFFFFF' : 'var(--ink, #15130F)',
                cursor: 'pointer',
                whiteSpace: 'nowrap',
                transition: 'all 0.15s ease',
              }}
            >
              {dist}
            </button>
          );
        })}
      </div>

      {/* Top Legend Spotlight Card (if rank 1 exists) */}
      {topCurator && (
        <div
          data-testid="spotlight-legend-card"
          style={{
            background: 'linear-gradient(135deg, rgba(255, 90, 31, 0.08) 0%, rgba(255, 224, 122, 0.15) 100%)',
            border: '1.5px solid var(--orange, #FF5A1F)',
            borderRadius: '16px',
            padding: '14px 16px',
            marginBottom: '16px',
            boxShadow: '0 4px 12px rgba(255, 90, 31, 0.08)',
          }}
        >
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '8px' }}>
            <span
              data-testid="crown-badge"
              style={{
                fontFamily: 'var(--mono, "Space Mono", monospace)',
                fontSize: '9.5px',
                fontWeight: 700,
                letterSpacing: '0.8px',
                color: 'var(--orange, #FF5A1F)',
                textTransform: 'uppercase',
                display: 'inline-flex',
                alignItems: 'center',
                gap: '4px',
              }}
            >
              {`👑 ${selectedDistrict === 'All' ? 'Tashkent Legend' : `${selectedDistrict} Crown Holder`}`}
            </span>
            <span
              data-testid="streak-flair"
              style={{
                fontFamily: 'var(--mono, "Space Mono", monospace)',
                fontSize: '10px',
                fontWeight: 700,
                color: 'var(--orange, #FF5A1F)',
                background: 'rgba(255, 90, 31, 0.12)',
                padding: '2px 6px',
                borderRadius: '6px',
              }}
            >
              {`🔥 ${topCurator.streakWeeks} wk streak`}
            </span>
          </div>

          <div style={{ display: 'flex', alignItems: 'center', gap: '12px' }}>
            <div
              style={{
                width: '42px',
                height: '42px',
                borderRadius: '50%',
                background: topCurator.avatarBg || 'var(--orange, #FF5A1F)',
                color: 'var(--ink, #15130F)',
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
                fontFamily: 'var(--display, "Bricolage Grotesque", sans-serif)',
                fontWeight: 800,
                fontSize: '15px',
                border: '1.5px solid var(--ink, #15130F)',
              }}
            >
              {topCurator.initials || topCurator.name.slice(0, 2).toUpperCase()}
            </div>

            <div style={{ flex: 1, minWidth: 0 }}>
              <div style={{ display: 'flex', alignItems: 'center', gap: '6px' }}>
                <span
                  style={{
                    fontFamily: 'var(--display, "Bricolage Grotesque", sans-serif)',
                    fontWeight: 800,
                    fontSize: '14px',
                    color: 'var(--ink, #15130F)',
                  }}
                >
                  {topCurator.name}
                </span>
                <span
                  style={{
                    fontFamily: 'var(--mono, "Space Mono", monospace)',
                    fontSize: '11px',
                    color: 'var(--ink3, #8E8877)',
                  }}
                >
                  {`@${topCurator.handle}`}
                </span>
              </div>
              <div
                style={{
                  fontFamily: 'var(--font, "Instrument Sans", sans-serif)',
                  fontSize: '11.5px',
                  color: 'var(--ink2, #575247)',
                  marginTop: '2px',
                }}
              >
                {`📍 ${topCurator.district} · ${topCurator.dropsCount} verified drops · ${topCurator.archetype}`}
              </div>
            </div>

            <button
              data-testid={`btn-passport-preview-${topCurator.id}`}
              onClick={() => {
                playSoundWithHaptic('select');
                onSelectCurator?.(topCurator);
              }}
              style={{
                padding: '6px 10px',
                borderRadius: '8px',
                background: 'var(--ink, #15130F)',
                color: '#FFFFFF',
                border: 'none',
                fontFamily: 'var(--mono, "Space Mono", monospace)',
                fontSize: '10px',
                fontWeight: 700,
                cursor: 'pointer',
              }}
            >
              Passport →
            </button>
          </div>
        </div>
      )}

      {/* Curator List */}
      <div style={{ display: 'flex', flexDirection: 'column', gap: '8px' }}>
        {filteredCurators.map((curator, index) => {
          const rank = index + 1;
          const isRank1 = rank === 1;
          const rankIcon = rank === 1 ? '👑' : rank === 2 ? '🥈' : rank === 3 ? '🥉' : `#${rank}`;

          return (
            <div
              key={curator.id}
              data-testid={`curator-card-${curator.id}`}
              style={{
                display: 'flex',
                alignItems: 'center',
                gap: '12px',
                padding: '10px 14px',
                borderRadius: '12px',
                background: isRank1 ? 'var(--paper2, #F1EEE4)' : 'var(--paper, #FBFAF6)',
                border: '1px solid var(--paper3, #E6E1D3)',
                transition: 'transform 0.1s ease',
              }}
            >
              {/* Rank */}
              <div
                style={{
                  width: '26px',
                  textAlign: 'center',
                  fontFamily: 'var(--mono, "Space Mono", monospace)',
                  fontSize: rank <= 3 ? '14px' : '11px',
                  fontWeight: 700,
                  color: isRank1 ? 'var(--orange, #FF5A1F)' : 'var(--ink2, #575247)',
                }}
              >
                {rankIcon}
              </div>

              {/* Avatar */}
              <div
                style={{
                  width: '34px',
                  height: '34px',
                  borderRadius: '50%',
                  background: curator.avatarBg || 'var(--paper3, #E6E1D3)',
                  color: 'var(--ink, #15130F)',
                  display: 'flex',
                  alignItems: 'center',
                  justifyContent: 'center',
                  fontFamily: 'var(--display, "Bricolage Grotesque", sans-serif)',
                  fontWeight: 700,
                  fontSize: '12px',
                  border: '1px solid var(--ink, #15130F)',
                }}
              >
                {curator.initials || curator.name.slice(0, 2).toUpperCase()}
              </div>

              {/* Details */}
              <div style={{ flex: 1, minWidth: 0 }}>
                <div style={{ display: 'flex', alignItems: 'center', gap: '6px' }}>
                  <span
                    style={{
                      fontFamily: 'var(--display, "Bricolage Grotesque", sans-serif)',
                      fontWeight: 700,
                      fontSize: '13px',
                      color: 'var(--ink, #15130F)',
                      overflow: 'hidden',
                      textOverflow: 'ellipsis',
                      whiteSpace: 'nowrap',
                    }}
                  >
                    {curator.name}
                  </span>
                  <span
                    style={{
                      fontFamily: 'var(--mono, "Space Mono", monospace)',
                      fontSize: '10.5px',
                      color: 'var(--ink3, #8E8877)',
                    }}
                  >
                    {`@${curator.handle}`}
                  </span>
                </div>
                <div
                  style={{
                    display: 'flex',
                    alignItems: 'center',
                    gap: '8px',
                    fontFamily: 'var(--font, "Instrument Sans", sans-serif)',
                    fontSize: '11px',
                    color: 'var(--ink2, #575247)',
                    marginTop: '2px',
                  }}
                >
                  <span>{`📍 ${curator.district}`}</span>
                  <span>·</span>
                  <span style={{ fontWeight: 600 }}>{`${curator.dropsCount} drops`}</span>
                  {curator.streakWeeks > 0 && (
                    <>
                      <span>·</span>
                      <span style={{ color: 'var(--orange, #FF5A1F)', fontWeight: 700 }}>
                        {`🔥 ${curator.streakWeeks}w`}
                      </span>
                    </>
                  )}
                </div>
              </div>

              {/* Action */}
              <button
                data-testid={`btn-passport-${curator.id}`}
                onClick={() => {
                  playSoundWithHaptic('select');
                  onSelectCurator?.(curator);
                }}
                style={{
                  background: 'none',
                  border: 'none',
                  color: 'var(--orange, #FF5A1F)',
                  fontFamily: 'var(--mono, "Space Mono", monospace)',
                  fontSize: '11px',
                  fontWeight: 700,
                  cursor: 'pointer',
                  padding: '4px',
                }}
              >
                →
              </button>
            </div>
          );
        })}

        {filteredCurators.length === 0 && (
          <div
            data-testid="empty-curators"
            style={{
              padding: '24px',
              textAlign: 'center',
              fontFamily: 'var(--font, "Instrument Sans", sans-serif)',
              fontSize: '13px',
              color: 'var(--ink3, #8E8877)',
            }}
          >
            {`No curators found for ${selectedDistrict}. Be the first to drop a spot!`}
          </div>
        )}
      </div>
    </div>
  );
};
